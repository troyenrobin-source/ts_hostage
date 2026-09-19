if not TSBridgeGuard.Await() then return end
local sessions, busy, cooldown = {}, {}, {}
local serial = 0
local weaponTypes = {}
for name, kind in pairs(Config.Weapons) do weaponTypes[HostageWeaponHash(GetHashKey(name))] = kind end

local function notify(id, msg, requestId) TriggerClientEvent('ts_hostage:notify', id, msg, requestId) end

-- De gevalideerde sessie bepaalt de locatie; de bridge controleert de jobs.
local function notifyPolice(session)
    local cfg = PoliceAlertConfig or { Enabled = true, Jobs = { police = true } }
    if cfg.Enabled == false then return end
    local ok, result = pcall(function()
        local ped = GetPlayerPed(session.captor)
        if ped == 0 then return 0 end
        local coords = GetEntityCoords(ped)
        return exports['ts_bridge']:AlertJobs(cfg.Jobs or { police = true }, {
            title = cfg.Title or TSL('server_politiemelding'),
            description = cfg.Description or TSL('server_er_is_een_gijzeling_gaande_een_persoon'),
            duration = cfg.Duration or 10000,
            position = cfg.Position or 'top-right',
            type = 'warning', icon = 'shield-halved'
        }, { x = coords.x, y = coords.y, z = coords.z }, cfg.WaypointSeconds or 60)
    end)
    if ok then
        print((TSL('server_troy_scripts_politiemelding_verstuurd_naar_agent_en')):format(result or 0))
        if result == 0 then print(TSL('server_troy_scripts_controleer_ts_bridge_check_en_policealertconfig_jobs')) end
    else print(TSL('server_troy_scripts_politiemelding_via_ts_bridge_mislukt')) end
end

