if not TSBridgeGuard.Await() then return end
local session, offered = nil, nil
local nextRequest, actionAt = 0, 0
local requestSerial, noticeContext = 0, nil
local function startContextAllowed(mode)
    if not TSBridgeGuard.IsReady() then return false end
    if GetVehiclePedIsIn(PlayerPedId(), false) ~= 0 then return Bridge.VehicleFirstPerson() end
    if mode ~= 'key' or Config.RequireAimOnFoot == false then return true end
    -- INPUT_AIM ondersteunt ook messen en aangepaste toetsen/controllerbindings.
    return HostageBool(IsPlayerFreeAiming(PlayerId())) or HostageBool(IsControlPressed(0, 25))
        or HostageBool(IsDisabledControlPressed(0, 25))
end
local weapons = {}
for name, kind in pairs(Config.Weapons) do weapons[HostageWeaponHash(GetHashKey(name))] = kind end
local function serverOnly() return source == 65535 end
local function peerPed(id)
    local player = GetPlayerFromServerId(id)
    if player == -1 then return 0 end
    return GetPlayerPed(player)
end
local function loadAnim(anim)
    RequestAnimDict(anim.dict)
    local deadline = GetGameTimer() + 3000
    while not HostageBool(HasAnimDictLoaded(anim.dict)) and GetGameTimer() < deadline do Wait(10) end
    return HostageBool(HasAnimDictLoaded(anim.dict))
end
local function play(ped, anim)
    TaskPlayAnim(ped, anim.dict, anim.clip, 8.0, -8.0, -1, anim.flag, 0.0, false, false, false)
end
local function hint(text)
    BeginTextCommandDisplayHelp('STRING')
    AddTextComponentSubstringPlayerName(text)
    EndTextCommandDisplayHelp(0, false, true, -1)
end
local function busy() return session ~= nil or offered ~= nil end
Bridge.IsBusy = busy
exports('IsBusy', busy)
exports('GetRole', function() return session and session.role or (offered and 'pending' or nil) end)

local function vehicleAllowed(a, b)
    local va, vb = GetVehiclePedIsIn(a, false), GetVehiclePedIsIn(b, false)
    if va == 0 and vb == 0 then return true, false end
    if not Config.Vehicle.Enabled then return false, false, TSL('client_gijzelen_in_voertuigen_is_uitgeschakeld') end
    if va == 0 or va ~= vb then return false, false, TSL('client_jullie_moeten_beiden_te_voet_zijn_of') end
    if GetEntitySpeed(va) > Config.Vehicle.MaxStartSpeed then return false, false, TSL('client_de_auto_moet_bij_het_vastpakken_stilstaan') end
    for _, pair in ipairs(Config.Vehicle.SeatPairs) do
        if GetPedInVehicleSeat(va, pair.captor) == a and GetPedInVehicleSeat(va, pair.victim) == b then return true, true end
    end
    return false, false, TSL('client_ga_als_bijrijder_naast_het_slachtoffer_op')
end
local function canTake(ped)
    local me = PlayerPedId()
    if busy() then return false, TSL('client_je_bent_al_bezig_met_een_gijzeling') end
    if not ped or ped == me or ped == 0 or not IsPedAPlayer(ped) then return false, TSL('client_geen_andere_speler_dichtbij_npcs_worden_niet') end
    if Bridge.IsDead(me) then return false, TSL('client_je_personage_staat_als_dood_of_zwaargewond') end
    if IsEntityDead(ped) then return false, TSL('client_het_slachtoffer_is_dood') end
    if IsPedRagdoll(me) or IsPedRagdoll(ped) then return false, TSL('client_een_van_jullie_ligt_op_de_grond') end
    if IsPedSwimming(me) or IsPedFalling(me) or IsPedCuffed(me) then return false, TSL('client_je_kunt_niet_gijzelen_terwijl_je_zwemt') end
    local weapon = HostageWeaponHash(GetSelectedPedWeapon(me))
    if weapon == GetHashKey('WEAPON_UNARMED') then return false, TSL('client_neem_eerst_een_toegestaan_wapen_in_je') end
    if not weapons[weapon] then return false, (TSL('client_dit_wapen_staat_niet_in_config_weapons')):format(weapon) end
    if Config.RequireAmmo and weapons[weapon] == 'firearm' and GetAmmoInPedWeapon(me, weapon) < 1 then return false, TSL('client_je_vuurwapen_heeft_geen_munitie') end
    local distance = #(GetEntityCoords(me) - GetEntityCoords(ped))
    if distance > Config.Distance then return false, (TSL('client_te_ver_weg_meter_ga_binnen_meter')):format(distance, Config.Distance) end
    local allowed, inCar, reason = vehicleAllowed(me, ped)
    if not allowed then return false, reason end
    if not inCar and not HasEntityClearLosToEntity(me, ped, 17) then return false, TSL('client_geen_vrij_zicht_op_het_slachtoffer_ga') end
    if inCar and not Bridge.VehicleFirstPerson() then return false, TSL('client_zet_als_bijrijder_je_voertuigcamera_op_first') end
    return true
