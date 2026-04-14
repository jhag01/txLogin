local admins = {}

AddEventHandler('txAdmin:events:adminsUpdated', function(data)
    if type(data) ~= 'table' then return end
    local lookup = {}
    for _, id in ipairs(data) do
        lookup[tonumber(id)] = true
    end

    for netId, info in pairs(admins) do
        if not lookup[netId] then
            local player = Player(netId)
            if player.state then
                player.state.txAdmin = false
                player.state.txLogin = false
            end

            admins[netId] = nil
        end
    end
end)

AddEventHandler('txAdmin:events:adminAuth', function(data)
    local netId = tonumber(data.netid)
    if not netId or netId < 0 then return end

    if not data.isAdmin then
        Player(netId).state.txAdmin = false
        Player(netId).state.txLogin = false
        admins[netId] = nil
        return
    end

    local status = (admins[netId] and admins[netId].onDuty) or false

    Player(netId).state.txAdmin = true
    Player(netId).state.txLogin = status

    admins[netId] = {
        username = data.username,
        isAdmin = data.isAdmin,
        onDuty = status
    }
end)

AddEventHandler('playerDropped', function()
    admins[source] = nil
end)

RegisterCommand(Settings.Command, function(source, args, rawCommand)
    local admin = admins[source]
    if not source or not admin or not admin.isAdmin then return end
    local status = not admin.onDuty

    Player(source).state.txLogin = status
    admin.onDuty = status

    TriggerClientEvent('txcl:reAuth', source)
    Notify(source, ('Duty status toggled to %s'):format(status and 'ON' or 'OFF'), 'inform')
    Log(source, status, admin.username)
end, Settings.AcePerms)