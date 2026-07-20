local resourceName = GetCurrentResourceName()

local admins = {}
local pendingResync = {}

local function toggleDuty(source, status)
    if not source or source == 0 then return end

    local admin = admins[source]
    if not admin or not admin.isAdmin then return nil end

    local newStatus = not admin.onDuty
    if status ~= nil then
        newStatus = status
    end

    if newStatus == admin.onDuty then return newStatus end

    local remaining = Cooldown.remaining(source)
    if remaining > 0 then
        Utils.Notify(source, Utils.Locale('duty_cooldown', remaining), 'error')
        return admin.onDuty
    end

    admin.onDuty = newStatus

    local sessionDuration
    if newStatus then
        DutyTracking.onDutyOn(admin)
    else
        sessionDuration = DutyTracking.onDutyOff(admin)
    end

    Player(source).state.txLogin = newStatus

    TriggerClientEvent('txcl:reAuth', source)

    Utils.Notify(source, Utils.Locale(newStatus and 'duty_on' or 'duty_off'), 'inform')
    Utils.Log(source, newStatus, admin.username, Utils.FormatDuration(sessionDuration))

    DutyTracking.persist(source, admin)
    Cooldown.record(source)

    return newStatus
end
exports('toggleDuty', toggleDuty)

local function getDutyTime(source)
    local admin = admins[source]
    if not admin then return 0 end

    return DutyTracking.getTime(admin)
end
exports('getDutyTime', getDutyTime)

local function fetchAdmins(onlyOnDuty)
    if not onlyOnDuty then return admins end

    local onDutyAdmins = {}
    for netId, info in pairs(admins) do
        if info.onDuty then
            onDutyAdmins[netId] = info
        end
    end
    return onDutyAdmins
end
exports('fetchAdmins', fetchAdmins)

AddEventHandler('txAdmin:events:adminsUpdated', function(data)
    if type(data) ~= 'table' then return end
    local lookup = {}
    for _, id in ipairs(data) do
        lookup[tonumber(id)] = true
    end

    for netId in pairs(admins) do
        if not lookup[netId] then
            local state = Player(netId).state
            state.txAdmin = false
            state.txLogin = false

            admins[netId] = nil
            DutyTracking.clear(netId)
        end
    end
end)

AddEventHandler('txAdmin:events:adminAuth', function(data)
    local netId = tonumber(data.netid)
    if not netId or netId < 0 then return end

    local state = Player(netId).state

    if not data.isAdmin then
        state.txAdmin = false
        state.txLogin = false
        admins[netId] = nil
        DutyTracking.clear(netId)
        return
    end

    local status
    if admins[netId] then
        status = admins[netId].onDuty
    else
        status = state.txLogin == true
    end

    local dutySince, totalDuty
    if admins[netId] then
        dutySince, totalDuty = admins[netId].dutySince, admins[netId].totalDuty
    else
        dutySince, totalDuty = DutyTracking.resolve(netId, pendingResync[netId])
    end

    pendingResync[netId] = nil

    state.txAdmin = true
    state.txLogin = status

    admins[netId] = {
        username = data.username,
        isAdmin = data.isAdmin,
        onDuty = status,
        dutySince = dutySince,
        totalDuty = totalDuty or 0
    }
end)

AddEventHandler('playerDropped', function()
    admins[source] = nil
    DutyTracking.clear(source)
    Cooldown.clear(source)
end)

AddEventHandler('onResourceStart', function(startedResource)
    if startedResource ~= resourceName then return end

    for _, playerId in ipairs(GetPlayers()) do
        local netId = tonumber(playerId)
        pendingResync[netId] = true
        TriggerClientEvent('txcl:reAuth', netId)
    end
end)

RegisterCommand(Settings.Command, function(source)
    toggleDuty(source)
end, Settings.AcePerms)
