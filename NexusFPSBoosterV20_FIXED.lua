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

-- V20 FIX: cleanup da execução anterior antes de criar novas conexões/GUI.
-- Evita duplicação de Heartbeat/RenderStep e artefatos de reload.
pcall(function()
	local previousCleanup = rawget(_G, "NexusFPSBoosterV20_Cleanup")
	if type(previousCleanup) == "function" then
		previousCleanup()
	end
end)

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
OriginalStreamingEnabled = nil
OriginalGlobalShadows = nil

pcall(function()
	OriginalStreamingRadius = Workspace.StreamingTargetRadius
	OriginalStreamingMinRadius = Workspace.StreamingMinRadius
	OriginalStreamingEnabled = Workspace.StreamingEnabled
	OriginalGlobalShadows = Lighting.GlobalShadows
end)

function SaveOriginal(obj)
	if not obj then return end
	if Backup[obj] then return end

	local data = {}
	if obj:IsA("SurfaceAppearance") then
		data.Parent = obj.Parent
	end

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

-- Garante que objetos criados enquanto o Booster estava OFF também tenham
-- o estado original salvo antes de qualquer boost futuro.
function EnsureBackupForCurrentObjects()
	for _, obj in ipairs(Workspace:GetDescendants()) do
		SaveOriginal(obj)
	end
	for _, obj in ipairs(Lighting:GetChildren()) do
		SaveOriginal(obj)
	end
	BackupCreated = true
end

function CreateBackup()
	EnsureBackupForCurrentObjects()
end

function RestoreObjectOriginal(obj, data)
	if not obj or not data then return end

	-- SurfaceAppearance removida pelo modo EXTREME volta ao parent original.
	if obj:IsA("SurfaceAppearance") and obj.Parent == nil and data.Parent and data.Parent.Parent then
		pcall(function() obj.Parent = data.Parent end)
	end

	if not obj.Parent then return end

	if obj:IsA("BasePart") then
		if data.Material ~= nil then obj.Material = data.Material end
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

function RestoreGraphics()
	for obj, data in pairs(Backup) do
		if obj then
			if obj.Parent or (obj:IsA("SurfaceAppearance") and data.Parent and data.Parent.Parent) then
				pcall(function() RestoreObjectOriginal(obj, data) end)
			else
				-- V20 FIX BUG-007: não manter referências de instâncias destruídas.
				Backup[obj] = nil
			end
		end
	end

	if OriginalGlobalShadows ~= nil then
		pcall(function() Lighting.GlobalShadows = OriginalGlobalShadows end)
	end
	if OriginalStreamingRadius ~= nil then
		pcall(function() Workspace.StreamingTargetRadius = OriginalStreamingRadius end)
	end
	if OriginalStreamingMinRadius ~= nil then
		pcall(function() Workspace.StreamingMinRadius = OriginalStreamingMinRadius end)
	end
	if OriginalStreamingEnabled ~= nil then
		pcall(function() Workspace.StreamingEnabled = OriginalStreamingEnabled end)
	end
	BoosterEnabled = false
end

--==================================================
-- BOOST
--==================================================

function ApplyBoostToObject(obj)
	local Config = Modes[CurrentMode]
	local data = Backup[obj]

	-- V20 FIX BUG-006:
	-- antes de aplicar o modo atual, volta o objeto ao snapshot original.
	-- Assim LOW -> ULTRA -> LOW ou ULTRA -> LOW não deixa resíduos do modo anterior.
	if data then
		pcall(function() RestoreObjectOriginal(obj, data) end)
	end

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
	EnsureBackupForCurrentObjects()

	-- Restaura temporariamente itens removidos pelo modo EXTREME para que
	-- um downgrade consiga encontrá-los e reaplicar o modo atual.
	for obj, data in pairs(Backup) do
		if obj and obj:IsA("SurfaceAppearance") and obj.Parent == nil and data.Parent and data.Parent.Parent then
			pcall(function() obj.Parent = data.Parent end)
		end
	end

	for _, obj in ipairs(Workspace:GetDescendants()) do
		ApplyBoostToObject(obj)
	end

	local Config = Modes[CurrentMode]

	if not Config.Effects then
		for _, obj in ipairs(Lighting:GetChildren()) do
			-- Restaura primeiro para que downgrade também reverta o modo anterior.
			local data = Backup[obj]
			if data then pcall(function() RestoreObjectOriginal(obj, data) end) end
			if obj:IsA("PostEffect") then obj.Enabled = false end
		end
	end

	if not Config.Shadows then
		Lighting.GlobalShadows = false
	else
		if OriginalGlobalShadows ~= nil then
			Lighting.GlobalShadows = OriginalGlobalShadows
		end
	end
end

-- V20 FIX BUG-004:
-- salva o estado original mesmo com o Booster desligado.
Workspace.DescendantAdded:Connect(function(obj)
	task.defer(function()
		pcall(function()
			SaveOriginal(obj)
			if BoosterEnabled then
				ApplyBoostToObject(obj)
			end
		end)
	end)
end)

