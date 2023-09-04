fx_version 'cerulean'
game 'gta5'
lua54 'yes'

description 'txLogin'
author 'jhag01'
version '1.0.0'

shared_scripts {
    'shared/strings.lua',
    'shared/settings.lua'
}

client_scripts {
    'client/functions.lua',
    'client/main.lua'
}

server_scripts {
    'server/functions.lua',
    'server/logger.lua'
}