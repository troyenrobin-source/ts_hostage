fx_version 'cerulean'
game 'gta5'

author 'TroyScripts'
description 'Speler-gijzelingen met handen-omhoog-controle, ox_target en toetsen'
version '1.1.6'

shared_scripts { '@ox_lib/init.lua', 'config.lua' }
client_scripts { 'bridge.lua', 'handsup.lua', 'client.lua', 'blade_pose.lua', 'diagnostics.lua' }
server_scripts { 'server_config.lua', 'webhooks.lua', 'server.lua', 'update_check.lua' }
dependency '/onesync'
dependency 'ox_lib'

dependency 'ts_bridge'