-- V20 FIX BUG-007: remove referências de instâncias que saíram do jogo.
Workspace.DescendantRemoving:Connect(function(obj)
	Backup[obj] = nil
end)
Lighting.ChildRemoved:Connect(function(obj)
	Backup[obj] = nil
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
do
	local oldSpeedConnection = rawget(_G, "NexusFPSBoosterV20_SpeedHeartbeatConnection")
	if oldSpeedConnection then
		pcall(function() oldSpeedConnection:Disconnect() end)
	end
end
SpeedHeartbeatConnection = RunService.Heartbeat:Connect(function()
	if SpeedEnabled or AimLockEnabled then
		ApplySpeed()
	end
end)
_G.NexusFPSBoosterV20_SpeedHeartbeatConnection = SpeedHeartbeatConnection

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

--==================================================
-- COMPLETE AUDIT / BUGFIX BUILD
-- Critical fixes: restored missing AimLock core, release toggle,
-- speed bonus lifecycle, graphics restore state, and UI interactability.
--==================================================
-- AIM LOCK CORE (restored)
--==================================================
-- The previous FIXED build kept the UI callbacks but lost the actual
-- Enable/Disable/Update functions. That made the button call nil.
AimTargetRoot = nil
AimTarget = nil
AimLockPreviousCameraType = nil
AimLockPreviousCameraSubject = nil
AimLockPreviousAutoRotate = nil
AimLockLastTargetAt = 0
AimLockTargetSwitchCooldown = 0
AimLockSelfMarker = nil

local function GetAimLocalCharacter()
	local character = Player and Player.Character
	local humanoid = character and character:FindFirstChildOfClass('Humanoid')
	local root = character and character:FindFirstChild('HumanoidRootPart')
	if not character or not humanoid or humanoid.Health <= 0 or not root then
		return nil, nil, nil
	end
	return character, humanoid, root
end

function IsCurrentTargetValid()
	local target = AimTarget
	local root = AimTargetRoot
	if not target or not root or not root.Parent then return false end
	local humanoid = target:FindFirstChildOfClass('Humanoid')
	return humanoid ~= nil and humanoid.Health > 0
end

local function IsTargetVisible(root, origin)
	if not LOCKON_REQUIRE_VISIBLE_ON_ACQUIRE then return true end
	local params = RaycastParams.new()
	params.FilterType = Enum.RaycastFilterType.Exclude
	params.FilterDescendantsInstances = {Player.Character}
	params.IgnoreWater = true
	local direction = root.Position - origin
	local hit = Workspace:Raycast(origin, direction, params)
	return hit == nil or hit.Instance:IsDescendantOf(root.Parent)
end

local function FindBestAimTarget()
	local camera = Workspace.CurrentCamera
	local _, _, localRoot = GetAimLocalCharacter()
	if not camera or not localRoot then return nil, nil end

	local viewport = camera.ViewportSize
	local center = Vector2.new(viewport.X * 0.5, viewport.Y * 0.5)
	local bestPlayer, bestRoot, bestScore = nil, nil, math.huge

	for _, other in ipairs(Players:GetPlayers()) do
		if other ~= Player then
			local character = other.Character
			local humanoid = character and character:FindFirstChildOfClass('Humanoid')
			local root = character and character:FindFirstChild('HumanoidRootPart')
			if humanoid and humanoid.Health > 0 and root then
				local offset = root.Position - localRoot.Position
				local distance = offset.Magnitude
				if distance <= LOCKON_RANGE and distance <= LOCKON_MAX_FOLLOW_DISTANCE then
					local direction = offset.Unit
					local dot = math.clamp(camera.CFrame.LookVector:Dot(direction), -1, 1)
					local angle = math.acos(dot)
					if angle <= LOCKON_ACQUIRE_ANGLE then
						local screenPoint, onScreen = camera:WorldToViewportPoint(root.Position)
						if onScreen and screenPoint.Z > 0 then
							local screenDistance = (Vector2.new(screenPoint.X, screenPoint.Y) - center).Magnitude
							local visible = IsTargetVisible(root, camera.CFrame.Position)
							if visible then
								local score = screenDistance + distance * 0.15
								if score < bestScore then
									bestScore = score
									bestPlayer = character
									bestRoot = root
								end
							end
						end
					end
				end
			end
		end
	end
	return bestPlayer, bestRoot
end

function ClearLockOn()
	AimTarget = nil
	AimTargetRoot = nil
	AimLockLastTargetAt = 0
	if AimLockSelfMarker then
		pcall(function() AimLockSelfMarker:Destroy() end)
		AimLockSelfMarker = nil
	end
end

function CreateSelfMarker(character)
	if AimLockSelfMarker then
		pcall(function() AimLockSelfMarker:Destroy() end)
	end
	local root = character and character:FindFirstChild('HumanoidRootPart')
	if not root then return end
	local marker = Instance.new('Highlight')
	marker.Name = 'NexusAimSelfMarker'
	marker.FillTransparency = 1
	marker.OutlineTransparency = 0.25
	marker.OutlineColor = PURPLE
	marker.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
	marker.Adornee = character
	marker.Parent = Gui or character
	AimLockSelfMarker = marker
end

function EnableLockOn()
	if AimLockEnabled then return true end
	local character, humanoid = GetAimLocalCharacter()
	if not character or not humanoid then
		warn('[NEXUS V4] AimLock: personagem inválido')
		return false
	end

	local target, root = FindBestAimTarget()
	local camera = Workspace.CurrentCamera
	AimLockPreviousCameraType = camera and camera.CameraType or nil
	AimLockPreviousCameraSubject = camera and camera.CameraSubject or nil
	AimLockPreviousAutoRotate = humanoid.AutoRotate

	AimTarget = target
	AimTargetRoot = root
	AimLockEnabled = true
	AimLockLastTargetAt = os.clock()
	humanoid.AutoRotate = false
	if camera then camera.CameraType = Enum.CameraType.Scriptable end
	ApplySpeed()
	CreateSelfMarker(character)
	ResetAutoBlockAnalysis('aim_enabled')
	AutoBlockManualRelease = false
	print('[NEXUS V4] AimLock ON' .. (target and (' -> ' .. tostring(target.Name)) or ' -> aguardando alvo'))
	return true
end

function DisableLockOn()
	local _, humanoid = GetAimLocalCharacter()
	local camera = Workspace.CurrentCamera
	AimLockEnabled = false
	if humanoid and AimLockPreviousAutoRotate ~= nil then
		humanoid.AutoRotate = AimLockPreviousAutoRotate
	end
	if camera then
		if AimLockPreviousCameraType then
			camera.CameraType = AimLockPreviousCameraType
		else
			camera.CameraType = Enum.CameraType.Custom
		end
		if AimLockPreviousCameraSubject and AimLockPreviousCameraSubject.Parent then
			camera.CameraSubject = AimLockPreviousCameraSubject
		elseif humanoid then
			camera.CameraSubject = humanoid
		end
	end
	AimLockPreviousCameraType = nil
	AimLockPreviousCameraSubject = nil
	AimLockPreviousAutoRotate = nil
	ClearLockOn()
	AutoBlockManualRelease = false
	ResetAutoBlockAnalysis('aim_disabled')
	ApplySpeed()
	print('[NEXUS V4] AimLock OFF')
end

function UpdateAimLock(dt)
	if not AimLockEnabled then return end
	local character, humanoid, localRoot = GetAimLocalCharacter()
	local camera = Workspace.CurrentCamera
	if not character or not humanoid or not localRoot or not camera then
		DisableLockOn()
		return
	end

	if not IsCurrentTargetValid() then
		local newTarget, newRoot = FindBestAimTarget()
		if newTarget and newRoot then
			AimTarget, AimTargetRoot = newTarget, newRoot
		else
			DisableLockOn()
			return
		end
	end

	local targetPosition = AimTargetRoot.Position
	local targetVelocity = AimTargetRoot.AssemblyLinearVelocity
	if LOCKON_PREDICTION then
		targetPosition += Vector3.new(targetVelocity.X, 0, targetVelocity.Z) * math.min(LOCKON_PREDICTION_TIME, LOCKON_MAX_PREDICTION / math.max(targetVelocity.Magnitude, 1))
	end

	local flatTarget = Vector3.new(targetPosition.X, localRoot.Position.Y, targetPosition.Z)
	local flat = flatTarget - localRoot.Position
	if flat.Magnitude > 0.001 then
		local turnAlpha = 1 - math.exp(-LOCKON_FACING_SMOOTH * math.clamp(dt, 1/240, 0.1))
		local desired = CFrame.lookAt(localRoot.Position, localRoot.Position + flat.Unit)
		localRoot.CFrame = localRoot.CFrame:Lerp(desired, turnAlpha)
	end

	local midpoint = (localRoot.Position + targetPosition) * 0.5 + Vector3.new(0, LOCKON_LOOK_HEIGHT, 0)
	local distance = math.clamp((localRoot.Position - targetPosition).Magnitude + LOCKON_EXTRA_DISTANCE, LOCKON_MIN_DISTANCE, LOCKON_MAX_DISTANCE)
	local direction = (targetPosition - localRoot.Position)
	if direction.Magnitude < 0.001 then direction = Vector3.new(0, 0, -1) end
	direction = direction.Unit
	local cameraPosition = localRoot.Position - direction * distance + Vector3.new(0, LOCKON_CAMERA_HEIGHT, 0)
	local desiredCamera = CFrame.lookAt(cameraPosition, midpoint)
	local cameraAlpha = 1 - math.exp(-LOCKON_CAMERA_SMOOTH * math.clamp(dt, 1/240, 0.1))
	camera.CFrame = camera.CFrame:Lerp(desiredCamera, cameraAlpha)
	camera.Focus = CFrame.new(midpoint)
end

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
--==================================================
-- GOD AUTO BLOCK V4
-- CombatCore/Claude principles merged into V3:
-- motion history, relative motion, acceleration, prediction,
-- TTC, confidence, threat hysteresis, confirmation frames,
-- explicit state machine, recovery and lifecycle reset.
--
-- Block execution is intentionally exposed as an adapter callback
-- for the user's own test arena:
--     _G.NexusV4_SetBlock(true/false)
--==================================================
AUTO_BLOCK_ENABLED = true
AUTO_BLOCK_DISTANCE = 12
AUTO_BLOCK_RELEASE_DISTANCE = 15
AUTO_BLOCK_DASH_DISTANCE = 18
AUTO_BLOCK_MIN_APPROACH_SPEED = 18
AUTO_BLOCK_DASH_SPEED = 48
AUTO_BLOCK_REACTION_TIME = 0.06
AUTO_BLOCK_ATTACK_SUPPRESS = 0.12

-- CombatCore-derived thresholds
AUTO_BLOCK_TTC_DANGER = 0.45
AUTO_BLOCK_TTC_EMERGENCY = 0.15
AUTO_BLOCK_PREDICTION_MIN = 0.05
AUTO_BLOCK_PREDICTION_MAX = 0.30
AUTO_BLOCK_MOTION_HISTORY = 10
AUTO_BLOCK_CONFIRM_FRAMES = 2
AUTO_BLOCK_ENTER = 0.66
AUTO_BLOCK_MAINTAIN = 0.42
AUTO_BLOCK_EXIT = 0.24
AUTO_BLOCK_MIN_CONFIDENCE = 0.50
AUTO_BLOCK_MAX_TARGET_DISTANCE = 40
AUTO_BLOCK_MIN_BLOCK_TIME = 0.10
AUTO_BLOCK_RECOVERY_TIME = 0.08
AUTO_BLOCK_EMERGENCY_SCORE = 0.88
AUTO_BLOCK_UPDATE_INTERVAL = 0.0

-- Adaptive score smoothing / momentum
AUTO_BLOCK_THREAT_RISE = 0.65
AUTO_BLOCK_THREAT_DECAY = 0.12
AUTO_BLOCK_CONFIDENCE_RISE = 0.35
AUTO_BLOCK_CONFIDENCE_DECAY = 0.18
AUTO_BLOCK_ACCEL_THRESHOLD = 55
AUTO_BLOCK_DASH_DELTA_SPEED = 10

AutoBlockActive = false
AutoBlockThreat = 0
AutoBlockConfidence = 0
AutoBlockTTC = math.huge
AutoBlockApproach = 0
AutoBlockTargetSpeed = 0
AutoBlockAcceleration = 0
AutoBlockPrediction = 0
AutoBlockState = 'IDLE'
AutoBlockStateSince = 0
AutoBlockConfirmCount = 0
AutoBlockLastStart = 0
AutoBlockLastRelease = 0
AutoBlockManualRelease = false
AutoBlockAttackUntil = 0
AutoBlockAttackAnimUntil = 0
AutoBlockLastAnimScan = 0
AutoBlockAttackConnection = nil
AutoBlockLastUpdate = 0
AutoBlockLastTarget = nil
AutoBlockMotion = {}
AutoBlockBound = false
AutoBlockHeartbeatConnection = nil

--==================================================
-- BLOCK ADAPTER
--==================================================

-- BLOCK/UNBLOCK adapter for the user's own test arena.
-- Priority:
--   1) use explicit _G.NexusV4_Block / _G.NexusV4_Unblock callbacks;
--   2) otherwise use the existing NexusV4_SetBlock callback;
--   3) otherwise report that no arena block handler is connected.
-- Captura os callbacks reais ANTES de instalar o adapter.
-- BUG-001 FIX: o adapter nunca consulta novamente o slot global que ele próprio ocupa.
local PreviousNexusV4Block = rawget(_G, "NexusV4_Block")
local PreviousNexusV4Unblock = rawget(_G, "NexusV4_Unblock")
local PreviousNexusV4SetBlock = rawget(_G, "NexusV4_SetBlock")

