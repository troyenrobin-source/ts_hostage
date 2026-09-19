dofile('locales/nl.lua'); dofile('locale.lua'); dofile('config.lua')
local api, status = {}, nil
function IsDuplicityVersion() return false end
function GetCurrentResourceName() return 'ts_bridge' end
function GetResourceMetadata() return '0.0.3' end
TSBridgeConfig = { TargetResource = 'ox_target' }
exports = setmetatable({}, { __call = function(_, n, f) api[n] = f end })
dofile('../ts_bridge/shared_status.lua'); status = api.GetStatus()
assert(status.api == 1 and status.features.RegisterRadialMenu and status.features.CheckConfigVersion)
function GetCurrentResourceName() return 'ts_hostage' end
function GetResourceState() return 'started' end
function GetGameTimer() return 0 end
function AddEventHandler() end
exports.ts_bridge = { GetStatus = function() return status end }
dofile('bridge_check.lua'); assert(TSBridgeGuard.Await())
status.version = '0.0.2(BETA)'; dofile('bridge_check.lua'); assert(not TSBridgeGuard.Await())
status.version = '0.0.3'; status.features.RegisterRadialMenu = nil
dofile('bridge_check.lua'); assert(not TSBridgeGuard.Await())
print('PASS: real status features, old bridge rejected, missing radial feature rejected')
