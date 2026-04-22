Utils = {}

local Notifies = {
    ['ox'] = function(src, msg, nType)
        if GetResourceState('ox_lib') ~= 'started' then return end
        lib.notify(src, {
            title = 'txLogin',
            description = msg,
            type = nType or 'inform'
        })
    end,
    ['custom'] = function(src, msg, nType)
        -- Add custom logic here
    end
}

local Logs = {
    ['ox'] = function(source, status, user)
        if GetResourceState('ox_lib') ~= 'started' then return end
        lib.logger(source, Settings.OxLogs.Event, string.format('%s | ID: %s | Duty: %s', user, source, status))
    end,
    ['discord'] = function(source, status, user)
        local dcLog = Settings.DiscordLogs
        if not dcLog.Webhook or dcLog.Webhook == 'WEBHOOK' then return end

        local embed = {{
            ['color'] = tonumber(dcLog.Color) or 15548997,
            ['title'] = dcLog.Title,
            ['description'] = string.format('**Admin:** %s\n**ID:** %s\n**Duty:** %s', user, source, tostring(status)),
            ['footer'] = { ['text'] = string.format('%s | %s', dcLog.Footer, os.date('%c')) }
        }}

        PerformHttpRequest(dcLog.Webhook, function(err, text, headers) end, 'POST',
            json.encode({ username = dcLog.Username, embeds = embed }),
            { ['Content-Type'] = 'application/json' })
    end,
    ['custom'] = function(source, status, user)
        -- Add custom logic here
    end
}

Utils.Notify = function(src, msg, nType)
    local notifyType = (Settings.Notify or 'none'):lower()
    if notifyType == 'none' then return end

    local notify = Notifies[notifyType]
    if not notify then 
        return print(string.format('^1[Error]^7 Notification type \'%s\' not supported.', notifyType))
    end

    notify(src, msg, nType)
end

Utils.Log = function(source, status, user)
    local logType = (Settings.Logger or 'none'):lower()
    if logType == 'none' then return end

    local logger = Logs[logType]
    if logger then
        logger(source, status, user)
    end
end