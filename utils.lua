Utils = {}

Utils.Notify = function(src, msg, nType)
    local notifyType = Settings.Notify:lower()
    if notifyType == 'none' then return end

    local providers = {
        ['ox'] = function()
            if GetResourceState('ox_lib') == 'started' then
                lib.notify(src, { title = 'txLogin', description = msg, type = nType or 'inform' })
            end
        end,
        ['custom'] = function()
            -- Custom logic here
        end
    }

    if providers[notifyType] then
        providers[notifyType]()
    else
        print(string.format('^1[Error]^7 Notification type \'%s\' not supported.', notifyType))
    end
end

Utils.Log = function(source, status, user)
    local logType = Settings.Logger:lower()
    if logType == 'none' then return end

    local loggers = {
        ['ox'] = function()
            if GetResourceState('ox_lib') == 'started' then
                lib.logger(source, Settings.OxLogs.Event, string.format('%s | ID: %s | Duty: %s', user, source, status))
            end
        end,
        ['discord'] = function()
            local dcLog = Settings.DiscordLogs
            local embed = {
                {
                    ['color'] = tonumber(dcLog.Color),
                    ['title'] = dcLog.Title,
                    ['description'] = string.format('**Admin:** %s\n**ID:** %s\n**Duty:** %s', user, source, tostring(status)),
                    ['footer'] = { ['text'] = dcLog.Footer .. ' | ' .. os.date('%c') }
                }
            }
            PerformHttpRequest(dcLog.Webhook, function(err, text, headers) end, 'POST', 
                json.encode({ username = dcLog.Username, embeds = embed }), 
                { ['Content-Type'] = 'application/json' })
        end,
        ['custom'] = function()
            -- Custom logic here
        end
    }

    if loggers[logType] then
        loggers[logType]()
    end
end