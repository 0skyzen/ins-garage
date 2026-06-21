fx_version 'cerulean'
game 'gta5'
lua54 'yes'

name 'ins-garages'
author 'skyzen'
version '1.0.0'

shared_scripts {
    '@ox_lib/init.lua',
    'config.lua',
}

files {
    'locales/*.json',
}

server_scripts {
    '@oxmysql/lib/MySQL.lua',
    'server/bridge.lua',
    'server/logs.lua',
    'server/db.lua',
    'server/main.lua',
    'server/categories.lua',
    'server/sharing.lua',
    'server/transfer.lua',
}

client_scripts {
    'client/bridge.lua',
    'client/main.lua',
    'client/menu.lua',
}

dependencies {
    'ox_lib',
    'oxmysql',
}
