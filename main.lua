local admins = {}

local function toggleDuty(source, status)
    if not source or source == 0 then return end

    local admin = admins[source]
    if not admin or not admin.isAdmin then return nil end

    local newStatus = (status ~= nil) and status or not admin.onDuty

    admin.onDuty = newStatus
    Player(source).state.txLogin = newStatus

    TriggerClientEvent('txcl:reAuth', source)

    Utils.Notify(source, string.format('Duty status toggled to %s', newStatus and 'ON' or 'OFF'), 'inform')
    Utils.Log(source, newStatus, admin.username)

    return newStatus
end
exports('toggleDuty', toggleDuty)

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
    toggleDuty(source)
end, Settings.AcePerms)