dofile('locales/nl.lua'); dofile('locale.lua')
local ownLocale = Locales.nl
 dofile('../ts_bridge/locales/nl.lua')
 for key, value in pairs(ownLocale) do Locales.nl[key] = value end
TSBridgeGuard = { Await = function() return true end, IsReady = function() return true end }
local commands, notices, requests = {}, {}, {}
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
function GetGameTimer() return 10000 end
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
function RegisterNetEvent() end
function AddEventHandler() end
function TriggerServerEvent(...) requests[#requests+1] = {...} end
exports = setmetatable({ ts_bridge = { GetTargetResource = function() return 'ox_target' end } }, { __call = function() end })
Bridge = { IsDead = function() return false end, Notify = function(s) notices[#notices+1] = s end,
 VehicleFirstPerson = function() return camera == 4 end }
dofile('config.lua'); dofile('client.lua')
commands['+ts_hostage_action']()
assert(notices[#notices]:find('Neem eerst'))
weapon = 999
commands['+ts_hostage_action']()
assert(notices[#notices]:find('Config.Weapons'))
weapon = 2578778090 -- zelfde hash als de signed config-knife
commands['+ts_hostage_action']()
assert(#requests == 1, 'signed/unsigned knife must pass')
distance = 5;commands.ts_hostagecheck();assert(notices[#notices]:find('Te ver weg'))
distance = 1;vehicle = true;commands.ts_hostagecheck();assert(notices[#notices]:find('first person'))
camera = 4;commands.ts_hostagecheck();assert(notices[#notices]:find('Lokale controles akkoord'))
print('PASS: actual client commands, unarmed, unknown weapon, hash normalization, distance and camera reasons')
