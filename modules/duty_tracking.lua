Modules = Modules or {}

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

local DutyTracking = {}

-- Called when an admin's duty status turns on: starts the session clock.
function DutyTracking.onDutyOn(admin)
    if not enabled then return end
    admin.dutySince = os.time()
end

-- Called when an admin's duty status turns off: rolls the session into the
-- running total and returns the session length in seconds.
function DutyTracking.onDutyOff(admin)
    if not enabled then return nil end

    local duration = os.time() - (admin.dutySince or os.time())
    admin.totalDuty = (admin.totalDuty or 0) + duration
    admin.dutySince = nil

    return duration
end

-- Persists dutySince/totalDuty for netId so they survive a script restart
-- while the player stays connected. No-op (and never touches disk) when disabled.
function DutyTracking.persist(netId, admin)
    if not enabled then return end

    local states = loadStates()
    states[tostring(netId)] = {
        dutySince = admin.dutySince,
        totalDuty = admin.totalDuty or 0
    }
    saveStates(states)
end

-- Returns the saved { dutySince, totalDuty } for netId, or nil.
function DutyTracking.restore(netId)
    if not enabled then return nil end
    return loadStates()[tostring(netId)]
end

function DutyTracking.clear(netId)
    if not enabled then return end

    local states = loadStates()
    if states[tostring(netId)] == nil then return end

    states[tostring(netId)] = nil
    saveStates(states)
end

Modules.DutyTracking = DutyTracking
