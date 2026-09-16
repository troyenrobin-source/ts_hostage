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
