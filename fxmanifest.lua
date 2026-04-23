fx_version 'cerulean'
game 'gta5'
lua54 'yes'

description 'txLogin'
author 'jhag01'
version '1.0.0'

server_only 'yes'

server_scripts {
    -- '@ox_lib/init.lua', -- Uncomment if using ox_lib notifications or logging
    'settings.lua',
    'utils.lua',
    'main.lua'
}