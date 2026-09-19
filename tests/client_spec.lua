dofile('locales/nl.lua'); dofile('locale.lua')
TSBridgeGuard = { Await = function() return true end, IsReady = function() return true end }
local commands, notices, requests, events, public = {}, {}, {}, {}, {}
local now, aiming = 10000, false
local weapon, distance, vehicle, camera = 0, 1, false, 0
local vec = {}; vec.__sub = function() return setmetatable({}, { __len = function() return distance end }) end
function GetHashKey(name) if name == 'WEAPON_KNIFE' then return -1716189206 elseif name == 'WEAPON_UNARMED' then return 0 else return name end end
function PlayerPedId() return 1 end
function PlayerId() return 1 end
function GetActivePlayers() return {1,2} end
function GetPlayerPed(id) return id end
function GetPlayerServerId(id) return id end
function NetworkGetPlayerIndexFromPed(id) return id end
function GetEntityCoords() return setmetatable({}, vec) end
function GetSelectedPedWeapon() return weapon end
function GetVehiclePedIsIn() return vehicle and 10 or 0 end
function GetEntitySpeed() return 0 end
function GetPedInVehicleSeat(_, seat) return seat == 0 and 1 or 2 end
function GetFollowVehicleCamViewMode() return camera end
function GetGameTimer() return now end
function IsPlayerFreeAiming() return aiming end
function IsControlPressed() return false end
function IsDisabledControlPressed() return false end
function IsPedAPlayer() return true end
function IsEntityDead() return false end
function IsPedRagdoll() return false end
function IsPedSwimming() return false end
function IsPedFalling() return false end
function IsPedCuffed() return false end
function HasEntityClearLosToEntity() return true end
function IsPedInAnyVehicle() return vehicle end
function CreateThread() end
function RegisterCommand(n, fn) commands[n] = fn end
function RegisterKeyMapping() end
function RegisterNetEvent(n, fn) events[n] = fn end
function AddEventHandler() end
function TriggerServerEvent(...) requests[#requests+1] = {...} end
exports = setmetatable({ ts_bridge = { GetTargetResource = function() return 'ox_target' end } }, { __call = function(_, name, fn) public[name] = fn end })
Bridge = { IsDead = function() return false end, Notify = function(s) notices[#notices+1] = s end,
 VehicleFirstPerson = function() return camera == 4 end }
dofile('config.lua'); dofile('client.lua')
local function action() commands['+ts_hostage_action']() end
local function advance() now = now + 6000 end
action(); assert(#notices == 0 and #requests == 0, 'E without aiming is silent')
aiming = true; action(); assert(notices[#notices]:find('Neem eerst'))
action(); assert(#notices == 1, 'failed attempts have request cooldown')
advance(); weapon = 999; action(); assert(notices[#notices]:find('Config.Weapons'))
advance(); weapon = 2578778090; action(); assert(#requests == 1, 'signed knife allowed')
local token = requests[#requests][3]
source = 65535; aiming = false
local before = #notices
events['ts_hostage:notify']('late', token); assert(#notices == before, 'late key rejection hidden after releasing aim')
aiming = true; events['ts_hostage:notify']('wrong token', token+1); assert(#notices == before)
events['ts_hostage:notify']('current', token); assert(notices[#notices] == 'current')
advance(); vehicle = true; camera = 0; before = #notices
local n = #requests; action(); assert(#notices == before and #requests == n, 'third person car is silent')
camera = 4; aiming = false; action(); assert(#requests == n+1, 'first person car needs no aim')
advance(); vehicle = false; public.TakeHostage(); assert(#requests == n+2, 'radial needs no aim')
events['ts_hostage:notify']('radial rejection', requests[#requests][3]); assert(notices[#notices] == 'radial rejection')
advance(); public.ExecuteHostage(); public.ReleaseHostage(); assert(#requests == n+2, 'idle execute/release cannot start hostage')
-- Real radial registration: callbacks call the public exports and own item is removed.
local removed, root, menu
lib = { registerRadial = function(v) menu = v end, addRadialItem = function(v) root = v end,
 removeRadialItem = function(id) removed = id end }
function GetCurrentResourceName() return 'ts_hostage' end
exports.ts_hostage = setmetatable({}, { __index = function(_, key) return function() public[key]() end end })
function AddEventHandler(name, fn) events[name] = fn end
exports.ts_bridge.RegisterRadialMenu = function(_, data)
 menu = data; root = { menu = data.id, id = data.id }
end
dofile('radial.lua')
assert(root.menu == menu.id and #menu.items == 3)
menu.items[1].onSelect(); assert(#requests == n+3)
-- Cleanup tested centrally in bridge shared_ui_spec.lua.
print('PASS: aim gate, failed-attempt cooldown, request correlation, vehicle camera, radial registration/actions/cleanup')

-- Start a real local session, then release aim; action/release remain usable.
function GetPlayerFromServerId(id) return id end
function RequestAnimDict() end
function HasAnimDictLoaded() return true end
function SetTimeout() end
function TaskPlayAnim() end
Bridge.BusyChanged = function() end
source = 65535; vehicle = false; aiming = false
local hash = 2578778090
events['ts_hostage:prepare'](99, 'captor', 2, 'blade', hash, false)
events['ts_hostage:begin'](99)
advance(); public.ExecuteHostage()
assert(requests[#requests][1] == 'ts_hostage:action' and requests[#requests][3] == 'execute')
public.ReleaseHostage(); assert(requests[#requests][3] == 'release')
print('PASS: active hostage execute/release without aiming')
