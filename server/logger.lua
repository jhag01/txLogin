RegisterServerEvent('txLogin:Logger')
AddEventHandler('txLogin:Logger', function(txActive, txUser)

    if Settings.Logger == 'ox' then
        oxLog(source, txActive, txUser)
    elseif Settings.Logger == 'discord' then
        discordLog(source, txActive, txUser)
    elseif Settings.Logger == 'custom' then
        customLog(source, txActive, txUser)
    else
        debug(Strings.debugNoLog)
        return
    end

end)