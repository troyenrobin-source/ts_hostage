local session, offered = nil, nil
local nextRequest, actionAt = 0, 0
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
    if not Config.Vehicle.Enabled then return false, false, 'Gijzelen in voertuigen is uitgeschakeld.' end
    if va == 0 or va ~= vb then return false, false, 'Jullie moeten beiden te voet zijn, of in dezelfde auto zitten.' end
    if GetEntitySpeed(va) > Config.Vehicle.MaxStartSpeed then return false, false, 'De auto moet bij het vastpakken stilstaan.' end
    for _, pair in ipairs(Config.Vehicle.SeatPairs) do
        if GetPedInVehicleSeat(va, pair.captor) == a and GetPedInVehicleSeat(va, pair.victim) == b then return true, true end
    end
    return false, false, 'Ga als bijrijder naast het slachtoffer op de bestuurdersstoel zitten.'
end
local function canTake(ped)
    local me = PlayerPedId()
    if busy() then return false, 'Je bent al bezig met een gijzeling.' end
    if not ped or ped == me or ped == 0 or not IsPedAPlayer(ped) then return false, 'Geen andere speler dichtbij. NPCs worden niet ondersteund.' end
    if Bridge.IsDead(me) then return false, 'Je personage staat als dood of zwaargewond geregistreerd.' end
    if IsEntityDead(ped) then return false, 'Het slachtoffer is dood.' end
    if IsPedRagdoll(me) or IsPedRagdoll(ped) then return false, 'Een van jullie ligt op de grond (ragdoll).' end
    if IsPedSwimming(me) or IsPedFalling(me) or IsPedCuffed(me) then return false, 'Je kunt niet gijzelen terwijl je zwemt, valt of geboeid bent.' end
    local weapon = HostageWeaponHash(GetSelectedPedWeapon(me))
    if weapon == GetHashKey('WEAPON_UNARMED') then return false, 'Neem eerst een toegestaan wapen in je hand.' end
    if not weapons[weapon] then return false, ('Dit wapen staat niet in Config.Weapons (hash %s).'):format(weapon) end
    if Config.RequireAmmo and weapons[weapon] == 'firearm' and GetAmmoInPedWeapon(me, weapon) < 1 then return false, 'Je vuurwapen heeft geen munitie.' end
    local distance = #(GetEntityCoords(me) - GetEntityCoords(ped))
    if distance > Config.Distance then return false, ('Te ver weg: %.1f meter. Ga binnen %.1f meter staan.'):format(distance, Config.Distance) end
    local allowed, inCar, reason = vehicleAllowed(me, ped)
    if not allowed then return false, reason end
    if not inCar and not HasEntityClearLosToEntity(me, ped, 17) then return false, 'Geen vrij zicht op het slachtoffer. Ga dichterbij zonder obstakel ertussen.' end
    if inCar and not Bridge.VehicleFirstPerson() then return false, 'Zet als bijrijder je voertuigcamera op first person.' end
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
    return reason or (ok and 'Lokale controles akkoord; slachtoffercontrole volgt bij vastpakken.' or 'Geen geschikte speler.'), nearest
end
RegisterCommand('ts_hostagecheck', function()
    local reason, target = explainFailure()
    local ped = PlayerPedId()
    print('[ts_hostagecheck] ' .. reason)
    print(('[ts_hostagecheck] wapen=%s | toegestaan=%s | auto=%s | camera=%s | doel=%s'):format(
        HostageWeaponHash(GetSelectedPedWeapon(ped)), tostring(weapons[HostageWeaponHash(GetSelectedPedWeapon(ped))] ~= nil),
        tostring(IsPedInAnyVehicle(ped, false)), GetFollowVehicleCamViewMode(),
        target and GetPlayerServerId(NetworkGetPlayerIndexFromPed(target)) or 'geen'))
    Bridge.Notify(reason)
end, false)
local function request(ped)
    if GetGameTimer() < nextRequest or not ped or not canTake(ped) then return end
    nextRequest = GetGameTimer() + Config.RequestCooldownMs
    TriggerServerEvent('ts_hostage:request', GetPlayerServerId(NetworkGetPlayerIndexFromPed(ped)))
