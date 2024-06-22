fx_version 'cerulean'
game 'gta5'

name "96rp_storages"
description "Storage Job, where you can rent storages"
author "PandaOnLimit"
version "1.0.0"
lua54 'yes'


shared_scripts {
	'@ox_lib/init.lua',
	'config.lua'
}

client_scripts {
	'client.lua',
	"@qbx_core/modules/playerdata.lua",
	"@96rp_npc/client/main.lua"
}

server_scripts {
	'server.lua',
	'@oxmysql/lib/MySQL.lua'
}

