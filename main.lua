local admins = {}
local pendingResync = {} -- netId -> true, only set for players connected at the moment this resource (re)started

local resourceName = GetCurrentResourceName()
local DUTY_STATE_FILE = 'duty_state.json'

local function loadDutyStates()
    local raw = LoadResourceFile(resourceName, DUTY_STATE_FILE)
    if not raw then return {} end

    local ok, data = pcall(json.decode, raw)
    if not ok or type(data) ~= 'table' then return {} end

    return data
end

local function saveDutyState(netId, admin)
    local states = loadDutyStates()
    states[tostring(netId)] = {
        onDuty = admin.onDuty,
        dutySince = admin.dutySince,
        totalDuty = admin.totalDuty or 0
    }
    SaveResourceFile(resourceName, DUTY_STATE_FILE, json.encode(states), -1)
end

local function loadDutyState(netId)
    return loadDutyStates()[tostring(netId)]
end

local function clearDutyState(netId)
    local states = loadDutyStates()
    if states[tostring(netId)] == nil then return end

    states[tostring(netId)] = nil
    SaveResourceFile(resourceName, DUTY_STATE_FILE, json.encode(states), -1)
end

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
        admin.dutySince = os.time()
    else
        sessionDuration = os.time() - (admin.dutySince or os.time())
        admin.totalDuty = (admin.totalDuty or 0) + sessionDuration
        admin.dutySince = nil
    end

    Player(source).state.txLogin = newStatus

    TriggerClientEvent('txcl:reAuth', source)

    Utils.Notify(source, Utils.Locale(newStatus and 'duty_on' or 'duty_off'), 'inform')
    Utils.Log(source, newStatus, admin.username, Utils.FormatDuration(sessionDuration))

    saveDutyState(source, admin)

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
            clearDutyState(netId)
        end
    end
end)

AddEventHandler('txAdmin:events:adminAuth', function(data)
    local netId = tonumber(data.netid)
    if not netId or netId < 0 then return end

    if not data.isAdmin then
        local state = Player(netId).state
        state.txAdmin = false
        state.txLogin = false
        admins[netId] = nil
        clearDutyState(netId)
        return
    end

    local status, dutySince, totalDuty = false, nil, 0

    if admins[netId] then
        status, dutySince, totalDuty = admins[netId].onDuty, admins[netId].dutySince, admins[netId].totalDuty or 0
    elseif pendingResync[netId] then
        local saved = loadDutyState(netId)
        if saved then
            status, dutySince, totalDuty = saved.onDuty, saved.dutySince, saved.totalDuty or 0
        end
    else
        clearDutyState(netId) -- fresh connection, ignore any leftover state from a previous session
    end

    pendingResync[netId] = nil

    local state = Player(netId).state
    state.txAdmin = true
    state.txLogin = status

    admins[netId] = {
        username = data.username,
        isAdmin = data.isAdmin,
        onDuty = status,
        dutySince = dutySince,
        totalDuty = totalDuty
    }
end)

AddEventHandler('playerDropped', function()
    admins[source] = nil
    clearDutyState(source)
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
