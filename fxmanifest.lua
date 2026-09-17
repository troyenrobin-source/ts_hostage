fx_version 'cerulean'
game 'gta5'

author 'TroyScripts'
description 'Speler-gijzelingen met toetsen/target; vereist ts_bridge 0.0.2(BETA)'
version '1.1.7'

shared_scripts { '@ox_lib/init.lua', 'locales/*.lua', 'locale.lua', 'config.lua', 'bridge_check.lua' }
client_scripts { 'bridge.lua', 'handsup.lua', 'client.lua', 'blade_pose.lua', 'diagnostics.lua' }
server_scripts { 'server_config.lua', 'webhooks.lua', 'server.lua', 'update_check.lua' }
dependency '/onesync'
dependency 'ox_lib'

dependency 'ts_bridge'

-- Verplicht: centrale bridge inclusief GetStatus API 1, zie UPDATE-INSTALLATIE.md.
ts_bridge_min_version '0.0.2'
