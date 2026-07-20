Cooldown = {}

local seconds = tonumber(Settings.Cooldown) or 0
local enabled = seconds > 0
local lastToggle = {}

function Cooldown.remaining(source)
    if not enabled then return 0 end

    local last = lastToggle[source]
    if not last then return 0 end

    local remaining = seconds - (os.time() - last)
    if remaining < 0 then return 0 end

    return remaining
end

function Cooldown.record(source)
    if not enabled then return end
    lastToggle[source] = os.time()
end

function Cooldown.clear(source)
    lastToggle[source] = nil
end
