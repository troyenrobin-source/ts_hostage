-- Gijzelingsinhoud blijft hier; transport en screenshots lopen via ts_bridge.
HostageLog = {}
local weaponNames = {}
for name in pairs(Config.Weapons) do weaponNames[HostageWeaponHash(GetHashKey(name))] = name end
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
function HostageLog.Event(s, action, reason)
    if not WebhookConfig.Enabled then return end
    if action == 'automatic' and not WebhookConfig.LogAutomaticRelease then return end
    local url = action == 'start' and WebhookConfig.Start or WebhookConfig.Actions
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
    exports['ts_bridge']:SendWebhook(action == 'start' and 'start' or 'actions', url, payload, {
        screenshot = WebhookConfig.Screenshots == true,
        playerId = s.captor
    })
end
