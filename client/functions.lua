function debug(str)
    if Settings.Debug then
        print(str)
    end
end

function Notify(txActive)

    local message

    if txActive then
        message = Strings.MenuEnable
    else
        message = Strings.MenuDisable
    end

    if Settings.Notify == 'ox' then
        lib.notify({
            title = 'txLogin',
            description = message,
        })

    elseif Settings.Notify == 'esx' then
        exports["esx_notify"]:Notify('info', 3000, message)

    elseif Settings.Notify == 'okok' then
        exports['okokNotify']:Alert("txLogin", message, 3000, 'info')

    elseif Settings.Notify == 'brave' then
        TriggerEvent('BraveNotify:Notify', 'info', 'txLogin', message, 3000)

    elseif Settings.Notify == 'custom' then
        -- insert code
    end
    
end

function isActive()
    return txActive
end

exports('isActive', isActive)
