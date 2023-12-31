function oxLog(source, txActive, txUser)
    lib.logger(source, Settings.oxLogs.Event, txUser .. ' | ID: ' .. source .. ' | Admin changed their menu access to: ' .. tostring(txActive))
end

function discordLog(source, txActive, txUser)

    local dcLog = Settings.DiscordLogs

    local Embed = {
        ["color"] = dcLog.Color,
        ["type"] = "rich",
        ["title"] = dcLog.title,
        ["description"] = txUser .. ' | ID: ' .. source .. ' | Admin changed their menu access to: ' .. tostring(txActive),
        ["footer"] = {
        ["text"] = dcLog.Footer .. ' | ' .. os.date('%c')
        }
    }

    PerformHttpRequest(dcLog.Webhook, function(err, text, headers) end, 'POST', json.encode({ username = dcLog.Username, embeds = { Embed } }), { ['Content-Type'] = 'application/json' })

end

function customLog(source, txActive, txUser)
    -- insert own logging system
end

RegisterServerEvent('txLogin:Logger')
AddEventHandler('txLogin:Logger', function(txActive, txUser)

    if Settings.Logger == 'ox' then
        oxLog(source, txActive, txUser)
    elseif Settings.Logger == 'discord' then
        discordLog(source, txActive, txUser)
    elseif Settings.Logger == 'custom' then
        customLog(source, txActive, txUser)
    else
        return
    end

end)