-- Se a execução anterior deste próprio script deixou um adapter instalado,
-- recupera os callbacks originais guardados no global.
if rawget(_G, "NexusFPSBoosterV20_BlockAdapterInstalled") then
	PreviousNexusV4Block = rawget(_G, "NexusFPSBoosterV20_PreviousBlock")
	PreviousNexusV4Unblock = rawget(_G, "NexusFPSBoosterV20_PreviousUnblock")
	PreviousNexusV4SetBlock = rawget(_G, "NexusFPSBoosterV20_PreviousSetBlock")
end

local NexusV4_BlockUnblockAdapter = {
	block = function()
		if type(PreviousNexusV4Block) == "function" then
			local ok, err = pcall(PreviousNexusV4Block)
			if not ok then warn("[NEXUS V4] Block callback error:", err) end
			return ok
		end

		if type(PreviousNexusV4SetBlock) == "function" then
			local ok, err = pcall(PreviousNexusV4SetBlock, true)
			if not ok then warn("[NEXUS V4] SetBlock(true) error:", err) end
			return ok
		end

		warn("[NEXUS V4] BLOCK requested, but no Block handler is connected.")
		return false
	end,

	unblock = function()
		if type(PreviousNexusV4Unblock) == "function" then
			local ok, err = pcall(PreviousNexusV4Unblock)
			if not ok then warn("[NEXUS V4] Unblock callback error:", err) end
			return ok
		end

		if type(PreviousNexusV4SetBlock) == "function" then
			local ok, err = pcall(PreviousNexusV4SetBlock, false)
			if not ok then warn("[NEXUS V4] SetBlock(false) error:", err) end
			return ok
		end

		warn("[NEXUS V4] UNBLOCK requested, but no Unblock handler is connected.")
		return false
	end,
}

