local sessions, busy, cooldown = {}, {}, {}
local serial = 0
local weaponTypes = {}
for name, kind in pairs(Config.Weapons) do weaponTypes[HostageWeaponHash(GetHashKey(name))] = kind end

local function notify(id, msg) TriggerClientEvent('ts_hostage:notify', id, msg) end

-- De gevalideerde sessie bepaalt de locatie; de bridge controleert de jobs.
local function notifyPolice(session)
    local cfg = PoliceAlertConfig or { Enabled = true, Jobs = { police = true } }
    if cfg.Enabled == false then return end
    local ok, result = pcall(function()
        local ped = GetPlayerPed(session.captor)
        if ped == 0 then return 0 end
        local coords = GetEntityCoords(ped)
        return exports['ts_bridge']:AlertJobs(cfg.Jobs or { police = true }, {
            title = cfg.Title or 'Politiemelding',
            description = cfg.Description or 'Er is een gijzeling gaande! Een persoon wordt gegijzeld.',
            duration = cfg.Duration or 10000,
            position = cfg.Position or 'top-right',
            type = 'warning', icon = 'shield-halved'
        }, { x = coords.x, y = coords.y, z = coords.z }, cfg.WaypointSeconds or 60)
    end)
    if ok then
        print(('[Troy Scripts] Politiemelding verstuurd naar %d agent(en).'):format(result or 0))
        if result == 0 then print('[Troy Scripts] Controleer ts_bridge_check en PoliceAlertConfig.Jobs.') end
    else print('^1[Troy Scripts] Politiemelding via ts_bridge mislukt.^7') end
end

-- Alleen serverconsole: test dezelfde ontvangers en clientmelding zonder gijzeling.
RegisterCommand('ts_hostage_policecheck', function(src, args)
    if src ~= 0 then return end
    local id = tonumber(args[1])
    if not id or id <= 0 or id % 1 ~= 0 or GetPlayerPed(id) == 0 then
        print('[TroyScripts] Gebruik: ts_hostage_policecheck <online speler-ID>')
        return
    end
    print('[TroyScripts] Testmelding naar politie; locatie van speler ' .. id)
    notifyPolice({ captor = id })
end, false)

local function finish(s, execute, action, reason)
    if sessions[s.id] ~= s then return end
    if s.phase == 'active' then HostageLog.Event(s, action or 'automatic', reason) end
    Player(s.captor).state:set('ts_hostageBlade', false, true)
    sessions[s.id] = nil
    busy[s.captor], busy[s.victim] = nil, nil
    TriggerClientEvent('ts_hostage:finish', s.captor, s.id, false)
    TriggerClientEvent('ts_hostage:finish', s.victim, s.id, execute == true)
end
local function valid(s, starting)
    local a, b = GetPlayerPed(s.captor), GetPlayerPed(s.victim)
    if a == 0 or b == 0 or not DoesEntityExist(a) or not DoesEntityExist(b) then return false end
    if GetEntityHealth(a) <= 0 or GetEntityHealth(b) <= 0 then return false end
    if GetPlayerRoutingBucket(s.captor) ~= GetPlayerRoutingBucket(s.victim) then return false end
    if #(GetEntityCoords(a) - GetEntityCoords(b)) > (starting and Config.Distance + 0.25 or Config.BreakDistance) then return false end
    if HostageWeaponHash(GetSelectedPedWeapon(a)) ~= s.weapon or not weaponTypes[s.weapon] then return false end
    local va, vb = GetVehiclePedIsIn(a, false), GetVehiclePedIsIn(b, false)
    if s.vehicle == 0 then return va == 0 and vb == 0 end
    if not Config.Vehicle.Enabled or va == 0 or va ~= vb or va ~= s.vehicle then return false end
    if starting and GetEntitySpeed(va) > Config.Vehicle.MaxStartSpeed then return false end
    for _, pair in ipairs(Config.Vehicle.SeatPairs) do
        if GetPedInVehicleSeat(va, pair.captor) == a and GetPedInVehicleSeat(va, pair.victim) == b then return true end
    end
    return false
end

RegisterNetEvent('ts_hostage:request', function(target)
    local src = source
    if type(target) ~= 'number' or target % 1 ~= 0 or target <= 0 or target == src then return end
    local now = GetGameTimer()
    if cooldown[src] and now - cooldown[src] < Config.RequestCooldownMs then return end
    cooldown[src] = now
    if busy[src] or busy[target] then notify(src, 'Een van jullie is al bezig met een gijzeling.'); return end
    local ped = GetPlayerPed(src)
    if ped == 0 then return end
    serial = serial + 1
    local s = { id = serial, captor = src, victim = target, weapon = HostageWeaponHash(GetSelectedPedWeapon(ped)),
        vehicle = GetVehiclePedIsIn(ped, false), phase = 'pending', created = now, ready = {} }
    if not valid(s, true) then notify(src, 'Niet mogelijk: controleer afstand, wapen en zitplaatsen.'); return end
    s.kind = weaponTypes[s.weapon]
    HostageLog.Snapshot(s)
    sessions[s.id], busy[src], busy[target] = s, s.id, s.id
    -- De slachtofferclient controleert zijn eigen handen, LOS en toestand.
    TriggerClientEvent('ts_hostage:offer', target, s.id, src, s.weapon, s.vehicle ~= 0)
    SetTimeout(Config.HandshakeTimeoutMs, function()
        if sessions[s.id] and s.phase ~= 'active' then
            finish(s, false)
            notify(src, 'Gijzeling afgebroken: geen geldige bevestiging ontvangen.')
        end
    end)
end)

