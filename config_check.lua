-- Vereiste configversie blijft gelijk zolang het configuratieschema gelijk blijft.
local required = '1.1.8'
if not TSBridgeGuard.Await() then return end
exports['ts_bridge']:CheckConfigVersion(Config.Version, required)
if Config.RequireAimOnFoot == nil then Config.RequireAimOnFoot = true end
if Config.NotificationCooldownMs == nil then Config.NotificationCooldownMs = 5000 end
if Config.Radial == nil then Config.Radial = { Enabled = true } end
