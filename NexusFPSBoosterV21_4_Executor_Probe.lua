-- Nexus FPS Booster V21.4 - EXECUTOR PROBE
-- Probe minimo para testar o mesmo modelo de GUI usado no V18.
-- Speed: OFF
-- Fly: OFF
-- Nao carrega o corpo do V21.

local Players = game:GetService("Players")
local Player = Players.LocalPlayer

assert(Player, "Players.LocalPlayer is nil")

local PlayerGui = Player:WaitForChild("PlayerGui")

local old = PlayerGui:FindFirstChild("NexusV21_4_Executor_Probe")
if old then
    old:Destroy()
end

local Gui = Instance.new("ScreenGui")
Gui.Name = "NexusV21_4_Executor_Probe"
Gui.ResetOnSpawn = false
Gui.IgnoreGuiInset = true
Gui.DisplayOrder = 100000
Gui.Parent = PlayerGui

local Main = Instance.new("Frame")
Main.Name = "Main"
Main.Size = UDim2.fromOffset(430, 230)
Main.Position = UDim2.new(0.5, -215, 0.5, -115)
Main.BackgroundColor3 = Color3.fromRGB(12, 8, 18)
Main.BackgroundTransparency = 0.05
Main.BorderSizePixel = 0
Main.Parent = Gui

local Corner = Instance.new("UICorner")
Corner.CornerRadius = UDim.new(0, 12)
Corner.Parent = Main

local Stroke = Instance.new("UIStroke")
Stroke.Color = Color3.fromRGB(145, 70, 255)
Stroke.Thickness = 2
Stroke.Parent = Main

local Title = Instance.new("TextLabel")
Title.BackgroundTransparency = 1
Title.Position = UDim2.fromOffset(16, 12)
Title.Size = UDim2.new(1, -32, 0, 32)
Title.Font = Enum.Font.GothamBold
Title.TextSize = 20
Title.TextXAlignment = Enum.TextXAlignment.Left
Title.TextColor3 = Color3.fromRGB(240, 230, 255)
Title.Text = "NEXUS V21.4 EXECUTOR PROBE"
Title.Parent = Main

local Status = Instance.new("TextLabel")
Status.BackgroundTransparency = 1
Status.Position = UDim2.fromOffset(16, 55)
Status.Size = UDim2.new(1, -32, 0, 30)
Status.Font = Enum.Font.GothamBold
Status.TextSize = 15
Status.TextXAlignment = Enum.TextXAlignment.Left
Status.TextColor3 = Color3.fromRGB(80, 255, 150)
Status.Text = "STATUS: GUI OK"
Status.Parent = Main

local Info = Instance.new("TextLabel")
Info.BackgroundTransparency = 1
Info.Position = UDim2.fromOffset(16, 92)
Info.Size = UDim2.new(1, -32, 0, 105)
Info.Font = Enum.Font.Code
Info.TextSize = 14
Info.TextWrapped = true
Info.TextXAlignment = Enum.TextXAlignment.Left
Info.TextYAlignment = Enum.TextYAlignment.Top
Info.TextColor3 = Color3.fromRGB(225, 225, 235)
Info.Text = table.concat({
    "[1] Executor executou o script",
    "[2] Players.LocalPlayer OK",
    "[3] PlayerGui OK",
    "[4] ScreenGui criado",
    "[5] Metodo de GUI igual ao V18",
    "",
    "Se este painel aparecer, o problema nao e",
    "PlayerGui/ScreenGui. Depois isolamos o V21."
}, "\n")
Info.Parent = Main

print("[NEXUS] V21.4 EXECUTOR PROBE OK")
