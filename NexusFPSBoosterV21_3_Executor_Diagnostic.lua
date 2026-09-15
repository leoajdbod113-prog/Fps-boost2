-- Nexus FPS Booster V21.3 - EXECUTOR DIAGNOSTIC
-- Uso: executar diretamente pelo executor externo.
-- Fluxo esperado:
-- loadstring(game:HttpGet(RAW_URL))()
--
-- Mantido o mesmo modelo de execução das versões anteriores.
-- Speed: FORÇADO OFF
-- Fly: FORÇADO OFF
--
-- NexusFPSBooster V21.3-Executor-Diagnostic
-- Diagnostic bootstrap based on the supplied V21.
-- Intended for an authorized Roblox Studio / own test environment.
-- Fly and Speed are disabled for this diagnostic build.

local NEXUS_DIAG = {
    version = "V21.3-Executor-Diagnostic",
    failed = false,
    step = 0,
    ui = nil,
}

local function safeString(value)
    local ok, result = pcall(tostring, value)
    return ok and result or "<unprintable>"
end

local function console(message)
    print("[NEXUS] " .. safeString(message))
end

local function createDiagnosticUI()
    local Players = game:GetService("Players")
    local player = Players.LocalPlayer
    assert(player, "LocalPlayer is nil")

    local playerGui = player:WaitForChild("PlayerGui", 10)
    assert(playerGui, "PlayerGui unavailable")

    local old = playerGui:FindFirstChild("NexusV21_3_Executor_Diagnostic")
    if old then
        old:Destroy()
    end

    local gui = Instance.new("ScreenGui")
    gui.Name = "NexusV21_3_Executor_Diagnostic"
    gui.ResetOnSpawn = false
    gui.IgnoreGuiInset = true
    gui.DisplayOrder = 100000
    gui.Parent = playerGui

    local frame = Instance.new("Frame")
    frame.Name = "Panel"
    frame.Size = UDim2.fromOffset(420, 275)
    frame.Position = UDim2.new(0, 18, 0.5, -137)
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
    title.Text = "NEXUS V21.2-DIAGNOSTIC"
    title.Parent = frame

    local status = Instance.new("TextLabel")
    status.BackgroundTransparency = 1
    status.Position = UDim2.fromOffset(14, 40)
    status.Size = UDim2.new(1, -28, 0, 26)
    status.Font = Enum.Font.GothamBold
    status.TextSize = 14
    status.TextXAlignment = Enum.TextXAlignment.Left
    status.TextColor3 = Color3.fromRGB(215, 195, 255)
    status.Text = "STATUS: BOOT"
    status.Parent = frame

    local log = Instance.new("TextLabel")
    log.BackgroundTransparency = 1
    log.Position = UDim2.fromOffset(14, 70)
    log.Size = UDim2.new(1, -28, 1, -82)
    log.Font = Enum.Font.Code
    log.TextSize = 13
    log.TextWrapped = false
    log.TextXAlignment = Enum.TextXAlignment.Left
    log.TextYAlignment = Enum.TextYAlignment.Top
    log.TextColor3 = Color3.fromRGB(225, 225, 235)
    log.Text = ""
    log.Parent = frame

    local lines = {}

    local api = {}

    function api.log(message)
        lines[#lines + 1] = safeString(message)
        while #lines > 11 do
            table.remove(lines, 1)
        end
        log.Text = table.concat(lines, "\n")
    end

    function api.status(message)
        status.Text = "STATUS: " .. safeString(message)
    end

    function api.error(stage, message)
        api.status("ERROR")
        api.log("FAILED: " .. safeString(stage))
        api.log(safeString(message):sub(1, 300))
    end

    api.gui = gui
    return api
end

-- Absolute first diagnostic output.
console("BOOT")
local uiOk, uiResult = pcall(createDiagnosticUI)

if not uiOk then
    console("DIAGNOSTIC GUI ERROR: " .. safeString(uiResult))
    return
end

NEXUS_DIAG.ui = uiResult
NEXUS_DIAG.ui.log("[NEXUS] BOOT")
NEXUS_DIAG.ui.status("INITIALIZING")

local function step(number, name, callback)
    NEXUS_DIAG.step = number
    NEXUS_DIAG.ui.log(("[%d] %s"):format(number, name))
    console(("%d. %s"):format(number, name))

    local ok, result = pcall(callback)

    if not ok then
        NEXUS_DIAG.failed = true
        NEXUS_DIAG.ui.error(name, result)
        console("ERROR | " .. name .. " | " .. safeString(result))
        return false
    end

    NEXUS_DIAG.ui.log("    OK")
    return true
end

local Players
local RunService
local player
local playerGui
local camera
local character
local humanoid

if not step(1, "Script iniciado", function()
    assert(NEXUS_DIAG.ui and NEXUS_DIAG.ui.gui.Parent, "Diagnostic GUI parent is missing")
end) then
    return
end

if not step(2, "Services OK", function()
    Players = game:GetService("Players")
    RunService = game:GetService("RunService")
    game:GetService("ReplicatedStorage")
    game:GetService("Workspace")
end) then
    return
end

if not step(3, "LocalPlayer OK", function()
    player = Players.LocalPlayer
    assert(player, "Players.LocalPlayer is nil")
end) then
    return
end

if not step(4, "PlayerGui OK", function()
    playerGui = player:WaitForChild("PlayerGui", 10)
    assert(playerGui, "PlayerGui unavailable")
end) then
    return
end

if not step(5, "GUI criada", function()
    assert(NEXUS_DIAG.ui.gui.Parent == playerGui, "Diagnostic GUI is not inside PlayerGui")
end) then
    return
end

if not step(6, "Camera OK", function()
    camera = workspace.CurrentCamera
    assert(camera, "workspace.CurrentCamera is nil")
end) then
    return
end

if not step(7, "Character OK", function()
    character = player.Character or player.CharacterAdded:Wait()
    assert(character, "Character unavailable")
end) then
    return
end

if not step(8, "Humanoid OK", function()
    humanoid = character:FindFirstChildOfClass("Humanoid")
    assert(humanoid, "Humanoid not found")
end) then
    return
end

if not step(9, "RenderStepped OK", function()
    assert(RunService.RenderStepped ~= nil, "RenderStepped unavailable")
end) then
    return
end

NEXUS_DIAG.ui.log("[NEXUS] BASIC BOOT OK")
NEXUS_DIAG.ui.log("[NEXUS] V21 STARTING...")
NEXUS_DIAG.ui.status("V21 INITIALIZING")
console("Basic bootstrap OK; starting supplied V21")

-- These globals are consumed by the corrected V21 integration points.
_G.NEXUS_V21_2_DIAGNOSTIC = NEXUS_DIAG
_G.NEXUS_V21_2_DISABLE_SPEED = true
_G.NEXUS_V21_2_DISABLE_FLY = true


-- ============================================================
-- SUPPLIED NEXUS V21 BODY
-- Preserved as provided for diagnostic comparison.
-- ============================================================

--[[
    NEXUS FPS BOOSTER V21
    LocalScript - Roblox Studio

    Novidades da V4:
    • Anti-Lag (reduz distância de streaming/renderização)
    • Desligar sons do jogo
    • Modo "Só o Essencial" (esconde HUD/Chat/Backpack)
    • Gráfico de FPS ao longo do tempo (aba INFO)
    • Ping médio / mínimo / máximo
    • Configurações salvas (via writefile/readfile, se o executor suportar)
    • Botão de minimizar o painel
    • Mantém: modos LOW/MEDIUM/HIGH/ULTRA/BATATA, RAM Cleaner, backup/restore
]]

-- ============================================================
-- V21.2 STAGED EXECUTION WRAPPER
-- Catches top-level failures and records the last section reached.
-- Speed/Fly remain disabled for this diagnostic build.
-- ============================================================
local __V212_STAGE = "PRE-BODY"

local function __V212Stage(name)
    __V212_STAGE = name
    pcall(function()
        if NEXUS_DIAG and NEXUS_DIAG.ui then
            NEXUS_DIAG.ui.log("[STAGE] " .. name)
            NEXUS_DIAG.ui.status(name)
        end
        print("[NEXUS] STAGE -> " .. name)
    end)
end

local function __V212ErrorText(err)
    local msg = safeString(err)
    local ok, trace = pcall(function()
        if debug and debug.traceback then
            return debug.traceback(msg, 2)
        end
        return msg
    end)
    if ok and trace then return safeString(trace) end
    return msg
end

local __V212BodyOK, __V212BodyErr

__V212BodyOK, __V212BodyErr = xpcall(function()
    __V212Stage("SERVICES")


local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local Lighting = game:GetService("Lighting")
local Workspace = game:GetService("Workspace")
local UserInputService = game:GetService("UserInputService")
local Stats = game:GetService("Stats")
local StarterGui = game:GetService("StarterGui")
local SoundService = game:GetService("SoundService")
local HttpService = game:GetService("HttpService")

local Player = Players.LocalPlayer

__V212Stage("COLORS")

--==================================================
-- COLORS
--==================================================

local PURPLE = Color3.fromRGB(180, 60, 255)
local PANEL2 = Color3.fromRGB(30, 18, 45)
local WHITE = Color3.fromRGB(240, 235, 250)
local GREEN = Color3.fromRGB(70, 255, 150)
local RED = Color3.fromRGB(255, 70, 90)
local YELLOW = Color3.fromRGB(255, 210, 70)

__V212Stage("CONFIG FILE (salvar/carregar configs)")

--==================================================
-- CONFIG FILE (salvar/carregar configs)
--==================================================

local CONFIG_FILE = "NexusFPSBooster_config.json"

local function SaveConfig(data)
	pcall(function()
		if writefile then
			writefile(CONFIG_FILE, HttpService:JSONEncode(data))
		end
	end)
end

local function LoadConfig()
	local ok, result = pcall(function()
		if isfile and isfile(CONFIG_FILE) and readfile then
			return HttpService:JSONDecode(readfile(CONFIG_FILE))
		end
		return nil
	end)
	if ok then return result end
	return nil
end

__V212Stage("STATE")

--==================================================
-- STATE
--==================================================

local BoosterEnabled = false
local CurrentMode = "LOW"
local AntiLagEnabled = false
local SoundsOff = false
local EssentialOnly = false
local Minimized = false
local SpeedEnabled = false
local SpeedValue = 20
local OriginalWalkSpeed = nil
local AimLockEnabled = false
local AimTarget = nil
local FlyEnabled = false
local FlySpeed = 60

local SavedConfig = LoadConfig()
if SavedConfig then
	CurrentMode = SavedConfig.CurrentMode or CurrentMode
	AntiLagEnabled = SavedConfig.AntiLagEnabled or false
	SoundsOff = SavedConfig.SoundsOff or false
	EssentialOnly = SavedConfig.EssentialOnly or false
	SpeedEnabled = false -- V21.3 executor diagnostic: forced OFF
	SpeedValue = math.clamp(SavedConfig.SpeedValue or 20, 20, 400)
	AimLockEnabled = false -- Hard lock starts OFF every session; never auto-activates from saved config
	FlyEnabled = false -- V21.3 executor diagnostic: forced OFF
FlySpeed = math.clamp(SavedConfig.FlySpeed or 60, 20, 150)
end

local function PersistConfig()
	SaveConfig({
		CurrentMode = CurrentMode,
		AntiLagEnabled = AntiLagEnabled,
		SoundsOff = SoundsOff,
		EssentialOnly = EssentialOnly,
		SpeedEnabled = SpeedEnabled,
		SpeedValue = SpeedValue,
		AimLockEnabled = AimLockEnabled,
		FlyEnabled = FlyEnabled,
		FlySpeed = FlySpeed
	})
end

__V212Stage("MODES")

--==================================================
-- MODES
--==================================================

local Modes = {
	LOW = { Textures = true, Decals = true, Particles = true, Effects = true, Shadows = true, Materials = true },
	MEDIUM = { Textures = false, Decals = false, Particles = false, Effects = true, Shadows = false, Materials = true },
	HIGH = { Textures = false, Decals = false, Particles = false, Effects = false, Shadows = false, Materials = true },
	ULTRA = { Textures = false, Decals = false, Particles = false, Effects = false, Shadows = false, Materials = false },
	BATATA = { Textures = false, Decals = false, Particles = false, Effects = false, Shadows = false, Materials = false, Extreme = true }
}

__V212Stage("BACKUP / RESTORE")

--==================================================
-- BACKUP / RESTORE
--==================================================

local Backup = {}
local BackupCreated = false
local OriginalStreamingRadius, OriginalStreamingMinRadius

pcall(function()
	OriginalStreamingRadius = Workspace.StreamingTargetRadius
	OriginalStreamingMinRadius = Workspace.StreamingMinRadius
end)

local function SaveOriginal(obj)
	if Backup[obj] then return end
	local data = {}

	if obj:IsA("BasePart") then
		data.Material = obj.Material
		data.CastShadow = obj.CastShadow
	end
	if obj:IsA("Texture") or obj:IsA("Decal") then
		data.Transparency = obj.Transparency
	end
	if obj:IsA("ParticleEmitter") or obj:IsA("Trail") or obj:IsA("Beam")
		or obj:IsA("Smoke") or obj:IsA("Fire") or obj:IsA("Sparkles") then
		data.Enabled = obj.Enabled
	end
	if obj:IsA("PostEffect") then
		data.Enabled = obj.Enabled
	end
	if obj:IsA("Sound") then
		data.Volume = obj.Volume
	end

	Backup[obj] = data
end

local function CreateBackup()
	if BackupCreated then return end
	for _, obj in ipairs(Workspace:GetDescendants()) do SaveOriginal(obj) end
	for _, obj in ipairs(Lighting:GetChildren()) do SaveOriginal(obj) end
	BackupCreated = true
end

local function RestoreGraphics()
	for obj, data in pairs(Backup) do
		if obj and obj.Parent then
			if obj:IsA("BasePart") then
				if data.Material then obj.Material = data.Material end
				if data.CastShadow ~= nil then obj.CastShadow = data.CastShadow end
			end
			if (obj:IsA("Texture") or obj:IsA("Decal")) and data.Transparency ~= nil then
				obj.Transparency = data.Transparency
			end
			if obj:IsA("ParticleEmitter") or obj:IsA("Trail") or obj:IsA("Beam")
				or obj:IsA("Smoke") or obj:IsA("Fire") or obj:IsA("Sparkles") then
				if data.Enabled ~= nil then obj.Enabled = data.Enabled end
			end
			if obj:IsA("PostEffect") and data.Enabled ~= nil then
				obj.Enabled = data.Enabled
			end
		end
	end
	Lighting.GlobalShadows = true
	BoosterEnabled = false
end

__V212Stage("BOOST")

--==================================================
-- BOOST
--==================================================

local function ApplyBoostToObject(obj)
	local Config = Modes[CurrentMode]

	if obj:IsA("Texture") then
		if not Config.Textures then obj.Transparency = 1 end
	elseif obj:IsA("Decal") then
		if not Config.Decals then obj.Transparency = 1 end
	elseif obj:IsA("SurfaceAppearance") then
		if Config.Extreme then obj.Parent = nil end
	elseif obj:IsA("BasePart") then
		if not Config.Shadows then obj.CastShadow = false end
		if not Config.Materials then obj.Material = Enum.Material.SmoothPlastic end
	elseif obj:IsA("ParticleEmitter") or obj:IsA("Trail") or obj:IsA("Beam")
		or obj:IsA("Smoke") or obj:IsA("Fire") or obj:IsA("Sparkles") then
		if not Config.Particles then obj.Enabled = false end
	end
end

local function ApplyBoost()
	CreateBackup()

	for _, obj in ipairs(Workspace:GetDescendants()) do
		ApplyBoostToObject(obj)
	end

	local Config = Modes[CurrentMode]

	if not Config.Effects then
		for _, obj in ipairs(Lighting:GetChildren()) do
			if obj:IsA("PostEffect") then obj.Enabled = false end
		end
	end

	if not Config.Shadows then
		Lighting.GlobalShadows = false
	end
end

-- aplica o boost automaticamente em partes/decals/texturas NOVAS
-- (ex: blocos que quebram e geram pedaços novos durante o jogo)
Workspace.DescendantAdded:Connect(function(obj)
	if not BoosterEnabled then return end
	task.defer(function()
		pcall(function()
			SaveOriginal(obj)
			ApplyBoostToObject(obj)
		end)
	end)
end)

__V212Stage("ANTI-LAG (reduz distância de renderização)")

--==================================================
-- ANTI-LAG (reduz distância de renderização)
--==================================================

local function ApplyAntiLag(state)
	pcall(function()
		if state then
			Workspace.StreamingEnabled = true
			Workspace.StreamingTargetRadius = 96
			Workspace.StreamingMinRadius = 48
		else
			if OriginalStreamingRadius then
				Workspace.StreamingTargetRadius = OriginalStreamingRadius
			end
			if OriginalStreamingMinRadius then
				Workspace.StreamingMinRadius = OriginalStreamingMinRadius
			end
		end
	end)
end

__V212Stage("SONS (mute geral)")

--==================================================
-- SONS (mute geral)
--==================================================

local SoundConnection

local function MuteAllSounds()
	for _, obj in ipairs(Workspace:GetDescendants()) do
		if obj:IsA("Sound") then
			SaveOriginal(obj)
			obj.Volume = 0
		end
	end
	pcall(function() SoundService.AmbientReverb = Enum.ReverbType.NoReverb end)
end

local function UnmuteAllSounds()
	for obj, data in pairs(Backup) do
		if obj and obj.Parent and obj:IsA("Sound") and data.Volume ~= nil then
			obj.Volume = data.Volume
		end
	end
end

local function ApplySoundsOff(state)
	if state then
		MuteAllSounds()
		if SoundConnection then SoundConnection:Disconnect() end
		SoundConnection = Workspace.DescendantAdded:Connect(function(obj)
			if obj:IsA("Sound") then
				task.wait()
				pcall(function() obj.Volume = 0 end)
			end
		end)
	else
		if SoundConnection then
			SoundConnection:Disconnect()
			SoundConnection = nil
		end
		UnmuteAllSounds()
	end
end

__V212Stage("MODO SÓ O ESSENCIAL (esconde HUD/Chat/Backpack)")

--==================================================
-- MODO SÓ O ESSENCIAL (esconde HUD/Chat/Backpack)
--==================================================

local function ApplyEssentialOnly(state)
	pcall(function()
		if state then
			StarterGui:SetCoreGuiEnabled(Enum.CoreGuiType.Backpack, false)
			StarterGui:SetCoreGuiEnabled(Enum.CoreGuiType.Chat, false)
			StarterGui:SetCoreGuiEnabled(Enum.CoreGuiType.PlayerList, false)
			StarterGui:SetCoreGuiEnabled(Enum.CoreGuiType.EmotesMenu, false)
		else
			StarterGui:SetCoreGuiEnabled(Enum.CoreGuiType.Backpack, true)
			StarterGui:SetCoreGuiEnabled(Enum.CoreGuiType.Chat, true)
			StarterGui:SetCoreGuiEnabled(Enum.CoreGuiType.PlayerList, true)
			StarterGui:SetCoreGuiEnabled(Enum.CoreGuiType.EmotesMenu, true)
		end
	end)
end

__V212Stage("RAM CLEANER")

--==================================================
-- RAM CLEANER
--==================================================

local function CleanRAM()
	local before = collectgarbage("count")
	collectgarbage("collect")
	local after = collectgarbage("count")
	return math.max(before - after, 0)
end

__V212Stage("PLAYER SPEED")

--==================================================
-- PLAYER SPEED
--==================================================

local function GetHumanoid()
	local Character = Player.Character
	return Character and Character:FindFirstChildOfClass("Humanoid")
end

local function ApplySpeed()
	local Humanoid = GetHumanoid()
	if not Humanoid then return end

	if OriginalWalkSpeed == nil then
		OriginalWalkSpeed = Humanoid.WalkSpeed
	end

	if SpeedEnabled then
		if Humanoid.WalkSpeed ~= SpeedValue then
			Humanoid.WalkSpeed = SpeedValue
		end
	else
		local restore = OriginalWalkSpeed or 16
		if Humanoid.WalkSpeed ~= restore then
			Humanoid.WalkSpeed = restore
		end
	end
end

-- Alguns jogos/characters sobrescrevem WalkSpeed.
-- Reaplica somente quando o valor mudou.
local SpeedHeartbeatConnection = RunService.Heartbeat:Connect(function()
	if SpeedEnabled then
		ApplySpeed()
	end
end)

Player.CharacterAdded:Connect(function(Character)
	OriginalWalkSpeed = nil
	task.wait(0.5)
	ApplySpeed()
end)


__V212Stage("NEXUS DUEL CAMERA / HARD LOCK - STUDIO V20")

--==================================================
-- NEXUS DUEL CAMERA / HARD LOCK - STUDIO V20
--==================================================
-- Studio / Place próprio.
-- Sistema de câmera de duelo com:
-- • anti-jitter e deadzone
-- • lado da câmera estabilizado durante todo o lock
-- • enquadramento dos dois personagens
-- • altura mínima/máxima
-- • distância adaptativa por FOV
-- • proteção contra câmera apontando para baixo
-- • proteção contra saída da tela
-- • anti-clipping em paredes
-- • rotação suave do personagem
-- • modos DUEL / SMOOTH / STABLE / CLOSE / FAR
-- Jogador = azul neon | alvo = roxo neon.

local LOCKON_RANGE = 110
local LOCKON_ACQUIRE_FOV = 0.78
local LOCKON_MAX_FOLLOW_DISTANCE = 500
local LOCKON_ACQUIRE_ANGLE = math.rad(62)
local LOCKON_REQUIRE_VISIBLE_ON_ACQUIRE = true
local LOCKON_CAMERA_PRIORITY = Enum.RenderPriority.Camera.Value + 2

-- Rotação
local LOCKON_FACING_SMOOTH = 9
local LOCKON_FACING_DEADZONE = 0.12

-- Câmera base
local LOCKON_MIN_DISTANCE = 9
local LOCKON_MAX_DISTANCE = 34
local LOCKON_DEFAULT_DISTANCE = 15
local LOCKON_CAMERA_HEIGHT = 5.2
local LOCKON_MIN_HEIGHT = 4.2
local LOCKON_MAX_HEIGHT = 7.5
local LOCKON_LOOK_HEIGHT = 3.15
local LOCKON_FRAME_MARGIN = 0.28
local LOCKON_EXTRA_DISTANCE = 2.8

-- Suavização única
local LOCKON_CAMERA_SMOOTH = 7.5
local LOCKON_DISTANCE_IN_SMOOTH = 3.8
local LOCKON_DISTANCE_OUT_SMOOTH = 18
local LOCKON_SIDE_SMOOTH = 4.5
local LOCKON_ANCHOR_SMOOTH = 10
local LOCKON_JITTER_DEADZONE = 0.055
local LOCKON_VERTICAL_DEADZONE = 0.10

-- Colisão
local LOCKON_WALL_BUFFER = 1.25
local LOCKON_MIN_WALL_DISTANCE = 6

-- Proteção de enquadramento
local LOCKON_SAFE_TOP = 0.14
local LOCKON_SAFE_BOTTOM = 0.86
local LOCKON_SAFE_LEFT = 0.12
local LOCKON_SAFE_RIGHT = 0.88

-- Modos de câmera.
local CameraModes = {"DUEL", "SMOOTH", "STABLE", "CLOSE", "FAR"}
local CameraMode = "DUEL"
local CameraModeIndex = 1

local AimTarget = nil
local AimTargetPlayer = nil
local AimTargetHumanoid = nil
local AimTargetRoot = nil
local AimTargetPart = nil
local AimLockGeneration = 0
local LockedHumanoidForFacing = nil
local LockMarker = nil
local SelfMarker = nil
local LastCameraPosition = nil
local LastCameraDistance = LOCKON_DEFAULT_DISTANCE
local LastCameraSide = nil
local LockCameraSideSign = 1
local CameraWasLocked = false
local PreviousCameraType = nil
local PreviousCameraSubject = nil
local PreviousAutoRotate = nil
local PreviousLocalHumanoid = nil
local StableAnchor = nil
local StableLookPoint = nil
local StableSide = nil

local DisableLockOn
local UP = Vector3.new(0, 1, 0)

local function GetCameraModeSettings()
	if CameraMode == "SMOOTH" then
		return 5.2, 4.5, 9, 2.5
	elseif CameraMode == "STABLE" then
		return 4.9, 3.2, 5.5, 2.1
	elseif CameraMode == "CLOSE" then
		return 4.7, 5.0, 12, 1.8
	elseif CameraMode == "FAR" then
		return 5.8, 3.8, 15, 4.2
	end
	return LOCKON_CAMERA_HEIGHT, LOCKON_CAMERA_SMOOTH, LOCKON_ANCHOR_SMOOTH, LOCKON_EXTRA_DISTANCE
end

local function SetCameraMode(mode)
	for i, name in ipairs(CameraModes) do
		if name == mode then
			CameraMode = name
			CameraModeIndex = i
			return CameraMode
		end
	end
	CameraMode = "DUEL"
	CameraModeIndex = 1
	return CameraMode
end

local function CycleCameraMode()
	CameraModeIndex = (CameraModeIndex % #CameraModes) + 1
	CameraMode = CameraModes[CameraModeIndex]
	return CameraMode
end

local function RemoveLockMarker()
	if LockMarker then pcall(function() LockMarker:Destroy() end) end
	LockMarker = nil
end

local function CreateLockMarker(character)
	RemoveLockMarker()
	if not character or not character.Parent then return end
	local ok, marker = pcall(function()
		local h = Instance.new('Highlight')
		h.Name = 'NexusLockMarker'
		h.Adornee = character
		h.FillTransparency = 1
		h.OutlineColor = PURPLE
		h.OutlineTransparency = 0
		h.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
		h.Parent = character
		return h
	end)
	if ok then LockMarker = marker end
end

local function RemoveSelfMarker()
	if SelfMarker then pcall(function() SelfMarker:Destroy() end) end
	SelfMarker = nil
end

local function CreateSelfMarker(character)
	if SelfMarker and SelfMarker.Parent == character and SelfMarker.Adornee == character then return end
	RemoveSelfMarker()
	if not character or not character.Parent then return end
	local ok, marker = pcall(function()
		local h = Instance.new('Highlight')
		h.Name = 'NexusSelfMarker'
		h.Adornee = character
		h.FillTransparency = 1
		h.OutlineColor = Color3.fromRGB(0, 170, 255)
		h.OutlineTransparency = 0
		h.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
		h.Parent = character
		return h
	end)
	if ok then SelfMarker = marker end
end

local function RefreshSelfMarker()
	local character = Player.Character
	if character then CreateSelfMarker(character) end
end

local function GetLockOnPart(character)
	if not character then return nil end
	return character:FindFirstChild('Head')
		or character:FindFirstChild('UpperTorso')
		or character:FindFirstChild('Torso')
		or character:FindFirstChild('HumanoidRootPart')
end

local function BuildTargetData(player, checkAcquireRules)
	if not player or player == Player or not player.Parent then return nil end
	local character = player.Character
	if not character or not character.Parent then return nil end
	local humanoid = character:FindFirstChildOfClass('Humanoid')
	local root = character:FindFirstChild('HumanoidRootPart')
	local part = GetLockOnPart(character)
	if not humanoid or humanoid.Health <= 0 or not root or not part then return nil end

	Camera = Workspace.CurrentCamera or Camera
	if not Camera then return nil end
	local offset = root.Position - Camera.CFrame.Position
	local distance = offset.Magnitude
	if distance < 2 or distance > LOCKON_RANGE then return nil end

	if checkAcquireRules then
		local direction = offset / distance
		if math.acos(math.clamp(Camera.CFrame.LookVector:Dot(direction), -1, 1)) > LOCKON_ACQUIRE_ANGLE then return nil end

		local screen, onScreen = Camera:WorldToViewportPoint(part.Position)
		if not onScreen or screen.Z <= 0 then return nil end
		local center = Vector2.new(Camera.ViewportSize.X * .5, Camera.ViewportSize.Y * .5)
		local screenDistance = (Vector2.new(screen.X, screen.Y) - center).Magnitude
		local maxScreenDistance = math.max(Camera.ViewportSize.X, Camera.ViewportSize.Y) * LOCKON_ACQUIRE_FOV
		if screenDistance > maxScreenDistance then return nil end

		if LOCKON_REQUIRE_VISIBLE_ON_ACQUIRE then
			local params = RaycastParams.new()
			params.FilterType = Enum.RaycastFilterType.Exclude
			params.FilterDescendantsInstances = {Player.Character}
			params.IgnoreWater = true
			local hit = Workspace:Raycast(Camera.CFrame.Position, part.Position - Camera.CFrame.Position, params)
			if hit and not hit.Instance:IsDescendantOf(character) then return nil end
		end

		return {Player=player, Character=character, Humanoid=humanoid, Root=root, Part=part, Distance=distance, ScreenDistance=screenDistance}
	end

	return {Player=player, Character=character, Humanoid=humanoid, Root=root, Part=part, Distance=distance}
end

local function FindLockOnTarget()
	Camera = Workspace.CurrentCamera or Camera
	if not Camera then return nil end
	local best, bestScore = nil, math.huge
	local viewport = Camera.ViewportSize
	local center = Vector2.new(viewport.X * .5, viewport.Y * .5)
	local screenScale = math.max(viewport.X, viewport.Y) * LOCKON_ACQUIRE_FOV

	for _, player in ipairs(Players:GetPlayers()) do
		local candidate = BuildTargetData(player, true)
		if candidate then
			local screenScore = candidate.ScreenDistance / math.max(screenScale, 1)
			local distanceScore = candidate.Distance / LOCKON_RANGE
			local score = screenScore * .82 + distanceScore * .18
			if score < bestScore then
				bestScore = score
				best = candidate
			end
		end
	end
	return best
end

local function RestoreCharacterFacing()
	if LockedHumanoidForFacing and LockedHumanoidForFacing.Parent then
		pcall(function() LockedHumanoidForFacing.AutoRotate = true end)
	end
	LockedHumanoidForFacing = nil
end

local function RestoreCamera()
	Camera = Workspace.CurrentCamera or Camera
	if not Camera then return end
	if PreviousCameraType then pcall(function() Camera.CameraType = PreviousCameraType end) end
	if PreviousCameraSubject and PreviousCameraSubject.Parent then pcall(function() Camera.CameraSubject = PreviousCameraSubject end) end
	PreviousCameraType = nil
	PreviousCameraSubject = nil
end

local function ClearLockOn()
	RemoveLockMarker()
	RestoreCharacterFacing()
	if PreviousLocalHumanoid and PreviousLocalHumanoid.Parent and PreviousAutoRotate ~= nil then
		pcall(function() PreviousLocalHumanoid.AutoRotate = PreviousAutoRotate end)
	end
	PreviousLocalHumanoid = nil
	PreviousAutoRotate = nil
	RestoreCamera()
	AimTarget, AimTargetPlayer, AimTargetHumanoid = nil, nil, nil
	AimTargetRoot, AimTargetPart = nil, nil
	AimLockGeneration += 1
	LastCameraPosition = nil
	LastCameraDistance = LOCKON_DEFAULT_DISTANCE
	LastCameraSide = nil
	StableAnchor = nil
	StableLookPoint = nil
	StableSide = nil
	LockCameraSideSign = 1
	CameraWasLocked = false
end

local function InitializeCameraSide(localRoot, targetRoot, midpoint)
	-- Define o lado uma única vez no início do lock. Isso evita a câmera
	-- trocar de lado/"orbitar" a cada pequena mudança do alvo.
	local duel = targetRoot.Position - localRoot.Position
	duel = Vector3.new(duel.X, 0, duel.Z)
	if duel.Magnitude < 0.05 then return LastCameraSide or Vector3.new(1,0,0) end
	duel = duel.Unit

	Camera = Workspace.CurrentCamera or Camera
	local side
	if Camera then
		local cameraFlat = Vector3.new(Camera.CFrame.Position.X - midpoint.X, 0, Camera.CFrame.Position.Z - midpoint.Z)
		cameraFlat = cameraFlat - duel * cameraFlat:Dot(duel)
		if cameraFlat.Magnitude > 0.1 then
			side = cameraFlat.Unit
		end
	end
	if not side then
		side = duel:Cross(UP)
		if side.Magnitude < 0.05 then side = Vector3.new(1,0,0) else side = side.Unit end
	end
	return side
end

local function AcquireLockOn()
	local target = FindLockOnTarget()
	if not target then ClearLockOn(); return false end

	Camera = Workspace.CurrentCamera or Camera
	local localCharacter = Player.Character
	local localHumanoid = localCharacter and localCharacter:FindFirstChildOfClass('Humanoid')
	local localRoot = localCharacter and localCharacter:FindFirstChild('HumanoidRootPart')
	if not Camera or not localHumanoid or not localRoot then return false end

	AimTarget = target.Character
	AimTargetPlayer = target.Player
	AimTargetHumanoid = target.Humanoid
	AimTargetRoot = target.Root
	AimTargetPart = target.Part
	AimLockGeneration += 1

	CreateLockMarker(target.Character)
	RefreshSelfMarker()

	PreviousCameraType = Camera.CameraType
	PreviousCameraSubject = Camera.CameraSubject
	pcall(function() Camera.CameraType = Enum.CameraType.Scriptable end)

	PreviousLocalHumanoid = localHumanoid
	PreviousAutoRotate = localHumanoid.AutoRotate
	pcall(function() localHumanoid.AutoRotate = false end)
	pcall(function() target.Humanoid.AutoRotate = false end)
	LockedHumanoidForFacing = target.Humanoid

	local a = localRoot.Position + Vector3.new(0, LOCKON_LOOK_HEIGHT, 0)
	local b = target.Root.Position + Vector3.new(0, LOCKON_LOOK_HEIGHT, 0)
	local midpoint = (a + b) * 0.5
	LastCameraSide = InitializeCameraSide(localRoot, target.Root, midpoint)
	StableSide = LastCameraSide
	LastCameraDistance = LOCKON_DEFAULT_DISTANCE
	LastCameraPosition = nil
	StableAnchor = midpoint
	StableLookPoint = midpoint
	CameraWasLocked = false

	return true
end

local function IsCurrentTargetValid()
	if not AimTargetPlayer or not AimTargetPlayer.Parent then return false end
	if not AimTarget or not AimTarget.Parent or AimTargetPlayer.Character ~= AimTarget then return false end
	if not AimTargetHumanoid or AimTargetHumanoid.Health <= 0 or AimTargetHumanoid.Parent ~= AimTarget then return false end
	if not AimTargetRoot or not AimTargetRoot.Parent or AimTargetRoot.Parent ~= AimTarget then return false end
	Camera = Workspace.CurrentCamera or Camera
	return Camera ~= nil and (AimTargetRoot.Position - Camera.CFrame.Position).Magnitude <= LOCKON_MAX_FOLLOW_DISTANCE
end

local function FaceLocalCharacterToTarget(dt)
	local character = Player.Character
	local localHumanoid = character and character:FindFirstChildOfClass('Humanoid')
	local localRoot = character and character:FindFirstChild('HumanoidRootPart')
	if not localHumanoid or not localRoot or not AimTargetRoot then return end

	local flat = AimTargetRoot.Position - localRoot.Position
	flat = Vector3.new(flat.X, 0, flat.Z)
	if flat.Magnitude < LOCKON_FACING_DEADZONE then return end

	pcall(function() localHumanoid.AutoRotate = false end)
	PreviousLocalHumanoid = localHumanoid
	local desired = CFrame.lookAt(localRoot.Position, localRoot.Position + flat.Unit)
	local alpha = 1 - math.exp(-LOCKON_FACING_SMOOTH * math.clamp(dt, 1/240, 1/20))
	localRoot.CFrame = localRoot.CFrame:Lerp(desired, alpha)
end

local function GetSafeCameraPosition(desiredPosition, framePoint)
	local ray = desiredPosition - framePoint
	local length = ray.Magnitude
	if length <= 0.01 then return desiredPosition end
	local params = RaycastParams.new()
	params.FilterType = Enum.RaycastFilterType.Exclude
	params.FilterDescendantsInstances = {Player.Character, AimTarget}
	params.IgnoreWater = true
	local hit = Workspace:Raycast(framePoint, ray, params)
	if hit then
		local safeLength = math.max(LOCKON_MIN_WALL_DISTANCE, hit.Distance - LOCKON_WALL_BUFFER)
		if safeLength < length then return framePoint + ray.Unit * safeLength end
	end
	return desiredPosition
end

local function CalculateRequiredDistance(localRoot, targetRoot, camera, extraDistance)
	local localPoint = localRoot.Position + Vector3.new(0, LOCKON_LOOK_HEIGHT, 0)
	local targetPoint = targetRoot.Position + Vector3.new(0, LOCKON_LOOK_HEIGHT, 0)
	local delta = targetPoint - localPoint
	local horizontalSeparation = Vector3.new(delta.X,0,delta.Z).Magnitude
	local verticalSeparation = math.abs(delta.Y)

	local viewport = camera.ViewportSize
	local aspect = math.max(viewport.X / math.max(viewport.Y,1), 0.5)
	local verticalFov = math.rad(math.clamp(camera.FieldOfView, 45, 90))
	local horizontalFov = 2 * math.atan(math.tan(verticalFov * .5) * aspect)
	local usableH = math.max(math.tan(horizontalFov*.5) * (1-LOCKON_FRAME_MARGIN), .16)
	local usableV = math.max(math.tan(verticalFov*.5) * (1-LOCKON_FRAME_MARGIN), .16)

	local horizontalDistance = (horizontalSeparation*.5) / usableH
	local verticalDistance = (verticalSeparation*.5) / usableV
	return math.clamp(math.max(horizontalDistance, verticalDistance) + extraDistance, LOCKON_MIN_DISTANCE, LOCKON_MAX_DISTANCE)
end

local function ProjectPointForCamera(worldPoint, cameraCFrame, camera)
	local localPoint = cameraCFrame:PointToObjectSpace(worldPoint)
	local z = -localPoint.Z
	if z <= 0.01 then return nil end
	local viewport = camera.ViewportSize
	local aspect = math.max(viewport.X / math.max(viewport.Y, 1), 0.5)
	local vfov = math.rad(math.clamp(camera.FieldOfView, 45, 90))
	local hfov = 2 * math.atan(math.tan(vfov * .5) * aspect)
	local nx = localPoint.X / (z * math.tan(hfov * .5))
	local ny = localPoint.Y / (z * math.tan(vfov * .5))
	return .5 + nx * .5, .5 - ny * .5
end

local function IsDuelFramingSafe(camera, cameraCFrame, localPoint, targetPoint)
	local lx, ly = ProjectPointForCamera(localPoint, cameraCFrame, camera)
	local tx, ty = ProjectPointForCamera(targetPoint, cameraCFrame, camera)
	if not lx or not tx then return false end
	return lx >= LOCKON_SAFE_LEFT and lx <= LOCKON_SAFE_RIGHT
		and tx >= LOCKON_SAFE_LEFT and tx <= LOCKON_SAFE_RIGHT
		and ly >= LOCKON_SAFE_TOP and ly <= LOCKON_SAFE_BOTTOM
		and ty >= LOCKON_SAFE_TOP and ty <= LOCKON_SAFE_BOTTOM
end

local function SolveDuelFraming(camera, midpoint, side, height, distance, localPoint, targetPoint, maxDistance)
	local solved = distance
	for _ = 1, 5 do
		local position = midpoint + side * solved + Vector3.new(0, height, 0)
		local candidate = CFrame.lookAt(position, midpoint + Vector3.new(0, .25, 0))
		if IsDuelFramingSafe(camera, candidate, localPoint, targetPoint) then
			return solved, position, candidate
		end
		solved = math.min(maxDistance, solved + 2.25)
		if solved >= maxDistance then break end
	end
	local position = midpoint + side * solved + Vector3.new(0, height, 0)
	local candidate = CFrame.lookAt(position, midpoint + Vector3.new(0, .25, 0))
	return solved, position, candidate
end

local function PointNeedsMoreDistance(worldPoint, camera, margin)
	local screen, onScreen = camera:WorldToViewportPoint(worldPoint)
	if screen.Z <= 0 then return true end
	local w, h = camera.ViewportSize.X, camera.ViewportSize.Y
	if w <= 1 or h <= 1 then return false end
	local x = screen.X / w
	local y = screen.Y / h
	return (not onScreen)
		or x < LOCKON_SAFE_LEFT - margin
		or x > LOCKON_SAFE_RIGHT + margin
		or y < LOCKON_SAFE_TOP - margin
		or y > LOCKON_SAFE_BOTTOM + margin
end

local function UpdateDuelCamera(dt)
	if not AimLockEnabled or not IsCurrentTargetValid() then
		if CameraWasLocked then CameraWasLocked=false; LastCameraPosition=nil end
		return
	end

	Camera = Workspace.CurrentCamera or Camera
	local localCharacter = Player.Character
	local localRoot = localCharacter and localCharacter:FindFirstChild('HumanoidRootPart')
	if not Camera or not localRoot or not AimTargetRoot then return end
	RefreshSelfMarker()

	local modeHeight, modeSmooth, modeAnchorSmooth, modeExtra = GetCameraModeSettings()
	local a = localRoot.Position + Vector3.new(0, LOCKON_LOOK_HEIGHT, 0)
	local b = AimTargetRoot.Position + Vector3.new(0, LOCKON_LOOK_HEIGHT, 0)
	local rawMidpoint = (a+b)*.5

	-- Anchor com deadzone: pequenas vibrações do personagem não movem a câmera.
	local anchorAlpha = 1 - math.exp(-modeAnchorSmooth * math.clamp(dt,1/240,1/20))
	if not StableAnchor then StableAnchor = rawMidpoint end
	local anchorDelta = rawMidpoint - StableAnchor
	if anchorDelta.Magnitude > LOCKON_JITTER_DEADZONE then
		StableAnchor = StableAnchor:Lerp(rawMidpoint, anchorAlpha)
	end
	local midpoint = StableAnchor

	-- Lado estabilizado; apenas pequenas correções são permitidas.
	if not StableSide then StableSide = InitializeCameraSide(localRoot,AimTargetRoot,midpoint) end
	local desiredSide = StableSide
	if LastCameraSide then
		desiredSide = LastCameraSide:Lerp(StableSide,1-math.exp(-LOCKON_SIDE_SMOOTH*math.clamp(dt,1/240,1/20)))
	end
	if desiredSide.Magnitude > .01 then LastCameraSide = desiredSide.Unit end

	local modeMin, modeMax = LOCKON_MIN_DISTANCE, LOCKON_MAX_DISTANCE
	if CameraMode == "CLOSE" then modeMin, modeMax = 8.5, 25 end
	if CameraMode == "FAR" then modeMin, modeMax = 12, 38 end
	local required = CalculateRequiredDistance(localRoot,AimTargetRoot,Camera,modeExtra)
	required = math.clamp(required,modeMin,math.min(modeMax,LOCKON_MAX_DISTANCE))

	-- Usa pontos próximos à cabeça/peito e projeta matematicamente no
	-- espaço da câmera candidata. Isso evita depender apenas do frame atual.
	local localFramePoint = localRoot.Position + Vector3.new(0,2.25,0)
	local targetFramePoint = AimTargetRoot.Position + Vector3.new(0,2.25,0)
	local solveSide = (LastCameraSide or StableSide or Vector3.new(1,0,0)).Unit
	local solvedDistance, solvedPosition, solvedCFrame = SolveDuelFraming(
		Camera, midpoint, solveSide, modeHeight, required,
		localFramePoint, targetFramePoint, modeMax
	)
	required = solvedDistance

	local distanceAlpha
	if required > LastCameraDistance then
		distanceAlpha = 1-math.exp(-LOCKON_DISTANCE_OUT_SMOOTH*math.clamp(dt,1/240,1/20))
	else
		distanceAlpha = 1-math.exp(-LOCKON_DISTANCE_IN_SMOOTH*math.clamp(dt,1/240,1/20))
	end
	LastCameraDistance += (required-LastCameraDistance)*distanceAlpha
	LastCameraDistance = math.clamp(LastCameraDistance,modeMin,modeMax)

	-- Altura dinâmica, mas com limite rígido para nunca despencar.
	local separation = (AimTargetRoot.Position-localRoot.Position).Magnitude
	local adaptiveHeight = math.clamp(modeHeight + math.clamp(separation-10,0,14)*.07,LOCKON_MIN_HEIGHT,LOCKON_MAX_HEIGHT)
	if CameraMode == "CLOSE" then adaptiveHeight = math.max(LOCKON_MIN_HEIGHT,adaptiveHeight-.35) end
	if CameraMode == "FAR" then adaptiveHeight = math.min(LOCKON_MAX_HEIGHT,adaptiveHeight+.35) end

	-- Recalcula a posição usando a distância já suavizada, mantendo o solver
	-- de enquadramento como referência. Se a distância suavizada ainda não for
	-- suficiente, a correção de segurança vence imediatamente.
	local frameDistance = math.max(LastCameraDistance, solvedDistance)
	local desiredPosition = midpoint + (LastCameraSide or StableSide) * frameDistance + Vector3.new(0,adaptiveHeight,0)
	desiredPosition = GetSafeCameraPosition(desiredPosition,midpoint)

	-- STABLE usa uma deadzone um pouco maior; SMOOTH deixa a câmera mais livre.
	local jitterThreshold = CameraMode == "STABLE" and .075 or (CameraMode == "SMOOTH" and .035 or .055)
	if LastCameraPosition and (desiredPosition-LastCameraPosition).Magnitude < jitterThreshold then
		desiredPosition = LastCameraPosition
	end

	local posAlpha = 1-math.exp(-modeSmooth*math.clamp(dt,1/240,1/20))
	if not LastCameraPosition then LastCameraPosition=desiredPosition
	else LastCameraPosition=LastCameraPosition:Lerp(desiredPosition,posAlpha) end

	-- Olhar para cima do midpoint: nunca mira no chão.
	local lookTarget = midpoint + Vector3.new(0,0.25,0)
	if not StableLookPoint then StableLookPoint=lookTarget end
	local lookDelta=lookTarget-StableLookPoint
	if math.abs(lookDelta.Y) > LOCKON_VERTICAL_DEADZONE or lookDelta.Magnitude > LOCKON_JITTER_DEADZONE then
		StableLookPoint=StableLookPoint:Lerp(lookTarget,anchorAlpha)
	end
	StableLookPoint=Vector3.new(StableLookPoint.X,math.max(StableLookPoint.Y,midpoint.Y-0.15),StableLookPoint.Z)

	local desiredCFrame=CFrame.lookAt(LastCameraPosition,StableLookPoint)
	Camera.CFrame=desiredCFrame
	CameraWasLocked=true

	FaceLocalCharacterToTarget(dt)
end

local function UpdateAimLock(dt)
	if not AimLockEnabled then return end
	if not IsCurrentTargetValid() then DisableLockOn(); return end
	UpdateDuelCamera(dt)
end

local function EnableLockOn()
	ClearLockOn()
	local acquired=AcquireLockOn()
	AimLockEnabled=acquired
	if acquired then RefreshSelfMarker() end
	return acquired
end

DisableLockOn=function()
	AimLockEnabled=false
	ClearLockOn()
	RemoveSelfMarker()
end

pcall(function() RunService:UnbindFromRenderStep('NexusAimLock') end)
RunService:BindToRenderStep('NexusAimLock',LOCKON_CAMERA_PRIORITY,function(dt)
	UpdateAimLock(dt)
end)

Player.CharacterAdded:Connect(function(character)
	task.defer(function()
		if AimLockEnabled then CreateSelfMarker(character) end
	end)
end)

--==================================================
__V212Stage("FLY")

--==================================================
-- FLY
--==================================================


--==================================================

local FlyVelocity = nil
local FlyGyro = nil
local FlyConnection = nil

local function StopFly()
	if FlyConnection then
		FlyConnection:Disconnect()
		FlyConnection = nil
	end
	if FlyVelocity then
		FlyVelocity:Destroy()
		FlyVelocity = nil
	end
	if FlyGyro then
		FlyGyro:Destroy()
		FlyGyro = nil
	end

	local humanoid = GetHumanoid()
	if humanoid then
		humanoid.PlatformStand = false
		humanoid.AutoRotate = true
		humanoid:ChangeState(Enum.HumanoidStateType.GettingUp)
	end
end

local function StartFly()
	StopFly()

	local character = Player.Character
	local humanoid = GetHumanoid()
	local root = character and character:FindFirstChild("HumanoidRootPart")
	if not humanoid or not root then return false end

	FlyVelocity = Instance.new("BodyVelocity")
	FlyVelocity.Name = "NexusFlyVelocity"
	FlyVelocity.MaxForce = Vector3.new(1e6, 1e6, 1e6)
	FlyVelocity.P = 15000
	FlyVelocity.Velocity = Vector3.zero
	FlyVelocity.Parent = root

	FlyGyro = Instance.new("BodyGyro")
	FlyGyro.Name = "NexusFlyGyro"
	FlyGyro.MaxTorque = Vector3.new(1e6, 1e6, 1e6)
	FlyGyro.P = 15000
	FlyGyro.D = 500
	FlyGyro.CFrame = root.CFrame
	FlyGyro.Parent = root

	humanoid.PlatformStand = true
	humanoid.AutoRotate = false

	FlyConnection = RunService.RenderStepped:Connect(function()
		if not FlyEnabled or not root.Parent or not FlyVelocity or not FlyGyro then
			return
		end

		Camera = Workspace.CurrentCamera or Camera
		if not Camera then return end

		local move = humanoid.MoveDirection
		local look = Camera.CFrame.LookVector
		local horizontal = Vector3.new(move.X, 0, move.Z)
		local vertical = look.Y
		local velocity = horizontal * FlySpeed + Vector3.new(0, vertical * FlySpeed, 0)

		-- Evita subir/descer quando o jogador está parado e olhando reto.
		if velocity.Magnitude < 0.05 then
			velocity = Vector3.zero
		end

		FlyVelocity.Velocity = velocity
		FlyGyro.CFrame = CFrame.lookAt(root.Position, root.Position + Camera.CFrame.LookVector)
	end)

	return true
end

Player.CharacterAdded:Connect(function()
	StopFly()
	if FlyEnabled then
		task.wait(0.5)
		if not StartFly() then
			FlyEnabled = false
		end
	end
end)

__V212Stage("GUI BASE")

--==================================================
-- GUI BASE
--==================================================

local Gui = Instance.new("ScreenGui")
Gui.Name = "NexusFPSBoosterV9"
Gui.ResetOnSpawn = false
Gui.IgnoreGuiInset = true
Gui.Parent = Player:WaitForChild("PlayerGui")

local Main = Instance.new("Frame")
Main.Name = "Main"
Main.Size = UDim2.fromOffset(500, 460)
Main.Position = UDim2.new(0.5, -250, 0.5, -230)
Main.BackgroundColor3 = Color3.fromRGB(15, 8, 22)
Main.BackgroundTransparency = 0.25
Main.BorderSizePixel = 0
Main.ClipsDescendants = true
Main.Parent = Gui

local MainCorner = Instance.new("UICorner")
MainCorner.CornerRadius = UDim.new(0, 16)
MainCorner.Parent = Main

local MainStroke = Instance.new("UIStroke")
MainStroke.Color = PURPLE
MainStroke.Thickness = 2
MainStroke.Transparency = 0.1
MainStroke.Parent = Main


__V212Stage("AIM LOCK FLOATING BUTTON")

--==================================================
-- AIM LOCK FLOATING BUTTON
--==================================================

local AimLockButton = Instance.new("TextButton")
AimLockButton.Name = "AimLockButton"
AimLockButton.Size = UDim2.fromOffset(58, 58)
AimLockButton.Position = UDim2.new(1, -82, 0.5, -29)
AimLockButton.BackgroundColor3 = AimLockEnabled and Color3.fromRGB(45, 15, 65) or Color3.fromRGB(20, 15, 25)
AimLockButton.BackgroundTransparency = 0.12
AimLockButton.BorderSizePixel = 0
AimLockButton.Text = "🎯"
AimLockButton.TextSize = 25
AimLockButton.AutoButtonColor = false
AimLockButton.ZIndex = 50
AimLockButton.Parent = Gui

local AimLockCorner = Instance.new("UICorner")
AimLockCorner.CornerRadius = UDim.new(1, 0)
AimLockCorner.Parent = AimLockButton

local AimLockStroke = Instance.new("UIStroke")
AimLockStroke.Color = PURPLE
AimLockStroke.Thickness = 2
AimLockStroke.Transparency = AimLockEnabled and 0 or 0.25
AimLockStroke.Parent = AimLockButton

local AimLockStateLabel = Instance.new("TextLabel")
AimLockStateLabel.Size = UDim2.new(1, 0, 0, 15)
AimLockStateLabel.Position = UDim2.new(0, 0, 1, -16)
AimLockStateLabel.BackgroundTransparency = 1
AimLockStateLabel.Text = AimLockEnabled and "ON" or "OFF"
AimLockStateLabel.TextColor3 = AimLockEnabled and GREEN or RED
AimLockStateLabel.TextSize = 8
AimLockStateLabel.Font = Enum.Font.GothamBold
AimLockStateLabel.ZIndex = 51
AimLockStateLabel.Parent = AimLockButton

local function RefreshAimLockButton()
	AimLockButton.BackgroundColor3 = AimLockEnabled
		and Color3.fromRGB(45, 15, 65)
		or Color3.fromRGB(20, 15, 25)
	AimLockStroke.Transparency = AimLockEnabled and 0 or 0.25
	AimLockStateLabel.Text = AimLockEnabled and "ON" or "OFF"
	AimLockStateLabel.TextColor3 = AimLockEnabled and GREEN or RED
end

AimLockButton.Activated:Connect(function()
	if AimLockEnabled then
		DisableLockOn()
	else
		EnableLockOn()
	end
	RefreshAimLockButton()
	PersistConfig()
end)


__V212Stage("FLY FLOATING BUTTON")

--==================================================
-- FLY FLOATING BUTTON
--==================================================

local FlyButton = Instance.new("TextButton")
FlyButton.Name = "FlyButton"
FlyButton.Size = UDim2.fromOffset(58, 58)
FlyButton.Position = UDim2.new(1, -72, 1, -72)
FlyButton.BackgroundColor3 = FlyEnabled and Color3.fromRGB(45, 15, 65) or Color3.fromRGB(20, 15, 25)
FlyButton.BackgroundTransparency = 0.12
FlyButton.BorderSizePixel = 0
FlyButton.Text = "✈"
FlyButton.TextSize = 25
FlyButton.AutoButtonColor = false
FlyButton.ZIndex = 50
FlyButton.Parent = Gui

local FlyCorner = Instance.new("UICorner")
FlyCorner.CornerRadius = UDim.new(1, 0)
FlyCorner.Parent = FlyButton

local FlyStroke = Instance.new("UIStroke")
FlyStroke.Color = PURPLE
FlyStroke.Thickness = 2
FlyStroke.Transparency = FlyEnabled and 0 or 0.25
FlyStroke.Parent = FlyButton

local FlyStateLabel = Instance.new("TextLabel")
FlyStateLabel.Size = UDim2.new(1, 0, 0, 15)
FlyStateLabel.Position = UDim2.new(0, 0, 1, -16)
FlyStateLabel.BackgroundTransparency = 1
FlyStateLabel.Text = FlyEnabled and "ON" or "OFF"
FlyStateLabel.TextColor3 = FlyEnabled and GREEN or RED
FlyStateLabel.TextSize = 8
FlyStateLabel.Font = Enum.Font.GothamBold
FlyStateLabel.ZIndex = 51
FlyStateLabel.Parent = FlyButton

local function RefreshFlyButton()
	FlyButton.BackgroundColor3 = FlyEnabled and Color3.fromRGB(45, 15, 65) or Color3.fromRGB(20, 15, 25)
	FlyStroke.Transparency = FlyEnabled and 0 or 0.25
	FlyStateLabel.Text = FlyEnabled and "ON" or "OFF"
	FlyStateLabel.TextColor3 = FlyEnabled and GREEN or RED
end

FlyButton.MouseButton1Click:Connect(function()
	FlyEnabled = false -- V21.3 executor diagnostic: locked OFF
	if FlyEnabled then
		if not StartFly() then FlyEnabled = false end
	else
		StopFly()
	end
	RefreshFlyButton()
	PersistConfig()
end)

__V212Stage("TOP BAR + MINIMIZE")

--==================================================
-- TOP BAR + MINIMIZE
--==================================================

local Top = Instance.new("Frame")
Top.Size = UDim2.new(1, 0, 0, 50)
Top.BackgroundTransparency = 1
Top.Parent = Main

local Title = Instance.new("TextLabel")
Title.Size = UDim2.new(1, -80, 1, 0)
Title.Position = UDim2.fromOffset(15, 0)
Title.BackgroundTransparency = 1
Title.Text = "N E X U S  //  FPS BOOSTER"
Title.TextColor3 = WHITE
Title.TextSize = 17
Title.Font = Enum.Font.GothamBold
Title.TextXAlignment = Enum.TextXAlignment.Left
Title.Parent = Top

local MinimizeButton = Instance.new("TextButton")
MinimizeButton.Size = UDim2.fromOffset(34, 34)
MinimizeButton.Position = UDim2.new(1, -44, 0, 8)
MinimizeButton.BackgroundColor3 = PANEL2
MinimizeButton.Text = "—"
MinimizeButton.TextColor3 = WHITE
MinimizeButton.TextSize = 16
MinimizeButton.Font = Enum.Font.GothamBold
MinimizeButton.AutoButtonColor = false
MinimizeButton.Parent = Top

local MinimizeCorner = Instance.new("UICorner")
MinimizeCorner.CornerRadius = UDim.new(0, 8)
MinimizeCorner.Parent = MinimizeButton

__V212Stage("TABS")

--==================================================
-- TABS
--==================================================

local BoostTab = Instance.new("TextButton")
BoostTab.Size = UDim2.fromOffset(150, 32)
BoostTab.Position = UDim2.fromOffset(15, 55)
BoostTab.BackgroundColor3 = PURPLE
BoostTab.Text = "BOOST"
BoostTab.TextColor3 = WHITE
BoostTab.Font = Enum.Font.GothamBold
BoostTab.TextSize = 12
BoostTab.AutoButtonColor = false
BoostTab.Parent = Main

local BoostTabCorner = Instance.new("UICorner")
BoostTabCorner.CornerRadius = UDim.new(0, 8)
BoostTabCorner.Parent = BoostTab

local InfoTab = Instance.new("TextButton")
InfoTab.Size = UDim2.fromOffset(150, 32)
InfoTab.Position = UDim2.fromOffset(175, 55)
InfoTab.BackgroundColor3 = PANEL2
InfoTab.Text = "INFO"
InfoTab.TextColor3 = WHITE
InfoTab.Font = Enum.Font.GothamBold
InfoTab.TextSize = 12
InfoTab.AutoButtonColor = false
InfoTab.Parent = Main

local InfoTabCorner = Instance.new("UICorner")
InfoTabCorner.CornerRadius = UDim.new(0, 8)
InfoTabCorner.Parent = InfoTab

local PlayerTab = Instance.new("TextButton")
PlayerTab.Size = UDim2.fromOffset(150, 32)
PlayerTab.Position = UDim2.fromOffset(335, 55)
PlayerTab.BackgroundColor3 = PANEL2
PlayerTab.Text = "PLAYER"
PlayerTab.TextColor3 = WHITE
PlayerTab.Font = Enum.Font.GothamBold
PlayerTab.TextSize = 12
PlayerTab.AutoButtonColor = false
PlayerTab.Parent = Main

local PlayerTabCorner = Instance.new("UICorner")
PlayerTabCorner.CornerRadius = UDim.new(0, 8)
PlayerTabCorner.Parent = PlayerTab

__V212Stage("BOOST PAGE")

--==================================================
-- BOOST PAGE
--==================================================

local BoostPage = Instance.new("Frame")
BoostPage.Size = UDim2.new(1, -30, 1, -100)
BoostPage.Position = UDim2.fromOffset(15, 98)
BoostPage.BackgroundTransparency = 1
BoostPage.Parent = Main

local Status = Instance.new("TextLabel")
Status.Size = UDim2.new(0.6, 0, 0, 26)
Status.BackgroundTransparency = 1
Status.Text = "●  BOOST DISABLED"
Status.TextColor3 = RED
Status.TextSize = 14
Status.Font = Enum.Font.GothamBold
Status.TextXAlignment = Enum.TextXAlignment.Left
Status.Parent = BoostPage

local Toggle = Instance.new("TextButton")
Toggle.Size = UDim2.fromOffset(110, 44)
Toggle.Position = UDim2.new(1, -110, 0, 0)
Toggle.BackgroundColor3 = PANEL2
Toggle.Text = "OFF"
Toggle.TextColor3 = RED
Toggle.TextSize = 15
Toggle.Font = Enum.Font.GothamBold
Toggle.AutoButtonColor = false
Toggle.Parent = BoostPage

local ToggleCorner = Instance.new("UICorner")
ToggleCorner.CornerRadius = UDim.new(0, 8)
ToggleCorner.Parent = Toggle

local ToggleStroke = Instance.new("UIStroke")
ToggleStroke.Color = PURPLE
ToggleStroke.Thickness = 1.5
ToggleStroke.Parent = Toggle

local ModeTitle = Instance.new("TextLabel")
ModeTitle.Size = UDim2.new(1, 0, 0, 20)
ModeTitle.Position = UDim2.fromOffset(0, 55)
ModeTitle.BackgroundTransparency = 1
ModeTitle.Text = "OPTIMIZATION MODE"
ModeTitle.TextColor3 = PURPLE
ModeTitle.TextSize = 11
ModeTitle.Font = Enum.Font.GothamBold
ModeTitle.TextXAlignment = Enum.TextXAlignment.Left
ModeTitle.Parent = BoostPage

local ModeContainer = Instance.new("Frame")
ModeContainer.Size = UDim2.new(1, 0, 0, 40)
ModeContainer.Position = UDim2.fromOffset(0, 78)
ModeContainer.BackgroundTransparency = 1
ModeContainer.Parent = BoostPage

local ModeNames = {"LOW", "MEDIUM", "HIGH", "ULTRA", "BATATA"}
local ModeButtons = {}

for i, ModeName in ipairs(ModeNames) do
	local Button = Instance.new("TextButton")
	Button.Size = UDim2.new(0.19, 0, 1, 0)
	Button.Position = UDim2.new((i - 1) * 0.205, 0, 0, 0)
	Button.BackgroundColor3 = ModeName == CurrentMode and PURPLE or PANEL2
	Button.Text = ModeName
	Button.TextColor3 = WHITE
	Button.TextSize = 9
	Button.Font = Enum.Font.GothamBold
	Button.AutoButtonColor = false
	Button.Parent = ModeContainer

	local Corner = Instance.new("UICorner")
	Corner.CornerRadius = UDim.new(0, 7)
	Corner.Parent = Button

	local Stroke = Instance.new("UIStroke")
	Stroke.Color = PURPLE
	Stroke.Thickness = 1
	Stroke.Transparency = ModeName == CurrentMode and 0 or 0.5
	Stroke.Parent = Button

	ModeButtons[ModeName] = Button
end

local CurrentModeLabel = Instance.new("TextLabel")
CurrentModeLabel.Size = UDim2.new(1, 0, 0, 20)
CurrentModeLabel.Position = UDim2.fromOffset(0, 122)
CurrentModeLabel.BackgroundTransparency = 1
CurrentModeLabel.Text = "MODE: " .. CurrentMode
CurrentModeLabel.TextColor3 = WHITE
CurrentModeLabel.TextSize = 12
CurrentModeLabel.Font = Enum.Font.GothamMedium
CurrentModeLabel.TextXAlignment = Enum.TextXAlignment.Left
CurrentModeLabel.Parent = BoostPage

__V212Stage("EXTRAS: ANTI-LAG / SONS / SÓ ESSENCIAL")

--==================================================
-- EXTRAS: ANTI-LAG / SONS / SÓ ESSENCIAL
--==================================================

local ExtrasTitle = Instance.new("TextLabel")
ExtrasTitle.Size = UDim2.new(1, 0, 0, 18)
ExtrasTitle.Position = UDim2.fromOffset(0, 150)
ExtrasTitle.BackgroundTransparency = 1
ExtrasTitle.Text = "EXTRAS"
ExtrasTitle.TextColor3 = PURPLE
ExtrasTitle.TextSize = 11
ExtrasTitle.Font = Enum.Font.GothamBold
ExtrasTitle.TextXAlignment = Enum.TextXAlignment.Left
ExtrasTitle.Parent = BoostPage

local function CreateExtraToggle(name, posY, initialState)
	local Btn = Instance.new("TextButton")
	Btn.Size = UDim2.new(1, 0, 0, 32)
	Btn.Position = UDim2.fromOffset(0, posY)
	Btn.BackgroundColor3 = initialState and Color3.fromRGB(15, 45, 30) or PANEL2
	Btn.Text = ""
	Btn.AutoButtonColor = false
	Btn.Parent = BoostPage

	local Corner = Instance.new("UICorner")
	Corner.CornerRadius = UDim.new(0, 7)
	Corner.Parent = Btn

	local Stroke = Instance.new("UIStroke")
	Stroke.Color = PURPLE
	Stroke.Thickness = 1
	Stroke.Parent = Btn

	local Label = Instance.new("TextLabel")
	Label.Size = UDim2.new(1, -70, 1, 0)
	Label.Position = UDim2.fromOffset(12, 0)
	Label.BackgroundTransparency = 1
	Label.Text = name
	Label.TextColor3 = WHITE
	Label.TextSize = 12
	Label.Font = Enum.Font.GothamMedium
	Label.TextXAlignment = Enum.TextXAlignment.Left
	Label.Parent = Btn

	local StateLabel = Instance.new("TextLabel")
	StateLabel.Size = UDim2.fromOffset(50, 32)
	StateLabel.Position = UDim2.new(1, -60, 0, 0)
	StateLabel.BackgroundTransparency = 1
	StateLabel.Text = initialState and "ON" or "OFF"
	StateLabel.TextColor3 = initialState and GREEN or RED
	StateLabel.TextSize = 12
	StateLabel.Font = Enum.Font.GothamBold
	StateLabel.TextXAlignment = Enum.TextXAlignment.Right
	StateLabel.Parent = Btn

	return Btn, StateLabel
end

local AntiLagBtn, AntiLagState = CreateExtraToggle("ANTI-LAG", 172, AntiLagEnabled)
local SoundsBtn, SoundsState = CreateExtraToggle("DESLIGAR SONS", 208, SoundsOff)
local EssentialBtn, EssentialState = CreateExtraToggle("SÓ O ESSENCIAL (HUD)", 244, EssentialOnly)

local Restore = Instance.new("TextButton")
Restore.Size = UDim2.new(0.485, 0, 0, 34)
Restore.Position = UDim2.fromOffset(0, 286)
Restore.BackgroundColor3 = PANEL2
Restore.Text = "↻  RESTORE"
Restore.TextColor3 = WHITE
Restore.TextSize = 11
Restore.Font = Enum.Font.GothamBold
Restore.AutoButtonColor = false
Restore.Parent = BoostPage

local RestoreCorner = Instance.new("UICorner")
RestoreCorner.CornerRadius = UDim.new(0, 7)
RestoreCorner.Parent = Restore

local RestoreStroke = Instance.new("UIStroke")
RestoreStroke.Color = PURPLE
RestoreStroke.Thickness = 1
RestoreStroke.Parent = Restore

local CleanButton = Instance.new("TextButton")
CleanButton.Size = UDim2.new(0.485, 0, 0, 34)
CleanButton.Position = UDim2.new(0.515, 0, 0, 286)
CleanButton.BackgroundColor3 = PANEL2
CleanButton.Text = "🧹  LIMPAR RAM"
CleanButton.TextColor3 = WHITE
CleanButton.TextSize = 11
CleanButton.Font = Enum.Font.GothamBold
CleanButton.AutoButtonColor = false
CleanButton.Parent = BoostPage

local CleanButtonCorner = Instance.new("UICorner")
CleanButtonCorner.CornerRadius = UDim.new(0, 7)
CleanButtonCorner.Parent = CleanButton

local CleanButtonStroke = Instance.new("UIStroke")
CleanButtonStroke.Color = PURPLE
CleanButtonStroke.Thickness = 1
CleanButtonStroke.Parent = CleanButton

local CleanResultLabel = Instance.new("TextLabel")
CleanResultLabel.Size = UDim2.new(1, 0, 0, 20)
CleanResultLabel.Position = UDim2.fromOffset(0, 326)
CleanResultLabel.BackgroundTransparency = 1
CleanResultLabel.Text = ""
CleanResultLabel.TextColor3 = YELLOW
CleanResultLabel.TextSize = 11
CleanResultLabel.Font = Enum.Font.GothamMedium
CleanResultLabel.TextXAlignment = Enum.TextXAlignment.Left
CleanResultLabel.Parent = BoostPage

__V212Stage("PLAYER PAGE")

--==================================================
-- PLAYER PAGE
--==================================================

local PlayerPage = Instance.new("Frame")
PlayerPage.Size = BoostPage.Size
PlayerPage.Position = BoostPage.Position
PlayerPage.BackgroundTransparency = 1
PlayerPage.Visible = false
PlayerPage.Parent = Main

local PlayerTitle = Instance.new("TextLabel")
PlayerTitle.Size = UDim2.new(1, 0, 0, 26)
PlayerTitle.BackgroundTransparency = 1
PlayerTitle.Text = "N E X U S  //  PLAYER"
PlayerTitle.TextColor3 = WHITE
PlayerTitle.TextSize = 15
PlayerTitle.Font = Enum.Font.GothamBold
PlayerTitle.TextXAlignment = Enum.TextXAlignment.Left
PlayerTitle.Parent = PlayerPage

local SpeedStatus = Instance.new("TextLabel")
SpeedStatus.Size = UDim2.new(1, 0, 0, 24)
SpeedStatus.Position = UDim2.fromOffset(0, 34)
SpeedStatus.BackgroundTransparency = 1
SpeedStatus.Text = SpeedEnabled and "●  SPEED ACTIVE" or "●  SPEED DISABLED"
SpeedStatus.TextColor3 = SpeedEnabled and GREEN or RED
SpeedStatus.TextSize = 13
SpeedStatus.Font = Enum.Font.GothamBold
SpeedStatus.TextXAlignment = Enum.TextXAlignment.Left
SpeedStatus.Parent = PlayerPage

local SpeedToggle = Instance.new("TextButton")
SpeedToggle.Size = UDim2.fromOffset(110, 42)
SpeedToggle.Position = UDim2.new(1, -110, 0, 28)
SpeedToggle.BackgroundColor3 = SpeedEnabled and Color3.fromRGB(15, 45, 30) or PANEL2
SpeedToggle.Text = SpeedEnabled and "ON" or "OFF"
SpeedToggle.TextColor3 = SpeedEnabled and GREEN or RED
SpeedToggle.TextSize = 14
SpeedToggle.Font = Enum.Font.GothamBold
SpeedToggle.AutoButtonColor = false
SpeedToggle.Parent = PlayerPage

local SpeedToggleCorner = Instance.new("UICorner")
SpeedToggleCorner.CornerRadius = UDim.new(0, 8)
SpeedToggleCorner.Parent = SpeedToggle

local SpeedToggleStroke = Instance.new("UIStroke")
SpeedToggleStroke.Color = PURPLE
SpeedToggleStroke.Thickness = 1.5
SpeedToggleStroke.Parent = SpeedToggle

local SpeedLabel = Instance.new("TextLabel")
SpeedLabel.Size = UDim2.new(1, 0, 0, 24)
SpeedLabel.Position = UDim2.fromOffset(0, 92)
SpeedLabel.BackgroundTransparency = 1
SpeedLabel.Text = "SPEED"
SpeedLabel.TextColor3 = PURPLE
SpeedLabel.TextSize = 11
SpeedLabel.Font = Enum.Font.GothamBold
SpeedLabel.TextXAlignment = Enum.TextXAlignment.Left
SpeedLabel.Parent = PlayerPage

local SpeedValueLabel = Instance.new("TextLabel")
SpeedValueLabel.Size = UDim2.new(1, 0, 0, 30)
SpeedValueLabel.Position = UDim2.fromOffset(0, 118)
SpeedValueLabel.BackgroundTransparency = 1
SpeedValueLabel.Text = "SPEED: " .. tostring(SpeedValue)
SpeedValueLabel.TextColor3 = WHITE
SpeedValueLabel.TextSize = 16
SpeedValueLabel.Font = Enum.Font.GothamBold
SpeedValueLabel.TextXAlignment = Enum.TextXAlignment.Center
SpeedValueLabel.Parent = PlayerPage

local SliderBack = Instance.new("Frame")
SliderBack.Size = UDim2.new(1, -20, 0, 12)
SliderBack.Position = UDim2.fromOffset(10, 160)
SliderBack.BackgroundColor3 = PANEL2
SliderBack.BorderSizePixel = 0
SliderBack.Parent = PlayerPage

local SliderBackCorner = Instance.new("UICorner")
SliderBackCorner.CornerRadius = UDim.new(1, 0)
SliderBackCorner.Parent = SliderBack

local SliderFill = Instance.new("Frame")
SliderFill.Size = UDim2.new((SpeedValue - 20) / 380, 0, 1, 0)
SliderFill.BackgroundColor3 = PURPLE
SliderFill.BorderSizePixel = 0
SliderFill.Parent = SliderBack

local SliderFillCorner = Instance.new("UICorner")
SliderFillCorner.CornerRadius = UDim.new(1, 0)
SliderFillCorner.Parent = SliderFill

local SliderKnob = Instance.new("TextButton")
SliderKnob.Size = UDim2.fromOffset(22, 22)
SliderKnob.AnchorPoint = Vector2.new(0.5, 0.5)
SliderKnob.Position = UDim2.new((SpeedValue - 20) / 380, 0, 0.5, 0)
SliderKnob.BackgroundColor3 = PURPLE
SliderKnob.Text = ""
SliderKnob.AutoButtonColor = false
SliderKnob.Parent = SliderBack

local SliderKnobCorner = Instance.new("UICorner")
SliderKnobCorner.CornerRadius = UDim.new(1, 0)
SliderKnobCorner.Parent = SliderKnob

local SliderStroke = Instance.new("UIStroke")
SliderStroke.Color = WHITE
SliderStroke.Thickness = 1
SliderStroke.Parent = SliderKnob

local SliderMin = Instance.new("TextLabel")
SliderMin.Size = UDim2.fromOffset(50, 20)
SliderMin.Position = UDim2.fromOffset(0, 180)
SliderMin.BackgroundTransparency = 1
SliderMin.Text = "20"
SliderMin.TextColor3 = WHITE
SliderMin.TextSize = 10
SliderMin.Font = Enum.Font.GothamMedium
SliderMin.TextXAlignment = Enum.TextXAlignment.Left
SliderMin.Parent = PlayerPage

local SliderMax = Instance.new("TextLabel")
SliderMax.Size = UDim2.fromOffset(50, 20)
SliderMax.Position = UDim2.new(1, -50, 0, 180)
SliderMax.BackgroundTransparency = 1
SliderMax.Text = "400"
SliderMax.TextColor3 = WHITE
SliderMax.TextSize = 10
SliderMax.Font = Enum.Font.GothamMedium
SliderMax.TextXAlignment = Enum.TextXAlignment.Right
SliderMax.Parent = PlayerPage

local SpeedHint = Instance.new("TextLabel")
SpeedHint.Size = UDim2.new(1, 0, 0, 40)
SpeedHint.Position = UDim2.fromOffset(0, 215)
SpeedHint.BackgroundTransparency = 1
SpeedHint.Text = "Arraste o controle para escolher de 20 até 400."
SpeedHint.TextColor3 = Color3.fromRGB(180, 170, 190)
SpeedHint.TextSize = 11
SpeedHint.Font = Enum.Font.GothamMedium
SpeedHint.TextXAlignment = Enum.TextXAlignment.Center
SpeedHint.Parent = PlayerPage


local AimTitle = Instance.new("TextLabel")
AimTitle.Size = UDim2.new(1, 0, 0, 24)
AimTitle.Position = UDim2.fromOffset(0, 265)
AimTitle.BackgroundTransparency = 1
AimTitle.Text = "AIM LOCK"
AimTitle.TextColor3 = PURPLE
AimTitle.TextSize = 11
AimTitle.Font = Enum.Font.GothamBold
AimTitle.TextXAlignment = Enum.TextXAlignment.Left
AimTitle.Parent = PlayerPage

local AimToggle = Instance.new("TextButton")
AimToggle.Size = UDim2.fromOffset(110, 38)
AimToggle.Position = UDim2.new(1, -110, 0, 258)
AimToggle.BackgroundColor3 = AimLockEnabled and Color3.fromRGB(15, 45, 30) or PANEL2
AimToggle.Text = AimLockEnabled and "ON" or "OFF"
AimToggle.TextColor3 = AimLockEnabled and GREEN or RED
AimToggle.TextSize = 13
AimToggle.Font = Enum.Font.GothamBold
AimToggle.AutoButtonColor = false
AimToggle.Parent = PlayerPage

local AimToggleCorner = Instance.new("UICorner")
AimToggleCorner.CornerRadius = UDim.new(0, 8)
AimToggleCorner.Parent = AimToggle

local AimToggleStroke = Instance.new("UIStroke")
AimToggleStroke.Color = PURPLE
AimToggleStroke.Thickness = 1.5
AimToggleStroke.Parent = AimToggle

local AimHint = Instance.new("TextLabel")
AimHint.Size = UDim2.new(1, 0, 0, 18)
AimHint.Position = UDim2.fromOffset(0, 305)
AimHint.BackgroundTransparency = 1
AimHint.Text = "Botão flutuante fixo • mobile/PC"
AimHint.TextColor3 = Color3.fromRGB(180, 170, 190)
AimHint.TextSize = 9
AimHint.Font = Enum.Font.GothamMedium
AimHint.TextXAlignment = Enum.TextXAlignment.Center
AimHint.Parent = PlayerPage

local CameraModeButton = Instance.new("TextButton")
CameraModeButton.Name = "CameraModeButton"
CameraModeButton.Size = UDim2.fromOffset(190, 28)
CameraModeButton.Position = UDim2.new(0.5, -95, 0, 326)
CameraModeButton.BackgroundColor3 = PANEL2
CameraModeButton.Text = "CAM: " .. CameraMode
CameraModeButton.TextColor3 = WHITE
CameraModeButton.TextSize = 10
CameraModeButton.Font = Enum.Font.GothamBold
CameraModeButton.AutoButtonColor = false
CameraModeButton.Parent = PlayerPage

local CameraModeCorner = Instance.new("UICorner")
CameraModeCorner.CornerRadius = UDim.new(0, 7)
CameraModeCorner.Parent = CameraModeButton

local CameraModeStroke = Instance.new("UIStroke")
CameraModeStroke.Color = PURPLE
CameraModeStroke.Thickness = 1.25
CameraModeStroke.Parent = CameraModeButton

local CameraModeHint = Instance.new("TextLabel")
CameraModeHint.Size = UDim2.new(1, 0, 0, 14)
CameraModeHint.Position = UDim2.fromOffset(0, 354)
CameraModeHint.BackgroundTransparency = 1
CameraModeHint.Text = "DUEL • SMOOTH • STABLE • CLOSE • FAR"
CameraModeHint.TextColor3 = Color3.fromRGB(150, 140, 165)
CameraModeHint.TextSize = 7
CameraModeHint.Font = Enum.Font.GothamMedium
CameraModeHint.TextXAlignment = Enum.TextXAlignment.Center
CameraModeHint.Parent = PlayerPage

local function RefreshCameraModeControl()
	CameraModeButton.Text = "CAM: " .. CameraMode
end

CameraModeButton.Activated:Connect(function()
	CycleCameraMode()
	RefreshCameraModeControl()
end)

local function RefreshAimControls()
	AimToggle.Text = AimLockEnabled and "ON" or "OFF"
	AimToggle.TextColor3 = AimLockEnabled and GREEN or RED
	AimToggle.BackgroundColor3 = AimLockEnabled and Color3.fromRGB(15, 45, 30) or PANEL2
	RefreshAimLockButton()
end

AimToggle.Activated:Connect(function()
	if AimLockEnabled then
		DisableLockOn()
	else
		EnableLockOn()
	end
	RefreshAimControls()
	PersistConfig()
end)


local FlyTitle = Instance.new("TextLabel")
FlyTitle.Size = UDim2.new(1, 0, 0, 24)
FlyTitle.Position = UDim2.fromOffset(0, 355)
FlyTitle.BackgroundTransparency = 1
FlyTitle.Text = "FLY"
FlyTitle.TextColor3 = PURPLE
FlyTitle.TextSize = 11
FlyTitle.Font = Enum.Font.GothamBold
FlyTitle.TextXAlignment = Enum.TextXAlignment.Left
FlyTitle.Parent = PlayerPage

local FlyToggle = Instance.new("TextButton")
FlyToggle.Size = UDim2.fromOffset(110, 38)
FlyToggle.Position = UDim2.new(1, -110, 0, 348)
FlyToggle.BackgroundColor3 = FlyEnabled and Color3.fromRGB(15, 45, 30) or PANEL2
FlyToggle.Text = FlyEnabled and "ON" or "OFF"
FlyToggle.TextColor3 = FlyEnabled and GREEN or RED
FlyToggle.TextSize = 13
FlyToggle.Font = Enum.Font.GothamBold
FlyToggle.AutoButtonColor = false
FlyToggle.Parent = PlayerPage

local FlyToggleCorner = Instance.new("UICorner")
FlyToggleCorner.CornerRadius = UDim.new(0, 8)
FlyToggleCorner.Parent = FlyToggle

local FlyToggleStroke = Instance.new("UIStroke")
FlyToggleStroke.Color = PURPLE
FlyToggleStroke.Thickness = 1.5
FlyToggleStroke.Parent = FlyToggle

local FlyHint = Instance.new("TextLabel")
FlyHint.Size = UDim2.new(1, -8, 0, 35)
FlyHint.Position = UDim2.fromOffset(4, 393)
FlyHint.BackgroundTransparency = 1
FlyHint.Text = "Use o direcional + olhe para cima/baixo para voar"
FlyHint.TextColor3 = Color3.fromRGB(180, 170, 190)
FlyHint.TextSize = 9
FlyHint.Font = Enum.Font.GothamMedium
FlyHint.TextXAlignment = Enum.TextXAlignment.Center
FlyHint.Parent = PlayerPage

local function RefreshFlyControls()
	FlyToggle.Text = FlyEnabled and "ON" or "OFF"
	FlyToggle.TextColor3 = FlyEnabled and GREEN or RED
	FlyToggle.BackgroundColor3 = FlyEnabled and Color3.fromRGB(15, 45, 30) or PANEL2
	RefreshFlyButton()
end

FlyToggle.MouseButton1Click:Connect(function()
	FlyEnabled = false -- V21.3 executor diagnostic: locked OFF
	if FlyEnabled then
		if not StartFly() then FlyEnabled = false end
	else
		StopFly()
	end
	RefreshFlyControls()
	PersistConfig()
end)

__V212Stage("INFO PAGE")

--==================================================
-- INFO PAGE
--==================================================

local InfoPage = Instance.new("Frame")
InfoPage.Size = BoostPage.Size
InfoPage.Position = BoostPage.Position
InfoPage.BackgroundTransparency = 1
InfoPage.Visible = false
InfoPage.Parent = Main

local StatsText = Instance.new("TextLabel")
StatsText.Size = UDim2.new(1, 0, 0, 150)
StatsText.BackgroundTransparency = 1
StatsText.TextColor3 = WHITE
StatsText.TextSize = 13
StatsText.Font = Enum.Font.Code
StatsText.TextXAlignment = Enum.TextXAlignment.Left
StatsText.TextYAlignment = Enum.TextYAlignment.Top
StatsText.Text = "N E X U S  //  INFO"
StatsText.Parent = InfoPage

local GraphTitle = Instance.new("TextLabel")
GraphTitle.Size = UDim2.new(1, 0, 0, 18)
GraphTitle.Position = UDim2.fromOffset(0, 155)
GraphTitle.BackgroundTransparency = 1
GraphTitle.Text = "FPS (últimos 40s)"
GraphTitle.TextColor3 = PURPLE
GraphTitle.TextSize = 11
GraphTitle.Font = Enum.Font.GothamBold
GraphTitle.TextXAlignment = Enum.TextXAlignment.Left
GraphTitle.Parent = InfoPage

local GraphContainer = Instance.new("Frame")
GraphContainer.Size = UDim2.new(1, 0, 0, 110)
GraphContainer.Position = UDim2.fromOffset(0, 176)
GraphContainer.BackgroundColor3 = PANEL2
GraphContainer.BackgroundTransparency = 0.3
GraphContainer.Parent = InfoPage

local GraphCorner = Instance.new("UICorner")
GraphCorner.CornerRadius = UDim.new(0, 8)
GraphCorner.Parent = GraphContainer

local GraphStroke = Instance.new("UIStroke")
GraphStroke.Color = PURPLE
GraphStroke.Thickness = 1
GraphStroke.Transparency = 0.4
GraphStroke.Parent = GraphContainer

local GraphLayout = Instance.new("UIListLayout")
GraphLayout.FillDirection = Enum.FillDirection.Horizontal
GraphLayout.VerticalAlignment = Enum.VerticalAlignment.Bottom
GraphLayout.HorizontalAlignment = Enum.HorizontalAlignment.Left
GraphLayout.Padding = UDim.new(0, 2)
GraphLayout.Parent = GraphContainer

local MAX_BARS = 40
local FPSHistory = {}
local Bars = {}

for i = 1, MAX_BARS do
	local Bar = Instance.new("Frame")
	Bar.Size = UDim2.new(0, 9, 0, 2)
	Bar.BackgroundColor3 = PURPLE
	Bar.BorderSizePixel = 0
	Bar.LayoutOrder = i
	Bar.Parent = GraphContainer

	local BarCorner = Instance.new("UICorner")
	BarCorner.CornerRadius = UDim.new(0, 2)
	BarCorner.Parent = Bar

	Bars[i] = Bar
end

__V212Stage("TOGGLE / MODE / EXTRAS / RESTORE LOGIC")

--==================================================
-- TOGGLE / MODE / EXTRAS / RESTORE LOGIC
--==================================================

local function UpdateToggle()
	if BoosterEnabled then
		Toggle.Text = "ON"
		Toggle.TextColor3 = GREEN
		Status.Text = "●  BOOST ACTIVE"
		Status.TextColor3 = GREEN
		ApplyBoost()
	else
		Toggle.Text = "OFF"
		Toggle.TextColor3 = RED
		Status.Text = "●  BOOST DISABLED"
		Status.TextColor3 = RED
		RestoreGraphics()
	end
end

Toggle.MouseButton1Click:Connect(function()
	BoosterEnabled = not BoosterEnabled
	TweenService:Create(
		Toggle, TweenInfo.new(0.2, Enum.EasingStyle.Quad),
		{ BackgroundColor3 = BoosterEnabled and Color3.fromRGB(15, 45, 30) or PANEL2 }
	):Play()
	UpdateToggle()
end)

for ModeName, Button in pairs(ModeButtons) do
	Button.MouseButton1Click:Connect(function()
		CurrentMode = ModeName
		CurrentModeLabel.Text = "MODE: " .. ModeName
		PersistConfig()

		for Name, OtherButton in pairs(ModeButtons) do
			TweenService:Create(
				OtherButton, TweenInfo.new(0.2),
				{ BackgroundColor3 = Name == CurrentMode and PURPLE or PANEL2 }
			):Play()
		end

		if BoosterEnabled then ApplyBoost() end
	end)
end

Restore.MouseButton1Click:Connect(function()
	RestoreGraphics()
	Status.Text = "●  GRAPHICS RESTORED"
	Status.TextColor3 = YELLOW

	task.delay(2, function()
		if not BoosterEnabled then
			Status.Text = "●  BOOST DISABLED"
			Status.TextColor3 = RED
		end
	end)

	Toggle.Text = "OFF"
	Toggle.TextColor3 = RED
	Toggle.BackgroundColor3 = PANEL2
end)

CleanButton.MouseButton1Click:Connect(function()
	local freed = CleanRAM()
	CleanResultLabel.Text = string.format("Liberado: %.1f MB", freed / 1024)
	task.delay(3, function() CleanResultLabel.Text = "" end)
end)

AntiLagBtn.MouseButton1Click:Connect(function()
	AntiLagEnabled = not AntiLagEnabled
	ApplyAntiLag(AntiLagEnabled)
	AntiLagBtn.BackgroundColor3 = AntiLagEnabled and Color3.fromRGB(15, 45, 30) or PANEL2
	AntiLagState.Text = AntiLagEnabled and "ON" or "OFF"
	AntiLagState.TextColor3 = AntiLagEnabled and GREEN or RED
	PersistConfig()
end)

SoundsBtn.MouseButton1Click:Connect(function()
	SoundsOff = not SoundsOff
	ApplySoundsOff(SoundsOff)
	SoundsBtn.BackgroundColor3 = SoundsOff and Color3.fromRGB(15, 45, 30) or PANEL2
	SoundsState.Text = SoundsOff and "ON" or "OFF"
	SoundsState.TextColor3 = SoundsOff and GREEN or RED
	PersistConfig()
end)

EssentialBtn.MouseButton1Click:Connect(function()
	EssentialOnly = not EssentialOnly
	ApplyEssentialOnly(EssentialOnly)
	EssentialBtn.BackgroundColor3 = EssentialOnly and Color3.fromRGB(15, 45, 30) or PANEL2
	EssentialState.Text = EssentialOnly and "ON" or "OFF"
	EssentialState.TextColor3 = EssentialOnly and GREEN or RED
	PersistConfig()
end)

-- aplica configs salvas ao iniciar
if AntiLagEnabled then ApplyAntiLag(true) end
if SoundsOff then ApplySoundsOff(true) end
if EssentialOnly then ApplyEssentialOnly(true) end

__V212Stage("PLAYER SPEED LOGIC")

--==================================================
-- PLAYER SPEED LOGIC
--==================================================

local function SetSpeedValue(value)
	SpeedValue = math.clamp(math.floor(value + 0.5), 20, 400)
	local alpha = (SpeedValue - 20) / 380
	SpeedValueLabel.Text = "SPEED: " .. tostring(SpeedValue)
	SliderFill.Size = UDim2.new(alpha, 0, 1, 0)
	SliderKnob.Position = UDim2.new(alpha, 0, 0.5, 0)
	if SpeedEnabled then ApplySpeed() end
	PersistConfig()
end

local SliderDragging = false

local function UpdateSliderFromX(x)
	local left = SliderBack.AbsolutePosition.X
	local width = SliderBack.AbsoluteSize.X
	if width <= 0 then return end
	local alpha = math.clamp((x - left) / width, 0, 1)
	SetSpeedValue(20 + alpha * 380)
end

SliderBack.InputBegan:Connect(function(Input)
	if Input.UserInputType == Enum.UserInputType.MouseButton1
		or Input.UserInputType == Enum.UserInputType.Touch then
		SliderDragging = true
		UpdateSliderFromX(Input.Position.X)
	end
end)

SliderKnob.InputBegan:Connect(function(Input)
	if Input.UserInputType == Enum.UserInputType.MouseButton1
		or Input.UserInputType == Enum.UserInputType.Touch then
		SliderDragging = true
	end
end)

UserInputService.InputChanged:Connect(function(Input)
	if not SliderDragging then return end
	if Input.UserInputType == Enum.UserInputType.MouseMovement
		or Input.UserInputType == Enum.UserInputType.Touch then
		UpdateSliderFromX(Input.Position.X)
	end
end)

UserInputService.InputEnded:Connect(function(Input)
	if Input.UserInputType == Enum.UserInputType.MouseButton1
		or Input.UserInputType == Enum.UserInputType.Touch then
		SliderDragging = false
	end
end)

SpeedToggle.MouseButton1Click:Connect(function()
	SpeedEnabled = false -- V21.3 executor diagnostic: locked OFF
	SpeedToggle.Text = SpeedEnabled and "ON" or "OFF"
	SpeedToggle.TextColor3 = SpeedEnabled and GREEN or RED
	SpeedToggle.BackgroundColor3 = SpeedEnabled and Color3.fromRGB(15, 45, 30) or PANEL2
	SpeedStatus.Text = SpeedEnabled and "●  SPEED ACTIVE" or "●  SPEED DISABLED"
	SpeedStatus.TextColor3 = SpeedEnabled and GREEN or RED
	ApplySpeed()
	PersistConfig()
end)

if SpeedEnabled then
	task.defer(ApplySpeed)
end
RefreshAimControls()
RefreshFlyControls()

__V212Stage("TABS SWITCH")

--==================================================
-- TABS SWITCH
--==================================================

local function SelectTab(tab)
	BoostPage.Visible = tab == "BOOST"
	InfoPage.Visible = tab == "INFO"
	PlayerPage.Visible = tab == "PLAYER"

	BoostTab.BackgroundColor3 = tab == "BOOST" and PURPLE or PANEL2
	InfoTab.BackgroundColor3 = tab == "INFO" and PURPLE or PANEL2
	PlayerTab.BackgroundColor3 = tab == "PLAYER" and PURPLE or PANEL2
end

BoostTab.MouseButton1Click:Connect(function()
	SelectTab("BOOST")
end)

InfoTab.MouseButton1Click:Connect(function()
	SelectTab("INFO")
end)

PlayerTab.MouseButton1Click:Connect(function()
	SelectTab("PLAYER")
end)

__V212Stage("MINIMIZAR")

--==================================================
-- MINIMIZAR
--==================================================

local FullSize = Main.Size
local MiniSize = UDim2.fromOffset(500, 50)

MinimizeButton.MouseButton1Click:Connect(function()
	Minimized = not Minimized

	TweenService:Create(
		Main, TweenInfo.new(0.25, Enum.EasingStyle.Quad),
		{ Size = Minimized and MiniSize or FullSize }
	):Play()

	BoostTab.Visible = not Minimized
	InfoTab.Visible = not Minimized
	PlayerTab.Visible = not Minimized
	BoostPage.Visible = not Minimized and BoostPage.Visible
	InfoPage.Visible = not Minimized and InfoPage.Visible
	PlayerPage.Visible = not Minimized and PlayerPage.Visible

	MinimizeButton.Text = Minimized and "▢" or "—"
end)

__V212Stage("DRAGGING")

--==================================================
-- DRAGGING
--==================================================

local Dragging = false
local DragStart
local StartPosition

Top.InputBegan:Connect(function(Input)
	if Input.UserInputType == Enum.UserInputType.MouseButton1
		or Input.UserInputType == Enum.UserInputType.Touch then
		Dragging = true
		DragStart = Input.Position
		StartPosition = Main.Position

		Input.Changed:Connect(function()
			if Input.UserInputState == Enum.UserInputState.End then
				Dragging = false
			end
		end)
	end
end)

UserInputService.InputChanged:Connect(function(Input)
	if not Dragging then return end
	if Input.UserInputType ~= Enum.UserInputType.MouseMovement
		and Input.UserInputType ~= Enum.UserInputType.Touch then
		return
	end

	local Delta = Input.Position - DragStart
	Main.Position = UDim2.new(
		StartPosition.X.Scale, StartPosition.X.Offset + Delta.X,
		StartPosition.Y.Scale, StartPosition.Y.Offset + Delta.Y
	)
end)

__V212Stage("FPS / PING / MEMORY / GRAPH")

--==================================================
-- FPS / PING / MEMORY / GRAPH
--==================================================

local Frames = 0
local LastFPSUpdate = os.clock()
local FPS = 0
local SessionStart = os.clock()

local PingSamples = {}
local PingMin, PingMax = math.huge, 0

RunService.RenderStepped:Connect(function()
	Frames += 1
	local Now = os.clock()

	if Now - LastFPSUpdate >= 1 then
		FPS = Frames
		Frames = 0
		LastFPSUpdate = Now

		local Ping = 0
		pcall(function()
			Ping = math.floor(Player:GetNetworkPing() * 1000)
		end)

		table.insert(PingSamples, Ping)
		if #PingSamples > 60 then table.remove(PingSamples, 1) end
		PingMin = math.min(PingMin, Ping)
		PingMax = math.max(PingMax, Ping)

		local PingSum = 0
		for _, p in ipairs(PingSamples) do PingSum += p end
		local PingAvg = #PingSamples > 0 and math.floor(PingSum / #PingSamples) or 0

		local InstanceCount = #Workspace:GetDescendants()

		local MemoryMB = "N/A"
		pcall(function()
			MemoryMB = string.format("%.1f MB", Stats:GetTotalMemoryUsageMb())
		end)

		local LuaMemoryMB = string.format("%.2f MB", collectgarbage("count") / 1024)

		local Uptime = os.clock() - SessionStart
		local UptimeStr = string.format("%02d:%02d", math.floor(Uptime / 60), math.floor(Uptime % 60))

		StatsText.Text =
			"N E X U S  //  INFO\n\n" ..
			"FPS           : " .. FPS .. "\n" ..
			"PING (atual)  : " .. Ping .. " ms\n" ..
			"PING (média)  : " .. PingAvg .. " ms\n" ..
			"PING (min/max): " .. (PingMin == math.huge and 0 or PingMin) .. " / " .. PingMax .. " ms\n\n" ..
			"MEMÓRIA (RAM) : " .. MemoryMB .. "\n" ..
			"MEMÓRIA LUA   : " .. LuaMemoryMB .. "\n" ..
			"INSTÂNCIAS    : " .. InstanceCount .. "\n\n" ..
			"BOOST         : " .. (BoosterEnabled and "ATIVO (" .. CurrentMode .. ")" or "DESATIVADO") .. "\n" ..
			"TEMPO DE SESSÃO: " .. UptimeStr

		-- atualiza gráfico
		table.insert(FPSHistory, FPS)
		if #FPSHistory > MAX_BARS then table.remove(FPSHistory, 1) end

		local maxFPS = 1
		for _, v in ipairs(FPSHistory) do maxFPS = math.max(maxFPS, v) end

		for i = 1, MAX_BARS do
			local value = FPSHistory[i - (MAX_BARS - #FPSHistory)] 
			local bar = Bars[i]
			if value then
				local height = math.clamp((value / maxFPS) * 100, 2, 100)
				bar.Size = UDim2.new(0, 9, 0, height)
				bar.BackgroundColor3 = value < 20 and RED or (value < 40 and YELLOW or PURPLE)
			else
				bar.Size = UDim2.new(0, 9, 0, 2)
			end
		end
	end
end)

__V212Stage("NEON ANIMATION")

--==================================================
-- NEON ANIMATION
--==================================================

task.spawn(function()
	while Gui.Parent do
		TweenService:Create(
			MainStroke, TweenInfo.new(1.4, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut),
			{ Transparency = 0.45 }
		):Play()
		task.wait(1.4)

		TweenService:Create(
			MainStroke, TweenInfo.new(1.4, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut),
			{ Transparency = 0.05 }
		):Play()
		task.wait(1.4)
	end
end)

print("NEXUS FPS BOOSTER V21 iniciado.")

end, function(err)
    return __V212ErrorText(err)
end)

if not __V212BodyOK then
    NEXUS_DIAG.failed = true
    NEXUS_DIAG.ui.error("V21.3 BODY | " .. __V212_STAGE, __V212BodyErr)
    console("V21.3 BODY ERROR | STAGE=" .. __V212_STAGE .. " | " .. safeString(__V212BodyErr))
    NEXUS_DIAG.ui.status("ERROR / " .. __V212_STAGE)
else
    NEXUS_DIAG.ui.log("[NEXUS] V21 BODY END")
    NEXUS_DIAG.ui.status("READY / V21 BODY END")
    console("V21.3 BODY END")
end

-- Reached only if the supplied V21 body itself returns normally.
pcall(function()
    console("V21 source reached end")
    local diag = _G.NEXUS_V21_2_DIAGNOSTIC
    if diag and diag.ui then
        diag.ui.log("[NEXUS] V21 SOURCE END")
        diag.ui.status("READY / SOURCE END")
    end
end)
