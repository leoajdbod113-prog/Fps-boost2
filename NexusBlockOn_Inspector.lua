--[[
    NexusBlockOn_Inspector.lua

    STANDALONE INSPECTOR
    ---------------------
    Apenas escaneia e mostra objetos relacionados ao sistema de bloqueio.

    NÃO:
      - depende do NexusFPSBoosterV20
      - depende do NexusBlockOn_Test
      - depende do CombatCore
      - dispara RemoteEvent/RemoteFunction
      - clica em botões
      - altera o estado de combate
]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ReplicatedFirst = game:GetService("ReplicatedFirst")
local UserInputService = game:GetService("UserInputService")

local LocalPlayer = Players.LocalPlayer
if not LocalPlayer then
    warn("[Nexus Inspector] LocalPlayer não encontrado.")
    return
end

local GUI_NAME = "NexusBlockOnInspectorUI"
local MAX_GUI_RESULTS = 80
local MAX_API_RESULTS = 80
local MAX_CANDIDATES = 30

local KEYWORDS = {
    "block", "blocking", "guard", "shield", "defend", "defense",
    "defence", "parry", "bloque", "bloquear", "bloqueio",
    "escudo", "defesa", "protecao", "proteção"
}

local State = {
    GuiResults = {},
    ApiResults = {},
    GuiCandidates = {},
    ApiCandidates = {},
    Scanning = false,
}

local function safeGetFullName(instance)
    local ok, result = pcall(function()
        return instance:GetFullName()
    end)
    return ok and result or "<GetFullName falhou>"
end

local function lower(value)
    return string.lower(tostring(value or ""))
end

local function containsKeyword(text)
    text = lower(text)
    for _, keyword in ipairs(KEYWORDS) do
        if string.find(text, keyword, 1, true) then
            return true, keyword
        end
    end
    return false, nil
end

local function scoreCandidate(instance)
    local score = 0
    local name = lower(instance.Name)
    local path = lower(safeGetFullName(instance))

    for _, keyword in ipairs(KEYWORDS) do
        if string.find(name, keyword, 1, true) then
            score += 10
        end
        if string.find(path, keyword, 1, true) then
            score += 3
        end
    end

    if instance:IsA("GuiButton") then
        score += 5
    end
    if instance:IsA("ImageButton") or instance:IsA("TextButton") then
        score += 2
    end

    return score
end

-- ============================================================
-- UI
-- ============================================================

local oldGui = LocalPlayer:FindFirstChild(GUI_NAME)
if oldGui then
    oldGui:Destroy()
end

local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = GUI_NAME
ScreenGui.ResetOnSpawn = false
ScreenGui.IgnoreGuiInset = true
ScreenGui.Parent = LocalPlayer:WaitForChild("PlayerGui")

local Main = Instance.new("Frame")
Main.Name = "Main"
Main.Size = UDim2.new(0, 390, 0, 520)
Main.Position = UDim2.new(0.5, -195, 0.5, -260)
Main.BackgroundColor3 = Color3.fromRGB(15, 15, 20)
Main.BorderSizePixel = 0
Main.Parent = ScreenGui

local Corner = Instance.new("UICorner")
Corner.CornerRadius = UDim.new(0, 12)
Corner.Parent = Main

local Stroke = Instance.new("UIStroke")
Stroke.Color = Color3.fromRGB(100, 60, 180)
Stroke.Thickness = 1
Stroke.Parent = Main

local Header = Instance.new("TextLabel")
Header.Size = UDim2.new(1, -20, 0, 45)
Header.Position = UDim2.new(0, 10, 0, 5)
Header.BackgroundTransparency = 1
Header.Text = "NEXUS BLOCK-ON INSPECTOR"
Header.TextColor3 = Color3.fromRGB(210, 180, 255)
Header.TextSize = 18
Header.Font = Enum.Font.GothamBold
Header.TextXAlignment = Enum.TextXAlignment.Left
Header.Parent = Main

local Status = Instance.new("TextLabel")
Status.Size = UDim2.new(1, -20, 0, 25)
Status.Position = UDim2.new(0, 10, 0, 45)
Status.BackgroundTransparency = 1
Status.Text = "Status: aguardando scan"
Status.TextColor3 = Color3.fromRGB(170, 170, 180)
Status.TextSize = 13
Status.Font = Enum.Font.Gotham
Status.TextXAlignment = Enum.TextXAlignment.Left
Status.Parent = Main

local ScanButton = Instance.new("TextButton")
ScanButton.Size = UDim2.new(0, 110, 0, 36)
ScanButton.Position = UDim2.new(0, 10, 0, 75)
ScanButton.BackgroundColor3 = Color3.fromRGB(75, 40, 130)
ScanButton.BorderSizePixel = 0
ScanButton.Text = "SCAN"
ScanButton.TextColor3 = Color3.new(1, 1, 1)
ScanButton.TextSize = 14
ScanButton.Font = Enum.Font.GothamBold
ScanButton.Parent = Main

local ScanCorner = Instance.new("UICorner")
ScanCorner.CornerRadius = UDim.new(0, 8)
ScanCorner.Parent = ScanButton

local ClearButton = Instance.new("TextButton")
ClearButton.Size = UDim2.new(0, 110, 0, 36)
ClearButton.Position = UDim2.new(0, 130, 0, 75)
ClearButton.BackgroundColor3 = Color3.fromRGB(45, 45, 55)
ClearButton.BorderSizePixel = 0
ClearButton.Text = "CLEAR"
ClearButton.TextColor3 = Color3.new(1, 1, 1)
ClearButton.TextSize = 14
ClearButton.Font = Enum.Font.GothamBold
ClearButton.Parent = Main

local ClearCorner = Instance.new("UICorner")
ClearCorner.CornerRadius = UDim.new(0, 8)
ClearCorner.Parent = ClearButton

local Counters = Instance.new("TextLabel")
Counters.Size = UDim2.new(1, -20, 0, 35)
Counters.Position = UDim2.new(0, 10, 0, 118)
Counters.BackgroundTransparency = 1
Counters.Text = "GUI: 0 | CANDIDATOS: 0 | API: 0"
Counters.TextColor3 = Color3.fromRGB(190, 190, 200)
Counters.TextSize = 12
Counters.Font = Enum.Font.Gotham
Counters.TextXAlignment = Enum.TextXAlignment.Left
Counters.Parent = Main

local Scroll = Instance.new("ScrollingFrame")
Scroll.Size = UDim2.new(1, -20, 1, -165)
Scroll.Position = UDim2.new(0, 10, 0, 155)
Scroll.BackgroundColor3 = Color3.fromRGB(9, 9, 13)
Scroll.BorderSizePixel = 0
Scroll.ScrollBarThickness = 5
Scroll.CanvasSize = UDim2.new(0, 0, 0, 0)
Scroll.Parent = Main

local ScrollCorner = Instance.new("UICorner")
ScrollCorner.CornerRadius = UDim.new(0, 8)
ScrollCorner.Parent = Scroll

local Layout = Instance.new("UIListLayout")
Layout.Padding = UDim.new(0, 5)
Layout.SortOrder = Enum.SortOrder.LayoutOrder
Layout.Parent = Scroll

local Padding = Instance.new("UIPadding")
Padding.PaddingTop = UDim.new(0, 8)
Padding.PaddingBottom = UDim.new(0, 8)
Padding.PaddingLeft = UDim.new(0, 8)
Padding.PaddingRight = UDim.new(0, 8)
Padding.Parent = Scroll

local function clearVisualResults()
    for _, child in ipairs(Scroll:GetChildren()) do
        if child:IsA("GuiObject")
            and not child:IsA("UIListLayout")
            and not child:IsA("UIPadding") then
            child:Destroy()
        end
    end
end

local function addLine(text, kind)
    local label = Instance.new("TextLabel")
    label.Size = UDim2.new(1, -5, 0, 0)
    label.AutomaticSize = Enum.AutomaticSize.Y
    label.BackgroundTransparency = 1
    label.TextWrapped = true
    label.TextXAlignment = Enum.TextXAlignment.Left
    label.TextYAlignment = Enum.TextYAlignment.Top
    label.Text = text
    label.Font = Enum.Font.Code
    label.TextSize = 11

    if kind == "candidate" then
        label.TextColor3 = Color3.fromRGB(255, 210, 100)
    elseif kind == "api" then
        label.TextColor3 = Color3.fromRGB(120, 190, 255)
    elseif kind == "error" then
        label.TextColor3 = Color3.fromRGB(255, 100, 100)
    elseif kind == "header" then
        label.TextColor3 = Color3.fromRGB(210, 180, 255)
        label.Font = Enum.Font.GothamBold
        label.TextSize = 13
    else
        label.TextColor3 = Color3.fromRGB(190, 190, 195)
    end

    label.Parent = Scroll
end

local function updateCanvas()
    task.defer(function()
        Scroll.CanvasSize = UDim2.new(0, 0, 0, Layout.AbsoluteContentSize.Y + 15)
    end)
end

-- ============================================================
-- GUI SCANNER
-- ============================================================

local function scanGUI()
    local PlayerGui = LocalPlayer:FindFirstChildOfClass("PlayerGui")
    if not PlayerGui then
        return
    end

    for _, instance in ipairs(PlayerGui:GetDescendants()) do
        if instance:IsA("GuiButton")
            and #State.GuiResults < MAX_GUI_RESULTS then

            local data = {
                Instance = instance,
                Name = instance.Name,
                ClassName = instance.ClassName,
                Path = safeGetFullName(instance),
                Visible = instance.Visible,
                Active = instance.Active,
                Score = scoreCandidate(instance),
            }

            if instance:IsA("ImageButton") then
                data.Image = instance.Image
            end

            if instance:IsA("TextButton") then
                data.Text = instance.Text
            end

            table.insert(State.GuiResults, data)

            local candidate = containsKeyword(
                instance.Name .. " " .. data.Path
            )

            if candidate then
                table.insert(State.GuiCandidates, data)
            end
        end
    end
end

-- ============================================================
-- API / OBJECT SCANNER
-- ============================================================

local function inspectContainer(container)
    if not container then
        return
    end

    for _, instance in ipairs(container:GetDescendants()) do
        local validClass =
            instance:IsA("RemoteEvent")
            or instance:IsA("RemoteFunction")
            or instance:IsA("BindableEvent")
            or instance:IsA("BindableFunction")
            or instance:IsA("ModuleScript")

        if validClass
            and #State.ApiResults < MAX_API_RESULTS then

            local path = safeGetFullName(instance)

            local data = {
                Instance = instance,
                Name = instance.Name,
                ClassName = instance.ClassName,
                Path = path,
            }

            table.insert(State.ApiResults, data)

            local candidate = containsKeyword(
                instance.Name .. " " .. path
            )

            if candidate then
                table.insert(State.ApiCandidates, data)
            end
        end
    end
end

local function scanAPI()
    inspectContainer(ReplicatedStorage)
    inspectContainer(ReplicatedFirst)
end

-- ============================================================
-- RENDER
-- ============================================================

local function renderResults()
    clearVisualResults()

    addLine("=== GUI BUTTON CANDIDATES ===", "header")

    table.sort(State.GuiCandidates, function(a, b)
        return a.Score > b.Score
    end)

    for index, data in ipairs(State.GuiCandidates) do
        if index > MAX_CANDIDATES then
            break
        end

        local extra = ""

        if data.Image then
            extra = "\nImage: " .. tostring(data.Image)
        end

        if data.Text then
            extra = "\nText: " .. tostring(data.Text)
        end

        addLine(
            string.format(
                "[CANDIDATE %d]\nName: %s\nClass: %s\nVisible: %s\nActive: %s\nScore: %d\nPath: %s%s",
                index,
                data.Name,
                data.ClassName,
                tostring(data.Visible),
                tostring(data.Active),
                data.Score,
                data.Path,
                extra
            ),
            "candidate"
        )
    end

    if #State.GuiCandidates == 0 then
        addLine("Nenhum candidato GUI encontrado.", "error")
    end

    addLine("\n=== TODOS OS GUI BUTTONS ===", "header")

    for index, data in ipairs(State.GuiResults) do
        addLine(
            string.format(
                "[GUI %d] %s | %s\n%s",
                index,
                data.Name,
                data.ClassName,
                data.Path
            ),
            "normal"
        )
    end

    addLine("\n=== API / OBJECT CANDIDATES ===", "header")

    for index, data in ipairs(State.ApiCandidates) do
        if index > MAX_CANDIDATES then
            break
        end

        addLine(
            string.format(
                "[API CANDIDATE %d]\nName: %s\nClass: %s\nPath: %s",
                index,
                data.Name,
                data.ClassName,
                data.Path
            ),
            "api"
        )
    end

    if #State.ApiCandidates == 0 then
        addLine(
            "Nenhum objeto com nome relacionado a block/guard/shield encontrado.",
            "error"
        )
    end

    addLine("\n=== API OBJECTS ===", "header")

    for index, data in ipairs(State.ApiResults) do
        addLine(
            string.format(
                "[API %d] %s | %s\n%s",
                index,
                data.Name,
                data.ClassName,
                data.Path
            ),
            "normal"
        )
    end

    Counters.Text = string.format(
        "GUI: %d | CANDIDATOS: %d | API: %d",
        #State.GuiResults,
        #State.GuiCandidates,
        #State.ApiResults
    )

    updateCanvas()
end

-- ============================================================
-- SCAN / CLEAR
-- ============================================================

local function Scan()
    if State.Scanning then
        return
    end

    State.Scanning = true
    Status.Text = "Status: escaneando..."

    State.GuiResults = {}
    State.ApiResults = {}
    State.GuiCandidates = {}
    State.ApiCandidates = {}

    task.wait()

    local guiOk, guiError = pcall(scanGUI)
    if not guiOk then
        warn("[Nexus Inspector] GUI scan error:", guiError)
    end

    local apiOk, apiError = pcall(scanAPI)
    if not apiOk then
        warn("[Nexus Inspector] API scan error:", apiError)
    end

    renderResults()

    Status.Text = string.format(
        "Status: scan concluído | GUI %d | API %d",
        #State.GuiResults,
        #State.ApiResults
    )

    State.Scanning = false
end

local function Clear()
    State.GuiResults = {}
    State.ApiResults = {}
    State.GuiCandidates = {}
    State.ApiCandidates = {}

    clearVisualResults()

    Counters.Text = "GUI: 0 | CANDIDATOS: 0 | API: 0"
    Status.Text = "Status: resultados limpos"

    updateCanvas()
end

ScanButton.Activated:Connect(Scan)
ClearButton.Activated:Connect(Clear)

-- ============================================================
-- DRAG / TOUCH
-- ============================================================

local dragging = false
local dragStart
local startPosition

Main.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1
        or input.UserInputType == Enum.UserInputType.Touch then

        dragging = true
        dragStart = input.Position
        startPosition = Main.Position

        input.Changed:Connect(function()
            if input.UserInputState == Enum.UserInputState.End then
                dragging = false
            end
        end)
    end
end)

UserInputService.InputChanged:Connect(function(input)
    if not dragging then
        return
    end

    if input.UserInputType ~= Enum.UserInputType.MouseMovement
        and input.UserInputType ~= Enum.UserInputType.Touch then
        return
    end

    local delta = input.Position - dragStart

    Main.Position = UDim2.new(
        startPosition.X.Scale,
        startPosition.X.Offset + delta.X,
        startPosition.Y.Scale,
        startPosition.Y.Offset + delta.Y
    )
end)

-- ============================================================
-- INITIAL SCAN
-- ============================================================

task.defer(Scan)

print("[NexusBlockOn_Inspector] Inspector iniciado.")
