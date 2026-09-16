local timers, requests, encoded = {}, {}, nil
local photoCallback, resource = nil, 'started'
function GetHashKey(x) return x end
function GetPlayerName(id) return 'Speler ' .. id end
function GetGameTimer() return 1000 end
function GetResourceState() return resource end
function SetTimeout(ms, f) timers[#timers + 1] = { ms = ms, f = f } end
function PerformHttpRequest(url, cb, method, body, headers)
 requests[#requests + 1] = { url = url, cb = cb, method = method, body = body, headers = headers }
end
json = { encode = function(t) encoded = t; return '{}' end, decode = function() return { retry_after = 1 } end }
exports = { ['screenshot-basic'] = { requestClientScreenshot = function(_, id, options, cb) photoCallback = cb end } }
dofile('config.lua'); dofile('server_config.lua'); dofile('webhooks.lua')
WebhookConfig.Start = 'https://discord.com/api/webhooks/123/start_token'
WebhookConfig.Actions = 'https://discord.com/api/webhooks/456/action_token'
local s = { id = 7, captor = 1, victim = 2, weapon = 'WEAPON_KNIFE', vehicle = 0 }
HostageLog.Snapshot(s)
HostageLog.Event(s, 'start')
assert(#requests == 0, 'wait for screenshot')
photoCallback(false, 'data:image/jpeg;base64,/9j/')
assert(#requests == 1 and requests[1].url == WebhookConfig.Start)
assert(requests[1].body:find('\255\216\255', 1, true), 'binary attachment')
assert(encoded.embeds[1].image.url == 'attachment://gijzeling.jpg')
assert(encoded.embeds[1].fields[1].value == 'Speler 1 (ID: 1)')
assert(encoded.embeds[1].fields[2].value == 'Speler 2 (ID: 2)')
assert(encoded.embeds[1].fields[3].value == 'WEAPON_KNIFE')
photoCallback(false, 'data:image/jpeg;base64,/9j/'); assert(#requests == 1, 'duplicate photo callback')
requests[1].cb(204, '')
timers[#timers].f() -- spacing timer
resource = 'stopped'
HostageLog.Event(s, 'release', 'Loslaten')
assert(#requests == 2 and requests[2].url == WebhookConfig.Actions)
assert(requests[2].headers['Content-Type'] == 'application/json')
assert(encoded.embeds[1].title == 'Gijzelaar losgelaten')
requests[2].cb(429, '{}');timers[#timers].f()
assert(#requests == 3, 'rate limit retry')
requests[3].cb(204, '');timers[#timers].f()
resource = 'started'
HostageLog.Event(s, 'execute')
local timeout = timers[#timers]
assert(timeout.ms == 8000);timeout.f()
assert(#requests == 4 and encoded.embeds[1].title == 'Gijzelaar omgelegd')
assert(not encoded.embeds[1].image, 'photo timeout sends text')
photoCallback(false, 'data:image/jpeg;base64,/9j/');assert(#requests == 4, 'late callback ignored')
requests[4].cb(204, '');timers[#timers].f()
WebhookConfig.Start = 'http://invalid.example/test'
HostageLog.Event(s, 'start');assert(#requests == 4, 'reject wrong webhook host')
print('PASS: two destinations, identities, weapon, JPEG multipart, fallback, timeout, duplicate callback, 429')
