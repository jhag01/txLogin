fx_version 'cerulean'
game 'gta5'
lua54 'yes'

description 'txLogin'
author 'jhag01'
version 'v1.0.2'

server_only 'yes'

server_scripts {
    -- '@ox_lib/init.lua', -- Uncomment if using ox_lib notifications or logging
    'locales/*.lua',
    'settings.lua',
    'utils.lua',
    'modules/*.lua',
    'main.lua'
}