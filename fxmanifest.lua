fx_version 'cerulean'
game 'gta5'
lua54 'yes'

description 'txLogin'
author 'jhag01'
version '0.4.2-beta'

shared_scripts {
    'shared/settings.lua'
}

client_scripts {
    'client/notify.lua',
    'client/main.lua'
}

server_scripts {
    'server/logger.lua',
    'server/main.lua'
}