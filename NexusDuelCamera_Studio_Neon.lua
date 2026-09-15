-- Nexus Duel Camera - Roblox Studio
-- Mecânica para o SEU próprio Place.
-- Mantém jogador local + alvo no enquadramento, com câmera suave,
-- rotação natural e distância dinâmica.

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local Workspace = game:GetService("Workspace")

local LocalPlayer = Players.LocalPlayer
local Camera = Workspace.CurrentCamera

-- =========================
-- CONFIGURAÇÃO
-- =========================
local MAX_TARGET_DISTANCE = 110
local ACQUIRE_FOV_DOT = math.cos(math.rad(62))
local TARGET_HEIGHT = 2.7
local PLAYER_HEIGHT = 2.5

local MIN_CAMERA_DISTANCE = 9
local MAX_CAMERA_DISTANCE = 28
local CAMERA_DISTANCE_PADDING = 5
local SCREEN_MARGIN = 0.78 -- menor = mais espaço nas bordas

local CAMERA_SMOOTHNESS = 10
local LOOK_SMOOTHNESS = 13
local ROTATION_SMOOTHNESS = 16
local POSITION_SMOOTHNESS = 10

local MAX_CAMERA_STEP = math.rad(12)
local MAX_ROTATION_STEP = math.rad(18)

local ENABLED = false
local CurrentTarget = nil
local SavedCameraType = Camera.CameraType
local SavedCameraSubject = Camera.CameraSubject
local LastCameraCFrame = nil
local LastTargetPosition = nil

-- =========================
-- UTILITÁRIOS
-- =========================
local function expSmooth(speed, dt)
    return 1 - math.exp(-speed * math.clamp(dt, 1 / 240, 1 / 20))
end

local function getCharacterParts(player)
    if not player then return nil end

    local character = player.Character
    if not character then return nil end

    local humanoid = character:FindFirstChildOfClass("Humanoid")
    local root = character:FindFirstChild("HumanoidRootPart")

    if not humanoid or humanoid.Health <= 0 or not root then
        return nil
    end

    return character, humanoid, root
end

local function isAlive(player)
    return getCharacterParts(player) ~= nil
end

local function getAimPosition(root, extraHeight)
    return root.Position + Vector3.new(0, extraHeight or TARGET_HEIGHT, 0)
end

local function hasLineOfSight(targetCharacter, targetPosition)
    local localCharacter = LocalPlayer.Character
    if not localCharacter then return false end

    local localRoot = localCharacter:FindFirstChild("HumanoidRootPart")
    if not localRoot then return false end

    local origin = localRoot.Position + Vector3.new(0, 2.2, 0)
    local direction = targetPosition - origin

    local params = RaycastParams.new()
    params.FilterType = Enum.RaycastFilterType.Exclude
    params.FilterDescendantsInstances = {localCharacter}
    params.IgnoreWater = true

    local result = Workspace:Raycast(origin, direction, params)
    return result == nil or result.Instance:IsDescendantOf(targetCharacter)
end

local function getBestTarget()
    local localCharacter, _, localRoot = getCharacterParts(LocalPlayer)
    if not localCharacter or not localRoot then return nil end

    local cameraPosition = Camera.CFrame.Position
    local cameraLook = Camera.CFrame.LookVector

    local bestPlayer = nil
    local bestScore = math.huge

    for _, player in ipairs(Players:GetPlayers()) do
        if player ~= LocalPlayer then
            local character, _, root = getCharacterParts(player)
            if character and root then
                local offset = root.Position - localRoot.Position
                local distance = offset.Magnitude

                if distance <= MAX_TARGET_DISTANCE and distance > 1 then
                    local direction = offset.Unit
                    local dot = cameraLook:Dot(direction)

                    if dot >= ACQUIRE_FOV_DOT then
                        local targetPos = getAimPosition(root)
                        if hasLineOfSight(character, targetPos) then
                            local screenPoint, visible = Camera:WorldToViewportPoint(targetPos)
                            if visible and screenPoint.Z > 0 then
                                local dx = screenPoint.X - Camera.ViewportSize.X * 0.5
                                local dy = screenPoint.Y - Camera.ViewportSize.Y * 0.5
                                local screenScore = dx * dx + dy * dy
                                local score = screenScore + distance * 20

                                if score < bestScore then
                                    bestScore = score
                                    bestPlayer = player
                                end
                            end
                        end
                    end
                end
            end
        end
    end

    return bestPlayer
end

local function clearTarget()
    CurrentTarget = nil
    LastTargetPosition = nil
end

local function acquireTarget()
    clearTarget()
    CurrentTarget = getBestTarget()
    return CurrentTarget ~= nil
end

