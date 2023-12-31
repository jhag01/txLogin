function Notify(txActive)

    local message

    if txActive then
        message = 'Your txAdmin menu has been enabled!'
    else
        message = 'Your txAdmin menu has been disabled!'
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
