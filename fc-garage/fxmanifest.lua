fx_version "cerulean"
game 'gta5'
author 'piotreq [discord.gg/piotreqscripts]'
description '5City 4.0 Garages - Inspired'
lua54 'yes'

ui_page 'web/build/index.html'

files {
	'web/build/index.html',
	'web/build/**/*',
  'config.lua',
  'client/utils.lua',
}

shared_scripts {
  '@ox_lib/init.lua',
  '@es_extended/imports.lua'
}

client_scripts {
  'client/*.lua'
}
server_scripts {
  '@oxmysql/lib/MySQL.lua',
  'server/*.lua'
}