-- =========================
-- CÂMERA
-- =========================
local function getPairData()
    local _, _, localRoot = getCharacterParts(LocalPlayer)
    local targetCharacter, _, targetRoot = getCharacterParts(CurrentTarget)

    if not localRoot or not targetCharacter or not targetRoot then
        return nil
    end

    local localPos = localRoot.Position + Vector3.new(0, PLAYER_HEIGHT, 0)
    local targetPos = targetRoot.Position + Vector3.new(0, TARGET_HEIGHT, 0)

    local midpoint = (localPos + targetPos) * 0.5
    local separation = (targetPos - localPos).Magnitude

    return localRoot, targetRoot, localPos, targetPos, midpoint, separation
end

local function getRequiredDistance(separation)
    local viewport = Camera.ViewportSize
    local aspect = math.max(viewport.X / math.max(viewport.Y, 1), 1)
    local verticalFov = math.rad(Camera.FieldOfView)
    local horizontalFov = 2 * math.atan(math.tan(verticalFov * 0.5) * aspect)

    -- Usa a menor abertura para garantir margem lateral suficiente.
    local halfFov = math.min(horizontalFov, verticalFov) * 0.5
    local required = (separation * 0.5) / math.max(math.tan(halfFov) * SCREEN_MARGIN, 0.05)

    return math.clamp(required + CAMERA_DISTANCE_PADDING, MIN_CAMERA_DISTANCE, MAX_CAMERA_DISTANCE)
end

local function getDesiredCameraCFrame(localRoot, targetRoot, midpoint, separation)
    local localPos = localRoot.Position + Vector3.new(0, PLAYER_HEIGHT, 0)
    local targetPos = targetRoot.Position + Vector3.new(0, TARGET_HEIGHT, 0)

    local pairDirection = targetPos - localPos
    local pairUnit = pairDirection.Magnitude > 0.01 and pairDirection.Unit or Camera.CFrame.LookVector

    -- Mantém a câmera atrás do jogador local, mas gira para o centro da dupla.
    local horizontalBack = Vector3.new(-pairUnit.X, 0, -pairUnit.Z)
    if horizontalBack.Magnitude < 0.05 then
        horizontalBack = Vector3.new(-Camera.CFrame.LookVector.X, 0, -Camera.CFrame.LookVector.Z)
    end
    horizontalBack = horizontalBack.Unit

    local distance = getRequiredDistance(separation)
    local desiredPosition = midpoint + horizontalBack * distance + Vector3.new(0, math.clamp(separation * 0.08, 1.2, 3.2), 0)

    return CFrame.lookAt(desiredPosition, midpoint)
end

local function clampCameraStep(current, desired, dt)
    local alpha = math.min(expSmooth(CAMERA_SMOOTHNESS, dt), 1)
    local result = current:Lerp(desired, alpha)

    local currentLook = current.LookVector
    local desiredLook = desired.LookVector
    local dot = math.clamp(currentLook:Dot(desiredLook), -1, 1)
    local angle = math.acos(dot)

    if angle > MAX_CAMERA_STEP then
        local t = MAX_CAMERA_STEP / angle
        local limitedLook = currentLook:Lerp(desiredLook, t).Unit
        local pos = result.Position
        result = CFrame.lookAt(pos, pos + limitedLook)
    end

    return result
end

local function keepBothVisible(cframe)
    local pair = getPairData()
    if not pair then return cframe end

    local _, _, localPos, targetPos = table.unpack(pair)
    local viewport = Camera.ViewportSize

    local lp, lv = Camera:WorldToViewportPoint(localPos)
    local tp, tv = Camera:WorldToViewportPoint(targetPos)

    if not lv or not tv or lp.Z <= 0 or tp.Z <= 0 then
        return cframe
    end

    local centerX = (lp.X + tp.X) * 0.5
    local centerY = (lp.Y + tp.Y) * 0.5
    local desiredX = viewport.X * 0.5
    local desiredY = viewport.Y * 0.5

    local offsetX = centerX - desiredX
    local offsetY = centerY - desiredY

    local maxX = viewport.X * 0.12
    local maxY = viewport.Y * 0.10

    if math.abs(offsetX) > maxX or math.abs(offsetY) > maxY then
        local right = cframe.RightVector
        local up = cframe.UpVector
        local worldCorrection = right * (-offsetX * 0.012) + up * (offsetY * 0.008)
        return CFrame.new(cframe.Position + worldCorrection) * (cframe - cframe.Position)
    end

    return cframe
end

