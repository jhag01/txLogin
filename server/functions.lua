function debug(str)
    if Settings.Debug then
        print(str)
    end
end

function oxLog(source, txuser, txActive)
    lib.logger(source, Settings.oxLogs.Event, txUser .. ' | ID: ' .. source .. ' | ' .. Strings.Logs '' .. txActive)
end

function discordLog(source, txuser, txActive)

    local dcLog = Settings.DiscordLogs

    local Embed = {
        ["color"] = dcLog.Color,
        ["type"] = "rich",
        ["title"] = dcLog.title,
        ["description"] = txUser .. ' | ID: ' .. source .. ' | ' .. Strings.Logs .. txActive,
        ["footer"] = {
        ["text"] = dcLog.Footer .. ' | ' .. os.date('%c')
        }
    }

    PerformHttpRequest(dcLog.Webhook, function(err, text, headers) end, 'POST', json.encode({ username = log.Username, embeds = { Embed } }), { ['Content-Type'] = 'application/json' })

end

function customLog(source, txActive, txUser)
    -- insert own logging system
end

