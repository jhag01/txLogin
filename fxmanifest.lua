fx_version 'cerulean'
game 'gta5'
lua54 'yes'

description 'txLogin'
author 'jhag01'
version '0.3.1-beta'

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