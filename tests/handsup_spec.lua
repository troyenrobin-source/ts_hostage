local threads, commands = {}, {}
local busy, anim, firing, state = false, false, 0, false
function PlayerPedId() return 42 end
function PlayerId() return 1 end
function DoesEntityExist() return true end
function IsEntityPlayingAnim() return anim end
function StopAnimTask() anim = false end
function TaskPlayAnim() anim = true end
function RequestAnimDict() end
function HasAnimDictLoaded() return true end
function IsPedCuffed() return false end
function IsPedRagdoll() return false end
function IsPedFalling() return false end
function IsPedSwimming() return false end
function IsPedInAnyVehicle() return false end
function GetGameTimer() return 1000 end
function DisablePlayerFiring() firing = firing + 1 end
function DisableControlAction() end
function Wait() coroutine.yield() end
function CreateThread(fn) threads[#threads+1] = fn end
function RegisterCommand(n,f) commands[n] = f end
function RegisterKeyMapping(_,_,_,key) assert(key=='H') end
function AddEventHandler() end
exports = function() end
LocalPlayer = { state = { set = function(_,_,value) state=value end } }
Bridge = { IsBusy=function() return busy end, IsDead=function() return false end }
dofile('config.lua');dofile('handsup.lua')
commands['+ts_handsup']();threads[#threads]()
assert(HandsUp.IsRaised() and state, 'H raises')
local controls = coroutine.create(threads[1]); assert(coroutine.resume(controls));assert(coroutine.resume(controls));assert(firing==1)
busy=true;commands['+ts_handsup']();assert(HandsUp.IsRaised(), 'H ignored while hostage preparing')
HandsUp.Lower();assert(not HandsUp.IsRaised() and not state, 'hostage transition clears own state')
local before=firing;assert(coroutine.resume(controls));assert(firing==before, 'no combat lock after lower')
busy=false;commands.handenomhoog();threads[#threads]();assert(HandsUp.IsRaised())
commands['+ts_handsup']();assert(not HandsUp.IsRaised(), 'toggle off')
commands['+ts_handsup']();local loading=threads[#threads];HandsUp.Lower();loading();assert(not HandsUp.IsRaised(), 'late animation load cancelled')
print('PASS: H toggle, busy guard, release combat, command alias, async cancellation')

-- Regressie: echte probleemmelding gaf native 1, geen boolean true.
commands['+ts_handsup']();threads[#threads]()
anim = 1
assert(HandsUp.IsRaised() == true, 'native 1 must become boolean true for ready handshake')
local ready = true and HandsUp.IsRaised()
assert(ready == true, 'strict network handshake accepts raised hands')
anim = 0
assert(HandsUp.IsRaised() == false, 'native 0 must NOT count as raised hands')
local watch = coroutine.create(threads[2]);assert(coroutine.resume(watch));assert(coroutine.resume(watch))
assert(not state, 'native 0 clears hands-up combat state')
for _, v in ipairs({ 0, 2, -1, '1', 'true', false }) do assert(HostageBool(v) == false) end
assert(HostageBool(nil) == false and HostageBool(true) == true and HostageBool(1) == true)
print('PASS: numeric native 1/0, boolean-ready handshake, hands-down cleanup')
