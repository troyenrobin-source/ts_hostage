-- Vereist ts_bridge 0.0.3, vóór dit script starten. Teksten: locales/nl.lua.
Config = {}
-- Alleen verhogen wanneer de CONFIG-indeling wijzigt, niet bij iedere scriptupdate.
Config.Version = '1.1.8'
Config.RequireAimOnFoot = true -- alleen sneltoets E; target/radial zijn bewuste keuzes
Config.NotificationCooldownMs = 5000 -- alle gewone meldingen samen
Config.Radial = { Enabled = true } -- ox_lib; zet uit bij een eigen radialmenu
Config.Locale = 'nl' -- Hoofdtaal; teksten staan in locales/nl.lua
Config.Interaction = 'both' -- 'target', 'key' of 'both'; target = ox_target
Config.Keys = { Action = 'E', Release = 'X' }
Config.Distance = 1.8
Config.BreakDistance = 4.0
Config.RequestCooldownMs = 1500
Config.HandshakeTimeoutMs = 6000
Config.ExecuteDelayMs = 1500 -- voorkomt omleggen met dezelfde E als vastpakken
Config.RequireAmmo = true
Config.HandsUp = {
    Enabled = true,
    Key = 'H',
    Anim = { dict = 'missminuteman_1ig_2', clip = 'handsup_base' }
}
Config.Vehicle = {
    Enabled = true,
    RequireFirstPerson = true, -- dader: vervangt handen-omhoog-controle in auto
    MaxStartSpeed = 0.5, -- m/s: auto moet bij het starten vrijwel stilstaan
    -- Beide spelers moeten reeds in dezelfde auto op de voorstoelen zitten.
    -- Geen teleport, carjack, achterbank of overgang van lopen naar auto.
    SeatPairs = { { captor = 0, victim = -1 } } -- bijrijder gijzelt bestuurder
}

-- Alleen expliciet opgegeven wapens. Custom wapens: voeg hun spawnnaam toe.
-- firearm = vuurwapen; blade = steek/snijwapen; blunt = slagwapen.
Config.Weapons = {
    WEAPON_PISTOL = 'firearm',
    WEAPON_COMBATPISTOL = 'firearm',
    WEAPON_APPISTOL = 'firearm',
    WEAPON_PISTOL50 = 'firearm',
    WEAPON_SNSPISTOL = 'firearm',
    WEAPON_HEAVYPISTOL = 'firearm',
    WEAPON_VINTAGEPISTOL = 'firearm',
    WEAPON_KNIFE = 'blade',
    WEAPON_SWITCHBLADE = 'blade',
    WEAPON_DAGGER = 'blade',
    WEAPON_BOTTLE = 'blade'
    -- WEAPON_BAT = 'blunt', -- lange wapens: eerst animatie/positie testen!
    -- WEAPON_SHIV = 'blade',
}

-- Standaard GTA-hostagepose als basis. Het mes wordt in de echte hand gehouden.
-- Geen meegeleverde custom YCD: exacte keel/slaap-uitlijning is NIET gegarandeerd.
-- Afzonderlijke profielen maken custom animaties/offsets per type mogelijk.
local function profile(x, y, z)
    return {
        captor = { dict = 'anim@gangops@hostage@', clip = 'perp_idle', flag = 49 },
        victim = { dict = 'anim@gangops@hostage@', clip = 'victim_idle', flag = 33 },
        attach = { x = x, y = y, z = z, rx = 0.0, ry = 0.0, rz = 0.0 },
        -- Seated: bovenlichaam, zonder attachment (stoelpositie blijft behouden).
        vehicleCaptor = { dict = 'anim@gangops@hostage@', clip = 'perp_idle', flag = 49 },
        vehicleVictim = { dict = 'missminuteman_1ig_2', clip = 'handsup_base', flag = 49 }
    }
end
Config.Profiles = {
    firearm = profile(-0.24, 0.11, 0.0),
    blade = profile(-0.18, 0.17, 0.0),
    blunt = profile(-0.18, 0.17, 0.0)
}

-- Lua/natives kunnen dezelfde 32-bit hash signed of unsigned voorstellen.
function HostageWeaponHash(hash)
    return type(hash) == 'number' and (hash & 0xFFFFFFFF) or hash
end

-- Sommige native-uitkomsten zijn 0/1; in Lua is ook 0 truthy.
-- Gebruik daarom geen 'not not value' voor zulke uitkomsten.
function HostageBool(value)
    return value == true or value == 1
end
function HostageIsPlayingAnim(ped, dict, clip, flags)
    return HostageBool(IsEntityPlayingAnim(ped, dict, clip, flags))
end

-- Eerste keel-afstelling: te voet, uitsluitend blade. Live pose-QA nog nodig.
Config.BladePose = {
    Enabled = true,
    NeckBone = 39317, -- SKEL_Neck_1, bone ID
    HandIK = true,
    IkIndex = 2, -- volgende arm-afstelling op basis van voor-/zijaanzicht
    -- Offset/rotatie t.o.v. de nek, mes horizontaal langs de voorzijde.
    Default = {
        -- In het ped-frame: rechts, voor de nek, wereldhoogte. Eenheid: meter.
        side = 0.0, front = 0.10, height = 0.0,
        bladeContact = 'auto',
        bladeFraction = 0.65,
        grip = { x = 0.0, y = 0.0, z = 0.0 }
    },
    Weapons = {} -- optioneel: [HostageWeaponHash(GetHashKey('WEAPON_KNIFE'))] = {...}
}

-- Langste modelas bepalen, niet hardcoded aannemen dat het lemmet langs X loopt.
function HostageBladeModelPoint(minimum, maximum, fraction)
    local axis = 'x'
    for _, candidate in ipairs({ 'y', 'z' }) do
        if maximum[candidate]-minimum[candidate] > maximum[axis]-minimum[axis] then axis=candidate end
    end
    local tip = math.abs(maximum[axis]) >= math.abs(minimum[axis]) and maximum[axis] or minimum[axis]
    local point = { x=0.0, y=0.0, z=0.0 }
    point[axis] = tip * fraction
    return point, axis
end
-- Richt de gemeten lengteas dwars over de keel, richting ped-links.
function HostageBladeRotation(axis, contactDistance, heading)
    local sign = contactDistance >= 0 and 1 or -1
    if axis=='z' then return 0.0,-90.0*sign,heading end
    if axis=='y' then return 0.0,0.0,heading+90.0*sign end
    return 0.0,0.0,heading+(sign==1 and 180.0 or 0.0)
end
