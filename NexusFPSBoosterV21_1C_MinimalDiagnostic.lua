-- NexusFPSBooster V21.1-C
-- MINIMAL BOOT DIAGNOSTIC
-- Purpose: determine whether the execution path itself works.
-- No V21 modules/features are loaded in this build.
-- Roblox Studio / authorized own test environment.

print("[NEXUS] C-BOOT: script source started")

local function safe(v)
    local ok, s = pcall(tostring, v)
    return ok and s or "<unprintable>"
end

local Players
local player
local playerGui
local gui
local frame
local status
local log

local function add(text)
    if log then
        log.Text = log.Text .. (log.Text == "" and "" or "\n") .. text
    end
    print("[NEXUS] " .. text)
end

local function fail(stage, err)
    if status then
        status.Text = "STATUS: ERROR"
    end
    add("[ERROR] " .. stage)
    add(safe(err))
end

local ok, err = pcall(function()
    add("1. Script iniciado")

    Players = game:GetService("Players")
    add("2. Players OK")

    player = Players.LocalPlayer
    assert(player, "LocalPlayer is nil")
    add("3. LocalPlayer OK")

    playerGui = player:WaitForChild("PlayerGui", 10)
    assert(playerGui, "PlayerGui not found")
    add("4. PlayerGui OK")

    gui = Instance.new("ScreenGui")
    gui.Name = "NexusV21_1C_MinimalDiagnostic"
    gui.ResetOnSpawn = false
    gui.IgnoreGuiInset = true
    gui.DisplayOrder = 100000
    gui.Parent = playerGui

    frame = Instance.new("Frame")
    frame.Name = "DiagnosticPanel"
    frame.Size = UDim2.fromOffset(430, 280)
    frame.Position = UDim2.new(0, 20, 0.5, -140)
    frame.BackgroundColor3 = Color3.fromRGB(12, 8, 18)
    frame.BackgroundTransparency = 0.05
    frame.BorderSizePixel = 0
    frame.Parent = gui

    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 10)
    corner.Parent = frame

    local stroke = Instance.new("UIStroke")
    stroke.Color = Color3.fromRGB(145, 70, 255)
    stroke.Thickness = 1.5
    stroke.Parent = frame

    local title = Instance.new("TextLabel")
    title.BackgroundTransparency = 1
    title.Position = UDim2.fromOffset(14, 10)
    title.Size = UDim2.new(1, -28, 0, 30)
    title.Font = Enum.Font.GothamBold
    title.TextSize = 18
    title.TextXAlignment = Enum.TextXAlignment.Left
    title.TextColor3 = Color3.fromRGB(240, 230, 255)
    title.Text = "NEXUS V21.1-C"
    title.Parent = frame

    status = Instance.new("TextLabel")
    status.BackgroundTransparency = 1
    status.Position = UDim2.fromOffset(14, 42)
    status.Size = UDim2.new(1, -28, 0, 26)
    status.Font = Enum.Font.GothamBold
    status.TextSize = 14
    status.TextXAlignment = Enum.TextXAlignment.Left
    status.TextColor3 = Color3.fromRGB(215, 195, 255)
    status.Text = "STATUS: INITIALIZING"
    status.Parent = frame

    log = Instance.new("TextLabel")
    log.BackgroundTransparency = 1
    log.Position = UDim2.fromOffset(14, 72)
    log.Size = UDim2.new(1, -28, 1, -84)
    log.Font = Enum.Font.Code
    log.TextSize = 13
    log.TextWrapped = false
    log.TextXAlignment = Enum.TextXAlignment.Left
    log.TextYAlignment = Enum.TextYAlignment.Top
    log.TextColor3 = Color3.fromRGB(225, 225, 235)
    log.Text = ""
    log.Parent = frame

    add("5. GUI criada")

    local camera = workspace.CurrentCamera
    assert(camera, "CurrentCamera is nil")
    add("6. Camera OK")

    local character = player.Character or player.CharacterAdded:Wait()
    assert(character, "Character unavailable")
    add("7. Character OK")

    local humanoid = character:FindFirstChildOfClass("Humanoid")
    assert(humanoid, "Humanoid not found")
    add("8. Humanoid OK")

    local RunService = game:GetService("RunService")
    assert(RunService.RenderStepped ~= nil, "RenderStepped unavailable")
    add("9. RenderStepped OK")

    add("10. MINIMAL DIAGNOSTIC READY")
    status.Text = "STATUS: READY"
end)

if not ok then
    fail("BOOT FAILURE", err)
end
