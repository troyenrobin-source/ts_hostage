dofile('locales/nl.lua'); dofile('locale.lua')
TSBridgeGuard = { Await = function() return true end, IsReady = function() return true end }
function PlayerPedId() return 42 end
local raised = false
HandsUp = { IsRaised = function() return raised end }
local api = {}
exports = setmetatable({ ts_bridge = setmetatable({}, { __index = function(_, n)
 return function(_, ...) return api[n](...) end end }) }, { __call = function(_, n, fn) api[n] = fn end })
function GetInvokingResource() return 'ts_hostage' end
function GetCurrentResourceName() return 'ts_bridge' end
function RegisterNetEvent() end
function AddEventHandler() end
TSBridgeConfig = { NotificationDuration = 5000, NotificationTitle = 'default' }
dofile('../ts_bridge/client/main.lua')
dofile('config.lua'); dofile('bridge.lua')
assert(not Bridge.HandsUp(42))
raised = true; assert(Bridge.HandsUp(42)); assert(not Bridge.HandsUp(99))
raised = false; assert(not Bridge.HandsUp(42))
local camera = 0
function GetFollowVehicleCamViewMode() return camera end
assert(not Bridge.VehicleFirstPerson());camera=4;assert(Bridge.VehicleFirstPerson())
print('PASS: own hands-up bridge and vehicle camera')

local now, inCar, shown = 10000, false, {}
function GetGameTimer() return now end
function GetVehiclePedIsIn() return inCar and 10 or 0 end
lib = { notify = function(data) shown[#shown+1] = data end }
Bridge.Notify('one'); Bridge.Notify('two'); assert(#shown == 1)
assert(shown[1].title == 'Gijzeling' and shown[1].id == 'ts_hostage:ts_hostage_notice')
now = now + 5000; Bridge.Notify('two'); assert(#shown == 2)
inCar = true; camera = 0; now = now + 5000; Bridge.Notify('hidden'); assert(#shown == 2)
camera = 4; Bridge.Notify('visible'); assert(#shown == 3)
Config.NotificationCooldownMs = 9000; now = now + 5000; Bridge.Notify('wait'); assert(#shown == 3)
now = now + 4000; Bridge.Notify('ready'); assert(#shown == 4)
print('PASS: shared notification limit, neutral title, vehicle silence, configurable cooldown')
