if not TSBridgeGuard.Await() then return end
-- Eigen H-toggle. Status en framegebonden combatblokkade hebben dezelfde eigenaar.
HandsUp = {}
local raised, pending, generation, ownerPed = false, false, 0, nil
local function busy() return Bridge.IsBusy and Bridge.IsBusy() or false end
function HandsUp.IsRaised()
    return raised and ownerPed == PlayerPedId()
        and HostageIsPlayingAnim(ownerPed, Config.HandsUp.Anim.dict, Config.HandsUp.Anim.clip, 3)
end
function HandsUp.Lower()
    generation = generation + 1
    pending = false
    local ped = ownerPed
    raised, ownerPed = false, nil
    LocalPlayer.state:set('ts_handsup', false, true)
    if ped and DoesEntityExist(ped) then
        StopAnimTask(ped, Config.HandsUp.Anim.dict, Config.HandsUp.Anim.clip, -4.0)
    end
end
local function allowed(ped)
    return Config.HandsUp.Enabled and not Bridge.IsDead(ped) and not IsPedCuffed(ped)
        and not IsPedRagdoll(ped) and not IsPedFalling(ped) and not IsPedSwimming(ped)
        and not IsPedInAnyVehicle(ped, false)
end
function HandsUp.Toggle()
    if busy() then return end -- slachtoffer kan tijdens gijzeling geen H-animatie starten
    if raised or pending then HandsUp.Lower(); return end
    local ped = PlayerPedId()
    if not allowed(ped) then return end
    pending = true
    generation = generation + 1
    local ticket = generation
    CreateThread(function()
        local anim = Config.HandsUp.Anim
        RequestAnimDict(anim.dict)
        local deadline = GetGameTimer() + 3000
        while not HostageBool(HasAnimDictLoaded(anim.dict)) and GetGameTimer() < deadline and generation == ticket do Wait(10) end
        if generation ~= ticket then return end
        pending = false
        if not HostageBool(HasAnimDictLoaded(anim.dict)) or busy() or PlayerPedId() ~= ped or not allowed(ped) then return end
        ownerPed, raised = ped, true
        TaskPlayAnim(ped, anim.dict, anim.clip, 8.0, -8.0, -1, 49, 0.0, false, false, false)
        LocalPlayer.state:set('ts_handsup', true, true)
    end)
end
exports('IsHandsUp', HandsUp.IsRaised)
exports('LowerHands', HandsUp.Lower)
RegisterCommand('+ts_handsup', HandsUp.Toggle, false)
RegisterCommand('-ts_handsup', function() end, false)
RegisterCommand('handenomhoog', HandsUp.Toggle, false)
RegisterKeyMapping('+ts_handsup', TSL('handsup_troyscripts_handen_omhoog_omlaag'), 'keyboard', Config.HandsUp.Key)
CreateThread(function()
    while true do
        if not raised then Wait(150) else
            Wait(0)
            if raised then
                if PlayerPedId() ~= ownerPed or not allowed(ownerPed) then HandsUp.Lower()
                else
                    DisablePlayerFiring(PlayerId(), true)
                    for _, control in ipairs({ 21, 22, 23, 24, 25, 37, 44, 45, 47, 58, 140, 141, 142, 143, 157, 158, 159, 160, 161, 162, 163, 164, 165, 261, 262 }) do
                        DisableControlAction(0, control, true)
                    end
                end
            end
        end
    end
end)
-- Als een andere resource de animatie beëindigt, blijft onze blokkade niet hangen.
CreateThread(function()
    while true do
        Wait(500)
        if raised and not HostageIsPlayingAnim(ownerPed, Config.HandsUp.Anim.dict, Config.HandsUp.Anim.clip, 3) then HandsUp.Lower() end
    end
end)
AddEventHandler('onClientResourceStop', function(name)
    if name == GetCurrentResourceName() then HandsUp.Lower() end
end)