end
local function closest(vehicle)
    local best, distance = nil, Config.Distance + 0.01
    for _, player in ipairs(GetActivePlayers()) do
        local ped = GetPlayerPed(player)
        if (not vehicle or GetVehiclePedIsIn(ped, false) == vehicle) and canTake(ped) then
            local d = #(GetEntityCoords(PlayerPedId()) - GetEntityCoords(ped))
            if d < distance then best, distance = ped, d end
        end
    end
    return best
end
-- Diagnose zoekt ook niet-geschikte spelers, zodat de afwijzingsreden zichtbaar is.
local function explainFailure()
    local nearest, distance = nil, 20.0
    for _, player in ipairs(GetActivePlayers()) do
        local ped = GetPlayerPed(player)
        if ped ~= PlayerPedId() then
            local d = #(GetEntityCoords(PlayerPedId()) - GetEntityCoords(ped))
            if d < distance then nearest, distance = ped, d end
        end
    end
    local ok, reason = canTake(nearest)
    return reason or (ok and TSL('client_lokale_controles_akkoord_slachtoffercontrole_volgt_bij_vastpakken') or TSL('client_geen_geschikte_speler')), nearest
end
RegisterCommand('ts_hostagecheck', function()
    local reason, target = explainFailure()
    local ped = PlayerPedId()
    print(TSL('client_ts_hostagecheck') .. reason)
    print((TSL('client_ts_hostagecheck_wapen_toegestaan_auto_camera_doel')):format(
        HostageWeaponHash(GetSelectedPedWeapon(ped)), tostring(weapons[HostageWeaponHash(GetSelectedPedWeapon(ped))] ~= nil),
        tostring(IsPedInAnyVehicle(ped, false)), GetFollowVehicleCamViewMode(),
        target and GetPlayerServerId(NetworkGetPlayerIndexFromPed(target)) or 'geen'))
    Bridge.Notify(reason)
end, false)
local function request(ped, mode)
    mode = mode or 'target'
    if GetGameTimer() < nextRequest or not startContextAllowed(mode) or not ped or not canTake(ped) then return end
    nextRequest = GetGameTimer() + Config.RequestCooldownMs
    requestSerial = requestSerial + 1
    noticeContext = { id = requestSerial, mode = mode, expires = GetGameTimer() + Config.HandshakeTimeoutMs + 2000 }
    TriggerServerEvent('ts_hostage:request', GetPlayerServerId(NetworkGetPlayerIndexFromPed(ped)), requestSerial)
end
local function tryStart(mode)
    if busy() or not startContextAllowed(mode) or GetGameTimer() < nextRequest then return end
    local ped = closest()
    if ped then request(ped, mode) else
        nextRequest = GetGameTimer() + Config.RequestCooldownMs
        local reason = explainFailure()
        Bridge.Notify(reason)
    end
