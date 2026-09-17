dofile('locales/nl.lua'); dofile('locale.lua')
local ownLocale = Locales.nl
 dofile('../ts_bridge/locales/nl.lua')
 for key, value in pairs(ownLocale) do Locales.nl[key] = value end
TSBridgeGuard = { Await = function() return true end, IsReady = function() return true end }
function PlayerPedId() return 42 end
local raised = false
HandsUp = { IsRaised = function() return raised end }
dofile('config.lua'); dofile('bridge.lua')
assert(not Bridge.HandsUp(42))
raised = true; assert(Bridge.HandsUp(42)); assert(not Bridge.HandsUp(99))
raised = false; assert(not Bridge.HandsUp(42))
local camera = 0
function GetFollowVehicleCamViewMode() return camera end
assert(not Bridge.VehicleFirstPerson());camera=4;assert(Bridge.VehicleFirstPerson())
print('PASS: own hands-up bridge and vehicle camera')
