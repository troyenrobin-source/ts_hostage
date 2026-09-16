local event, command, shown, waypoint
local now = 1000
function RegisterNetEvent(_, fn) event = fn end
function RegisterCommand(_, fn) command = fn end
function RegisterKeyMapping(_, _, _, key) assert(key == 'G') end
function GetGameTimer() return now end
function GetStreetNameAtCoord() return 1, 2 end
function GetStreetNameFromHashKey(hash) return hash == 1 and 'Main Street' or 'Cross Street' end
function GetNameOfZone() return 'CITY' end
function GetLabelText() return 'Centrum' end
lib = { notify = function(data) shown = data end }
function SetNewWaypoint(x, y) waypoint = { x, y } end
dofile('../ts_bridge/config.lua'); dofile('../ts_bridge/client/alerts.lua')
command(); assert(not waypoint)
source = 65535
event({ description = 'Gijzeling' }, { x=120, y=240, z=30 }, 60)
assert(shown.description:find('Main Street / Cross Street (Centrum)', 1, true))
assert(shown.description:find('standaard G', 1, true))
command(); assert(waypoint[1] == 120 and waypoint[2] == 240)
waypoint = nil; command(); assert(not waypoint, 'consumed waypoint')
event({}, { x=10, y=20, z=30 }, 60)
now = now + 60001; command(); assert(not waypoint, 'expired alert')
event({}, { x=10, y=20, z=30 }, 60)
event({}, { x=50, y=60, z=30 }, 60)
command(); assert(waypoint[1] == 50, 'latest alert wins')
waypoint = nil; source = 1
event({}, { x=90, y=90, z=30 }, 60); command(); assert(not waypoint)
print('PASS: location text, G waypoint, expiry, latest alert, server-only event')