_G.NexusFPSBoosterV20_PreviousBlock = PreviousNexusV4Block
_G.NexusFPSBoosterV20_PreviousUnblock = PreviousNexusV4Unblock
_G.NexusFPSBoosterV20_PreviousSetBlock = PreviousNexusV4SetBlock
_G.NexusFPSBoosterV20_BlockAdapterInstalled = true

_G.NexusV4_Block = NexusV4_BlockUnblockAdapter.block
_G.NexusV4_Unblock = NexusV4_BlockUnblockAdapter.unblock

function NexusV4_SetBlockOutput(active)
    if active then
        return NexusV4_BlockUnblockAdapter.block()
    else
        return NexusV4_BlockUnblockAdapter.unblock()
    end
end

function ResetAutoBlockAnalysis(reason)
	AutoBlockThreat = 0
	AutoBlockConfidence = 0
	AutoBlockTTC = math.huge
	AutoBlockApproach = 0
	AutoBlockTargetSpeed = 0
	AutoBlockAcceleration = 0
	AutoBlockPrediction = 0
	AutoBlockConfirmCount = 0
	AutoBlockManualRelease = false
	AutoBlockState = 'IDLE'
	AutoBlockStateSince = os.clock()
	AutoBlockLastTarget = nil
	table.clear(AutoBlockMotion)
	if AutoBlockActive then
		if NexusV4_SetBlockOutput(false) then
			AutoBlockActive = false
		end
	end
end

function SetAutoBlockState(active)
	if active == AutoBlockActive then return true end

	-- BUG-002 FIX: só altera o estado interno depois que o comando externo
	-- foi realmente executado. O adapter retorna false em caso de falha.
	local ok = NexusV4_SetBlockOutput(active)
	if not ok then
		pcall(RefreshAimLockButton)
		return false
	end

	AutoBlockActive = active
	if active then
		AutoBlockLastStart = os.clock()
	else
		AutoBlockLastRelease = os.clock()
	end
	pcall(RefreshAimLockButton)
	return true
end

function MarkLocalAttack()
	AutoBlockAttackUntil = math.max(AutoBlockAttackUntil, os.clock() + AUTO_BLOCK_ATTACK_SUPPRESS)
end

function IsLocalAttackAnimationPlaying()
	local now = os.clock()
	if now - AutoBlockLastAnimScan < 0.05 then
		return now < AutoBlockAttackAnimUntil
	end
	AutoBlockLastAnimScan = now

	local character = Player.Character
	local humanoid = character and character:FindFirstChildOfClass('Humanoid')
	local animator = humanoid and humanoid:FindFirstChildOfClass('Animator')
	if not animator then return now < AutoBlockAttackAnimUntil end

	local attacking = false
	local ok, tracks = pcall(function() return animator:GetPlayingAnimationTracks() end)
	if not ok then return now < AutoBlockAttackAnimUntil end
	for _, track in ipairs(tracks) do
		if track.IsPlaying then
			local name = string.lower(tostring(track.Name or ''))
			local animationName = ''
			pcall(function()
				animationName = string.lower(tostring(track.Animation and track.Animation.Name or ''))
			end)
			local attackName = name .. ' ' .. animationName
			if attackName:find('attack', 1, true)
				or attackName:find('punch', 1, true)
				or attackName:find('strike', 1, true)
				or attackName:find('swing', 1, true)
				or attackName:find('combo', 1, true)
				or attackName:find('m1', 1, true) then
				attacking = true
				break
			end
		end
	end

	if attacking then
		AutoBlockAttackAnimUntil = now + AUTO_BLOCK_ATTACK_SUPPRESS
	else
		AutoBlockAttackAnimUntil = math.min(AutoBlockAttackAnimUntil, now)
	end
	return attacking or now < AutoBlockAttackAnimUntil
end

function IsLocalAttacking()
	return os.clock() < AutoBlockAttackUntil or IsLocalAttackAnimationPlaying()
end

if AutoBlockAttackConnection then
	pcall(function() AutoBlockAttackConnection:Disconnect() end)
	AutoBlockAttackConnection = nil
