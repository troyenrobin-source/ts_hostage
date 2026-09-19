if not TSBridgeGuard.Await() then return end
if not Config.Radial or not Config.Radial.Enabled then return end
local id = 'ts_hostage_radial'
exports['ts_bridge']:RegisterRadialMenu({ id = id, label = TSL('notification_title'), icon = 'person-rifle', items = {
    { label = TSL('radial_take'), icon = 'person-rifle', onSelect = function() exports[GetCurrentResourceName()]:TakeHostage() end },
    { label = TSL('radial_release'), icon = 'person-walking', onSelect = function() exports[GetCurrentResourceName()]:ReleaseHostage() end },
    { label = TSL('radial_execute'), icon = 'crosshairs', onSelect = function() exports[GetCurrentResourceName()]:ExecuteHostage() end }
} })
-- Registraties worden door ts_bridge opgeruimd bij resource-stop.
