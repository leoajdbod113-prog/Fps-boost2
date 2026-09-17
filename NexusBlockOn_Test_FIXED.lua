--[[
    NexusBlockOn_Test.lua

    Independent Block-On controller for a test arena.

    IMPORTANT:
    - This module does NOT implement threat detection.
    - This module does NOT modify NexusFPSBoosterV20.lua.
    - This module does NOT invent or assume an arena-specific API.
    - The actual arena input belongs in BlockInputAdapter.

    Public API:
        BlockOn.Start()
        BlockOn.Stop()
        BlockOn.SetEnabled(true/false)
        BlockOn.IsEnabled()
        BlockOn.SetThreatState(true/false)
        BlockOn.IsBlocking()
        BlockOn.SetDebug(true/false)
        BlockOn.SetInputAdapter({
            StartBlock = function() ... end,
            StopBlock  = function() ... end,
        })

    State:
        IDLE
        BLOCKING
]]

local BlockOn = {}

--==================================================
-- CONSTANTS
--==================================================

BlockOn.States = {
    IDLE = "IDLE",
    BLOCKING = "BLOCKING",
}

--==================================================
-- INTERNAL STATE
--==================================================

local running = false
local enabled = true
local threatState = false
local state = BlockOn.States.IDLE
local debugEnabled = false
local lastError = nil

-- The module itself creates no heartbeat/render loop.
-- These tables exist so future connections/tasks can be
-- cleaned centrally if the module is extended.
local connections = {}
local tasks = {}

-- No arena API is assumed here.
-- IMPORTANT: the default adapter is deliberately NOT a fake success.
-- Until a real adapter is installed, block requests fail safely.
local BlockInputAdapter = {
    StartBlock = function()
        return false, "No real BlockInputAdapter is configured."
    end,

    StopBlock = function()
        return true
    end,
}

--==================================================
-- DEBUG
--==================================================

local function debugLog(message)
    if not debugEnabled then
        return
    end

    print("[NEXUS BLOCK-ON] " .. message)
end

function BlockOn.SetDebug(value)
    debugEnabled = value == true
end

--==================================================
-- VALIDATION
--==================================================

local function validateAdapter(adapter)
    if type(adapter) ~= "table" then
        return false, "Input adapter must be a table."
    end

    if type(adapter.StartBlock) ~= "function" then
        return false, "Input adapter requires StartBlock()."
    end

    if type(adapter.StopBlock) ~= "function" then
        return false, "Input adapter requires StopBlock()."
    end

    return true
end

-- Execute an adapter callback safely.
--
-- A callback may:
--   return true/false
-- or return nothing.
--
-- If it returns nothing, successful execution is treated as success.
local function callAdapter(methodName)
    local fn = BlockInputAdapter[methodName]

    if type(fn) ~= "function" then
        return false, "Adapter method '" .. methodName .. "' is not callable."
    end

    local ok, result = pcall(fn)

    if not ok then
        return false, result
    end

    if result == false then
        return false, "Adapter rejected " .. methodName .. "()."
    end

    return true
end

--==================================================
-- CLEANUP
--==================================================

local function disconnectAll()
    for key, connection in pairs(connections) do
        if connection then
            pcall(function()
                connection:Disconnect()
            end)
        end

        connections[key] = nil
    end
end

local function cancelAllTasks()
    for key, thread in pairs(tasks) do
        if thread then
            pcall(function()
                task.cancel(thread)
            end)
        end

        tasks[key] = nil
    end
end

--==================================================
-- BLOCK STATE TRANSITIONS
--==================================================

local function enterBlocking()
    -- Idempotency: never send BLOCK ON again if already active.
    if state == BlockOn.States.BLOCKING then
        return true
    end

    local ok, err = callAdapter("StartBlock")

    if not ok then
        -- The external action did not report success.
        -- Keep the internal state at IDLE.
        state = BlockOn.States.IDLE

        if debugEnabled then
            warn("[NEXUS BLOCK-ON] StartBlock failed:", err)
        end

        return false
    end

    state = BlockOn.States.BLOCKING
    debugLog("BLOCK ON")

    return true
end

local function leaveBlocking()
    -- Idempotency: do not send BLOCK OFF if already idle.
    if state == BlockOn.States.IDLE then
        return true
    end

    -- Do not claim the block was released when the adapter failed.
    -- Keeping BLOCKING allows a later reconcile/Stop() to retry the release.
    local ok, err = callAdapter("StopBlock")

    if not ok then
        if debugEnabled then
            warn("[NEXUS BLOCK-ON] StopBlock failed:", err)
        end
        return false
    end

    state = BlockOn.States.IDLE
    debugLog("BLOCK OFF")

    return true
