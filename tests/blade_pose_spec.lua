dofile('locales/nl.lua'); dofile('locale.lua')
local ownLocale = Locales.nl
 dofile('../ts_bridge/locales/nl.lua')
 for key, value in pairs(ownLocale) do Locales.nl[key] = value end
TSBridgeGuard = { Await = function() return true end, IsReady = function() return true end }
local threads={}
local state={id=1,victim=2,weapon=7}
local visible,deleted,ik=true,false,false
local objectPos={x=0,y=0,z=0}
local ry=0
function CreateThread(fn) threads[#threads+1]=coroutine.create(fn) end
function Wait() coroutine.yield() end
function GetActivePlayers() return {1} end
function GetPlayerServerId(i) return i end
function Player() return {state={ts_hostageBlade=state}} end
function GetPlayerFromServerId(i) return i end
function GetPlayerPed(i) return i end
function PlayerPedId() return 1 end
function DoesEntityExist() return true end
function IsPedInAnyVehicle() return false end
function IsEntityDead() return false end
function GetSelectedPedWeapon() return 7 end
function GetWeapontypeModel() return 8 end
function IsModelValid() return true end
function RequestModel() end
function GetGameTimer() return 1000 end
function HasModelLoaded() return 1 end
function GetEntityCoords(id) return id==9 and objectPos or {x=0,y=0,z=0} end
function CreateObject() return 9 end
function SetEntityCollision() end
function SetModelAsNoLongerNeeded() end
function SetPedCurrentWeaponVisible(_,value) visible=value end
function DeleteEntity(o) assert(o==9);deleted=true end
function SetIkTarget() ik=true end
function AddEventHandler() end
function GetCurrentResourceName() return 'ts_hostage' end
function GetModelDimensions() return {x=-0.01,y=-0.01,z=-0.07},{x=0.01,y=0.01,z=0.295} end
function GetPedBoneCoords() return {x=0,y=0,z=1.5} end
function GetEntityHeading() return 0 end
function SetEntityRotation(_,_,y) ry=math.rad(y) end
function GetOffsetFromEntityInWorldCoords(id,x,y,z)
 if id==9 then return {x=objectPos.x+math.cos(ry)*x+math.sin(ry)*z,y=objectPos.y+y,z=objectPos.z-math.sin(ry)*x+math.cos(ry)*z} end
 return {x=x,y=y,z=z}
end
function SetEntityCoordsNoOffset(_,x,y,z) objectPos={x=x,y=y,z=z} end
function SetEntityVisible() end
dofile('config.lua');dofile('blade_pose.lua')
local function step(i) local ok,err=coroutine.resume(threads[i]);assert(ok,err) end
step(1);step(1);step(1)
local p=GetOffsetFromEntityInWorldCoords(9,0,0,0.295*0.65)
assert(math.abs(p.x)<0.00001 and math.abs(p.y-0.10)<0.00001 and math.abs(p.z-1.5)<0.00001, 'blade point reaches throat, not grip')
assert(objectPos.x>0.19, 'grip away from throat contact')
step(2);step(2);assert(not visible and ik)
state=false;step(1);assert(deleted and visible)
local point,axis=HostageBladeModelPoint({x=-.01,y=-.01,z=-.07},{x=.01,y=.01,z=.295},.65)
assert(axis=='z' and math.abs(point.z-.19175)<0.00001)
print('PASS: measured Z-axis, horizontal blade contact at throat, grip separation, cleanup (simulated natives)')
