-- NEXUS V20 GOD MODE + AUTO BLOCK FIX FINAL
-- FIX: reduz o uso de locals no escopo principal para evitar "Out of local registers" (limite Luau: 200 locals por função).
-- A lógica do arquivo-base foi preservada; apenas declarações de topo dentro do wrapper foram deslocalizadas.

--[[
    NEXUS FPS BOOSTER V8
    LocalScript - Roblox Studio

    Novidades da V4:
    • Anti-Lag (reduz distância de streaming/renderização)
    • Modo "Só o Essencial" (esconde HUD/Chat/Backpack)
    • Gráfico de FPS ao longo do tempo (aba INFO)
    • Ping médio / mínimo / máximo
    • Configurações salvas (via writefile/readfile, se o executor suportar)
    • Botão de minimizar o painel
    • Mantém: modos LOW/MEDIUM/HIGH/ULTRA/BATATA, RAM Cleaner, backup/restore
]]

--==================================================
-- SERVICES
--==================================================

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local Lighting = game:GetService("Lighting")
local Workspace = game:GetService("Workspace")
local UserInputService = game:GetService("UserInputService")
local Stats = game:GetService("Stats")
local StarterGui = game:GetService("StarterGui")
local HttpService = game:GetService("HttpService")

local Player = Players.LocalPlayer

--==================================================
-- NEXUS BOOT GUARD / V18.3 FIX
-- Mostra feedback mesmo se alguma parte posterior do script falhar.
--==================================================
local NexusBootGui = Instance.new("ScreenGui")
NexusBootGui.Name = "NexusV183BootGuard"
NexusBootGui.ResetOnSpawn = false
NexusBootGui.IgnoreGuiInset = true
local NexusGuiParent = nil
pcall(function()
	if Player then
		NexusGuiParent = Player:WaitForChild("PlayerGui", 10)
	end
end)
if not NexusGuiParent then
	pcall(function()
		if gethui then NexusGuiParent = gethui() end
	end)
end
if NexusGuiParent then
	NexusBootGui.Parent = NexusGuiParent
end

local NexusBootLabel = Instance.new("TextLabel")
NexusBootLabel.Size = UDim2.fromOffset(360, 42)
NexusBootLabel.Position = UDim2.new(0.5, -180, 0, 12)
NexusBootLabel.BackgroundColor3 = Color3.fromRGB(25, 18, 35)
NexusBootLabel.BackgroundTransparency = 0.08
NexusBootLabel.TextColor3 = Color3.fromRGB(240, 235, 250)
NexusBootLabel.Text = "NEXUS V20 • iniciando..."
NexusBootLabel.TextSize = 13
NexusBootLabel.Font = Enum.Font.GothamBold
NexusBootLabel.ZIndex = 999
NexusBootLabel.Parent = NexusBootGui

local NexusBootCorner = Instance.new("UICorner")
NexusBootCorner.CornerRadius = UDim.new(0, 8)
NexusBootCorner.Parent = NexusBootLabel

local NexusBootStroke = Instance.new("UIStroke")
NexusBootStroke.Color = Color3.fromRGB(180, 60, 255)
NexusBootStroke.Thickness = 1.5
NexusBootStroke.Parent = NexusBootLabel

local function NexusBootStatus(msg)
	pcall(function()
		NexusBootLabel.Text = "NEXUS V18.3 • " .. tostring(msg)
	end)
end

NexusBootStatus("serviços OK")

