-- De server stuurt uitsluitend politieagenten de positie bij de start.
local pendingLocation, expiresAt

RegisterNetEvent('ts_hostage:policeAlert', function(data, coords, waypointSeconds)
    if source ~= 65535 then return end -- uitsluitend afkomstig van de server
    if type(data) ~= 'table' or type(coords) ~= 'table'
        or type(coords.x) ~= 'number' or type(coords.y) ~= 'number'
        or type(coords.z) ~= 'number' then return end

    local streetHash, crossingHash = GetStreetNameAtCoord(coords.x, coords.y, coords.z)
    local street = GetStreetNameFromHashKey(streetHash) or ''
    local crossing = crossingHash ~= 0 and GetStreetNameFromHashKey(crossingHash) or ''
    local zoneCode = GetNameOfZone(coords.x, coords.y, coords.z)
    local zone = zoneCode and GetLabelText(zoneCode) or ''
    if zone == 'NULL' or zone == '' then zone = zoneCode or '' end

    local location = street
    if crossing ~= '' and crossing ~= street then
        location = location ~= '' and (location .. ' / ' .. crossing) or crossing
    end
    if zone ~= '' then
        location = location ~= '' and (location .. ' (' .. zone .. ')') or zone
    end
    if location == '' then
        location = ('X: %.0f, Y: %.0f'):format(coords.x, coords.y)
    end
    local seconds = math.max(1, math.min(tonumber(waypointSeconds) or 60, 600))
    pendingLocation = { x = coords.x, y = coords.y }
    expiresAt = GetGameTimer() + seconds * 1000
    data.description = (data.description or '') .. '\nLocatie: ' .. location
        .. ('\nDruk op G voor een waypoint (%.0f seconden).'):format(seconds)
    lib.notify(data)
    print('[TroyScripts] Politiemelding ontvangen; locatie: ' .. location)
end)

RegisterCommand('ts_hostage_waypoint', function()
    if not pendingLocation then return end
    if GetGameTimer() > expiresAt then
        pendingLocation = nil
        return
    end
    SetNewWaypoint(pendingLocation.x, pendingLocation.y)
    pendingLocation = nil
    lib.notify({
        title = 'Politiemelding',
        description = 'Waypoint ingesteld naar de gemelde gijzeling.',
        type = 'success',
        duration = 4000
    })
end, false)
RegisterKeyMapping('ts_hostage_waypoint', 'Gijzeling: waypoint naar laatste politiemelding', 'keyboard', 'G')