RegisterNetEvent('ts_hostage:accept', function(id, accepted, rejection)
    local s = sessions[id]
    if not s or source ~= s.victim or s.phase ~= 'pending' then return end
    if accepted ~= true then
        local reasons = {
            busy = 'Slachtoffer is al bezig met een gijzeling.',
            peer = 'Slachtoffer ziet de gijzelnemer nog niet. Probeer opnieuw.',
            dead = 'Slachtoffer staat als dood of zwaargewond geregistreerd.',
            ragdoll = 'Slachtoffer ligt op de grond (ragdoll).',
            cuffed = 'Slachtoffer is geboeid.',
            hands = 'Slachtoffer moet met H of /handenomhoog de TroyScripts-handen omhoog doen.',
            weapon = 'Wapen ontbreekt in de configuratie van het slachtoffer. Herstart de resource.',
            vehicle = 'Voertuig of zitplaats klopt niet volgens slachtofferclient.',
            distance = 'Afstand is te groot volgens slachtofferclient.',
            los = 'Slachtofferclient meldt geen vrij zicht. Ga recht tegenover elkaar staan.'
        }
        local message = type(rejection) == 'string' and reasons[rejection] or nil
        finish(s, false)
        notify(s.captor, message or 'Slachtofferclient heeft de gijzeling geweigerd.')
        return
    end
    if not valid(s, true) then
        finish(s, false)
        notify(s.captor, 'Servercontrole gewijzigd: afstand, wapen, gezondheid of zitplaats. Probeer opnieuw.')
        return
    end
    s.phase = 'preparing'
    TriggerClientEvent('ts_hostage:prepare', s.captor, s.id, 'captor', s.victim, s.kind, s.weapon, s.vehicle ~= 0)
    TriggerClientEvent('ts_hostage:prepare', s.victim, s.id, 'victim', s.captor, s.kind, s.weapon, s.vehicle ~= 0)
end)

RegisterNetEvent('ts_hostage:ready', function(id, ok)
    local s = sessions[id]
    local src = source
    if not s or (src ~= s.captor and src ~= s.victim) or s.phase ~= 'preparing' then return end
    if ok ~= true or not valid(s, true) then finish(s, false); return end
    s.ready[src] = true
    if s.ready[s.captor] and s.ready[s.victim] then
        s.phase, s.activeAt = 'active', GetGameTimer()
        TriggerClientEvent('ts_hostage:begin', s.captor, id)
        TriggerClientEvent('ts_hostage:begin', s.victim, id)
        if s.kind == 'blade' and s.vehicle == 0 and Config.BladePose.Enabled then
            Player(s.captor).state:set('ts_hostageBlade', { id=s.id, victim=s.victim, weapon=s.weapon }, true)
        end
        notifyPolice(s)
        HostageLog.Event(s, 'start')
    end
end)

RegisterNetEvent('ts_hostage:action', function(id, action)
    local s = sessions[id]
    if not s or source ~= s.captor or s.phase ~= 'active' then return end
    if action == 'release' then finish(s, false, 'release', 'Losgelaten door gijzelnemer'); return end
    if action ~= 'execute' or GetGameTimer() - s.activeAt < Config.ExecuteDelayMs then return end
    if not valid(s, false) then finish(s, false); return end
    -- Doel wordt UITSLUITEND uit de serversessie gehaald, nooit uit een client-event.
    -- Ammunitie is op de captorclient gecontroleerd; inventarisspecifieke serverside
    -- ammo-adapters kunnen hier toegevoegd worden (OneSync meldt geen betrouwbare clip).
    finish(s, true, 'execute', 'Omleggen door de server toegestaan')
end)

RegisterNetEvent('ts_hostage:cancel', function(id)
    local s = sessions[id]
    if s and (source == s.captor or source == s.victim) then finish(s, false, 'automatic', 'Clientcontrole: camera of spelertoestand gewijzigd') end
end)
AddEventHandler('playerDropped', function()
    local src = source
    local s = sessions[busy[src]]
    if s then finish(s, false, 'automatic', 'Speler heeft de server verlaten') end
    cooldown[src] = nil
end)
CreateThread(function()
    while true do
        Wait(500)
        local remove = {}
        for _, s in pairs(sessions) do
            if not valid(s, s.phase ~= 'active') then remove[#remove + 1] = s end
        end
        for _, s in ipairs(remove) do finish(s, false, 'automatic', 'Servercontrole of resource gestopt') end
    end
end)
AddEventHandler('onResourceStop', function(name)
    if name ~= GetCurrentResourceName() then return end
    local remove = {}
    for _, s in pairs(sessions) do remove[#remove + 1] = s end
    for _, s in ipairs(remove) do finish(s, false, 'automatic', 'Servercontrole of resource gestopt') end
end)
print(('^5[TroyScripts]^7 ts_hostage %s gestart'):format(GetResourceMetadata(GetCurrentResourceName(), 'version', 0) or 'onbekend'))
