dofile('locales/nl.lua'); dofile('locale.lua')
function IsDuplicityVersion() return true end
function GetCurrentResourceName() return 'ts_bridge' end
function GetInvokingResource() return 'ts_hostage' end
TSBridgeConfig = { Version = '0.0.3' }
local api = {}
exports = setmetatable({ ts_bridge = setmetatable({}, { __index = function(_, n)
 return function(_, ...) return api[n](...) end end }) }, { __call = function(_, n, fn) api[n] = fn end })
-- Load bridge locale while preserving hostage keys.
local old = Locales.nl; dofile('../ts_bridge/locales/nl.lua')
for k,v in pairs(old) do Locales.nl[k] = v end
dofile('../ts_bridge/config_version.lua')
TSBridgeGuard = { Await = function() return true end }

Config = {}; dofile('config_check.lua')
assert(Config.Version == nil, 'do not pretend old config has been updated')
assert(Config.RequireAimOnFoot and Config.NotificationCooldownMs == 5000 and Config.Radial.Enabled)
Config = { Version = '1.1.8', RequireAimOnFoot = false, NotificationCooldownMs = 8000, Radial = { Enabled = false } }
dofile('config_check.lua')
assert(not Config.RequireAimOnFoot and Config.NotificationCooldownMs == 8000 and not Config.Radial.Enabled)
print('PASS: old config defaults and preserved user choices')