-- =========================
-- ROTAÇÃO DO PERSONAGEM
-- =========================
local function faceTarget(dt)
    local _, localHumanoid, localRoot = getCharacterParts(LocalPlayer)
    local _, _, targetRoot = getCharacterParts(CurrentTarget)

    if not localHumanoid or not localRoot or not targetRoot then return end

    local direction = targetRoot.Position - localRoot.Position
    direction = Vector3.new(direction.X, 0, direction.Z)

    if direction.Magnitude < 0.05 then return end

    local desired = CFrame.lookAt(localRoot.Position, localRoot.Position + direction.Unit)
    local alpha = expSmooth(ROTATION_SMOOTHNESS, dt)
    local current = localRoot.CFrame
    local blended = current:Lerp(desired, alpha)

    local currentLook = current.LookVector
    local desiredLook = desired.LookVector
    local dot = math.clamp(currentLook:Dot(desiredLook), -1, 1)
    local angle = math.acos(dot)

    if angle > MAX_ROTATION_STEP then
        local t = MAX_ROTATION_STEP / angle
        local limitedLook = currentLook:Lerp(desiredLook, t).Unit
        blended = CFrame.lookAt(localRoot.Position, localRoot.Position + Vector3.new(limitedLook.X, 0, limitedLook.Z).Unit)
    end

    localHumanoid.AutoRotate = false
    localRoot.CFrame = blended
end

-- =========================
-- CONTROLE
-- =========================
local function restoreCamera()
    Camera.CameraType = SavedCameraType or Enum.CameraType.Custom
    Camera.CameraSubject = SavedCameraSubject
    LastCameraCFrame = nil

    local _, humanoid = getCharacterParts(LocalPlayer)
    if humanoid then
        humanoid.AutoRotate = true
    end
end

local function enable()
    if ENABLED then return end

    SavedCameraType = Camera.CameraType
    SavedCameraSubject = Camera.CameraSubject

    if not acquireTarget() then
        ENABLED = false
        return false
    end

    ENABLED = true
    Camera.CameraType = Enum.CameraType.Scriptable
    LastCameraCFrame = Camera.CFrame
    return true
end

local function disable()
    ENABLED = false
    clearTarget()
    restoreCamera()
end

local function toggle()
    if ENABLED then
        disable()
    else
        enable()
    end
end

-- Tecla Q no PC.
UserInputService.InputBegan:Connect(function(input, processed)
    if processed then return end
    if input.KeyCode == Enum.KeyCode.Q then
        toggle()
    end
end)

-- Botão mobile simples.
local gui = Instance.new("ScreenGui")
gui.Name = "NexusDuelCameraUI"
gui.ResetOnSpawn = false
gui.IgnoreGuiInset = true
gui.Parent = LocalPlayer:WaitForChild("PlayerGui")

local button = Instance.new("TextButton")
button.Name = "DuelCameraToggle"
button.Size = UDim2.fromOffset(64, 64)
button.Position = UDim2.new(1, -82, 0.5, -32)
button.BackgroundTransparency = 0.15
button.TextColor3 = Color3.fromRGB(255, 255, 255)
button.TextScaled = true
button.Font = Enum.Font.GothamBold
button.Text = "CAM\nOFF"
button.Parent = gui

local corner = Instance.new("UICorner")
corner.CornerRadius = UDim.new(0, 14)
corner.Parent = button

button.Activated:Connect(toggle)

local function refreshButton()
    button.Text = ENABLED and "CAM\nON" or "CAM\nOFF"
end

-- =========================
-- LOOP PRINCIPAL
-- =========================
RunService:BindToRenderStep("NexusDuelCamera", Enum.RenderPriority.Camera.Value + 1, function(dt)
    refreshButton()

    if not ENABLED then
        return
    end

    local pair = getPairData()
    if not pair then
        disable()
        return
    end

    local localRoot, targetRoot, _, targetPos, midpoint, separation = table.unpack(pair)

    -- Se o alvo morreu/desapareceu, o lock termina. Não troca automaticamente.
    if not isAlive(CurrentTarget) then
        disable()
        return
    end

    -- Rotação natural do jogador local.
    faceTarget(dt)

    -- Câmera com centro na dupla e distância dinâmica.
    local desired = getDesiredCameraCFrame(localRoot, targetRoot, midpoint, separation)
    desired = keepBothVisible(desired)

    if LastCameraCFrame then
        LastCameraCFrame = clampCameraStep(LastCameraCFrame, desired, dt)
    else
        LastCameraCFrame = desired
    end

    Camera.CFrame = LastCameraCFrame
    LastTargetPosition = targetPos
end)

-- Limpeza ao sair/renascer.
Players.PlayerRemoving:Connect(function(player)
    if player == CurrentTarget then
        disable()
    end
end)

LocalPlayer.CharacterAdded:Connect(function()
    if ENABLED then
        task.defer(disable)
    end
end)


-- Initial self neon highlight
task.defer(RefreshSelfHighlight)
