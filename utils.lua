function Notify(src, msg, nType)
    if Settings.Notify == 'none' then return end

    if Settings.Notify == 'ox' and GetResourceState('ox_lib') == 'started' then
        lib.notify(src, { title = 'txLogin', description = msg, type = nType or 'inform' })
    else
        print(('txLogin: Notify %s | %s'):format(src, msg))
    end
end

function Log(source, status, user)    
    local logType = Settings.Logger:lower()
    if logType == 'none' then return end

    if logType == 'ox' and GetResourceState('ox_lib') == 'started' then
        lib.logger(source, Settings.OxLogs.Event, string.format('%s | ID: %s | Duty: %s', user, source, tostring(status)))

    elseif logType == 'discord' then
        local dcLog = Settings.DiscordLogs
        local Embed = {
            ["color"] = tonumber(dcLog.Color),
            ["title"] = dcLog.Title,
            ["description"] = string.format('**Admin:** %s\n**ID:** %s\n**Duty:** %s', user, source, tostring(status)),
            ["footer"] = { ["text"] = dcLog.Footer .. ' | ' .. os.date('%c') }
        }
        PerformHttpRequest(dcLog.Webhook, function(err, text, headers) end, 'POST', json.encode({ username = dcLog.Username, embeds = { Embed } }), { ['Content-Type'] = 'application/json' })

    elseif logType == 'custom' then
        -- Insert own logging system here
    end
end