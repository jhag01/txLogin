txActive = false
txPerms = nil
txUser = nil

RegisterNetEvent('txcl:setAdmin')
AddEventHandler("txcl:setAdmin", function(username, perms)

    txUser = username
    txPerms = perms

    debug(txUsername, perms)

end)

RegisterNetEvent('txLogin:switch')
AddEventHandler('txLogin:switch', function()

    if not txPerms then debug(Strings.debugNoPerms) return end 

    txActive = not txActive
    debug(Strings.debugStateChange .. txActive)

    Notify(txActive)

    TriggerEvent('txcl:reAuth')

    if Settings.EnableLogs then
        TriggerServerEvent('txLogin:Logger', txActive, txUser)
        debug(Strings.debugLogTriggered)
    end

end)

RegisterCommand(Settings.Command, function()

    if not txPerms then debug(Strings.debugNoPerms) return end 

    TriggerEvent('txLogin:switch')
    TriggerServerEvent('txLogin:ToggleLogIn')

end, Settings.AcePerms)