end

local function reconcile()
    -- Nothing should happen while stopped.
    if not running then
        return
    end

    -- Disabled always means no block.
    if not enabled then
        leaveBlocking()
        return
    end

    -- Threat controls the desired block state.
    if threatState then
        enterBlocking()
    else
        leaveBlocking()
    end
end

--==================================================
-- PUBLIC LIFECYCLE
--==================================================

function BlockOn.Start()
    if running then
        -- Idempotent Start().
        reconcile()
        return true
    end

    running = true

    debugLog("START")

    reconcile()

    return true
end

function BlockOn.Stop()
    -- Always attempt release first. If it fails, keep the internal state
    -- truthful and report failure instead of pretending the input stopped.
    local released = leaveBlocking()

    running = false

    disconnectAll()
    cancelAllTasks()

    debugLog("STOP")

    return released
end

--==================================================
-- ENABLE / THREAT API
--==================================================

function BlockOn.SetEnabled(value)
    enabled = value == true

    if not enabled then
        -- Guaranteed release path.
        leaveBlocking()
    elseif running then
        -- If re-enabled while a threat is active, reconcile once.
        reconcile()
    end
end

function BlockOn.IsEnabled()
    return enabled
end

function BlockOn.SetThreatState(value)
    threatState = value == true

    -- React immediately to the requested threat state.
    -- There is intentionally no frame loop or polling here.
    if running then
        reconcile()
    end
end

function BlockOn.IsBlocking()
    return state == BlockOn.States.BLOCKING
end

function BlockOn.GetState()
    return state
end

function BlockOn.IsRunning()
    return running
end

function BlockOn.HasThreat()
    return threatState
end

--==================================================
-- INPUT ADAPTER
--==================================================

function BlockOn.SetInputAdapter(adapter)
    local valid, err = validateAdapter(adapter)

    if not valid then
        error("[NEXUS BLOCK-ON] " .. err, 2)
    end

    -- Never abandon an adapter that may still own an active block.
    if state == BlockOn.States.BLOCKING then
        local released, releaseErr = callAdapter("StopBlock")
        if not released then
            if debugEnabled then
                warn("[NEXUS BLOCK-ON] Cannot replace adapter; old StopBlock failed:", releaseErr)
            end
            return false, releaseErr
        end
        state = BlockOn.States.IDLE
    end

    BlockInputAdapter = {
        StartBlock = adapter.StartBlock,
        StopBlock = adapter.StopBlock,
    }

    if running and enabled and threatState then
        return enterBlocking()
    end

    return true
end

-- Convenience constructor for a legitimate test-arena callback adapter.
-- The arena owns the actual input implementation; this module only invokes it.
function BlockOn.CreateCallbackAdapter(startBlock, stopBlock)
    if type(startBlock) ~= "function" then
        error("[NEXUS BLOCK-ON] CreateCallbackAdapter requires startBlock().", 2)
    end
    if type(stopBlock) ~= "function" then
        error("[NEXUS BLOCK-ON] CreateCallbackAdapter requires stopBlock().", 2)
    end

    return {
        StartBlock = startBlock,
        StopBlock = stopBlock,
    }
end

-- Optional read-only reference for diagnostics.
-- The returned table is a copy so callers cannot replace the
-- controller's functions accidentally.
function BlockOn.GetInputAdapter()
    return {
        StartBlock = BlockInputAdapter.StartBlock,
        StopBlock = BlockInputAdapter.StopBlock,
    }
end

--==================================================
-- OPTIONAL INTERNAL REGISTRATION HELPERS
--==================================================

-- These are intentionally not used by the default controller.
-- They allow future integrations to register resources that Stop()
-- must clean up.

function BlockOn.RegisterConnection(name, connection)
    if type(name) ~= "string" then
        error("[NEXUS BLOCK-ON] Connection name must be a string.", 2)
    end
    if connection == nil or type(connection.Disconnect) ~= "function" then
        error("[NEXUS BLOCK-ON] Connection must provide Disconnect().", 2)
    end

    if connections[name] then
        pcall(function()
            connections[name]:Disconnect()
        end)
    end

    connections[name] = connection
end

function BlockOn.RegisterTask(name, thread)
    if type(name) ~= "string" then
        error("[NEXUS BLOCK-ON] Task name must be a string.", 2)
    end
    if thread == nil then
        error("[NEXUS BLOCK-ON] Task thread cannot be nil.", 2)
    end

    if tasks[name] then
        pcall(function()
            task.cancel(tasks[name])
        end)
    end

    tasks[name] = thread
end

function BlockOn.GetLastError()
    return lastError
end

--==================================================
-- RETURN MODULE
--==================================================

return BlockOn
