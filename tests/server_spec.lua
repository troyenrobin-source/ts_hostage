function Player() return { state = { set = function() end } } end
HostageLog = { Snapshot = function() end, Event = function() end }
-- Run from ts_hostage with Lua 5.4: lua tests/server_spec.lua
local handlers, emitted, timers, commands = {}, {}, {}, {}
function RegisterCommand(name, fn) commands[name] = fn end
local now, dead, far, bucket, selected = 10000, false, false, 0, 'WEAPON_PISTOL'
local coords = setmetatable({ x = 120, y = 240, z = 30 }, { __sub = function() return setmetatable({}, { __len = function() return far and 20 or 1 end }) end })
function RegisterNetEvent(n, fn) handlers[n] = fn end
function AddEventHandler(n, fn) handlers[n] = fn end
function TriggerClientEvent(...) emitted[#emitted + 1] = {...} end
function GetHashKey(s) return s end
function GetGameTimer() return now end
function GetPlayerPed(id) return (id == 1 or id == 2 or id == 3) and id or 0 end
function DoesEntityExist(p) return p ~= 0 end
function GetEntityHealth() return dead and 0 or 200 end
function GetPlayerRoutingBucket(p) return p == 2 and bucket or 0 end
function GetEntityCoords() return coords end
function GetSelectedPedWeapon() return selected end
function GetVehiclePedIsIn() return 0 end
function GetEntitySpeed() return 0 end
function SetTimeout(_, f) timers[#timers + 1] = f end
function CreateThread() end
function GetCurrentResourceName() return 'ts_hostage' end
local function call(n, src, ...) source = src; handlers['ts_hostage:' .. n](...) end
local function count(n)
 local c = 0; for _, e in ipairs(emitted) do if e[1] == 'ts_hostage:' .. n then c = c + 1 end end; return c
end
local function request()
 now = now + 2000; call('request', 1, 2)
 for i = #emitted, 1, -1 do if emitted[i][1] == 'ts_hostage:offer' then return emitted[i][3] end end
end
dofile('server_config.lua')
function GetResourceState() return 'started' end
function GetPlayers() return { '1', '2', '3', '4' } end
exports = { es_extended = { getSharedObject = function()
 return { GetPlayerFromId = function(id)
  if id == 4 then return nil end -- disconnected player
  return { getJob = function() return { name = id == 3 and 'police' or 'unemployed' } end }
 end }
end } }
local function alerts()
 local n = 0
 for _, e in ipairs(emitted) do
  if e[1] == 'ts_hostage:policeAlert' then
   assert(e[2] == 3, 'only police may receive alerts')
   assert(e[4].x == 120 and e[4].y == 240 and e[4].z == 30, 'server location included')
   assert(e[3].duration == 10000 and e[3].type == 'warning')
   n = n + 1
  end
 end
 return n
end
dofile('config.lua'); dofile('server.lua')
local id = request(); assert(count('offer') == 1)
call('accept', 3, id, true); assert(count('prepare') == 0, 'third-party accept')
call('accept', 2, id, false); assert(count('finish') == 2, 'hands down rejected')
assert(alerts() == 0, 'rejected hostage must not alert police')
emitted = {}; id = request(); call('accept', 2, id, true)
call('ready', 1, id, true); assert(count('begin') == 0, 'both clients required')
assert(alerts() == 0, 'no alert during preparation')
call('ready', 2, id, true); assert(count('begin') == 2)
assert(alerts() == 1, 'one alert at confirmed start')
call('ready', 2, id, true); assert(alerts() == 1, 'replayed ready cannot repeat alert')
call('action', 1, id, 'execute'); assert(count('finish') == 0, 'accidental E protection')
now = now + 2000
call('action', 3, id, 'execute'); assert(count('finish') == 0, 'third-party execute')
call('action', 2, id, 'execute'); assert(count('finish') == 0, 'victim cannot execute')
call('action', 1, id, 'execute'); assert(count('finish') == 2)
assert(emitted[#emitted][2] == 2 and emitted[#emitted][4] == true, 'only bound victim killed')
call('action', 1, id, 'execute'); assert(count('finish') == 2, 'replay ignored')
emitted = {}; far = true; request(); assert(count('offer') == 0, 'distance check'); far = false
bucket = 4; request(); assert(count('offer') == 0, 'bucket check'); bucket = 0
selected = 'WEAPON_RPG'; request(); assert(count('offer') == 0, 'weapon allowlist'); selected = 'WEAPON_PISTOL'
id = request(); call('accept', 2, id, true); call('ready', 1, id, true); call('ready', 2, id, true)
call('request', 3, 2); assert(count('offer') == 1, 'double hostage denied')
source = 1; handlers.playerDropped(); assert(count('finish') == 2, 'disconnect cleanup')
emitted = {}; id = request(); timers[#timers](); assert(count('finish') == 2, 'timeout cleanup')
print('PASS: server lifecycle, consent-state handshake, validation, replay and cleanup')

-- Older config without police block: defaults still alert only police.
emitted = {}; PoliceAlertConfig = nil
commands.ts_hostage_policecheck(0, {'1'}); assert(alerts() == 1)
emitted = {}; commands.ts_hostage_policecheck(3, {'1'}); assert(alerts() == 0, 'console only')
PoliceAlertConfig = { Enabled = false }; commands.ts_hostage_policecheck(0, {'1'}); assert(alerts() == 0)
PoliceAlertConfig = { Enabled = true, Jobs = { police = true } }
exports.es_extended.getSharedObject = function()
 return { GetPlayerFromId = function(id)
  if id == 1 then error('bad player') end
  return { job = { name = id == 3 and 'police' or 'unemployed' } }
 end }
end
commands.ts_hostage_policecheck(0, {'1'}); assert(alerts() == 1, 'job fallback and per-player isolation')
print('PASS: old config, console-only diagnostics, disabled alerts, job fallback, player isolation')
