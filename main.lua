local resourceName = GetCurrentResourceName()

local admins = {}
local pendingResync = {} -- netId -> true, only set for players connected at the moment this resource (re)started

local function toggleDuty(source, status)
    if not source or source == 0 then return end

    local admin = admins[source]
    if not admin or not admin.isAdmin then return nil end

    local newStatus = not admin.onDuty
    if status ~= nil then
        newStatus = status
    end

    if newStatus == admin.onDuty then return newStatus end

    admin.onDuty = newStatus

    local sessionDuration
    if newStatus then
        Modules.DutyTracking.onDutyOn(admin)
    else
        sessionDuration = Modules.DutyTracking.onDutyOff(admin)
    end

    Player(source).state.txLogin = newStatus

    TriggerClientEvent('txcl:reAuth', source)

    Utils.Notify(source, Utils.Locale(newStatus and 'duty_on' or 'duty_off'), 'inform')
    Utils.Log(source, newStatus, admin.username, Utils.FormatDuration(sessionDuration))

    Modules.DutyTracking.persist(source, admin)

    return newStatus
end
exports('toggleDuty', toggleDuty)

local function getDutyTime(source)
    local admin = admins[source]
    if not admin then return 0 end

    local total = admin.totalDuty or 0
    if admin.onDuty and admin.dutySince then
        total = total + (os.time() - admin.dutySince)
    end

    return total
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
            Modules.DutyTracking.clear(netId)
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
        Modules.DutyTracking.clear(netId)
        return
    end

    -- onDuty survives a script restart on its own: the state bag lives on the
    -- player entity, not in this resource's memory, so it only resets when the
    -- player actually disconnects. dutySince/totalDuty have no such home, so
    -- they're only restored for players who were connected when we restarted.
    local status
    if admins[netId] then
        status = admins[netId].onDuty
    else
        status = state.txLogin == true
    end

    local dutySince, totalDuty
    if admins[netId] then
        dutySince, totalDuty = admins[netId].dutySince, admins[netId].totalDuty
    elseif pendingResync[netId] then
        local saved = Modules.DutyTracking.restore(netId)
        if saved then
            dutySince, totalDuty = saved.dutySince, saved.totalDuty
        end
    else
        Modules.DutyTracking.clear(netId) -- fresh connection, ignore any leftover state from a previous session
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
    Modules.DutyTracking.clear(source)
end)

AddEventHandler('onResourceStart', function(startedResource)
    if startedResource ~= resourceName then return end

    -- players still connected when this resource restarts keep their admin/duty
    -- state by re-running the client auth flow, which re-fires adminAuth below
    for _, playerId in ipairs(GetPlayers()) do
        local netId = tonumber(playerId)
        pendingResync[netId] = true
        TriggerClientEvent('txcl:reAuth', netId)
    end
end)

RegisterCommand(Settings.Command, function(source)
    toggleDuty(source)
end, Settings.AcePerms)