end
AutoBlockAttackConnection = UserInputService.InputBegan:Connect(function(Input, gameProcessed)
	if gameProcessed then return end
	if Input.UserInputType == Enum.UserInputType.MouseButton1
		or Input.KeyCode == Enum.KeyCode.ButtonR2 then
		MarkLocalAttack()
	end
end)

--==================================================
-- MOTION / PREDICTION
--==================================================
local function GetFlatVelocity(part)
	if not part then return Vector3.zero end
	local v = part.AssemblyLinearVelocity
	return Vector3.new(v.X, 0, v.Z)
end

local function PushMotionSample(position, velocity, now)
	table.insert(AutoBlockMotion, {p = position, v = velocity, t = now})
	while #AutoBlockMotion > AUTO_BLOCK_MOTION_HISTORY do
		table.remove(AutoBlockMotion, 1)
	end
end

local function GetMotionStats(targetRoot, localRoot, dt)
	local now = os.clock()
	local targetVelocity = GetFlatVelocity(targetRoot)
	local offset = localRoot.Position - targetRoot.Position
	local distance = offset.Magnitude
	local toPlayer = distance > 0.001 and offset.Unit or Vector3.zero
	local targetSpeed = targetVelocity.Magnitude
	local approach = targetSpeed > 0.1 and targetVelocity.Unit:Dot(toPlayer) or 0

	local previous = AutoBlockMotion[#AutoBlockMotion]
	local acceleration = 0
	local deltaSpeed = 0
	if previous and now > previous.t then
		local elapsed = math.max(now - previous.t, 1/240)
		deltaSpeed = targetSpeed - previous.v.Magnitude
		acceleration = deltaSpeed / elapsed
	end

	PushMotionSample(targetRoot.Position, targetVelocity, now)

	local dashFactor = 0
	if targetSpeed >= AUTO_BLOCK_DASH_SPEED then
		dashFactor = math.clamp((targetSpeed - AUTO_BLOCK_DASH_SPEED) / 35, 0, 1)
	end
	if acceleration >= AUTO_BLOCK_ACCEL_THRESHOLD then
		dashFactor = math.max(dashFactor, 0.75)
	elseif deltaSpeed >= AUTO_BLOCK_DASH_DELTA_SPEED then
		dashFactor = math.max(dashFactor, 0.55)
	end

	local prediction = math.clamp(
		AUTO_BLOCK_PREDICTION_MIN + targetSpeed * 0.0022 + math.max(acceleration, 0) * 0.0008,
		AUTO_BLOCK_PREDICTION_MIN,
		AUTO_BLOCK_PREDICTION_MAX
	)

	local predictedPosition = targetRoot.Position + targetVelocity * prediction
	local predictedOffset = localRoot.Position - predictedPosition
	local predictedDistance = predictedOffset.Magnitude

	local closingSpeed = math.max(0, targetSpeed * approach)
	local ttc = math.huge
	if closingSpeed > 0.1 then
		ttc = math.max(0, distance / closingSpeed)
	end

	return {
		distance = distance,
		targetSpeed = targetSpeed,
		approach = approach,
		acceleration = acceleration,
		deltaSpeed = deltaSpeed,
		dashFactor = dashFactor,
		prediction = prediction,
		predictedDistance = predictedDistance,
		ttc = ttc,
	}
end

--==================================================
-- THREAT / CONFIDENCE
--==================================================
function GetAutoBlockAnalysis(dt)
	if not AUTO_BLOCK_ENABLED or not AimLockEnabled then return nil end
	if AutoBlockManualRelease or IsLocalAttacking() then return nil end
	if not IsCurrentTargetValid() or not AimTargetRoot then return nil end

	local character = Player.Character
	local localRoot = character and character:FindFirstChild('HumanoidRootPart')
	if not localRoot then return nil end

	local stats = GetMotionStats(AimTargetRoot, localRoot, dt)
	if stats.distance > AUTO_BLOCK_MAX_TARGET_DISTANCE then return nil end

	local distanceThreat = 1 - math.clamp(stats.predictedDistance / AUTO_BLOCK_DISTANCE, 0, 1)
	local approachThreat = 0
	if stats.approach >= 0.35 and stats.targetSpeed >= AUTO_BLOCK_MIN_APPROACH_SPEED then
		approachThreat = math.clamp((stats.approach - 0.35) / 0.65, 0, 1)
	end

	local dashThreat = stats.dashFactor
	local ttcThreat = 0
	if stats.ttc < math.huge then
		if stats.ttc <= AUTO_BLOCK_TTC_EMERGENCY then
			ttcThreat = 1
		elseif stats.ttc <= AUTO_BLOCK_TTC_DANGER then
			ttcThreat = 1 - math.clamp((stats.ttc - AUTO_BLOCK_TTC_EMERGENCY) / (AUTO_BLOCK_TTC_DANGER - AUTO_BLOCK_TTC_EMERGENCY), 0, 1)
		end
	end

	local accelerationThreat = math.clamp(math.max(stats.acceleration, 0) / AUTO_BLOCK_ACCEL_THRESHOLD, 0, 1)

	local threat =
		distanceThreat * 0.20 +
		approachThreat * 0.28 +
		dashThreat * 0.22 +
		ttcThreat * 0.25 +
		accelerationThreat * 0.05

	if stats.distance <= AUTO_BLOCK_DISTANCE
		and stats.approach >= 0.60
		and stats.targetSpeed >= AUTO_BLOCK_MIN_APPROACH_SPEED then
		threat = math.max(threat, 0.80)
	end
	if stats.ttc <= AUTO_BLOCK_TTC_EMERGENCY
		and stats.approach >= 0.50 then
		threat = math.max(threat, 0.95)
	end

	-- Confidence: stable target + valid motion history + meaningful approach.
	local confidence = 0.45
	if AutoBlockLastTarget == AimTargetRoot then confidence += 0.20 end
	if #AutoBlockMotion >= 3 then confidence += 0.15 end
	if stats.targetSpeed >= 2 then confidence += 0.10 end
	if math.abs(stats.approach) >= 0.35 then confidence += 0.10 end
	if stats.distance <= AUTO_BLOCK_MAX_TARGET_DISTANCE then confidence += 0.05 end
	confidence = math.clamp(confidence, 0, 1)

	AutoBlockLastTarget = AimTargetRoot

	return {
		threat = math.clamp(threat, 0, 1),
		confidence = confidence,
		distance = stats.distance,
		targetSpeed = stats.targetSpeed,
		approach = stats.approach,
		acceleration = stats.acceleration,
		dashFactor = stats.dashFactor,
		prediction = stats.prediction,
		ttc = stats.ttc,
	}
end

function GetAutoBlockThreat()
	local analysis = GetAutoBlockAnalysis(1/60)
	return analysis and analysis.threat or 0
end

function FaceTargetForAutoBlock(dt)
	local character = Player.Character
	local root = character and character:FindFirstChild('HumanoidRootPart')
	local humanoid = character and character:FindFirstChildOfClass('Humanoid')
	if not root or not humanoid or humanoid.Health <= 0 or not AimTargetRoot then return end
	local flat = Vector3.new(AimTargetRoot.Position.X - root.Position.X, 0, AimTargetRoot.Position.Z - root.Position.Z)
	if flat.Magnitude < 0.001 then return end
	local desired = CFrame.lookAt(root.Position, root.Position + flat.Unit)
	local alpha = 1 - math.exp(-38 * math.clamp(dt, 1/240, 1/20))
	root.CFrame = root.CFrame:Lerp(desired, alpha)
end

--==================================================
-- STATE MACHINE
--==================================================
local function EnterAutoBlockState(state)
	if AutoBlockState == state then return end
	AutoBlockState = state
	AutoBlockStateSince = os.clock()
	if state == 'BLOCK' then
		SetAutoBlockState(true)
	elseif state == 'RECOVERY' or state == 'IDLE' or state == 'WATCH' then
		SetAutoBlockState(false)
	end
end

function UpdateAutoBlock(dt)
	EnsureCombatButtonsVisible()
	if not AUTO_BLOCK_ENABLED or not AimLockEnabled then
		ResetAutoBlockAnalysis('disabled')
		return
	end

	local now = os.clock()
	if now - AutoBlockLastUpdate < AUTO_BLOCK_UPDATE_INTERVAL then return end
	AutoBlockLastUpdate = now

	local character = Player.Character
	local humanoid = character and character:FindFirstChildOfClass('Humanoid')
	local localRoot = character and character:FindFirstChild('HumanoidRootPart')
	if not humanoid or humanoid.Health <= 0 or not localRoot or not AimTargetRoot then
		ResetAutoBlockAnalysis('invalid_character')
		return
	end

	if IsLocalAttacking() then
		AutoBlockThreat = 0
		AutoBlockConfirmCount = 0
		EnterAutoBlockState('WATCH')
		return
	end

	local distance = (localRoot.Position - AimTargetRoot.Position).Magnitude
	if AutoBlockManualRelease then
		AutoBlockThreat = 0
		AutoBlockConfirmCount = 0
		EnterAutoBlockState('WATCH')
		if distance > AUTO_BLOCK_RELEASE_DISTANCE then
			AutoBlockManualRelease = false
		end
		return
	end

	local analysis = GetAutoBlockAnalysis(dt)
	if not analysis then
		AutoBlockThreat = AutoBlockThreat * math.exp(-AUTO_BLOCK_THREAT_DECAY * math.max(dt, 0))
		AutoBlockConfidence = AutoBlockConfidence * math.exp(-AUTO_BLOCK_CONFIDENCE_DECAY * math.max(dt, 0))
		if AutoBlockActive and distance > AUTO_BLOCK_RELEASE_DISTANCE and now - AutoBlockLastStart >= AUTO_BLOCK_MIN_BLOCK_TIME then
			EnterAutoBlockState('RECOVERY')
		end
		return
	end

	-- Momentum filter: threat rises quickly but decays deliberately.
	local threatAlpha = analysis.threat >= AutoBlockThreat and AUTO_BLOCK_THREAT_RISE or AUTO_BLOCK_THREAT_DECAY
	AutoBlockThreat += (analysis.threat - AutoBlockThreat) * math.clamp(threatAlpha * math.max(dt * 60, 0.5), 0, 1)
	local confAlpha = analysis.confidence >= AutoBlockConfidence and AUTO_BLOCK_CONFIDENCE_RISE or AUTO_BLOCK_CONFIDENCE_DECAY
	AutoBlockConfidence += (analysis.confidence - AutoBlockConfidence) * math.clamp(confAlpha * math.max(dt * 60, 0.5), 0, 1)

	AutoBlockTTC = analysis.ttc
	AutoBlockApproach = analysis.approach
	AutoBlockTargetSpeed = analysis.targetSpeed
	AutoBlockAcceleration = analysis.acceleration
	AutoBlockPrediction = analysis.prediction

	local emergency = analysis.ttc <= AUTO_BLOCK_TTC_EMERGENCY and analysis.threat >= AUTO_BLOCK_EMERGENCY_SCORE
	local enterCandidate = AutoBlockThreat >= AUTO_BLOCK_ENTER and AutoBlockConfidence >= AUTO_BLOCK_MIN_CONFIDENCE

	if emergency then
		AutoBlockConfirmCount = AUTO_BLOCK_CONFIRM_FRAMES
	elseif enterCandidate then
		AutoBlockConfirmCount += 1
	else
		AutoBlockConfirmCount = math.max(0, AutoBlockConfirmCount - 1)
	end

	if AutoBlockState == 'IDLE' then
		if AutoBlockThreat >= AUTO_BLOCK_EXIT then
			EnterAutoBlockState('WATCH')
		end
	elseif AutoBlockState == 'WATCH' then
		if AutoBlockConfirmCount >= AUTO_BLOCK_CONFIRM_FRAMES or emergency then
			EnterAutoBlockState('THREAT')
		end
	elseif AutoBlockState == 'THREAT' then
		FaceTargetForAutoBlock(dt)
		if AutoBlockThreat >= AUTO_BLOCK_MAINTAIN and AutoBlockConfidence >= AUTO_BLOCK_MIN_CONFIDENCE then
			EnterAutoBlockState('BLOCK')
		elseif AutoBlockThreat < AUTO_BLOCK_EXIT then
			EnterAutoBlockState('RECOVERY')
		end
	elseif AutoBlockState == 'BLOCK' then
		FaceTargetForAutoBlock(dt)
		if now - AutoBlockLastStart < AUTO_BLOCK_MIN_BLOCK_TIME then return end
		if AutoBlockThreat < AUTO_BLOCK_MAINTAIN and distance > AUTO_BLOCK_RELEASE_DISTANCE then
			EnterAutoBlockState('RECOVERY')
		end
	elseif AutoBlockState == 'RECOVERY' then
		if now - AutoBlockStateSince >= AUTO_BLOCK_RECOVERY_TIME then
			if AutoBlockThreat >= AUTO_BLOCK_ENTER and AutoBlockConfidence >= AUTO_BLOCK_MIN_CONFIDENCE then
				EnterAutoBlockState('THREAT')
			else
				EnterAutoBlockState('WATCH')
			end
		end
	end
end

function EnsureCombatButtonsVisible()
	if Gui and Gui.Parent then
		if AimLockButton then AimLockButton.Visible = true end
		if AutoBlockReleaseButton then AutoBlockReleaseButton.Visible = true end
		if GodModeBadge then GodModeBadge.Visible = true end
		if AutoBlockBadge then AutoBlockBadge.Visible = true end
	end
end

function BindAutoBlockInput()
	AutoBlockBound = true
end

function UnbindAutoBlockInput()
	AutoBlockBound = false
	AutoBlockManualRelease = false
	ResetAutoBlockAnalysis('unbind')
end

BindAutoBlockInput()
if type(rawget(_G, 'NexusV4_SetBlock')) ~= 'function' then
	warn('[NEXUS V4] AutoBlock: nenhum _G.NexusV4_SetBlock foi conectado; o estado pode mudar, mas a arena não receberá o comando de bloqueio.')
end

-- Dedicated simulation/update loop for the decision engine.
-- AimLock camera work remains on the render binding below.
if AutoBlockHeartbeatConnection then
	pcall(function() AutoBlockHeartbeatConnection:Disconnect() end)
end
AutoBlockHeartbeatConnection = RunService.Heartbeat:Connect(function(dt)
	UpdateAutoBlock(dt)
end)

-- Public diagnostics for the user's own test arena.
_G.NexusV4_AutoBlock = {
	GetState = function() return AutoBlockState end,
	GetThreat = function() return AutoBlockThreat end,
	GetConfidence = function() return AutoBlockConfidence end,
	GetTTC = function() return AutoBlockTTC end,
	GetApproach = function() return AutoBlockApproach end,
	GetTargetSpeed = function() return AutoBlockTargetSpeed end,
	GetAcceleration = function() return AutoBlockAcceleration end,
	GetPrediction = function() return AutoBlockPrediction end,
	IsBlocking = function() return AutoBlockActive end,
	Reset = function() ResetAutoBlockAnalysis('manual') end,
}

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
		pcall(function() ResetAutoBlockAnalysis('death') end)
		if AimLockEnabled then
			DisableLockOn()
		else
			ClearLockOn()
		end
	end)
