-- Visuele keelpositie, lokaal weergegeven voor iedere speler in streamingbereik.
-- De serversessie/echte inventaris blijven leidend; het object geeft geen wapen.
local visuals = {}
-- Gebruik het ped-frame voor horizontaal, en alleen de positie van het nekbot.
-- Nekbot-rotatie en attachment-Eulerassen bepalen de richting niet meer.
local function place(v)
    local pose=v.pose
    local neck=GetPedBoneCoords(v.target,Config.BladePose.NeckBone,0.0,0.0,0.0)
    local origin=GetEntityCoords(v.target)
    local rightPoint=GetOffsetFromEntityInWorldCoords(v.target,1.0,0.0,0.0)
    local frontPoint=GetOffsetFromEntityInWorldCoords(v.target,0.0,1.0,0.0)
    local side,front,height=pose.side or 0.0,pose.front or 0.10,pose.height or 0.0
    local desired={
        x=neck.x+(rightPoint.x-origin.x)*side+(frontPoint.x-origin.x)*front,
        y=neck.y+(rightPoint.y-origin.y)*side+(frontPoint.y-origin.y)*front,
        z=neck.z+(rightPoint.z-origin.z)*side+(frontPoint.z-origin.z)*front+height
    }
    local rx,ry,rz=HostageBladeRotation(v.axis,v.contact[v.axis],GetEntityHeading(v.target))
    SetEntityRotation(v.object,rx,ry,rz,2,true)
    -- Meet de actuele gedraaide modelvector, zodat alleen het lemmetcontact
    -- op de keel terechtkomt. Handvat blijft een apart modelpunt.
    local objectOrigin=GetEntityCoords(v.object)
    local contact=GetOffsetFromEntityInWorldCoords(v.object,v.contact.x,v.contact.y,v.contact.z)
    SetEntityCoordsNoOffset(v.object,desired.x-(contact.x-objectOrigin.x),
        desired.y-(contact.y-objectOrigin.y),desired.z-(contact.z-objectOrigin.z),false,false,false)
end
local function clear(v)
    if v.object and DoesEntityExist(v.object) then DeleteEntity(v.object) end
    if v.ped and DoesEntityExist(v.ped) then
        SetPedCurrentWeaponVisible(v.ped, true, false, false, false)
    end
    v.object = nil
end
local function otherPed(id)
    local index = GetPlayerFromServerId(id)
    return index ~= -1 and GetPlayerPed(index) or 0
end
CreateThread(function()
    while true do
        Wait(250)
        local seen = {}
        if Config.BladePose.Enabled then
            for _, player in ipairs(GetActivePlayers()) do
                local id = GetPlayerServerId(player)
                local state = Player(id).state.ts_hostageBlade
                if type(state) == 'table' and type(state.victim) == 'number' and type(state.weapon) == 'number' then
                    local ped, target = GetPlayerPed(player), otherPed(state.victim)
                    if target ~= 0 and DoesEntityExist(ped) and not IsPedInAnyVehicle(ped, false)
                        and not IsEntityDead(ped) and not IsEntityDead(target)
                        and HostageWeaponHash(GetSelectedPedWeapon(ped)) == state.weapon then
                        seen[id] = true
                        local v = visuals[id]
                        if v and (v.id ~= state.id or v.ped ~= ped or v.target ~= target) then clear(v);visuals[id]=nil;v=nil end
                        if not v then
                            local model = GetWeapontypeModel(state.weapon)
                            if model ~= 0 and IsModelValid(model) then
                                RequestModel(model)
                                visuals[id] = { id=state.id, ped=ped, target=target, weapon=state.weapon, model=model, since=GetGameTimer() }
                            end
                        elseif not v.object and HostageBool(HasModelLoaded(v.model)) then
                            local p = GetEntityCoords(ped)
                            local object = CreateObject(v.model, p.x, p.y, p.z, false, false, false)
                            if object ~= 0 then
                                v.object = object
                                SetEntityCollision(object, false, false)
                                local pose = Config.BladePose.Weapons[state.weapon] or Config.BladePose.Default
                                v.grip = pose.grip or { x=0.0, y=0.0, z=0.0 }
                                v.pose=pose
                                local minimum,maximum=GetModelDimensions(v.model)
                                v.contact,v.axis=HostageBladeModelPoint(minimum,maximum,pose.bladeFraction or 0.65)
                                if type(pose.bladeContact)=='table' then v.contact=pose.bladeContact end
                                if pose.axis then v.axis=pose.axis end
                                if ped==PlayerPedId() then
                                    print(('[ts_mespositie] world-pose model=%s as=%s contact=%.3f,%.3f,%.3f'):format(v.model,v.axis,v.contact.x,v.contact.y,v.contact.z))
                                end
                                SetEntityVisible(object,false,false)
                                place(v)
                                v.calibrated=true
                                SetEntityVisible(object,true,false)

                            end
                            SetModelAsNoLongerNeeded(v.model)
                        elseif not v.object and GetGameTimer()-v.since > 3000 then
                            SetModelAsNoLongerNeeded(v.model);clear(v);visuals[id]=nil
                        end
                    end
                end
            end
        end
        for id,v in pairs(visuals) do if not seen[id] then clear(v);visuals[id]=nil end end
    end
end)
CreateThread(function()
    while true do
        Wait(next(visuals) and 0 or 250)
        for _,v in pairs(visuals) do
            if v.calibrated and v.object and DoesEntityExist(v.object) and DoesEntityExist(v.ped) then
                place(v)
                SetPedCurrentWeaponVisible(v.ped, false, false, false, false)
                if Config.BladePose.HandIK then
                    -- Hand volgt het handvat van de lokale visuele prop; per frame.
                    SetIkTarget(v.ped, Config.BladePose.IkIndex, v.object, -1,
                        v.grip.x, v.grip.y, v.grip.z, 0, 0, 100)
                end
            end
        end
    end
end)
AddEventHandler('onClientResourceStop', function(name)
    if name ~= GetCurrentResourceName() then return end
    for _,v in pairs(visuals) do clear(v) end
end)
