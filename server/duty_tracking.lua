DutyTracking = {}

local enabled = Settings.DutyTracking == true
local resourceName = GetCurrentResourceName()
local STATE_FILE = 'duty_state.json'

local function loadStates()
    local raw = LoadResourceFile(resourceName, STATE_FILE)
    if not raw then return {} end

    local ok, data = pcall(json.decode, raw)
    if not ok or type(data) ~= 'table' then return {} end

    return data
end

local function saveStates(states)
    SaveResourceFile(resourceName, STATE_FILE, json.encode(states), -1)
end

function DutyTracking.onDutyOn(admin)
    if not enabled then return end
    admin.dutySince = os.time()
end

function DutyTracking.onDutyOff(admin)
    if not enabled then return nil end

    local duration = os.time() - (admin.dutySince or os.time())
    admin.totalDuty = (admin.totalDuty or 0) + duration
    admin.dutySince = nil

    return duration
end

function DutyTracking.persist(netId, admin)
    if not enabled then return end

    local states = loadStates()
    states[tostring(netId)] = {
        dutySince = admin.dutySince,
        totalDuty = admin.totalDuty or 0
    }
    saveStates(states)
end

function DutyTracking.clear(netId)
    if not enabled then return end

    local states = loadStates()
    if states[tostring(netId)] == nil then return end

    states[tostring(netId)] = nil
    saveStates(states)
end

function DutyTracking.resolve(netId, isPendingResync)
    if not enabled then return nil, 0 end

    if isPendingResync then
        local saved = loadStates()[tostring(netId)]
        if saved then
            return saved.dutySince, saved.totalDuty or 0
        end
        return nil, 0
    end

    DutyTracking.clear(netId)
    return nil, 0
end

function DutyTracking.getTime(admin)
    local total = admin.totalDuty or 0
    if admin.onDuty and admin.dutySince then
        total = total + (os.time() - admin.dutySince)
    end
    return total
end