end

HookLocalCharacter(Player.Character)
Player.CharacterAdded:Connect(function(character)
	pcall(function() ResetAutoBlockAnalysis('respawn') end)
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
end)

--==================================================

-- FLY
--==================================================

--==================================================

FlyVelocity = nil
FlyGyro = nil
FlyConnection = nil
FlyRespawnToken = 0

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
	FlyRespawnToken += 1
	local token = FlyRespawnToken

	StopFly()
	if FlyEnabled then
		task.wait(0.5)
		-- BUG-009 FIX: uma respawn antiga não pode iniciar Fly no character novo.
		if token ~= FlyRespawnToken or not FlyEnabled then return end
		if not StartFly() then
			FlyEnabled = false
		end
	end
end)

--==================================================
-- RELOAD CLEANUP
--==================================================
-- BUG-008 FIX: evita Heartbeat/RenderStep duplicados entre execuções.
_G.NexusFPSBoosterV20_Cleanup = function()
	pcall(function()
		local c = rawget(_G, "NexusFPSBoosterV20_SpeedHeartbeatConnection")
		if c then c:Disconnect() end
		_G.NexusFPSBoosterV20_SpeedHeartbeatConnection = nil
	end)

	pcall(function()
		if SpeedHeartbeatConnection then SpeedHeartbeatConnection:Disconnect() end
		SpeedHeartbeatConnection = nil
	end)
	pcall(function()
		if AutoBlockAttackConnection then AutoBlockAttackConnection:Disconnect() end
		AutoBlockAttackConnection = nil
	end)
	pcall(function()
		if AutoBlockHeartbeatConnection then AutoBlockHeartbeatConnection:Disconnect() end
		AutoBlockHeartbeatConnection = nil
	end)
	pcall(function()
		if LocalDeathConnection then LocalDeathConnection:Disconnect() end
		LocalDeathConnection = nil
	end)
	pcall(function()
		if FlyConnection then FlyConnection:Disconnect() end
		FlyConnection = nil
	end)
	pcall(function()
		if FlyVelocity then FlyVelocity:Destroy() end
		FlyVelocity = nil
	end)
	pcall(function()
		if FlyGyro then FlyGyro:Destroy() end
		FlyGyro = nil
	end)
	pcall(function()
		RunService:UnbindFromRenderStep("NexusAimLock")
	end)

	pcall(function()
		local pg = Player and Player:FindFirstChildOfClass("PlayerGui")
		if pg then
			local oldGui = pg:FindFirstChild("NexusFPSBoosterV9")
			if oldGui then oldGui:Destroy() end
			local oldBoot = pg:FindFirstChild("NexusV183BootGuard")
			if oldBoot then oldBoot:Destroy() end
		end
	end)
