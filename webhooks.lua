-- Geen net-events: alleen door de gevalideerde serversessies aangeroepen.
HostageLog = {}
local queue, processing, pendingPhotos = {}, false, 0
local weaponNames = {}
for name in pairs(Config.Weapons) do weaponNames[HostageWeaponHash(GetHashKey(name))] = name end
local function warning(message) print('^3[ts_hostage webhook] ' .. message .. '^7') end
local function urlValid(url)
    return type(url) == 'string' and (
        url:match('^https://discord%.com/api/webhooks/%d+/[%w_-]+$') ~= nil
        or url:match('^https://discord%.com/api/v%d+/webhooks/%d+/[%w_-]+$') ~= nil)
end
local function safeName(id)
    local ok, value = pcall(WebhookConfig.PlayerName, id)
    local name = ok and type(value) == 'string' and value or GetPlayerName(id) or 'Onbekend'
    name = name:gsub('[%c`*_~|<>]', '')
    -- Begrens op UTF-8-codepunten: knip geen multibyte teken doormidden.
    local valid, offset = pcall(utf8.offset, name, 101)
    if not valid then name = 'Onbekend' elseif offset then name = name:sub(1, offset - 1) end
    return name .. ' (ID: ' .. tostring(id) .. ')'
end
function HostageLog.Snapshot(s)
    s.logNames = { captor = safeName(s.captor), victim = safeName(s.victim) }