end
exports('TakeHostage', function() tryStart('radial') end)
local function cleanup()
    local s, ped = session, PlayerPedId()
    session, offered = nil, nil
    if s then
        if s.active and s.role == 'victim' then HandsUp.Lower() end
        if s.attached then DetachEntity(ped, true, false) end
        if s.anim then StopAnimTask(ped, s.anim.dict, s.anim.clip, -4.0) end
        if s.role == 'victim' and s.previousWeapon and HasPedGotWeapon(ped, s.previousWeapon, false) then
            SetCurrentPedWeapon(ped, s.previousWeapon, true)
        end
    end
    Bridge.BusyChanged(false, nil)
end
RegisterNetEvent('ts_hostage:notify', function(message, requestId)
    if not serverOnly() or type(message) ~= 'string' then return end
    local context = noticeContext
    if not context or context.id ~= requestId or GetGameTimer() > context.expires then return end
    if not startContextAllowed(context.mode) then return end
    Bridge.Notify(message)
end)
RegisterNetEvent('ts_hostage:offer', function(id, captor, weapon, vehicle)
    if not serverOnly() then return end
    local me, other = PlayerPedId(), peerPed(captor)
    local rejection
    if busy() then rejection = 'busy'
    elseif other == 0 then rejection = 'peer'
    elseif Bridge.IsDead(me) then rejection = 'dead'
    elseif IsPedRagdoll(me) then rejection = 'ragdoll'
    elseif IsPedCuffed(me) then rejection = 'cuffed'

    elseif not vehicle and not Bridge.HandsUp(me) then rejection = 'hands'
    elseif not weapons[weapon] then rejection = 'weapon'
    end
    -- Wapen van de dader wordt op de server en zijn eigen client gecontroleerd.
    -- Geen extra afwijzing door een vertraagde remote wapenreplica op slachtofferclient.
    if not rejection then
        local allowed, inCar = vehicleAllowed(other, me)
        if not allowed or inCar ~= vehicle then rejection = 'vehicle'
        elseif #(GetEntityCoords(me) - GetEntityCoords(other)) > Config.Distance + 0.25 then rejection = 'distance'
        elseif not vehicle and not HasEntityClearLosToEntity(other, me, 17) then rejection = 'los' end
    end
    local ok = rejection == nil
    if rejection then
        print(TSL('client_ts_hostage_slachtoffer_afgewezen') .. rejection)
        if rejection == 'hands' then
            for _, anim in ipairs({ Config.HandsUp.Anim }) do
                print((TSL('client_ts_hostage_slachtoffer')):format(anim.dict, anim.clip,
                    tostring(HostageIsPlayingAnim(me, anim.dict, anim.clip, 3))))
            end
        end
    end
    if ok then
        offered = id
        Bridge.BusyChanged(true, 'pending')
        SetTimeout(Config.HandshakeTimeoutMs + 1000, function()
            if offered == id and not session then cleanup() end
        end)
    end
    TriggerServerEvent('ts_hostage:accept', id, ok == true, rejection)
end)
RegisterNetEvent('ts_hostage:prepare', function(id, role, peer, kind, weapon, vehicle)
    if not serverOnly() then return end
    if session or (role == 'victim' and offered ~= id) then
        TriggerServerEvent('ts_hostage:ready', id, false); return
    end
    local profile = Config.Profiles[kind]
    local s = { id = id, role = role, peer = peer, kind = kind, weapon = weapon, vehicle = vehicle,
        profile = profile, active = false, ped = PlayerPedId() }
    session, offered = s, nil
    Bridge.BusyChanged(true, role)
    local key = vehicle and (role == 'captor' and 'vehicleCaptor' or 'vehicleVictim') or role
    s.anim = profile and profile[key]
    local ok = s.anim and loadAnim(s.anim) and not Bridge.IsDead(PlayerPedId()) and peerPed(peer) ~= 0
    if session ~= s then return end -- vrijgelaten tijdens laden
    if role == 'victim' and not vehicle then ok = ok and Bridge.HandsUp(PlayerPedId()) end
    if role == 'captor' then
        ok = ok and (not vehicle or Bridge.VehicleFirstPerson())
        ok = ok and HostageWeaponHash(GetSelectedPedWeapon(PlayerPedId())) == weapon
        if Config.RequireAmmo and kind == 'firearm' then ok = ok and GetAmmoInPedWeapon(PlayerPedId(), weapon) > 0 end
    end
    TriggerServerEvent('ts_hostage:ready', id, ok == true)
    SetTimeout(Config.HandshakeTimeoutMs + 1000, function()
        if session == s and not s.active then TriggerServerEvent('ts_hostage:cancel', id); cleanup() end
    end)
end)
RegisterNetEvent('ts_hostage:begin', function(id)
    if not serverOnly() or not session or session.id ~= id then return end
    local s, ped = session, PlayerPedId()
    local other = peerPed(s.peer)
    if other == 0 or Bridge.IsDead(ped) or (s.role == 'victim' and not s.vehicle and not Bridge.HandsUp(ped))
        or (s.role == 'captor' and s.vehicle and not Bridge.VehicleFirstPerson()) then
        TriggerServerEvent('ts_hostage:cancel', id); return
    end
    s.active, s.started = true, GetGameTimer()
    if s.role == 'victim' then
        HandsUp.Lower() -- stop eigen status VOORDAT de hostagepose start
        s.previousWeapon = HostageWeaponHash(GetSelectedPedWeapon(ped))
        SetCurrentPedWeapon(ped, GetHashKey('WEAPON_UNARMED'), true)
        if not s.vehicle then
            ClearPedTasksImmediately(ped)
            local o = s.profile.attach
            AttachEntityToEntity(ped, other, 0, o.x, o.y, o.z, o.rx, o.ry, o.rz,
                false, false, false, false, 2, true)
            s.attached = true
        end
    end
    play(ped, s.anim)
end)
RegisterNetEvent('ts_hostage:finish', function(id, execute)
    if not serverOnly() then return end
    if offered == id then cleanup(); return end
    if not session or session.id ~= id then return end
    local victim = session.role == 'victim'
    cleanup()
    if execute and victim then Bridge.Kill() end
end)

