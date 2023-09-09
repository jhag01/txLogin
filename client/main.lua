txActive = false
txPerms = nil
txUser = nil

RegisterNetEvent('txcl:setAdmin')
AddEventHandler("txcl:setAdmin", function(username, perms)

    txUser = username
    txPerms = perms

end)

RegisterNetEvent('txLogin:switch')
AddEventHandler('txLogin:switch', function()

    if not txPerms then return end 

    txActive = not txActive

    Notify(txActive)

    TriggerEvent('txcl:reAuth')

    if Settings.EnableLogs then
        TriggerServerEvent('txLogin:Logger', txActive, txUser)
    end

end)

RegisterCommand(Settings.Command, function()

    if not txPerms then return end 

    TriggerEvent('txLogin:switch')
    TriggerServerEvent('txLogin:ToggleLogIn')

end, Settings.AcePerms)

function isLoggedIn()
    return txActive
end

exports('isLoggedIn', isLoggedIn)