-- Alleen serverconsole: test dezelfde ontvangers en clientmelding zonder gijzeling.
RegisterCommand('ts_hostage_policecheck', function(src, args)
    if src ~= 0 then return end
    local id = tonumber(args[1])
    if not id or id <= 0 or id % 1 ~= 0 or GetPlayerPed(id) == 0 then
        print(TSL('server_troyscripts_gebruik_ts_hostage_policecheck_online_speler_id'))
        return
    end
    print(TSL('server_troyscripts_testmelding_naar_politie_locatie_van_speler') .. id)
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

RegisterNetEvent('ts_hostage:request', function(target, requestId)
    if type(requestId) ~= 'number' or requestId % 1 ~= 0 or requestId < 1 or requestId > 2147483647 then return end
    local src = source
    if not TSBridgeGuard.IsReady() then return end
    if type(target) ~= 'number' or target % 1 ~= 0 or target <= 0 or target == src then return end
    local now = GetGameTimer()
    if cooldown[src] and now - cooldown[src] < Config.RequestCooldownMs then return end
    cooldown[src] = now
    if busy[src] or busy[target] then notify(src, TSL('server_een_van_jullie_is_al_bezig_met'), requestId); return end
    local ped = GetPlayerPed(src)
    if ped == 0 then return end
    serial = serial + 1
    local s = { id = serial, requestId = requestId, captor = src, victim = target, weapon = HostageWeaponHash(GetSelectedPedWeapon(ped)),
        vehicle = GetVehiclePedIsIn(ped, false), phase = 'pending', created = now, ready = {} }
    if not valid(s, true) then notify(src, TSL('server_niet_mogelijk_controleer_afstand_wapen_en_zitplaatsen'), requestId); return end
    s.kind = weaponTypes[s.weapon]
    HostageLog.Snapshot(s)
    sessions[s.id], busy[src], busy[target] = s, s.id, s.id
    -- De slachtofferclient controleert zijn eigen handen, LOS en toestand.
    TriggerClientEvent('ts_hostage:offer', target, s.id, src, s.weapon, s.vehicle ~= 0)
    SetTimeout(Config.HandshakeTimeoutMs, function()
        if sessions[s.id] and s.phase ~= 'active' then
            finish(s, false)
            notify(src, TSL('server_gijzeling_afgebroken_geen_geldige_bevestiging_ontvangen'), requestId)
        end
    end)
end)

RegisterNetEvent('ts_hostage:accept', function(id, accepted, rejection)
    local s = sessions[id]
    if not s or source ~= s.victim or s.phase ~= 'pending' then return end
    if accepted ~= true then
        local reasons = {
            busy = TSL('server_slachtoffer_is_al_bezig_met_een_gijzeling'),
            peer = TSL('server_slachtoffer_ziet_de_gijzelnemer_nog_niet_probeer'),
            dead = TSL('server_slachtoffer_staat_als_dood_of_zwaargewond_geregistreerd'),
            ragdoll = TSL('server_slachtoffer_ligt_op_de_grond_ragdoll'),
            cuffed = TSL('server_slachtoffer_is_geboeid'),
            hands = TSL('server_slachtoffer_moet_met_of_handenomhoog_de_troyscripts'),
            weapon = TSL('server_wapen_ontbreekt_in_de_configuratie_van_het'),
            vehicle = TSL('server_voertuig_of_zitplaats_klopt_niet_volgens_slachtofferclient'),
            distance = TSL('server_afstand_is_te_groot_volgens_slachtofferclient'),
            los = TSL('server_slachtofferclient_meldt_geen_vrij_zicht_ga_recht')
        }
        local message = type(rejection) == 'string' and reasons[rejection] or nil
        finish(s, false)
        notify(s.captor, message or TSL('server_slachtofferclient_heeft_de_gijzeling_geweigerd'), s.requestId)
        return
    end
    if not valid(s, true) then
        finish(s, false)
        notify(s.captor, TSL('server_servercontrole_gewijzigd_afstand_wapen_gezondheid_of_zitplaats'), s.requestId)
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
    if action == 'release' then finish(s, false, 'release', TSL('server_losgelaten_door_gijzelnemer')); return end
    if action ~= 'execute' or GetGameTimer() - s.activeAt < Config.ExecuteDelayMs then return end
    if not valid(s, false) then finish(s, false); return end
    -- Doel wordt UITSLUITEND uit de serversessie gehaald, nooit uit een client-event.
    -- Ammunitie is op de captorclient gecontroleerd; inventarisspecifieke serverside
    -- ammo-adapters kunnen hier toegevoegd worden (OneSync meldt geen betrouwbare clip).
    finish(s, true, 'execute', TSL('server_omleggen_door_de_server_toegestaan'))
end)

RegisterNetEvent('ts_hostage:cancel', function(id)
    local s = sessions[id]
    if s and (source == s.captor or source == s.victim) then finish(s, false, 'automatic', TSL('server_clientcontrole_camera_of_spelertoestand_gewijzigd')) end
end)
AddEventHandler('playerDropped', function()
    local src = source
    local s = sessions[busy[src]]
    if s then finish(s, false, 'automatic', TSL('server_speler_heeft_de_server_verlaten')) end
    cooldown[src] = nil
end)
CreateThread(function()
    while true do
        Wait(500)
        local remove = {}
        for _, s in pairs(sessions) do
            if not valid(s, s.phase ~= 'active') then remove[#remove + 1] = s end
        end
        for _, s in ipairs(remove) do finish(s, false, 'automatic', TSL('server_servercontrole_of_resource_gestopt')) end
    end
end)
AddEventHandler('onResourceStop', function(name)
    if name ~= GetCurrentResourceName() then return end
    local remove = {}
    for _, s in pairs(sessions) do remove[#remove + 1] = s end
    for _, s in ipairs(remove) do finish(s, false, 'automatic', TSL('server_servercontrole_of_resource_gestopt')) end
end)
print((TSL('server_troyscripts_ts_hostage_gestart')):format(GetResourceMetadata(GetCurrentResourceName(), 'version', 0) or 'onbekend'))