end
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
RegisterNetEvent('ts_hostage:notify', function(message)
    if serverOnly() then Bridge.Notify(message) end
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
        print('[ts_hostage slachtoffer] Afgewezen: ' .. rejection)
        if rejection == 'hands' then
            for _, anim in ipairs({ Config.HandsUp.Anim }) do
                print(('[ts_hostage slachtoffer] %s / %s = %s'):format(anim.dict, anim.clip,
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

RegisterCommand('+ts_hostage_action', function()
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
                Bridge.Notify('Geen munitie. Laat de gijzelaar los.'); return
            end
            TriggerServerEvent('ts_hostage:action', s.id, 'execute')
        end
    elseif Config.Interaction == 'key' or Config.Interaction == 'both' then
        local ped = closest()
        if ped then request(ped) else local reason = explainFailure(); Bridge.Notify(reason) end
    end
end, false)
RegisterCommand('-ts_hostage_action', function() end, false)
RegisterCommand('+ts_hostage_release', function()
    if session and session.role == 'captor' then
        TriggerServerEvent('ts_hostage:action', session.id, 'release')
    end
end, false)
RegisterCommand('-ts_hostage_release', function() end, false)
RegisterKeyMapping('+ts_hostage_action', 'TroyScripts: gijzelen / omleggen', 'keyboard', Config.Keys.Action)
RegisterKeyMapping('+ts_hostage_release', 'TroyScripts: gijzelaar loslaten', 'keyboard', Config.Keys.Release)

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
                    hint(s.vehicle and 'Je bent gegijzeld. Je kunt blijven rijden en praten.' or 'Je bent gegijzeld. Je kunt nog praten.')
                end
            else
                for _, control in ipairs({ 21, 22, 23, 24, 25, 37, 44, 45, 47, 58, 75, 140, 141, 142, 143, 157, 158, 159, 160, 161, 162, 163, 164, 165, 261, 262 }) do
                    DisableControlAction(0, control, true)
                end
                if s.vehicle then
                    for _, control in ipairs({ 59, 60, 71, 72 }) do DisableControlAction(0, control, true) end
                end
                if s.active then hint(('Gijzelaar: ~y~%s~s~ omleggen | ~y~%s~s~ loslaten'):format(Config.Keys.Action, Config.Keys.Release)) end
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
local function registerTarget()
    if Config.Interaction == 'key' or targetRegistered or GetResourceState('ox_target') ~= 'started' then return end
    exports.ox_target:addGlobalPlayer({ {
        name = 'ts_hostage_player', label = 'Gijzelen (handen omhoog vereist)', icon = 'fas fa-person-rifle', distance = Config.Distance,
        canInteract = function(entity) return canTake(entity) end,
        onSelect = function(data) request(data.entity) end
    } })
    exports.ox_target:addGlobalVehicle({ {
        name = 'ts_hostage_vehicle', label = 'Inzittende gijzelen (first person)', icon = 'fas fa-person-rifle', distance = Config.Distance,
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
        print('^3[ts_hostage] ox_target ontbreekt. Start ox_target of kies Config.Interaction = key.^7')
    end

end)
AddEventHandler('onClientResourceStart', function(name) if name == 'ox_target' then registerTarget() end end)
AddEventHandler('onClientResourceStop', function(name)
    if name == 'ox_target' then targetRegistered = false end
    if name ~= GetCurrentResourceName() then return end
    cleanup()
    if targetRegistered and GetResourceState('ox_target') == 'started' then
        exports.ox_target:removeGlobalPlayer('ts_hostage_player')
        exports.ox_target:removeGlobalVehicle('ts_hostage_vehicle')
    end
end)
