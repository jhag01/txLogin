Utils = {}

local function formatDuration(seconds)
    if not seconds or seconds <= 0 then return nil end

    local hours = math.floor(seconds / 3600)
    local minutes = math.floor((seconds % 3600) / 60)
    local secs = seconds % 60

    if hours > 0 then
        return string.format('%dh %dm', hours, minutes)
    elseif minutes > 0 then
        return string.format('%dm %ds', minutes, secs)
    end

    return string.format('%ds', secs)
end
Utils.FormatDuration = formatDuration

function Utils.Locale(key, ...)
    local localeType = (Settings.Locale or 'en'):lower()
    local locale = Locales[localeType] or Locales['en']
    local str = locale[key] or key

    if select('#', ...) > 0 then
        return string.format(str, ...)
    end

    return str
end

local Notifies = {
    ['ox'] = function(source, msg, nType)
        if GetResourceState('ox_lib') ~= 'started' then return end
        lib.notify(source, {
            title = 'txLogin',
            description = msg,
            type = nType or 'inform'
        })
    end,

    ['custom'] = function(source, msg, nType)
        -- Add custom logic here
    end,

    ['none'] = function() end
}

local Logs = {
    ['ox'] = function(source, status, user, duration)
        if GetResourceState('ox_lib') ~= 'started' then return end

        local msg = string.format('%s | ID: %s | Duty: %s', user, source, status)
        if duration then
            msg = string.format('%s | Session: %s', msg, duration)
        end

        lib.logger(source, Settings.OxLogs.Event, msg)
    end,

    ['discord'] = function(source, status, user, duration)
        local dcLog = Settings.DiscordLogs
        if not dcLog.Webhook or dcLog.Webhook == 'WEBHOOK' then return end

        local description = string.format('**Admin:** %s\n**ID:** %s\n**Duty:** %s', user, source, tostring(status))
        if duration then
            description = string.format('%s\n**Session:** %s', description, duration)
        end

        local data = {
            username = dcLog.Username,
            embeds = {{
                ['color'] = tonumber(dcLog.Color) or 15548997,
                ['title'] = dcLog.Title,
                ['description'] = description,
                ['footer'] = { ['text'] = string.format('%s | %s', dcLog.Footer, os.date('%c')) }
            }}
        }

        PerformHttpRequest(dcLog.Webhook, function() end, 'POST', json.encode(data), { ['Content-Type'] = 'application/json' })
    end,

    ['custom'] = function(source, status, user, duration)
        -- Add custom logic here
    end,

    ['none'] = function() end
}

local function InitializeUtils()
    local notifyType = (Settings.Notify or 'none'):lower()
    local logType = (Settings.Logger or 'none'):lower()
    local localeType = (Settings.Locale or 'en'):lower()

    Utils.Notify = Notifies[notifyType] or function()
        print(string.format('^1[Error]^7 Notification type "%s" is invalid.', notifyType))
    end

    Utils.Log = Logs[logType] or function()
        print(string.format('^1[Error]^7 Logger type "%s" is invalid.', logType))
    end

    if not Locales[localeType] then
        print(string.format('^1[Error]^7 Locale "%s" is invalid, falling back to "en".', localeType))
    end
end

InitializeUtils()