end

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
AimLockButton.Active = true
pcall(function() AimLockButton.Interactable = true end)
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

AutoBlockReleaseButton = Instance.new('TextButton')
AutoBlockReleaseButton.Name = 'AutoBlockReleaseButton'
AutoBlockReleaseButton.Size = UDim2.fromOffset(58, 42)
-- Fica no alto/direita, sem colar no canto da tela.
-- Tambem fica acima do botao principal do AimLock.
AutoBlockReleaseButton.Position = UDim2.new(1, -82, 0, 105)
AutoBlockReleaseButton.BackgroundColor3 = Color3.fromRGB(20, 15, 25)
AutoBlockReleaseButton.BackgroundTransparency = 0.10
AutoBlockReleaseButton.BorderSizePixel = 0
AutoBlockReleaseButton.Text = '🛡'
AutoBlockReleaseButton.TextSize = 20
AutoBlockReleaseButton.AutoButtonColor = false
AutoBlockReleaseButton.Active = true
pcall(function() AutoBlockReleaseButton.Interactable = true end)
AutoBlockReleaseButton.ZIndex = 50
AutoBlockReleaseButton.Parent = Gui

AutoBlockReleaseCorner = Instance.new('UICorner')
AutoBlockReleaseCorner.CornerRadius = UDim.new(1, 0)
AutoBlockReleaseCorner.Parent = AutoBlockReleaseButton

