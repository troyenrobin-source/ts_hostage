if not TSBridgeGuard.Await() then return end
Bridge = {}

function Bridge.Notify(message)
    if not TSBridgeGuard.IsReady() then return end
    if GetVehiclePedIsIn(PlayerPedId(), false) ~= 0 and not Bridge.VehicleFirstPerson() then return end
    local cooldown = math.max(0, tonumber(Config.NotificationCooldownMs) or 5000)
    return exports['ts_bridge']:Notify({ id = 'ts_hostage_notice', title = TSL('notification_title'),
        description = message, type = 'inform', duration = math.max(1, math.min(5000, cooldown)) }, cooldown)
end

function Bridge.IsDead(ped)
    if not TSBridgeGuard.IsReady() then return true end
    return exports['ts_bridge']:IsDead(ped)
end

function Bridge.HandsUp(ped)
    return ped == PlayerPedId() and HandsUp.IsRaised()
end

function Bridge.Kill()
    -- Standaard GTA-dood; ambulance-resources moeten dit op hun normale manier zien.
    -- Heeft jouw ambulance een custom death-flow? Pas uitsluitend deze adapter aan.
    SetEntityHealth(PlayerPedId(), 0)
end

function Bridge.BusyChanged(busy, role)
    -- Laat inventory/emote/teleport scripts deze status respecteren:
    -- exports.ts_hostage:IsBusy() / exports.ts_hostage:GetRole()
    -- LocalPlayer.state.ts_hostageBusy is alleen een lokale UI/integratiehint.
    LocalPlayer.state:set('ts_hostageBusy', busy, false)
    TriggerEvent('ts_hostage:busyChanged', busy, role)
end

-- Cameramodus is alleen op de eigen client betrouwbaar te controleren.
function Bridge.VehicleFirstPerson()
    return not Config.Vehicle.RequireFirstPerson or GetFollowVehicleCamViewMode() == 4
end