end
local alphabet = 'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/'
local values = {}
for i = 1, #alphabet do values[alphabet:byte(i)] = i - 1 end
local function decodeJpeg(uri)
    if type(uri) ~= 'string' or #uri > math.ceil(WebhookConfig.MaxImageBytes / 3) * 4 + 64 then return nil end
    local encoded = uri:match('^data:image/jpeg;base64,([A-Za-z0-9+/=]+)$')
        or uri:match('^data:image/jpg;base64,([A-Za-z0-9+/=]+)$')
    if not encoded or #encoded % 4 ~= 0 then return nil end
    local blocks = {}
    for i = 1, #encoded, 4 do
        local a, b, c, d = encoded:byte(i, i + 3)
        local x, y, z, w = values[a], values[b], values[c], values[d]
        if not x or not y or (not z and c ~= 61) or (not w and d ~= 61) then return nil end
        if (c == 61 or d == 61) and i ~= #encoded - 3 then return nil end
        if c == 61 and d ~= 61 then return nil end
        local n = (x << 18) | (y << 12) | ((z or 0) << 6) | (w or 0)
        local part = string.char((n >> 16) & 255)
        if c ~= 61 then part = part .. string.char((n >> 8) & 255) end
        if d ~= 61 then part = part .. string.char(n & 255) end
        blocks[#blocks + 1] = part
    end
    local bytes = table.concat(blocks)
    if #bytes > WebhookConfig.MaxImageBytes or bytes:sub(1, 3) ~= '\255\216\255' then return nil end
    return bytes
end
local function bodyFor(item)
    if not item.image then return json.encode(item.payload), 'application/json' end
    -- Boundary mag niet voorkomen in de afbeelding.
    local boundary = 'tsHostageBoundary' .. tostring(GetGameTimer())
    while item.image:find(boundary, 1, true) do boundary = boundary .. 'x' end
    local body = '--' .. boundary .. '\r\nContent-Disposition: form-data; name="payload_json"\r\nContent-Type: application/json\r\n\r\n'
        .. json.encode(item.payload) .. '\r\n--' .. boundary
        .. '\r\nContent-Disposition: form-data; name="files[0]"; filename="gijzeling.jpg"\r\nContent-Type: image/jpeg\r\n\r\n'
        .. item.image .. '\r\n--' .. boundary .. '--\r\n'
    return body, 'multipart/form-data; boundary=' .. boundary
end
local pump
pump = function()
    if processing or #queue == 0 then return end
    processing = true
    local item = queue[1]
    local body, contentType = bodyFor(item)
    local responded = false
    local function done(status, response)
        if responded then return end
        responded = true
        if status == 429 and item.retries < 3 then
            item.retries = item.retries + 1
            local ok, data = pcall(json.decode, response or '')
            local seconds = ok and type(data) == 'table' and tonumber(data.retry_after) or 2
            if not seconds or seconds ~= seconds then seconds = 2 end
            SetTimeout(math.floor(math.max(1, math.min(seconds, 60)) * 1000), function()
                processing = false; pump()
            end)
            return
        end
        if status < 200 or status >= 300 then warning('Versturen mislukt (HTTP ' .. tostring(status) .. '). Controleer server_config.lua; URL wordt niet gelogd.') end
        table.remove(queue, 1)
        SetTimeout(1000, function() processing = false; pump() end)
    end
    local ok = pcall(PerformHttpRequest, item.url, function(status, response) done(tonumber(status) or 0, response) end,
        'POST', body, { ['Content-Type'] = contentType }, { followLocation = false })
    if not ok then done(0, '') end
    -- Geen automatische POST-herhaling bij time-outs: voorkomt dubbele Discord-logs.
    SetTimeout(30000, function() done(0, '') end)
end
local function enqueue(url, payload, image)
    if #queue >= WebhookConfig.MaxQueue then warning('Wachtrij vol; log overgeslagen.'); return end
    queue[#queue + 1] = { url = url, payload = payload, image = image, retries = 0 }
    pump()
end
function HostageLog.Event(s, action, reason)
    if not WebhookConfig.Enabled then return end
    if action == 'automatic' and not WebhookConfig.LogAutomaticRelease then return end
    local url = action == 'start' and WebhookConfig.Start or WebhookConfig.Actions
    if url == '' then return end
    if not urlValid(url) then warning('Ongeldige webhook-URL in server_config.lua. Gebruik https://discord.com/api/webhooks/...'); return end
    if #queue + pendingPhotos >= WebhookConfig.MaxQueue then warning('Wachtrij vol; log overgeslagen.'); return end
    local titles = { start = 'Gijzeling gestart', release = 'Gijzelaar losgelaten', execute = 'Gijzelaar omgelegd', automatic = 'Gijzeling automatisch beëindigd' }
    local names = s.logNames or { captor = safeName(s.captor), victim = safeName(s.victim) }
    local fields = {
        { name = 'Gijzelnemer', value = names.captor, inline = true },
        { name = 'Gegijzelde', value = names.victim, inline = true },
        { name = 'Wapen', value = weaponNames[s.weapon] or tostring(s.weapon), inline = false },
        { name = 'Situatie', value = s.vehicle ~= 0 and 'In een auto' or 'Te voet', inline = true },
        { name = 'Actie', value = titles[action] or action, inline = true }
    }
    if reason then fields[#fields + 1] = { name = 'Reden', value = reason, inline = false } end
    local embed = { title = titles[action], color = action == 'execute' and 15158332 or action == 'start' and 16753920 or 3066993,
        fields = fields, timestamp = os.date('!%Y-%m-%dT%H:%M:%SZ'),
        footer = { text = 'TroyScripts | Sessie ' .. tostring(s.id) .. ' | Screenshot vanuit gijzelnemer' } }
    local payload = { username = WebhookConfig.Username, allowed_mentions = { parse = {} }, embeds = { embed } }
    if WebhookConfig.AvatarUrl:match('^https://') then payload.avatar_url = WebhookConfig.AvatarUrl end
    if not WebhookConfig.Screenshots or GetResourceState('screenshot-basic') ~= 'started' or not GetPlayerName(s.captor) then
        embed.description = 'Geen screenshot beschikbaar.'
        enqueue(url, payload); return
    end
    pendingPhotos = pendingPhotos + 1
    local completed = false
    local function complete(image)
        if completed then return end
        completed = true
        pendingPhotos = pendingPhotos - 1
        if image then
            embed.image = { url = 'attachment://gijzeling.jpg' }
            payload.attachments = { { id = 0, filename = 'gijzeling.jpg' } }
        else embed.description = 'Screenshot niet beschikbaar of verlopen; actie wel geregistreerd.' end
        enqueue(url, payload, image)
    end
    SetTimeout(WebhookConfig.ScreenshotTimeoutMs, function() complete(nil) end)
    local ok = pcall(function()
        exports['screenshot-basic']:requestClientScreenshot(s.captor, { encoding = 'jpg', quality = 0.65 }, function(err, data)
            if completed then return end
            complete(not err and decodeJpeg(data) or nil)
        end)
    end)
    if not ok then complete(nil) end
end
