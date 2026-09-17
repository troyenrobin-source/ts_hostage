if not TSBridgeGuard.Await() then return end
-- Gijzelingsinhoud blijft hier; transport en screenshots lopen via ts_bridge.
HostageLog = {}
local weaponNames = {}
for name in pairs(Config.Weapons) do weaponNames[HostageWeaponHash(GetHashKey(name))] = name end
local function safeName(id)
    local ok, value = pcall(WebhookConfig.PlayerName, id)
    local name = ok and type(value) == 'string' and value or GetPlayerName(id) or TSL('webhooks_onbekend')
    name = name:gsub('[%c`*_~|<>]', '')
    -- Begrens op UTF-8-codepunten: knip geen multibyte teken doormidden.
    local valid, offset = pcall(utf8.offset, name, 101)
    if not valid then name = TSL('webhooks_onbekend') elseif offset then name = name:sub(1, offset - 1) end
    return name .. TSL('webhooks_id') .. tostring(id) .. ')'
end
function HostageLog.Snapshot(s)
    s.logNames = { captor = safeName(s.captor), victim = safeName(s.victim) }
end
function HostageLog.Event(s, action, reason)
    if not TSBridgeGuard.IsReady() then return end
    if not WebhookConfig.Enabled then return end
    if action == 'automatic' and not WebhookConfig.LogAutomaticRelease then return end
    local url = action == 'start' and WebhookConfig.Start or WebhookConfig.Actions
    local titles = { start = TSL('webhooks_gijzeling_gestart'), release = TSL('webhooks_gijzelaar_losgelaten'), execute = TSL('webhooks_gijzelaar_omgelegd'), automatic = TSL('webhooks_gijzeling_automatisch_beeindigd') }
    local names = s.logNames or { captor = safeName(s.captor), victim = safeName(s.victim) }
    local fields = {
        { name = TSL('webhooks_gijzelnemer'), value = names.captor, inline = true },
        { name = TSL('webhooks_gegijzelde'), value = names.victim, inline = true },
        { name = TSL('webhooks_wapen'), value = weaponNames[s.weapon] or tostring(s.weapon), inline = false },
        { name = TSL('webhooks_situatie'), value = s.vehicle ~= 0 and TSL('webhooks_in_een_auto') or TSL('webhooks_te_voet'), inline = true },
        { name = TSL('webhooks_actie'), value = titles[action] or action, inline = true }
    }
    if reason then fields[#fields + 1] = { name = TSL('webhooks_reden'), value = reason, inline = false } end
    local embed = { title = titles[action], color = action == 'execute' and 15158332 or action == 'start' and 16753920 or 3066993,
        fields = fields, timestamp = os.date('!%Y-%m-%dT%H:%M:%SZ'),
        footer = { text = TSL('webhooks_troyscripts_sessie') .. tostring(s.id) .. TSL('webhooks_screenshot_vanuit_gijzelnemer') } }
    local payload = { username = WebhookConfig.Username, allowed_mentions = { parse = {} }, embeds = { embed } }
    if WebhookConfig.AvatarUrl:match('^https://') then payload.avatar_url = WebhookConfig.AvatarUrl end
    exports['ts_bridge']:SendWebhook(action == 'start' and 'start' or 'actions', url, payload, {
        screenshot = WebhookConfig.Screenshots == true,
        playerId = s.captor
    })
end