local function hostageAction()
    local s = session
    if s then
        if s.active and s.role == 'captor' and GetGameTimer() - s.started >= Config.ExecuteDelayMs
            and GetGameTimer() > actionAt then
            actionAt = GetGameTimer() + 750
            if HostageWeaponHash(GetSelectedPedWeapon(PlayerPedId())) ~= s.weapon then return end
            if s.vehicle and not Bridge.VehicleFirstPerson() then
                TriggerServerEvent('ts_hostage:cancel', s.id); return
            end
            if Config.RequireAmmo and s.kind == 'firearm' and GetAmmoInPedWeapon(PlayerPedId(), s.weapon) < 1 then
                Bridge.Notify(TSL('client_geen_munitie_laat_de_gijzelaar_los')); return
            end
            TriggerServerEvent('ts_hostage:action', s.id, 'execute')
        end
    end
end
RegisterCommand('+ts_hostage_action', function()
    if session then hostageAction()
    elseif Config.Interaction == 'key' or Config.Interaction == 'both' then tryStart('key') end
end, false)
exports('ExecuteHostage', hostageAction)
RegisterCommand('-ts_hostage_action', function() end, false)
local function releaseHostage()
    if session and session.role == 'captor' then
        TriggerServerEvent('ts_hostage:action', session.id, 'release')
    end
end
RegisterCommand('+ts_hostage_release', releaseHostage, false)
exports('ReleaseHostage', releaseHostage)
RegisterCommand('-ts_hostage_release', function() end, false)
RegisterKeyMapping('+ts_hostage_action', TSL('client_troyscripts_gijzelen_omleggen'), 'keyboard', Config.Keys.Action)
RegisterKeyMapping('+ts_hostage_release', TSL('client_troyscripts_gijzelaar_loslaten'), 'keyboard', Config.Keys.Release)