AutoBlockReleaseStroke = Instance.new('UIStroke')
AutoBlockReleaseStroke.Color = Color3.fromRGB(255, 190, 70)
AutoBlockReleaseStroke.Thickness = 2
AutoBlockReleaseStroke.Transparency = 0.15
AutoBlockReleaseStroke.Parent = AutoBlockReleaseButton

AutoBlockReleaseLabel = Instance.new('TextLabel')
AutoBlockReleaseLabel.Size = UDim2.new(1, 0, 0, 12)
AutoBlockReleaseLabel.Position = UDim2.new(0, 0, 1, -13)
AutoBlockReleaseLabel.BackgroundTransparency = 1
AutoBlockReleaseLabel.Text = 'BLOCK'
AutoBlockReleaseLabel.TextColor3 = Color3.fromRGB(255, 220, 120)
AutoBlockReleaseLabel.TextSize = 7
AutoBlockReleaseLabel.Font = Enum.Font.GothamBold
AutoBlockReleaseLabel.ZIndex = 51
AutoBlockReleaseLabel.Parent = AutoBlockReleaseButton

function RefreshAutoBlockReleaseButton()
	local armed = not AutoBlockManualRelease
	AutoBlockReleaseButton.BackgroundColor3 = AutoBlockActive and Color3.fromRGB(55, 38, 10) or Color3.fromRGB(20, 15, 25)
	AutoBlockReleaseStroke.Color = AutoBlockManualRelease and Color3.fromRGB(255, 90, 90) or Color3.fromRGB(255, 190, 70)
	AutoBlockReleaseLabel.Text = AutoBlockManualRelease and 'RELEASED' or (AutoBlockActive and 'BLOCKING' or 'BLOCK')
	AutoBlockReleaseLabel.TextColor3 = AutoBlockManualRelease and RED or (armed and Color3.fromRGB(255, 220, 120) or RED)
end

AutoBlockReleaseButton.Activated:Connect(function()
	-- Primeiro clique libera; segundo clique rearma imediatamente.
	AutoBlockManualRelease = not AutoBlockManualRelease
	AutoBlockThreat = 0
	AutoBlockConfirmCount = 0
	SetAutoBlockState(false)
	if not AutoBlockManualRelease then
		AutoBlockState = 'IDLE'
		AutoBlockStateSince = os.clock()
	end
	RefreshAutoBlockReleaseButton()
	RefreshAimLockButton()
end)

function RefreshAimLockButton()
	AimLockButton.BackgroundColor3 = AimLockEnabled
		and Color3.fromRGB(45, 15, 65)
		or Color3.fromRGB(20, 15, 25)
	AimLockStroke.Transparency = AimLockEnabled and 0 or 0.25
	AimLockStateLabel.Text = AimLockEnabled and "GOD X" or "OFF"
	AimLockStateLabel.TextColor3 = AimLockEnabled and GREEN or RED
	GodModeBadge.TextColor3 = AimLockEnabled and Color3.fromRGB(255, 80, 180) or PURPLE
	AutoBlockBadge.Text = AutoBlockManualRelease and "AUTO BLOCK: RELEASED" or (AutoBlockActive and "AUTO BLOCK: BLOCK" or (AUTO_BLOCK_ENABLED and "AUTO BLOCK: ON" or "AUTO BLOCK: OFF"))
	AutoBlockBadge.TextColor3 = AutoBlockManualRelease and RED or (AutoBlockActive and Color3.fromRGB(255, 220, 80) or (AUTO_BLOCK_ENABLED and Color3.fromRGB(120, 255, 170) or RED))
	if AutoBlockReleaseButton then RefreshAutoBlockReleaseButton() end
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

RefreshAutoBlockReleaseButton()
RefreshAimLockButton()

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

FlyButton.Activated:Connect(function()
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

FlyToggle.Activated:Connect(function()
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

		-- BUG-003 FIX: ativação é transacional. Se ApplyBoost falhar,
		-- o estado lógico não fica preso em ON.
		local ok, err = xpcall(ApplyBoost, debug.traceback)
		if not ok then
			BoosterEnabled = false
			pcall(RestoreGraphics)
			Toggle.Text = "OFF"
			Toggle.TextColor3 = RED
			Status.Text = "●  BOOST FAILED"
			Status.TextColor3 = RED
			warn("[NEXUS V20] ApplyBoost failed:", err)
		end
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

		if BoosterEnabled then
			local ok, err = xpcall(ApplyBoost, debug.traceback)
			if not ok then
				BoosterEnabled = false
				pcall(RestoreGraphics)
				pcall(UpdateToggle)
				warn("[NEXUS V20] Mode reapply failed:", err)
			end
		end
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

SpeedToggle.Activated:Connect(function()
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
NexusBootStatus("GUI criada • V20 V4 AUTO BLOCK")
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

print("NEXUS FPS BOOSTER V20 V4 AUTO BLOCK iniciado.")


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
	warn("[NEXUS V20 V4 AUTO BLOCK] " .. tostring(__NexusRunErr))
else
	NexusBootStatus("GUI criada • V20 V4 AUTO BLOCK")
	task.delay(2, function()
		pcall(function() NexusBootGui:Destroy() end)
	end)
end


