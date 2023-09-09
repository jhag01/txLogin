local LoggedIn = {}

function ToggleLogIn(source)

    local identifier = GetPlayerIdentifierByType(source, 'license')

    if not LoggedIn[identifier] then
        LoggedIn[identifier] = true
        
    elseif LoggedIn[identifier] then
        LoggedIn[identifier] = nil

    end 
end

function isLoggedIn(source)
    local license = GetPlayerIdentifierByType(source, 'license')
    return LoggedIn[license] ~= nil
end

RegisterServerEvent('txLogin:ToggleLogIn')
AddEventHandler('txLogin:ToggleLogIn', function()
    local identifier = source
    ToggleLogIn(identifier)
end)

AddEventHandler("playerDropped", function()
    local identifier = GetPlayerIdentifierByType(source, 'license')
    
    if LoggedIn[identifier] then 
        ToggleLogIn(source)
    end 
    
end)

exports('isLoggedIn', isLoggedIn)