CreateThread(function()
    while true do
        local s = session
        if not s then Wait(200) else
            Wait(0)
            local ped = PlayerPedId()
            DisablePlayerFiring(PlayerId(), true)
            if s.role == 'victim' then
                DisableAllControlActions(0)
                for _, control in ipairs({ 1, 2, 245, 249, 199, 200 }) do EnableControlAction(0, control, true) end
                if s.vehicle then
                    -- Bestuurder behoudt uitsluitend rijbediening, camera en spraak.
                    for _, control in ipairs({ 59, 60, 63, 64, 71, 72, 76 }) do
                        EnableControlAction(0, control, true)
                    end
                end
                if s.active then
                    hint(s.vehicle and TSL('client_je_bent_gegijzeld_je_kunt_blijven_rijden') or TSL('client_je_bent_gegijzeld_je_kunt_nog_praten'))
                end
            else
                for _, control in ipairs({ 21, 22, 23, 24, 25, 37, 44, 45, 47, 58, 75, 140, 141, 142, 143, 157, 158, 159, 160, 161, 162, 163, 164, 165, 261, 262 }) do
                    DisableControlAction(0, control, true)
                end
                if s.vehicle then
                    for _, control in ipairs({ 59, 60, 71, 72 }) do DisableControlAction(0, control, true) end
                end
                if s.active then hint((TSL('client_gijzelaar_omleggen_loslaten')):format(Config.Keys.Action, Config.Keys.Release)) end
            end
        end
    end
end)
CreateThread(function()
    while true do
        Wait(250)
        local s = session
        if s and s.active then
            local ped, other = PlayerPedId(), peerPed(s.peer)
            local invalid = ped ~= s.ped or Bridge.IsDead(ped) or other == 0
            if not invalid then
                invalid = IsEntityDead(other) or #(GetEntityCoords(ped) - GetEntityCoords(other)) > Config.BreakDistance
                local a, b = GetVehiclePedIsIn(ped, false), GetVehiclePedIsIn(other, false)
                invalid = invalid or (s.vehicle and (a == 0 or a ~= b)) or (not s.vehicle and (a ~= 0 or b ~= 0))
                if s.role == 'captor' then
                    invalid = invalid or IsPedRagdoll(ped) or HostageWeaponHash(GetSelectedPedWeapon(ped)) ~= s.weapon
                        or (s.vehicle and not Bridge.VehicleFirstPerson())
                end
                if s.attached then invalid = invalid or not IsEntityAttachedToEntity(ped, other) end
            end
            if invalid then TriggerServerEvent('ts_hostage:cancel', s.id); cleanup()
            elseif not HostageIsPlayingAnim(ped, s.anim.dict, s.anim.clip, 3) then play(ped, s.anim) end
        end
    end
end)

local targetRegistered = false
local targetResource = exports['ts_bridge']:GetTargetResource()
local function registerTarget()
    if not TSBridgeGuard.IsReady() or Config.Interaction == 'key' or targetRegistered or GetResourceState(targetResource) ~= 'started' then return end
    exports['ts_bridge']:AddGlobalPlayer({ {
        name = 'ts_hostage_player', label = TSL('client_gijzelen_handen_omhoog_vereist'), icon = 'fas fa-person-rifle', distance = Config.Distance,
        canInteract = function(entity) return canTake(entity) end,
        onSelect = function(data) request(data.entity) end
    } })
    exports['ts_bridge']:AddGlobalVehicle({ {
        name = 'ts_hostage_vehicle', label = TSL('client_inzittende_gijzelen_first_person'), icon = 'fas fa-person-rifle', distance = Config.Distance,
        canInteract = function(entity) return closest(entity) ~= nil end,
        onSelect = function(data) request(closest(data.entity)) end
    } })
    targetRegistered = true
end
CreateThread(function()
    for _, profile in pairs(Config.Profiles) do
        for _, key in ipairs({ 'captor', 'victim', 'vehicleCaptor', 'vehicleVictim' }) do
            if profile[key] then loadAnim(profile[key]) end
        end
    end
    Wait(1000)
    registerTarget()
    if Config.Interaction ~= 'key' and not targetRegistered then
        print(TSL('client_ts_hostage_ox_target_ontbreekt_start_ox_target_of_kies'))
    end

end)
AddEventHandler('onClientResourceStart', function(name) if name == targetResource then registerTarget() end end)
AddEventHandler('onClientResourceStop', function(name)
    if name == targetResource then targetRegistered = false end
    if name ~= GetCurrentResourceName() then return end
    cleanup()

end)

AddEventHandler('ts_hostage:bridgeLost', function() cleanup(); targetRegistered = false end)