--==================================================
-- V18.3 FIX2 DIAGNOSTIC WRAPPER
-- Captura erro de runtime e mostra o ponto no próprio BootGuard.
--==================================================
local __NexusRunOk, __NexusRunErr = xpcall(function()

--==================================================
-- COLORS
--==================================================

PURPLE = Color3.fromRGB(180, 60, 255)
PANEL2 = Color3.fromRGB(30, 18, 45)
WHITE = Color3.fromRGB(240, 235, 250)
GREEN = Color3.fromRGB(70, 255, 150)
RED = Color3.fromRGB(255, 70, 90)
YELLOW = Color3.fromRGB(255, 210, 70)

--==================================================
-- CONFIG FILE (salvar/carregar configs)
--==================================================

CONFIG_FILE = "NexusFPSBooster_config.json"

function SaveConfig(data)
	pcall(function()
		if writefile then
			writefile(CONFIG_FILE, HttpService:JSONEncode(data))
		end
	end)
end

function LoadConfig()
	local ok, result = pcall(function()
		if isfile and isfile(CONFIG_FILE) and readfile then
			return HttpService:JSONDecode(readfile(CONFIG_FILE))
		end
		return nil
	end)
	if ok then return result end
	return nil
end

--==================================================
-- STATE
--==================================================

BoosterEnabled = false
CurrentMode = "LOW"
AntiLagEnabled = false
EssentialOnly = false
Minimized = false
SpeedEnabled = false
SpeedValue = 20
OriginalWalkSpeed = nil
GOD_SPEED_BONUS = 10
AimLockEnabled = false
AimTarget = nil
FlyEnabled = false
FlySpeed = 60

SavedConfig = LoadConfig()
if SavedConfig then
	CurrentMode = SavedConfig.CurrentMode or CurrentMode
	AntiLagEnabled = SavedConfig.AntiLagEnabled or false
		EssentialOnly = SavedConfig.EssentialOnly or false
	SpeedEnabled = SavedConfig.SpeedEnabled or false
	SpeedValue = math.clamp(SavedConfig.SpeedValue or 20, 20, 400)
	AimLockEnabled = false -- Hard lock starts OFF every session; never auto-activates from saved config
	FlyEnabled = SavedConfig.FlyEnabled or false
FlySpeed = math.clamp(SavedConfig.FlySpeed or 60, 20, 150)
end

function PersistConfig()
	SaveConfig({
		CurrentMode = CurrentMode,
		AntiLagEnabled = AntiLagEnabled,
		EssentialOnly = EssentialOnly,
		SpeedEnabled = SpeedEnabled,
		SpeedValue = SpeedValue,
		AimLockEnabled = AimLockEnabled,
		FlyEnabled = FlyEnabled,
		FlySpeed = FlySpeed
	})
end

--==================================================
-- MODES
--==================================================

Modes = {
	LOW = { Textures = true, Decals = true, Particles = true, Effects = true, Shadows = true, Materials = true },
	MEDIUM = { Textures = false, Decals = false, Particles = false, Effects = true, Shadows = false, Materials = true },
	HIGH = { Textures = false, Decals = false, Particles = false, Effects = false, Shadows = false, Materials = true },
	ULTRA = { Textures = false, Decals = false, Particles = false, Effects = false, Shadows = false, Materials = false },
	BATATA = { Textures = false, Decals = false, Particles = false, Effects = false, Shadows = false, Materials = false, Extreme = true }
}

--==================================================
-- BACKUP / RESTORE
--==================================================

Backup = {}
BackupCreated = false
OriginalStreamingRadius = nil
OriginalStreamingMinRadius = nil

pcall(function()
	OriginalStreamingRadius = Workspace.StreamingTargetRadius
	OriginalStreamingMinRadius = Workspace.StreamingMinRadius
end)

function SaveOriginal(obj)
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

	Backup[obj] = data
end

function CreateBackup()
	if BackupCreated then return end
	for _, obj in ipairs(Workspace:GetDescendants()) do SaveOriginal(obj) end
	for _, obj in ipairs(Lighting:GetChildren()) do SaveOriginal(obj) end
	BackupCreated = true
end

function RestoreGraphics()
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

--==================================================
-- BOOST
--==================================================

function ApplyBoostToObject(obj)
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

function ApplyBoost()
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

--==================================================
-- ANTI-LAG (reduz distância de renderização)
--==================================================

function ApplyAntiLag(state)
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

--==================================================
-- MODO SÓ O ESSENCIAL (esconde HUD/Chat/Backpack)
--==================================================

function ApplyEssentialOnly(state)
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

--==================================================
-- RAM CLEANER
--==================================================

function CleanRAM()
	local before = collectgarbage("count")
	collectgarbage("collect")
	local after = collectgarbage("count")
	return math.max(before - after, 0)
end

--==================================================
-- PLAYER SPEED
--==================================================

function GetHumanoid()
	local Character = Player.Character
	return Character and Character:FindFirstChildOfClass("Humanoid")
end

function ApplySpeed()
	local Humanoid = GetHumanoid()
	if not Humanoid then return end

	if OriginalWalkSpeed == nil then
		OriginalWalkSpeed = Humanoid.WalkSpeed
	end

	local desiredSpeed
	if SpeedEnabled then
		desiredSpeed = SpeedValue
	else
		desiredSpeed = OriginalWalkSpeed or 16
	end

	-- Enquanto o lock estiver ativo, dá +10 de WalkSpeed sem acumular
	-- o bônus a cada frame. Ao desligar, o valor base é restaurado.
	if AimLockEnabled then
		desiredSpeed += GOD_SPEED_BONUS
	end

	if Humanoid.WalkSpeed ~= desiredSpeed then
		Humanoid.WalkSpeed = desiredSpeed
	end
end

-- Alguns jogos/characters sobrescrevem WalkSpeed.
-- Reaplica somente quando o valor mudou.
SpeedHeartbeatConnection = RunService.Heartbeat:Connect(function()
	if SpeedEnabled then
		ApplySpeed()
	end
end)

Player.CharacterAdded:Connect(function(Character)
	OriginalWalkSpeed = nil
	task.wait(0.5)
	ApplySpeed()
end)


--==================================================
-- NEXUS DUEL CAMERA / HARD LOCK - V18.7 FLUID SYNC
--==================================================
-- V18.7: target sync mais solto, câmera mais alta, fluidez adaptativa e cleanup de morte.
-- Mantém jogador e alvo visíveis, acompanha mudança de direção e evita
-- que a câmera fique presa em um único lado.
LOCKON_RANGE = 110
LOCKON_ACQUIRE_FOV = 0.78
LOCKON_MAX_FOLLOW_DISTANCE = 500
LOCKON_ACQUIRE_ANGLE = math.rad(62)
LOCKON_REQUIRE_VISIBLE_ON_ACQUIRE = true

LOCKON_CAMERA_PRIORITY = Enum.RenderPriority.Camera.Value + 1
LOCKON_FACING_SMOOTH = 10
LOCKON_CAMERA_SMOOTH = 12
LOCKON_DISTANCE_SMOOTH = 9
LOCKON_SIDE_SMOOTH = 8
LOCKON_MIN_DISTANCE = 11
LOCKON_MAX_DISTANCE = 42
LOCKON_DEFAULT_DISTANCE = 18
LOCKON_VERTICAL_OFFSET = 3.8
LOCKON_FRAME_MARGIN = 0.22
LOCKON_WALL_BUFFER = 1.25

-- Camera mais alta, mas sem afastar demais.
LOCKON_CAMERA_HEIGHT = 4.2
LOCKON_LOOK_HEIGHT = 1.35
LOCKON_EXTRA_DISTANCE = 6.0

-- Prediction limitada para não ultrapassar o alvo.
LOCKON_PREDICTION = true
LOCKON_PREDICTION_TIME = 0.075
LOCKON_MAX_PREDICTION = 5.0

-- FOV safety: quanto maior, mais espaço de emergência.
LOCKON_EDGE_MARGIN = 0.16
LOCKON_EMERGENCY_MARGIN = 0.08
LOCKON_MOVEMENT_THRESHOLD = 2.0
LOCKON_DIRECTION_MEMORY = 0.82

-- V18.7: mais liberdade visual sem perder o alvo.
LOCKON_TARGET_AIM_BLEND = 0.82
LOCKON_PLAYER_AIM_DISTANCE = 5.5
LOCKON_MAX_TURN_RATE = 20

-- GOD MODE / ADAPTIVE COMBAT CORE
--==================================================
-- GOD AUTO BLOCK
-- Reação defensiva: detecta aproximação/dash do alvo,
-- gira o personagem para ele e aciona o Block.
--==================================================
AUTO_BLOCK_ENABLED = true
AUTO_BLOCK_DISTANCE = 25
AUTO_BLOCK_DASH_DISTANCE = 32
AUTO_BLOCK_MIN_APPROACH_SPEED = 12
AUTO_BLOCK_DASH_SPEED = 42
AUTO_BLOCK_REACTION_TIME = 0.12
AUTO_BLOCK_HOLD_TIME = 0.22
AUTO_BLOCK_RELEASE_COOLDOWN = 0.16
AUTO_BLOCK_INPUT_PRIORITY = 3000

AutoBlockActive = false
AutoBlockThreat = 0
AutoBlockLastStart = 0
AutoBlockLastRelease = 0
AutoBlockUntil = 0
AutoBlockBound = false
AutoBlockVirtualInput = nil
AutoBlockTouchButton = nil

GOD_MAX_TARGET_DISTANCE = 500
GOD_PREDICTION_MIN = 0.055
GOD_PREDICTION_MAX = 0.18
GOD_PREDICTION_SPEED_SCALE = 0.0022
GOD_ACCEL_RESPONSE = 0.18
GOD_FACING_MOVE_BLEND = 0.30
GOD_FACING_DASH_BLEND = 0.12
GOD_DASH_SPEED_THRESHOLD = 42
GOD_CAMERA_HEIGHT_MIN = 4.2
GOD_CAMERA_HEIGHT_MAX = 5.4
GOD_CAMERA_DISTANCE_MIN = 12
GOD_CAMERA_DISTANCE_MAX = 36
GOD_FOV_NORMAL = 70
GOD_FOV_COMBAT = 76
GOD_FOV_DASH = 82
GOD_FOV_SMOOTH = 10

AimTarget = nil
AimTargetPlayer = nil
AimTargetHumanoid = nil
AimTargetRoot = nil
AimTargetPart = nil
AimLockGeneration = 0
LockedHumanoidForFacing = nil
LockMarker = nil
SelfMarker = nil
LastCameraPosition = nil
LastCameraDistance = LOCKON_DEFAULT_DISTANCE
LastCameraSide = nil
LastMovementDirection = nil
CameraWasLocked = false
PreviousCameraType = nil
PreviousLocalAutoRotate = nil
CameraRaycastClock = 0
CachedSafeDistance = LOCKON_DEFAULT_DISTANCE
LocalDeathConnection = nil
TargetDeathConnection = nil
TargetCharacterRemovingConnection = nil
LastTargetVelocity = Vector3.zero
TargetAcceleration = Vector3.zero
LastLocalVelocity = Vector3.zero
CombatFOV = GOD_FOV_NORMAL
PreviousCameraFOV = nil
GodCoreActive = false

function RemoveLockMarker()
	if LockMarker then pcall(function() LockMarker:Destroy() end) end
	LockMarker = nil
end

function CreateLockMarker(character)
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

function RemoveSelfMarker()
	if SelfMarker then pcall(function() SelfMarker:Destroy() end) end
	SelfMarker = nil
end

function CreateSelfMarker(character)
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

function RefreshSelfMarker()
	local character = Player.Character
	if character then CreateSelfMarker(character) end
end

function GetLockOnPart(character)
	if not character then return nil end
	return character:FindFirstChild('Head')
		or character:FindFirstChild('UpperTorso')
		or character:FindFirstChild('Torso')
		or character:FindFirstChild('HumanoidRootPart')
end

function GetPredictedTargetPosition()
	if not AimTargetPart or not AimTargetPart.Parent then return nil end
	local position = AimTargetPart.Position
	if not LOCKON_PREDICTION then return position end

	local velocity = AimTargetPart.AssemblyLinearVelocity
	local dt = math.clamp(1 / 60, 1 / 240, 1 / 20)
	local rawAcceleration = (velocity - LastTargetVelocity) / dt
	TargetAcceleration = TargetAcceleration:Lerp(rawAcceleration, GOD_ACCEL_RESPONSE)
	LastTargetVelocity = velocity

	local speed = velocity.Magnitude
	local predictionTime = math.clamp(
		GOD_PREDICTION_MIN + speed * GOD_PREDICTION_SPEED_SCALE,
		GOD_PREDICTION_MIN,
		GOD_PREDICTION_MAX
	)

	local lead = velocity * predictionTime + TargetAcceleration * (predictionTime * predictionTime * 0.5)
	if lead.Magnitude > LOCKON_MAX_PREDICTION then
		lead = lead.Unit * LOCKON_MAX_PREDICTION
	end
	return position + lead
end

function BuildTargetData(player, checkAcquireRules)
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

function FindLockOnTarget()
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
			local score = screenScore * .76 + distanceScore * .16
			if score < bestScore then bestScore, best = score, candidate end
		end
	end
	return best
end

function RestoreCharacterFacing()
	local character = Player.Character
	local localHumanoid = character and character:FindFirstChildOfClass('Humanoid')
	if localHumanoid then
		pcall(function()
			if PreviousLocalAutoRotate ~= nil then
				localHumanoid.AutoRotate = PreviousLocalAutoRotate
			else
				localHumanoid.AutoRotate = true
			end
		end)
	end
	PreviousLocalAutoRotate = nil
	LockedHumanoidForFacing = nil
end

function ClearLockOn()
	if TargetDeathConnection then
		pcall(function() TargetDeathConnection:Disconnect() end)
		TargetDeathConnection = nil
	end
	if TargetCharacterRemovingConnection then
		pcall(function() TargetCharacterRemovingConnection:Disconnect() end)
		TargetCharacterRemovingConnection = nil
	end
	if Camera and PreviousCameraType then
		pcall(function() Camera.CameraType = PreviousCameraType end)
	end
	PreviousCameraType = nil
	RemoveLockMarker()
	RestoreCharacterFacing()
	AimTarget, AimTargetPlayer, AimTargetHumanoid = nil, nil, nil
	AimTargetRoot, AimTargetPart = nil, nil
	AimLockGeneration += 1
	LastCameraPosition = nil
	LastCameraDistance = LOCKON_DEFAULT_DISTANCE
	CachedSafeDistance = LOCKON_DEFAULT_DISTANCE
	CameraRaycastClock = 0
	LastCameraSide = nil
	LastMovementDirection = nil
	LastTargetVelocity = Vector3.zero
	TargetAcceleration = Vector3.zero
	LastLocalVelocity = Vector3.zero
	GodCoreActive = false
	if Camera and PreviousCameraFOV then
		pcall(function() Camera.FieldOfView = PreviousCameraFOV end)
	end
	PreviousCameraFOV = nil
	CombatFOV = GOD_FOV_NORMAL
	CameraWasLocked = false
end

function AcquireLockOn()
	local target = FindLockOnTarget()
	if not target then ClearLockOn(); return false end

	Camera = Workspace.CurrentCamera or Camera
	if Camera then
		PreviousCameraType = Camera.CameraType
		PreviousCameraFOV = Camera.FieldOfView
		CombatFOV = Camera.FieldOfView
		pcall(function() Camera.CameraType = Enum.CameraType.Scriptable end)
	end

	local character = Player.Character
	local localHumanoid = character and character:FindFirstChildOfClass('Humanoid')
	if localHumanoid then
		PreviousLocalAutoRotate = localHumanoid.AutoRotate
		pcall(function() localHumanoid.AutoRotate = false end)
	end

	AimTarget = target.Character
	AimTargetPlayer = target.Player
	AimTargetHumanoid = target.Humanoid
	AimTargetRoot = target.Root
	AimTargetPart = target.Part

	-- Destrava imediatamente quando o inimigo morre ou o Character é removido.
	-- Isso evita a câmera permanecer Scriptable olhando para um alvo morto.
	if AimTargetHumanoid then
		TargetDeathConnection = AimTargetHumanoid.Died:Connect(function()
			if AimLockEnabled then
				DisableLockOn()
			else
				ClearLockOn()
			end
			pcall(RefreshAimLockButton)
			pcall(RefreshAimControls)
		end)
	end
	if AimTargetPlayer then
		TargetCharacterRemovingConnection = AimTargetPlayer.CharacterRemoving:Connect(function(character)
			if character == AimTarget then
				if AimLockEnabled then
					DisableLockOn()
				else
					ClearLockOn()
				end
				pcall(RefreshAimLockButton)
				pcall(RefreshAimControls)
			end
		end)
	end

	AimLockGeneration += 1
	CreateLockMarker(target.Character)
	RefreshSelfMarker()
	return true
end

function IsCurrentTargetValid()
	if not AimTargetPlayer or not AimTargetPlayer.Parent then return false end
	if not AimTarget or not AimTarget.Parent or AimTargetPlayer.Character ~= AimTarget then return false end
	if not AimTargetHumanoid or AimTargetHumanoid.Health <= 0 or AimTargetHumanoid.Parent ~= AimTarget then return false end
	if not AimTargetRoot or not AimTargetRoot.Parent or AimTargetRoot.Parent ~= AimTarget then return false end
	Camera = Workspace.CurrentCamera or Camera
	return Camera ~= nil and (AimTargetRoot.Position - Camera.CFrame.Position).Magnitude <= LOCKON_MAX_FOLLOW_DISTANCE
end

-- LOCK-ON FACING:
-- O player acompanha o sentido do alvo. A câmera não escolhe um lado novo;
-- ela permanece atrás do player e acompanha a rotação dele.
function FaceLocalCharacterToTarget(dt)
	local character = Player.Character
	local localHumanoid = character and character:FindFirstChildOfClass('Humanoid')
	local localRoot = character and character:FindFirstChild('HumanoidRootPart')
	if not localHumanoid or localHumanoid.Health <= 0 or not localRoot or not AimTargetRoot then return end

	local predicted = GetPredictedTargetPosition() or AimTargetRoot.Position
	local toTarget = Vector3.new(predicted.X - localRoot.Position.X, 0, predicted.Z - localRoot.Position.Z)
	if toTarget.Magnitude < 0.001 then return end

	local targetDir = toTarget.Unit
	local velocity = Vector3.new(localRoot.AssemblyLinearVelocity.X, 0, localRoot.AssemblyLinearVelocity.Z)
	local speed = velocity.Magnitude
	local moveDir = speed > 2 and velocity.Unit or targetDir
	local dashFactor = math.clamp((speed - GOD_DASH_SPEED_THRESHOLD) / 55, 0, 1)

	-- Freestyle: alvo continua sendo a referência, mas o movimento do jogador
	-- conserva parte da orientação para que strafe/dash não pareçam "puxados".
	local blended = targetDir:Lerp(moveDir, GOD_FACING_MOVE_BLEND + dashFactor * GOD_FACING_DASH_BLEND)
	if blended.Magnitude < 0.001 then blended = targetDir end

	pcall(function() localHumanoid.AutoRotate = false end)
	LockedHumanoidForFacing = localHumanoid
	local desired = CFrame.lookAt(localRoot.Position, localRoot.Position + blended.Unit)
	local turnSpeed = math.clamp(LOCKON_FACING_SMOOTH + speed * 0.16 + dashFactor * 8, 9, LOCKON_MAX_TURN_RATE)
	local alpha = 1 - math.exp(-turnSpeed * math.clamp(dt, 1/240, 1/20))
	localRoot.CFrame = localRoot.CFrame:Lerp(desired, alpha)
end

-- Uma única checagem de colisão em intervalos curtos. Evita raycast pesado
-- em todo frame sem deixar a câmera atravessar paredes.
function GetSafeCameraDistance(origin, desiredPosition, desiredDistance, dt)
	CameraRaycastClock += dt
	if CameraRaycastClock < 0.075 and CachedSafeDistance > 0 then
		return math.clamp(CachedSafeDistance, LOCKON_MIN_DISTANCE, desiredDistance)
	end
	CameraRaycastClock = 0

	local direction = desiredPosition - origin
	local magnitude = direction.Magnitude
	if magnitude < 0.001 then return desiredDistance end

	local params = RaycastParams.new()
	params.FilterType = Enum.RaycastFilterType.Exclude
	params.FilterDescendantsInstances = {Player.Character, AimTarget}
	params.IgnoreWater = true

	local hit = Workspace:Raycast(origin, direction.Unit * desiredDistance, params)
	if hit then
		CachedSafeDistance = math.clamp((hit.Position - origin).Magnitude - LOCKON_WALL_BUFFER, LOCKON_MIN_DISTANCE, desiredDistance)
	else
		CachedSafeDistance = desiredDistance
	end
	return CachedSafeDistance
end

function UpdateDuelCamera(dt)
	if not AimLockEnabled or not IsCurrentTargetValid() then
		if CameraWasLocked then
			CameraWasLocked = false
			LastCameraPosition = nil
			if Camera and PreviousCameraType then
				pcall(function() Camera.CameraType = PreviousCameraType end)
				PreviousCameraType = nil
			end
			RestoreCharacterFacing()
		end
		return
	end

	Camera = Workspace.CurrentCamera or Camera
	local localCharacter = Player.Character
	local localRoot = localCharacter and localCharacter:FindFirstChild('HumanoidRootPart')
	local localHumanoid = localCharacter and localCharacter:FindFirstChildOfClass('Humanoid')
	if not Camera or not localRoot or not localHumanoid or not AimTargetRoot then return end

	GodCoreActive = true
	FaceLocalCharacterToTarget(dt)

	local predictedTarget = GetPredictedTargetPosition() or AimTargetRoot.Position
	local rootPos = localRoot.Position
	local rootForward = Vector3.new(localRoot.CFrame.LookVector.X, 0, localRoot.CFrame.LookVector.Z)
	if rootForward.Magnitude < 0.001 then rootForward = Vector3.new(0, 0, -1) end
	rootForward = rootForward.Unit

	local velocity = Vector3.new(localRoot.AssemblyLinearVelocity.X, 0, localRoot.AssemblyLinearVelocity.Z)
	local speed = velocity.Magnitude
	local acceleration = (velocity - LastLocalVelocity).Magnitude / math.max(dt, 1/240)
	LastLocalVelocity = velocity
	local dashFactor = math.clamp(math.max(speed - GOD_DASH_SPEED_THRESHOLD, acceleration * 0.035) / 55, 0, 1)

	local playerFocus = rootPos + Vector3.new(0, LOCKON_VERTICAL_OFFSET, 0)
	local targetFocus = predictedTarget + Vector3.new(0, LOCKON_VERTICAL_OFFSET + LOCKON_LOOK_HEIGHT, 0)
	local separation = (targetFocus - playerFocus).Magnitude

	-- Distância/altura adaptativas: aproxima no combate e abre espaço no dash.
	local desiredDistance = math.clamp(
		LOCKON_DEFAULT_DISTANCE + math.clamp(separation - 10, 0, 20) * 0.22 + dashFactor * 5,
		GOD_CAMERA_DISTANCE_MIN,
		GOD_CAMERA_DISTANCE_MAX
	)
	local desiredHeight = math.clamp(GOD_CAMERA_HEIGHT_MIN + dashFactor * 1.2, GOD_CAMERA_HEIGHT_MIN, GOD_CAMERA_HEIGHT_MAX)

	local desiredPosition = rootPos - rootForward * desiredDistance + Vector3.new(0, desiredHeight, 0)
	local safeDistance = GetSafeCameraDistance(playerFocus, desiredPosition, desiredDistance, dt)
	local distAlpha = 1 - math.exp(-(LOCKON_DISTANCE_SMOOTH + dashFactor * 5) * math.clamp(dt, 1/240, 1/20))
	LastCameraDistance = LastCameraDistance + (safeDistance - LastCameraDistance) * distAlpha
	desiredPosition = rootPos - rootForward * LastCameraDistance + Vector3.new(0, desiredHeight, 0)

	local playerLookPoint = playerFocus + rootForward * LOCKON_PLAYER_AIM_DISTANCE
	local lookBlend = math.clamp(LOCKON_TARGET_AIM_BLEND - dashFactor * 0.08, 0.70, 0.86)
	local lookPoint = playerLookPoint:Lerp(targetFocus, lookBlend)
	local desiredCFrame = CFrame.lookAt(desiredPosition, lookPoint)

	local cameraSmooth = math.clamp(12 + speed * 0.28 + dashFactor * 8, 12, 30)
	local posAlpha = 1 - math.exp(-cameraSmooth * math.clamp(dt, 1/240, 1/20))
	LastCameraPosition = LastCameraPosition and LastCameraPosition:Lerp(desiredPosition, posAlpha) or desiredPosition
	local finalCFrame = CFrame.lookAt(LastCameraPosition, lookPoint)
	Camera.CFrame = Camera.CFrame:Lerp(finalCFrame, posAlpha)
	Camera.Focus = CFrame.new(lookPoint)

	-- FOV adaptativo: abre durante movimento rápido e volta suavemente.
	local desiredFOV = GOD_FOV_NORMAL + (GOD_FOV_COMBAT - GOD_FOV_NORMAL) * math.clamp(speed / 28, 0, 1)
	if dashFactor > 0 then desiredFOV = GOD_FOV_DASH end
	CombatFOV = CombatFOV + (desiredFOV - CombatFOV) * (1 - math.exp(-GOD_FOV_SMOOTH * math.clamp(dt, 1/240, 1/20)))
	pcall(function() Camera.FieldOfView = CombatFOV end)

	CameraWasLocked = true
end

function UpdateAimLock(dt)
	if not AimLockEnabled then return end
	local localCharacter = Player.Character
	local localHumanoid = localCharacter and localCharacter:FindFirstChildOfClass('Humanoid')
	if not localHumanoid or localHumanoid.Health <= 0 then
		DisableLockOn()
		return
	end
	if not IsCurrentTargetValid() then
		DisableLockOn()
		return
	end
	UpdateDuelCamera(dt)
end

function EnableLockOn()
	ClearLockOn()
	Camera = Workspace.CurrentCamera or Camera
	if Camera then
		PreviousCameraType = Camera.CameraType
		pcall(function() Camera.CameraType = Enum.CameraType.Scriptable end)
	end
	local acquired = AcquireLockOn()
	AimLockEnabled = acquired
	ApplySpeed()
	if acquired then RefreshSelfMarker() end
	return acquired
end

DisableLockOn = function()
	AimLockEnabled = false
	ApplySpeed()
	AutoBlockActive = false
	AutoBlockThreat = 0
	ClearLockOn()
	RemoveSelfMarker()
end

-- Tenta usar o mesmo input do JJS: F.
-- Em touch, o ContextActionService cria um botão de ação enquanto a ação estiver bound.
function GetVirtualInputManager()
	if AutoBlockVirtualInput ~= nil then return AutoBlockVirtualInput end
	local ok, service = pcall(function()
		return game:GetService("VirtualInputManager")
	end)
	if ok then
		AutoBlockVirtualInput = service
	end
	return AutoBlockVirtualInput
end

function SendBlockInput(isDown)
	local vim = GetVirtualInputManager()
	if vim then
		pcall(function()
			vim:SendKeyEvent(isDown, Enum.KeyCode.F, false, game)
		end)
	end
end

function SetAutoBlockState(active)
	if active == AutoBlockActive then return end

	AutoBlockActive = active

	if active then
		AutoBlockLastStart = os.clock()
		AutoBlockUntil = AutoBlockLastStart + AUTO_BLOCK_HOLD_TIME
		SendBlockInput(true)
	else
		AutoBlockLastRelease = os.clock()
		SendBlockInput(false)
	end
end

function BindAutoBlockInput()
	-- Não captura o F do jogador: o jogo continua recebendo o input normalmente.
	-- O Auto Block somente envia F durante uma janela de ameaça.
	AutoBlockBound = true
end

function UnbindAutoBlockInput()
	AutoBlockBound = false
	SetAutoBlockState(false)
end

function GetAutoBlockThreat()
	if not AUTO_BLOCK_ENABLED or not AimLockEnabled then
		return 0
	end
	if not IsCurrentTargetValid() or not AimTargetRoot then
		return 0
	end

	local character = Player.Character
	local localRoot = character and character:FindFirstChild("HumanoidRootPart")
	if not localRoot then return 0 end

	local offset = localRoot.Position - AimTargetRoot.Position
	local distance = offset.Magnitude
	if distance > AUTO_BLOCK_DASH_DISTANCE then
		return 0
	end

	if distance < 0.001 then
		return 1
	end

	local toPlayer = offset.Unit
	local targetVelocity = Vector3.new(
		AimTargetRoot.AssemblyLinearVelocity.X,
		0,
		AimTargetRoot.AssemblyLinearVelocity.Z
	)
	local targetSpeed = targetVelocity.Magnitude

	-- Dot > 0 significa que o alvo está se movendo na direção do player.
	local approach = 0
	if targetSpeed > 0.1 then
		approach = targetVelocity.Unit:Dot(toPlayer)
	end

	-- Quanto mais perto, maior a ameaça.
	local distanceThreat = 1 - math.clamp(distance / AUTO_BLOCK_DISTANCE, 0, 1)

	-- Dash vindo na nossa direção recebe prioridade máxima.
	local dashThreat = 0
	if targetSpeed >= AUTO_BLOCK_DASH_SPEED and approach > 0.45 then
		dashThreat = math.clamp(
			(targetSpeed - AUTO_BLOCK_DASH_SPEED) / 35,
			0,
			1
		)
	end

	local approachThreat = 0
	if approach >= 0.45 and targetSpeed >= AUTO_BLOCK_MIN_APPROACH_SPEED then
		approachThreat = math.clamp(
			(approach - 0.45) / 0.55,
			0,
			1
		)
	end

	local threat = distanceThreat * 0.55 + approachThreat * 0.30 + dashThreat * 0.75

	-- Dentro do raio curto, uma aproximação moderada já é suficiente.
	if distance <= AUTO_BLOCK_DISTANCE and approach >= 0.35 then
		threat = math.max(threat, 0.72)
	end

	-- Dash muito rápido apontado diretamente para o player.
	if distance <= AUTO_BLOCK_DASH_DISTANCE
		and targetSpeed >= AUTO_BLOCK_DASH_SPEED
		and approach >= 0.65 then
		threat = math.max(threat, 1)
	end

	return math.clamp(threat, 0, 1)
end

function FaceTargetForAutoBlock(dt)
	local character = Player.Character
	local root = character and character:FindFirstChild("HumanoidRootPart")
	local humanoid = character and character:FindFirstChildOfClass("Humanoid")
	if not root or not humanoid or humanoid.Health <= 0 or not AimTargetRoot then return end

	local flat = Vector3.new(
		AimTargetRoot.Position.X - root.Position.X,
		0,
		AimTargetRoot.Position.Z - root.Position.Z
	)
	if flat.Magnitude < 0.001 then return end

	local desired = CFrame.lookAt(root.Position, root.Position + flat.Unit)
	local alpha = 1 - math.exp(-38 * math.clamp(dt, 1/240, 1/20))
	root.CFrame = root.CFrame:Lerp(desired, alpha)
end

function UpdateAutoBlock(dt)
	if not AUTO_BLOCK_ENABLED then
		if AutoBlockActive then SetAutoBlockState(false) end
		return
	end

	local threat = GetAutoBlockThreat()
	AutoBlockThreat = threat

	local now = os.clock()

	if threat >= 0.72 then
		-- A reação começa imediatamente: primeiro gira, depois mantém o block.
		FaceTargetForAutoBlock(dt)

		if not AutoBlockActive and (now - AutoBlockLastRelease) >= AUTO_BLOCK_RELEASE_COOLDOWN then
			SetAutoBlockState(true)
		end
		AutoBlockUntil = math.max(AutoBlockUntil, now + AUTO_BLOCK_HOLD_TIME)
	elseif AutoBlockActive then
		-- Pequena tolerância evita soltar no meio de um dash por uma única frame.
		if now >= AutoBlockUntil + AUTO_BLOCK_REACTION_TIME then
			SetAutoBlockState(false)
		end
	end
end

BindAutoBlockInput()

-- V18.7: morte do personagem nunca deixa a câmera presa em Scriptable.
function HookLocalCharacter(character)
	if LocalDeathConnection then
		pcall(function() LocalDeathConnection:Disconnect() end)
		LocalDeathConnection = nil
	end
	if not character then return end
	local humanoid = character:FindFirstChildOfClass('Humanoid') or character:WaitForChild('Humanoid', 3)
	if not humanoid then return end
	LocalDeathConnection = humanoid.Died:Connect(function()
		if AimLockEnabled then
			DisableLockOn()
		else
			ClearLockOn()
		end
	end)
end

HookLocalCharacter(Player.Character)
Player.CharacterAdded:Connect(function(character)
	-- Reseta completamente o estado de câmera ao respawnar.
	if AimLockEnabled then
		DisableLockOn()
	else
		ClearLockOn()
	end
	HookLocalCharacter(character)
	task.defer(function()
		if AimLockEnabled then CreateSelfMarker(character) end
	end)
end)

pcall(function() RunService:UnbindFromRenderStep('NexusAimLock') end)
RunService:BindToRenderStep('NexusAimLock', LOCKON_CAMERA_PRIORITY, function(dt)
	UpdateAimLock(dt)
	UpdateAutoBlock(dt)
end)

--==================================================

-- FLY
--==================================================

--==================================================

FlyVelocity = nil
FlyGyro = nil
FlyConnection = nil

function StopFly()
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

function StartFly()
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

--==================================================
-- GUI BASE
--==================================================

Gui = Instance.new("ScreenGui")
Gui.Name = "NexusFPSBoosterV9"
Gui.ResetOnSpawn = false
Gui.IgnoreGuiInset = true
Gui.Parent = Player:WaitForChild("PlayerGui")

Main = Instance.new("Frame")
Main.Name = "Main"
Main.Size = UDim2.fromOffset(500, 460)
Main.Position = UDim2.new(0.5, -250, 0.5, -230)
Main.BackgroundColor3 = Color3.fromRGB(15, 8, 22)
Main.BackgroundTransparency = 0.25
Main.BorderSizePixel = 0
Main.ClipsDescendants = true
Main.Parent = Gui

MainCorner = Instance.new("UICorner")
MainCorner.CornerRadius = UDim.new(0, 16)
MainCorner.Parent = Main

MainStroke = Instance.new("UIStroke")
MainStroke.Color = PURPLE
MainStroke.Thickness = 2
MainStroke.Transparency = 0.1
MainStroke.Parent = Main


--==================================================
-- AIM LOCK FLOATING BUTTON
--==================================================

AimLockButton = Instance.new("TextButton")
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

AimLockCorner = Instance.new("UICorner")
AimLockCorner.CornerRadius = UDim.new(1, 0)
AimLockCorner.Parent = AimLockButton

AimLockStroke = Instance.new("UIStroke")
AimLockStroke.Color = PURPLE
AimLockStroke.Thickness = 2
AimLockStroke.Transparency = AimLockEnabled and 0 or 0.25
AimLockStroke.Parent = AimLockButton

AimLockStateLabel = Instance.new("TextLabel")
AimLockStateLabel.Size = UDim2.new(1, 0, 0, 15)
AimLockStateLabel.Position = UDim2.new(0, 0, 1, -16)
AimLockStateLabel.BackgroundTransparency = 1
AimLockStateLabel.Text = AimLockEnabled and "GOD X" or "OFF"
AimLockStateLabel.TextColor3 = AimLockEnabled and GREEN or RED
AimLockStateLabel.TextSize = 8
AimLockStateLabel.Font = Enum.Font.GothamBold
AimLockStateLabel.ZIndex = 51
AimLockStateLabel.Parent = AimLockButton

GodModeBadge = Instance.new("TextLabel")
GodModeBadge.Name = "GodModeBadge"
GodModeBadge.Size = UDim2.fromOffset(58, 16)
GodModeBadge.Position = UDim2.new(1, -82, 0.5, 34)
GodModeBadge.BackgroundTransparency = 1
GodModeBadge.Text = "GOD X"
GodModeBadge.TextColor3 = PURPLE
GodModeBadge.TextSize = 9
GodModeBadge.Font = Enum.Font.GothamBold
GodModeBadge.ZIndex = 51
GodModeBadge.Parent = Gui

AutoBlockBadge = Instance.new("TextLabel")
AutoBlockBadge.Name = "AutoBlockBadge"
AutoBlockBadge.Size = UDim2.fromOffset(92, 16)
AutoBlockBadge.Position = UDim2.new(1, -116, 0.5, 52)
AutoBlockBadge.BackgroundTransparency = 1
AutoBlockBadge.Text = "AUTO BLOCK: ON"
AutoBlockBadge.TextColor3 = Color3.fromRGB(120, 255, 170)
AutoBlockBadge.TextSize = 8
AutoBlockBadge.Font = Enum.Font.GothamBold
AutoBlockBadge.ZIndex = 51
AutoBlockBadge.Parent = Gui

function RefreshAimLockButton()
	AimLockButton.BackgroundColor3 = AimLockEnabled
		and Color3.fromRGB(45, 15, 65)
		or Color3.fromRGB(20, 15, 25)
	AimLockStroke.Transparency = AimLockEnabled and 0 or 0.25
	AimLockStateLabel.Text = AimLockEnabled and "GOD X" or "OFF"
	AimLockStateLabel.TextColor3 = AimLockEnabled and GREEN or RED
	GodModeBadge.TextColor3 = AimLockEnabled and Color3.fromRGB(255, 80, 180) or PURPLE
	AutoBlockBadge.Text = AutoBlockActive and "AUTO BLOCK: BLOCK" or (AUTO_BLOCK_ENABLED and "AUTO BLOCK: ON" or "AUTO BLOCK: OFF")
	AutoBlockBadge.TextColor3 = AutoBlockActive and Color3.fromRGB(255, 220, 80) or (AUTO_BLOCK_ENABLED and Color3.fromRGB(120, 255, 170) or RED)
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


--==================================================
-- FLY FLOATING BUTTON
--==================================================

FlyButton = Instance.new("TextButton")
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

FlyCorner = Instance.new("UICorner")
FlyCorner.CornerRadius = UDim.new(1, 0)
FlyCorner.Parent = FlyButton

FlyStroke = Instance.new("UIStroke")
FlyStroke.Color = PURPLE
FlyStroke.Thickness = 2
FlyStroke.Transparency = FlyEnabled and 0 or 0.25
FlyStroke.Parent = FlyButton

FlyStateLabel = Instance.new("TextLabel")
FlyStateLabel.Size = UDim2.new(1, 0, 0, 15)
FlyStateLabel.Position = UDim2.new(0, 0, 1, -16)
FlyStateLabel.BackgroundTransparency = 1
FlyStateLabel.Text = FlyEnabled and "ON" or "OFF"
FlyStateLabel.TextColor3 = FlyEnabled and GREEN or RED
FlyStateLabel.TextSize = 8
FlyStateLabel.Font = Enum.Font.GothamBold
FlyStateLabel.ZIndex = 51
FlyStateLabel.Parent = FlyButton

function RefreshFlyButton()
	FlyButton.BackgroundColor3 = FlyEnabled and Color3.fromRGB(45, 15, 65) or Color3.fromRGB(20, 15, 25)
	FlyStroke.Transparency = FlyEnabled and 0 or 0.25
	FlyStateLabel.Text = FlyEnabled and "ON" or "OFF"
	FlyStateLabel.TextColor3 = FlyEnabled and GREEN or RED
end

FlyButton.MouseButton1Click:Connect(function()
	FlyEnabled = not FlyEnabled
	if FlyEnabled then
		if not StartFly() then FlyEnabled = false end
	else
		StopFly()
	end
	RefreshFlyButton()
	PersistConfig()
end)

--==================================================
-- TOP BAR + MINIMIZE
--==================================================

Top = Instance.new("Frame")
Top.Size = UDim2.new(1, 0, 0, 50)
Top.BackgroundTransparency = 1
Top.Parent = Main

Title = Instance.new("TextLabel")
Title.Size = UDim2.new(1, -80, 1, 0)
Title.Position = UDim2.fromOffset(15, 0)
Title.BackgroundTransparency = 1
Title.Text = "N E X U S  //  FPS BOOSTER"
Title.TextColor3 = WHITE
Title.TextSize = 17
Title.Font = Enum.Font.GothamBold
Title.TextXAlignment = Enum.TextXAlignment.Left
Title.Parent = Top

MinimizeButton = Instance.new("TextButton")
MinimizeButton.Size = UDim2.fromOffset(34, 34)
MinimizeButton.Position = UDim2.new(1, -44, 0, 8)
MinimizeButton.BackgroundColor3 = PANEL2
MinimizeButton.Text = "—"
MinimizeButton.TextColor3 = WHITE
MinimizeButton.TextSize = 16
MinimizeButton.Font = Enum.Font.GothamBold
MinimizeButton.AutoButtonColor = false
MinimizeButton.Parent = Top

MinimizeCorner = Instance.new("UICorner")
MinimizeCorner.CornerRadius = UDim.new(0, 8)
MinimizeCorner.Parent = MinimizeButton

--==================================================
-- TABS
--==================================================

BoostTab = Instance.new("TextButton")
BoostTab.Size = UDim2.fromOffset(150, 32)
BoostTab.Position = UDim2.fromOffset(15, 55)
BoostTab.BackgroundColor3 = PURPLE
BoostTab.Text = "BOOST"
BoostTab.TextColor3 = WHITE
BoostTab.Font = Enum.Font.GothamBold
BoostTab.TextSize = 12
BoostTab.AutoButtonColor = false
BoostTab.Parent = Main

BoostTabCorner = Instance.new("UICorner")
BoostTabCorner.CornerRadius = UDim.new(0, 8)
BoostTabCorner.Parent = BoostTab

InfoTab = Instance.new("TextButton")
InfoTab.Size = UDim2.fromOffset(150, 32)
InfoTab.Position = UDim2.fromOffset(175, 55)
InfoTab.BackgroundColor3 = PANEL2
InfoTab.Text = "INFO"
InfoTab.TextColor3 = WHITE
InfoTab.Font = Enum.Font.GothamBold
InfoTab.TextSize = 12
InfoTab.AutoButtonColor = false
InfoTab.Parent = Main

InfoTabCorner = Instance.new("UICorner")
InfoTabCorner.CornerRadius = UDim.new(0, 8)
InfoTabCorner.Parent = InfoTab

PlayerTab = Instance.new("TextButton")
PlayerTab.Size = UDim2.fromOffset(150, 32)
PlayerTab.Position = UDim2.fromOffset(335, 55)
PlayerTab.BackgroundColor3 = PANEL2
PlayerTab.Text = "PLAYER"
PlayerTab.TextColor3 = WHITE
PlayerTab.Font = Enum.Font.GothamBold
PlayerTab.TextSize = 12
PlayerTab.AutoButtonColor = false
PlayerTab.Parent = Main

PlayerTabCorner = Instance.new("UICorner")
PlayerTabCorner.CornerRadius = UDim.new(0, 8)
PlayerTabCorner.Parent = PlayerTab

--==================================================
-- BOOST PAGE
--==================================================

BoostPage = Instance.new("Frame")
BoostPage.Size = UDim2.new(1, -30, 1, -100)
BoostPage.Position = UDim2.fromOffset(15, 98)
BoostPage.BackgroundTransparency = 1
BoostPage.Parent = Main

Status = Instance.new("TextLabel")
Status.Size = UDim2.new(0.6, 0, 0, 26)
Status.BackgroundTransparency = 1
Status.Text = "●  BOOST DISABLED"
Status.TextColor3 = RED
Status.TextSize = 14
Status.Font = Enum.Font.GothamBold
Status.TextXAlignment = Enum.TextXAlignment.Left
Status.Parent = BoostPage

Toggle = Instance.new("TextButton")
Toggle.Size = UDim2.fromOffset(110, 44)
Toggle.Position = UDim2.new(1, -110, 0, 0)
Toggle.BackgroundColor3 = PANEL2
Toggle.Text = "OFF"
Toggle.TextColor3 = RED
Toggle.TextSize = 15
Toggle.Font = Enum.Font.GothamBold
Toggle.AutoButtonColor = false
Toggle.Parent = BoostPage

ToggleCorner = Instance.new("UICorner")
ToggleCorner.CornerRadius = UDim.new(0, 8)
ToggleCorner.Parent = Toggle

ToggleStroke = Instance.new("UIStroke")
ToggleStroke.Color = PURPLE
ToggleStroke.Thickness = 1.5
ToggleStroke.Parent = Toggle

ModeTitle = Instance.new("TextLabel")
ModeTitle.Size = UDim2.new(1, 0, 0, 20)
ModeTitle.Position = UDim2.fromOffset(0, 55)
ModeTitle.BackgroundTransparency = 1
ModeTitle.Text = "OPTIMIZATION MODE"
ModeTitle.TextColor3 = PURPLE
ModeTitle.TextSize = 11
ModeTitle.Font = Enum.Font.GothamBold
ModeTitle.TextXAlignment = Enum.TextXAlignment.Left
ModeTitle.Parent = BoostPage

ModeContainer = Instance.new("Frame")
ModeContainer.Size = UDim2.new(1, 0, 0, 40)
ModeContainer.Position = UDim2.fromOffset(0, 78)
ModeContainer.BackgroundTransparency = 1
ModeContainer.Parent = BoostPage

ModeNames = {"LOW", "MEDIUM", "HIGH", "ULTRA", "BATATA"}
ModeButtons = {}

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

CurrentModeLabel = Instance.new("TextLabel")
CurrentModeLabel.Size = UDim2.new(1, 0, 0, 20)
CurrentModeLabel.Position = UDim2.fromOffset(0, 122)
CurrentModeLabel.BackgroundTransparency = 1
CurrentModeLabel.Text = "MODE: " .. CurrentMode
CurrentModeLabel.TextColor3 = WHITE
CurrentModeLabel.TextSize = 12
CurrentModeLabel.Font = Enum.Font.GothamMedium
CurrentModeLabel.TextXAlignment = Enum.TextXAlignment.Left
CurrentModeLabel.Parent = BoostPage

--==================================================
-- EXTRAS: ANTI-LAG / SONS / SÓ ESSENCIAL
--==================================================

ExtrasTitle = Instance.new("TextLabel")
ExtrasTitle.Size = UDim2.new(1, 0, 0, 18)
ExtrasTitle.Position = UDim2.fromOffset(0, 150)
ExtrasTitle.BackgroundTransparency = 1
ExtrasTitle.Text = "EXTRAS"
ExtrasTitle.TextColor3 = PURPLE
ExtrasTitle.TextSize = 11
ExtrasTitle.Font = Enum.Font.GothamBold
ExtrasTitle.TextXAlignment = Enum.TextXAlignment.Left
ExtrasTitle.Parent = BoostPage

function CreateExtraToggle(name, posY, initialState)
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

AntiLagBtn, AntiLagState = CreateExtraToggle("ANTI-LAG", 172, AntiLagEnabled)
EssentialBtn, EssentialState = CreateExtraToggle("SÓ O ESSENCIAL (HUD)", 244, EssentialOnly)

Restore = Instance.new("TextButton")
Restore.Size = UDim2.new(0.485, 0, 0, 34)
Restore.Position = UDim2.fromOffset(0, 286)
Restore.BackgroundColor3 = PANEL2
Restore.Text = "↻  RESTORE"
Restore.TextColor3 = WHITE
Restore.TextSize = 11
Restore.Font = Enum.Font.GothamBold
Restore.AutoButtonColor = false
Restore.Parent = BoostPage

RestoreCorner = Instance.new("UICorner")
RestoreCorner.CornerRadius = UDim.new(0, 7)
RestoreCorner.Parent = Restore

RestoreStroke = Instance.new("UIStroke")
RestoreStroke.Color = PURPLE
RestoreStroke.Thickness = 1
RestoreStroke.Parent = Restore

CleanButton = Instance.new("TextButton")
CleanButton.Size = UDim2.new(0.485, 0, 0, 34)
CleanButton.Position = UDim2.new(0.515, 0, 0, 286)
CleanButton.BackgroundColor3 = PANEL2
CleanButton.Text = "🧹  LIMPAR RAM"
CleanButton.TextColor3 = WHITE
CleanButton.TextSize = 11
CleanButton.Font = Enum.Font.GothamBold
CleanButton.AutoButtonColor = false
CleanButton.Parent = BoostPage

CleanButtonCorner = Instance.new("UICorner")
CleanButtonCorner.CornerRadius = UDim.new(0, 7)
CleanButtonCorner.Parent = CleanButton

CleanButtonStroke = Instance.new("UIStroke")
CleanButtonStroke.Color = PURPLE
CleanButtonStroke.Thickness = 1
CleanButtonStroke.Parent = CleanButton

CleanResultLabel = Instance.new("TextLabel")
CleanResultLabel.Size = UDim2.new(1, 0, 0, 20)
CleanResultLabel.Position = UDim2.fromOffset(0, 326)
CleanResultLabel.BackgroundTransparency = 1
CleanResultLabel.Text = ""
CleanResultLabel.TextColor3 = YELLOW
CleanResultLabel.TextSize = 11
CleanResultLabel.Font = Enum.Font.GothamMedium
CleanResultLabel.TextXAlignment = Enum.TextXAlignment.Left
CleanResultLabel.Parent = BoostPage

--==================================================
-- PLAYER PAGE
--==================================================

PlayerPage = Instance.new("Frame")
PlayerPage.Size = BoostPage.Size
PlayerPage.Position = BoostPage.Position
PlayerPage.BackgroundTransparency = 1
PlayerPage.Visible = false
PlayerPage.Parent = Main

PlayerTitle = Instance.new("TextLabel")
PlayerTitle.Size = UDim2.new(1, 0, 0, 26)
PlayerTitle.BackgroundTransparency = 1
PlayerTitle.Text = "N E X U S  //  PLAYER"
PlayerTitle.TextColor3 = WHITE
PlayerTitle.TextSize = 15
PlayerTitle.Font = Enum.Font.GothamBold
PlayerTitle.TextXAlignment = Enum.TextXAlignment.Left
PlayerTitle.Parent = PlayerPage

SpeedStatus = Instance.new("TextLabel")
SpeedStatus.Size = UDim2.new(1, 0, 0, 24)
SpeedStatus.Position = UDim2.fromOffset(0, 34)
SpeedStatus.BackgroundTransparency = 1
SpeedStatus.Text = SpeedEnabled and "●  SPEED ACTIVE" or "●  SPEED DISABLED"
SpeedStatus.TextColor3 = SpeedEnabled and GREEN or RED
SpeedStatus.TextSize = 13
SpeedStatus.Font = Enum.Font.GothamBold
SpeedStatus.TextXAlignment = Enum.TextXAlignment.Left
SpeedStatus.Parent = PlayerPage

SpeedToggle = Instance.new("TextButton")
SpeedToggle.Size = UDim2.fromOffset(110, 42)
SpeedToggle.Position = UDim2.new(1, -110, 0, 28)
SpeedToggle.BackgroundColor3 = SpeedEnabled and Color3.fromRGB(15, 45, 30) or PANEL2
SpeedToggle.Text = SpeedEnabled and "ON" or "OFF"
SpeedToggle.TextColor3 = SpeedEnabled and GREEN or RED
SpeedToggle.TextSize = 14
SpeedToggle.Font = Enum.Font.GothamBold
SpeedToggle.AutoButtonColor = false
SpeedToggle.Parent = PlayerPage

SpeedToggleCorner = Instance.new("UICorner")
SpeedToggleCorner.CornerRadius = UDim.new(0, 8)
SpeedToggleCorner.Parent = SpeedToggle

SpeedToggleStroke = Instance.new("UIStroke")
SpeedToggleStroke.Color = PURPLE
SpeedToggleStroke.Thickness = 1.5
SpeedToggleStroke.Parent = SpeedToggle

SpeedLabel = Instance.new("TextLabel")
SpeedLabel.Size = UDim2.new(1, 0, 0, 24)
SpeedLabel.Position = UDim2.fromOffset(0, 92)
SpeedLabel.BackgroundTransparency = 1
SpeedLabel.Text = "SPEED"
SpeedLabel.TextColor3 = PURPLE
SpeedLabel.TextSize = 11
SpeedLabel.Font = Enum.Font.GothamBold
SpeedLabel.TextXAlignment = Enum.TextXAlignment.Left
SpeedLabel.Parent = PlayerPage

SpeedValueLabel = Instance.new("TextLabel")
SpeedValueLabel.Size = UDim2.new(1, 0, 0, 30)
SpeedValueLabel.Position = UDim2.fromOffset(0, 118)
SpeedValueLabel.BackgroundTransparency = 1
SpeedValueLabel.Text = "SPEED: " .. tostring(SpeedValue)
SpeedValueLabel.TextColor3 = WHITE
SpeedValueLabel.TextSize = 16
SpeedValueLabel.Font = Enum.Font.GothamBold
SpeedValueLabel.TextXAlignment = Enum.TextXAlignment.Center
SpeedValueLabel.Parent = PlayerPage

SliderBack = Instance.new("Frame")
SliderBack.Size = UDim2.new(1, -20, 0, 12)
SliderBack.Position = UDim2.fromOffset(10, 160)
SliderBack.BackgroundColor3 = PANEL2
SliderBack.BorderSizePixel = 0
SliderBack.Parent = PlayerPage

SliderBackCorner = Instance.new("UICorner")
SliderBackCorner.CornerRadius = UDim.new(1, 0)
SliderBackCorner.Parent = SliderBack

SliderFill = Instance.new("Frame")
SliderFill.Size = UDim2.new((SpeedValue - 20) / 380, 0, 1, 0)
SliderFill.BackgroundColor3 = PURPLE
SliderFill.BorderSizePixel = 0
SliderFill.Parent = SliderBack

SliderFillCorner = Instance.new("UICorner")
SliderFillCorner.CornerRadius = UDim.new(1, 0)
SliderFillCorner.Parent = SliderFill

SliderKnob = Instance.new("TextButton")
SliderKnob.Size = UDim2.fromOffset(22, 22)
SliderKnob.AnchorPoint = Vector2.new(0.5, 0.5)
SliderKnob.Position = UDim2.new((SpeedValue - 20) / 380, 0, 0.5, 0)
SliderKnob.BackgroundColor3 = PURPLE
SliderKnob.Text = ""
SliderKnob.AutoButtonColor = false
SliderKnob.Parent = SliderBack

SliderKnobCorner = Instance.new("UICorner")
SliderKnobCorner.CornerRadius = UDim.new(1, 0)
SliderKnobCorner.Parent = SliderKnob

SliderStroke = Instance.new("UIStroke")
SliderStroke.Color = WHITE
SliderStroke.Thickness = 1
SliderStroke.Parent = SliderKnob

SliderMin = Instance.new("TextLabel")
SliderMin.Size = UDim2.fromOffset(50, 20)
SliderMin.Position = UDim2.fromOffset(0, 180)
SliderMin.BackgroundTransparency = 1
SliderMin.Text = "20"
SliderMin.TextColor3 = WHITE
SliderMin.TextSize = 10
SliderMin.Font = Enum.Font.GothamMedium
SliderMin.TextXAlignment = Enum.TextXAlignment.Left
SliderMin.Parent = PlayerPage

SliderMax = Instance.new("TextLabel")
SliderMax.Size = UDim2.fromOffset(50, 20)
SliderMax.Position = UDim2.new(1, -50, 0, 180)
SliderMax.BackgroundTransparency = 1
SliderMax.Text = "400"
SliderMax.TextColor3 = WHITE
SliderMax.TextSize = 10
SliderMax.Font = Enum.Font.GothamMedium
SliderMax.TextXAlignment = Enum.TextXAlignment.Right
SliderMax.Parent = PlayerPage

SpeedHint = Instance.new("TextLabel")
SpeedHint.Size = UDim2.new(1, 0, 0, 40)
SpeedHint.Position = UDim2.fromOffset(0, 215)
SpeedHint.BackgroundTransparency = 1
SpeedHint.Text = "Arraste o controle para escolher de 20 até 400."
SpeedHint.TextColor3 = Color3.fromRGB(180, 170, 190)
SpeedHint.TextSize = 11
SpeedHint.Font = Enum.Font.GothamMedium
SpeedHint.TextXAlignment = Enum.TextXAlignment.Center
SpeedHint.Parent = PlayerPage


AimTitle = Instance.new("TextLabel")
AimTitle.Size = UDim2.new(1, 0, 0, 24)
AimTitle.Position = UDim2.fromOffset(0, 265)
AimTitle.BackgroundTransparency = 1
AimTitle.Text = "AIM LOCK"
AimTitle.TextColor3 = PURPLE
AimTitle.TextSize = 11
AimTitle.Font = Enum.Font.GothamBold
AimTitle.TextXAlignment = Enum.TextXAlignment.Left
AimTitle.Parent = PlayerPage

AimToggle = Instance.new("TextButton")
AimToggle.Size = UDim2.fromOffset(110, 38)
AimToggle.Position = UDim2.new(1, -110, 0, 258)
AimToggle.BackgroundColor3 = AimLockEnabled and Color3.fromRGB(15, 45, 30) or PANEL2
AimToggle.Text = AimLockEnabled and "ON" or "OFF"
AimToggle.TextColor3 = AimLockEnabled and GREEN or RED
AimToggle.TextSize = 13
AimToggle.Font = Enum.Font.GothamBold
AimToggle.AutoButtonColor = false
AimToggle.Parent = PlayerPage

AimToggleCorner = Instance.new("UICorner")
AimToggleCorner.CornerRadius = UDim.new(0, 8)
AimToggleCorner.Parent = AimToggle

AimToggleStroke = Instance.new("UIStroke")
AimToggleStroke.Color = PURPLE
AimToggleStroke.Thickness = 1.5
AimToggleStroke.Parent = AimToggle

AimHint = Instance.new("TextLabel")
AimHint.Size = UDim2.new(1, 0, 0, 45)
AimHint.Position = UDim2.fromOffset(0, 305)
AimHint.BackgroundTransparency = 1
AimHint.Text = "Botão flutuante fixo • arrastar: OFF"
AimHint.TextColor3 = Color3.fromRGB(180, 170, 190)
AimHint.TextSize = 10
AimHint.Font = Enum.Font.GothamMedium
AimHint.TextXAlignment = Enum.TextXAlignment.Center
AimHint.Parent = PlayerPage

function RefreshAimControls()
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


FlyTitle = Instance.new("TextLabel")
FlyTitle.Size = UDim2.new(1, 0, 0, 24)
FlyTitle.Position = UDim2.fromOffset(0, 355)
FlyTitle.BackgroundTransparency = 1
FlyTitle.Text = "FLY"
FlyTitle.TextColor3 = PURPLE
FlyTitle.TextSize = 11
FlyTitle.Font = Enum.Font.GothamBold
FlyTitle.TextXAlignment = Enum.TextXAlignment.Left
FlyTitle.Parent = PlayerPage

FlyToggle = Instance.new("TextButton")
FlyToggle.Size = UDim2.fromOffset(110, 38)
FlyToggle.Position = UDim2.new(1, -110, 0, 348)
FlyToggle.BackgroundColor3 = FlyEnabled and Color3.fromRGB(15, 45, 30) or PANEL2
FlyToggle.Text = FlyEnabled and "ON" or "OFF"
FlyToggle.TextColor3 = FlyEnabled and GREEN or RED
FlyToggle.TextSize = 13
FlyToggle.Font = Enum.Font.GothamBold
FlyToggle.AutoButtonColor = false
FlyToggle.Parent = PlayerPage

FlyToggleCorner = Instance.new("UICorner")
FlyToggleCorner.CornerRadius = UDim.new(0, 8)
FlyToggleCorner.Parent = FlyToggle

FlyToggleStroke = Instance.new("UIStroke")
FlyToggleStroke.Color = PURPLE
FlyToggleStroke.Thickness = 1.5
FlyToggleStroke.Parent = FlyToggle

FlyHint = Instance.new("TextLabel")
FlyHint.Size = UDim2.new(1, -8, 0, 35)
FlyHint.Position = UDim2.fromOffset(4, 393)
FlyHint.BackgroundTransparency = 1
FlyHint.Text = "Use o direcional + olhe para cima/baixo para voar"
FlyHint.TextColor3 = Color3.fromRGB(180, 170, 190)
FlyHint.TextSize = 9
FlyHint.Font = Enum.Font.GothamMedium
FlyHint.TextXAlignment = Enum.TextXAlignment.Center
FlyHint.Parent = PlayerPage

function RefreshFlyControls()
	FlyToggle.Text = FlyEnabled and "ON" or "OFF"
	FlyToggle.TextColor3 = FlyEnabled and GREEN or RED
	FlyToggle.BackgroundColor3 = FlyEnabled and Color3.fromRGB(15, 45, 30) or PANEL2
	RefreshFlyButton()
end

FlyToggle.MouseButton1Click:Connect(function()
	FlyEnabled = not FlyEnabled
	if FlyEnabled then
		if not StartFly() then FlyEnabled = false end
	else
		StopFly()
	end
	RefreshFlyControls()
	PersistConfig()
end)

--==================================================
-- INFO PAGE
--==================================================

InfoPage = Instance.new("Frame")
InfoPage.Size = BoostPage.Size
InfoPage.Position = BoostPage.Position
InfoPage.BackgroundTransparency = 1
InfoPage.Visible = false
InfoPage.Parent = Main

StatsText = Instance.new("TextLabel")
StatsText.Size = UDim2.new(1, 0, 0, 150)
StatsText.BackgroundTransparency = 1
StatsText.TextColor3 = WHITE
StatsText.TextSize = 13
StatsText.Font = Enum.Font.Code
StatsText.TextXAlignment = Enum.TextXAlignment.Left
StatsText.TextYAlignment = Enum.TextYAlignment.Top
StatsText.Text = "N E X U S  //  INFO"
StatsText.Parent = InfoPage

GraphTitle = Instance.new("TextLabel")
GraphTitle.Size = UDim2.new(1, 0, 0, 18)
GraphTitle.Position = UDim2.fromOffset(0, 155)
GraphTitle.BackgroundTransparency = 1
GraphTitle.Text = "FPS (últimos 40s)"
GraphTitle.TextColor3 = PURPLE
GraphTitle.TextSize = 11
GraphTitle.Font = Enum.Font.GothamBold
GraphTitle.TextXAlignment = Enum.TextXAlignment.Left
GraphTitle.Parent = InfoPage

GraphContainer = Instance.new("Frame")
GraphContainer.Size = UDim2.new(1, 0, 0, 110)
GraphContainer.Position = UDim2.fromOffset(0, 176)
GraphContainer.BackgroundColor3 = PANEL2
GraphContainer.BackgroundTransparency = 0.3
GraphContainer.Parent = InfoPage

GraphCorner = Instance.new("UICorner")
GraphCorner.CornerRadius = UDim.new(0, 8)
GraphCorner.Parent = GraphContainer

GraphStroke = Instance.new("UIStroke")
GraphStroke.Color = PURPLE
GraphStroke.Thickness = 1
GraphStroke.Transparency = 0.4
GraphStroke.Parent = GraphContainer

GraphLayout = Instance.new("UIListLayout")
GraphLayout.FillDirection = Enum.FillDirection.Horizontal
GraphLayout.VerticalAlignment = Enum.VerticalAlignment.Bottom
GraphLayout.HorizontalAlignment = Enum.HorizontalAlignment.Left
GraphLayout.Padding = UDim.new(0, 2)
GraphLayout.Parent = GraphContainer

MAX_BARS = 40
FPSHistory = {}
Bars = {}

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

--==================================================
-- TOGGLE / MODE / EXTRAS / RESTORE LOGIC
--==================================================

function UpdateToggle()
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
if EssentialOnly then ApplyEssentialOnly(true) end

--==================================================
-- PLAYER SPEED LOGIC
--==================================================

function SetSpeedValue(value)
	SpeedValue = math.clamp(math.floor(value + 0.5), 20, 400)
	local alpha = (SpeedValue - 20) / 380
	SpeedValueLabel.Text = "SPEED: " .. tostring(SpeedValue)
	SliderFill.Size = UDim2.new(alpha, 0, 1, 0)
	SliderKnob.Position = UDim2.new(alpha, 0, 0.5, 0)
	if SpeedEnabled then ApplySpeed() end
	PersistConfig()
end

SliderDragging = false

function UpdateSliderFromX(x)
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
	SpeedEnabled = not SpeedEnabled
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
NexusBootStatus("GUI criada • V20 FIX FINAL")
task.delay(2, function()
	pcall(function() NexusBootGui:Destroy() end)
end)

RefreshAimControls()
RefreshFlyControls()

--==================================================
-- TABS SWITCH
--==================================================

function SelectTab(tab)
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

--==================================================
-- MINIMIZAR
--==================================================

FullSize = Main.Size
MiniSize = UDim2.fromOffset(500, 50)

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

--==================================================
-- DRAGGING
--==================================================

Dragging = false
DragStart = nil
StartPosition = nil

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

--==================================================
-- FPS / PING / MEMORY / GRAPH
--==================================================

Frames = 0
LastFPSUpdate = os.clock()
FPS = 0
SessionStart = os.clock()

PingSamples = {}
PingMin, PingMax = math.huge, 0

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

print("NEXUS FPS BOOSTER V11 MAX+ iniciado.")


--==================================================
-- FINAL SAFETY
--==================================================
pcall(function()
	if AimLockEnabled then
		DisableLockOn()
	end
end)


end, function(err)
	return tostring(err)
end)

if not __NexusRunOk then
	NexusBootStatus("ERRO: " .. tostring(__NexusRunErr))
	warn("[NEXUS V20 FIX FINAL] " .. tostring(__NexusRunErr))
else
	NexusBootStatus("GUI criada • V20 FIX FINAL")
	task.delay(2, function()
		pcall(function() NexusBootGui:Destroy() end)
	end)
end


