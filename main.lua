-- LocalScript → StarterPlayer > StarterPlayerScripts
-- MIDHUB v10.2 - 100% CORRIGIDO

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local Workspace = game:GetService("Workspace")
local Camera = Workspace.CurrentCamera
local Lighting = game:GetService("Lighting")
local StarterGui = game:GetService("StarterGui")

local player = Players.LocalPlayer

-- ====================== CONFIGURAÇÕES ======================
local Settings = {
    ESP_Enabled = false,
    ESP_MaxDistance = 9999,
    ESP_ShowBoxes = true,
    ESP_TextSize = 13,
    ESP_TeamCheck = false,
    
    Teleport_Distance = 3,
    Teleport_Height = 0,
    
    NoClip_Enabled = false,
    FullBright_Enabled = false,
    Fly_Enabled = false,
    Fly_Speed = 50,
    
    UI_Theme = "Purple",
}

-- ====================== TEMAS ======================
local Themes = {
    Purple = {
        Primary = Color3.fromRGB(140, 70, 255), Secondary = Color3.fromRGB(100, 50, 200),
        Background = Color3.fromRGB(10, 8, 22), Surface = Color3.fromRGB(18, 14, 38),
        SurfaceLight = Color3.fromRGB(25, 20, 48), Accent = Color3.fromRGB(255, 80, 200),
        Text = Color3.fromRGB(240, 210, 255), TextSecondary = Color3.fromRGB(170, 150, 210),
        Success = Color3.fromRGB(60, 255, 100), Warning = Color3.fromRGB(255, 200, 50),
        Danger = Color3.fromRGB(255, 60, 60), Glow = Color3.fromRGB(200, 120, 255),
        Name = "Roxo Cósmico", Icon = "💜",
    },
    Midnight = {
        Primary = Color3.fromRGB(50, 120, 255), Secondary = Color3.fromRGB(30, 80, 200),
        Background = Color3.fromRGB(6, 10, 18), Surface = Color3.fromRGB(12, 18, 32),
        SurfaceLight = Color3.fromRGB(18, 26, 44), Accent = Color3.fromRGB(70, 190, 255),
        Text = Color3.fromRGB(210, 230, 255), TextSecondary = Color3.fromRGB(150, 180, 230),
        Success = Color3.fromRGB(60, 255, 170), Warning = Color3.fromRGB(255, 210, 60),
        Danger = Color3.fromRGB(255, 80, 80), Glow = Color3.fromRGB(100, 170, 255),
        Name = "Azul Meia-Noite", Icon = "🌙",
    },
    Crimson = {
        Primary = Color3.fromRGB(255, 50, 50), Secondary = Color3.fromRGB(200, 30, 30),
        Background = Color3.fromRGB(22, 8, 8), Surface = Color3.fromRGB(32, 12, 12),
        SurfaceLight = Color3.fromRGB(44, 18, 18), Accent = Color3.fromRGB(255, 140, 70),
        Text = Color3.fromRGB(255, 210, 210), TextSecondary = Color3.fromRGB(230, 150, 150),
        Success = Color3.fromRGB(100, 255, 100), Warning = Color3.fromRGB(255, 255, 60),
        Danger = Color3.fromRGB(255, 40, 40), Glow = Color3.fromRGB(255, 90, 70),
        Name = "Vermelho Carmesim", Icon = "❤️",
    },
    Emerald = {
        Primary = Color3.fromRGB(30, 210, 110), Secondary = Color3.fromRGB(20, 160, 80),
        Background = Color3.fromRGB(6, 18, 10), Surface = Color3.fromRGB(10, 26, 16),
        SurfaceLight = Color3.fromRGB(16, 36, 24), Accent = Color3.fromRGB(80, 255, 150),
        Text = Color3.fromRGB(190, 255, 220), TextSecondary = Color3.fromRGB(140, 230, 180),
        Success = Color3.fromRGB(60, 255, 140), Warning = Color3.fromRGB(255, 230, 60),
        Danger = Color3.fromRGB(255, 80, 80), Glow = Color3.fromRGB(70, 255, 140),
        Name = "Verde Esmeralda", Icon = "💚",
    },
    Gold = {
        Primary = Color3.fromRGB(255, 170, 30), Secondary = Color3.fromRGB(200, 130, 20),
        Background = Color3.fromRGB(18, 13, 4), Surface = Color3.fromRGB(28, 20, 6),
        SurfaceLight = Color3.fromRGB(38, 30, 10), Accent = Color3.fromRGB(255, 210, 80),
        Text = Color3.fromRGB(255, 240, 190), TextSecondary = Color3.fromRGB(230, 200, 150),
        Success = Color3.fromRGB(130, 255, 80), Warning = Color3.fromRGB(255, 255, 80),
        Danger = Color3.fromRGB(255, 80, 80), Glow = Color3.fromRGB(255, 190, 60),
        Name = "Dourado Real", Icon = "👑",
    },
}

local currentTheme = Themes[Settings.UI_Theme]

-- ====================== ANTI FALL ======================
player.CharacterAdded:Connect(function(char)
    local h = char:WaitForChild("Humanoid", 5)
    if h then
        h:SetStateEnabled(Enum.HumanoidStateType.FallingDown, false)
        h.StateChanged:Connect(function(_, ns)
            if ns == Enum.HumanoidStateType.FallingDown then
                h:ChangeState(Enum.HumanoidStateType.GettingUp)
            end
        end)
    end
end)
if player.Character then
    local h = player.Character:FindFirstChild("Humanoid")
    if h then h:SetStateEnabled(Enum.HumanoidStateType.FallingDown, false) end
end

-- ====================== FULLBRIGHT ======================
local function toggleFullBright(on)
    Settings.FullBright_Enabled = on
    Lighting.Brightness = on and 3 or 2
    Lighting.GlobalShadows = not on
end

-- ====================== NOCLIP ======================
local function toggleNoClip(on)
    Settings.NoClip_Enabled = on
end
RunService.Stepped:Connect(function()
    if Settings.NoClip_Enabled and player.Character then
        for _, p in pairs(player.Character:GetDescendants()) do
            if p:IsA("BasePart") then p.CanCollide = false end
        end
    end
end)

-- ====================== FLY ======================
local flyConn = nil
local function toggleFly(on)
    Settings.Fly_Enabled = on
    if on then
        if flyConn then flyConn:Disconnect() end
        flyConn = RunService.Heartbeat:Connect(function()
            if not Settings.Fly_Enabled then if flyConn then flyConn:Disconnect(); flyConn = nil end; return end
            local char = player.Character
            if not char or not char:FindFirstChild("HumanoidRootPart") then return end
            local root = char.HumanoidRootPart
            local h = char:FindFirstChild("Humanoid")
            if h then h.PlatformStand = true end
            local move = Vector3.zero
            if UserInputService:IsKeyDown(Enum.KeyCode.W) then move += Camera.CFrame.LookVector end
            if UserInputService:IsKeyDown(Enum.KeyCode.S) then move -= Camera.CFrame.LookVector end
            if UserInputService:IsKeyDown(Enum.KeyCode.A) then move -= Camera.CFrame.RightVector end
            if UserInputService:IsKeyDown(Enum.KeyCode.D) then move += Camera.CFrame.RightVector end
            if UserInputService:IsKeyDown(Enum.KeyCode.Space) then move += Vector3.new(0,1,0) end
            if UserInputService:IsKeyDown(Enum.KeyCode.LeftControl) then move -= Vector3.new(0,1,0) end
            root.Velocity = move.Magnitude > 0 and move.Unit * Settings.Fly_Speed or Vector3.zero
        end)
    else
        if flyConn then flyConn:Disconnect(); flyConn = nil end
        if player.Character then
            local h = player.Character:FindFirstChild("Humanoid")
            if h then h.PlatformStand = false end
        end
    end
end

-- ====================== TELEPORT ======================
local targetPlayer = nil
local isTP = false
local tpConn = nil

local function doTeleport(plr)
    if not plr or not plr.Character then return end
    local tRoot = plr.Character:FindFirstChild("HumanoidRootPart")
    if not tRoot then return end
    local myChar = player.Character
    if not myChar then return end
    local myRoot = myChar:FindFirstChild("HumanoidRootPart")
    if not myRoot then return end
    
    local behind = -tRoot.CFrame.LookVector
    local pos = tRoot.Position + (behind * Settings.Teleport_Distance) + Vector3.new(0, Settings.Teleport_Height, 0)
    local rot = myRoot.CFrame - myRoot.Position
    myRoot.CFrame = CFrame.new(pos) * rot
end

local function startTP()
    if not targetPlayer then return end
    if not targetPlayer.Character then return end
    if tpConn then tpConn:Disconnect() end
    isTP = true
    tpConn = RunService.Heartbeat:Connect(function()
        if not isTP then if tpConn then tpConn:Disconnect(); tpConn = nil end; return end
        doTeleport(targetPlayer)
    end)
end

local function stopTP()
    isTP = false
    if tpConn then tpConn:Disconnect(); tpConn = nil end
end

-- ====================== TEAM TP ======================
local isTeamTP = false
local teamConn = nil
local teamTarget = nil

local function getRandomTeam()
    local t = {}
    for _, p in pairs(Players:GetPlayers()) do
        if p ~= player and p.Team == player.Team and p.Character and p.Character:FindFirstChild("HumanoidRootPart") then
            local h = p.Character:FindFirstChild("Humanoid")
            if h and h.Health > 0 then table.insert(t, p) end
        end
    end
    return #t > 0 and t[math.random(1, #t)] or nil
end

local function startTeamTP()
    if teamConn then teamConn:Disconnect() end
    local ft = getRandomTeam()
    if ft then teamTarget = ft.Character end
    isTeamTP = true
    teamConn = RunService.Heartbeat:Connect(function()
        if not isTeamTP then if teamConn then teamConn:Disconnect(); teamConn = nil end; return end
        local valid = teamTarget and teamTarget.Parent and teamTarget:FindFirstChild("HumanoidRootPart")
        local h = valid and teamTarget:FindFirstChild("Humanoid")
        if not valid or not h or h.Health <= 0 then
            local nt = getRandomTeam()
            if nt and nt.Character then teamTarget = nt.Character else return end
        end
        if teamTarget then doTeleport(Players:GetPlayerFromCharacter(teamTarget)) end
    end)
end

local function stopTeamTP()
    isTeamTP = false
    if teamConn then teamConn:Disconnect(); teamConn = nil end
end

-- ====================== CORPSE TP ======================
local targetCorpse = nil
local isCorpseTP = false
local corpseConn = nil

local function doCorpseTP(corpse)
    if not corpse or not corpse:IsA("Model") then return end
    local myChar = player.Character
    if not myChar then return end
    local myRoot = myChar:FindFirstChild("HumanoidRootPart")
    if not myRoot then return end
    
    local part = corpse:FindFirstChild("HumanoidRootPart") or corpse:FindFirstChild("Head") or corpse:FindFirstChild("Torso")
    if not part then
        for _, p in pairs(corpse:GetDescendants()) do
            if p:IsA("BasePart") then part = p; break end
        end
    end
    if not part then return end
    
    local pos = part.Position + Vector3.new(0, 3, 0)
    local rot = myRoot.CFrame - myRoot.Position
    myRoot.CFrame = CFrame.new(pos) * rot
end

local function startCorpseTP()
    if not targetCorpse then return end
    if corpseConn then corpseConn:Disconnect() end
    isCorpseTP = true
    corpseConn = RunService.Heartbeat:Connect(function()
        if not isCorpseTP then if corpseConn then corpseConn:Disconnect(); corpseConn = nil end; return end
        if targetCorpse and targetCorpse.Parent then doCorpseTP(targetCorpse) else stopCorpseTP() end
    end)
end

local function stopCorpseTP()
    isCorpseTP = false
    if corpseConn then corpseConn:Disconnect(); corpseConn = nil end
end

-- ====================== ESP ======================
local espData = {}

local function createESP(plr, idx)
    if not plr.Character then return end
    local char = plr.Character
    local head = char:FindFirstChild("Head")
    if not head then return end
    if Settings.ESP_TeamCheck and plr.Team == player.Team then return end
    
    if espData[plr] then
        pcall(function() espData[plr].hl:Destroy() end)
        pcall(function() espData[plr].bb:Destroy() end)
    end
    
    local data = {}
    
    if Settings.ESP_ShowBoxes then
        local hl = Instance.new("Highlight")
        hl.FillColor = currentTheme.Accent
        hl.FillTransparency = 0.85
        hl.OutlineColor = currentTheme.Primary
        hl.OutlineTransparency = 0.2
        hl.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
        hl.Parent = char
        data.hl = hl
    end
    
    local bb = Instance.new("BillboardGui")
    bb.Size = UDim2.new(0, 160, 0, 35)
    bb.StudsOffset = Vector3.new(0, 2.2 + (idx * 0.5), 0)
    bb.AlwaysOnTop = true
    bb.MaxDistance = Settings.ESP_MaxDistance
    bb.Parent = head
    data.bb = bb
    
    local f = Instance.new("Frame", bb)
    f.Size = UDim2.new(1, 0, 1, 0)
    f.BackgroundColor3 = currentTheme.Surface
    f.BackgroundTransparency = 0.25
    f.BorderSizePixel = 0
    Instance.new("UICorner", f).CornerRadius = UDim.new(0, 8)
    
    local l = Instance.new("TextLabel", f)
    l.Size = UDim2.new(1, -6, 1, 0)
    l.Position = UDim2.new(0, 3, 0, 0)
    l.BackgroundTransparency = 1
    l.Text = plr.DisplayName
    l.TextColor3 = Color3.new(1, 1, 1)
    l.TextSize = Settings.ESP_TextSize
    l.Font = Enum.Font.GothamBlack
    l.TextXAlignment = Enum.TextXAlignment.Center
    
    char.AncestryChanged:Connect(function()
        if not char.Parent then
            pcall(function() data.hl:Destroy() end)
            pcall(function() data.bb:Destroy() end)
            espData[plr] = nil
        end
    end)
    
    espData[plr] = data
end

local function refreshESP()
    if not Settings.ESP_Enabled then return end
    for _, d in pairs(espData) do
        pcall(function() d.hl:Destroy() end)
        pcall(function() d.bb:Destroy() end)
    end
    espData = {}
    local list = {}
    for _, p in pairs(Players:GetPlayers()) do
        if p ~= player then table.insert(list, p) end
    end
    for i, p in ipairs(list) do
        if p.Character then createESP(p, i) end
    end
end

local function enableESP()
    Settings.ESP_Enabled = true
    refreshESP()
end

local function disableESP()
    Settings.ESP_Enabled = false
    for _, d in pairs(espData) do
        pcall(function() d.hl:Destroy() end)
        pcall(function() d.bb:Destroy() end)
    end
    espData = {}
end

-- ====================== GUI ======================
local screenGui = Instance.new("ScreenGui")
screenGui.Name = "MIDHUB"
screenGui.ResetOnSpawn = false
screenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
screenGui.Parent = player:WaitForChild("PlayerGui")

local mainFrame = Instance.new("Frame")
mainFrame.Size = UDim2.new(0, 320, 0, 500)
mainFrame.Position = UDim2.new(0, 5, 0.5, -250)
mainFrame.BackgroundColor3 = currentTheme.Background
mainFrame.BorderSizePixel = 0
mainFrame.Active = true
mainFrame.Draggable = true
mainFrame.ClipsDescendants = true
mainFrame.Parent = screenGui
Instance.new("UICorner", mainFrame).CornerRadius = UDim.new(0, 16)
Instance.new("UIStroke", mainFrame).Color = currentTheme.Primary
mainFrame.UIStroke.Thickness = 2

-- Header
local header = Instance.new("Frame")
header.Size = UDim2.new(1, 0, 0, 45)
header.BackgroundColor3 = currentTheme.Surface
header.BorderSizePixel = 0
header.ClipsDescendants = true
header.Parent = mainFrame
Instance.new("UICorner", header).CornerRadius = UDim.new(0, 16)

local logo = Instance.new("TextLabel")
logo.Size = UDim2.new(0, 35, 0, 35)
logo.Position = UDim2.new(0, 8, 0, 5)
logo.BackgroundTransparency = 1
logo.Text = currentTheme.Icon
logo.TextSize = 22
logo.Font = Enum.Font.GothamBlack
logo.Parent = header

local title = Instance.new("TextLabel")
title.Size = UDim2.new(1, -100, 0, 25)
title.Position = UDim2.new(0, 48, 0, 5)
title.BackgroundTransparency = 1
title.Text = "MIDHUB v10.2"
title.TextColor3 = Color3.new(1, 1, 1)
title.TextSize = 16
title.Font = Enum.Font.GothamBlack
title.TextXAlignment = Enum.TextXAlignment.Left
title.Parent = header

local sub = Instance.new("TextLabel")
sub.Size = UDim2.new(0, 100, 0, 14)
sub.Position = UDim2.new(0, 48, 0, 28)
sub.BackgroundTransparency = 1
sub.Text = "100% Corrigido"
sub.TextColor3 = currentTheme.Accent
sub.TextSize = 9
sub.Font = Enum.Font.GothamBold
sub.TextXAlignment = Enum.TextXAlignment.Left
sub.Parent = header

local btnX = Instance.new("TextButton")
btnX.Size = UDim2.new(0, 26, 0, 26)
btnX.Position = UDim2.new(1, -34, 0, 10)
btnX.BackgroundColor3 = Color3.fromRGB(255, 55, 55)
btnX.BackgroundTransparency = 0.2
btnX.Text = "✕"
btnX.TextColor3 = Color3.new(1, 1, 1)
btnX.TextSize = 13
btnX.Font = Enum.Font.GothamBold
btnX.AutoButtonColor = false
btnX.Parent = header
Instance.new("UICorner", btnX).CornerRadius = UDim.new(0, 7)
btnX.MouseButton1Click:Connect(function() mainFrame.Visible = false end)

-- Status
local statusBar = Instance.new("Frame")
statusBar.Size = UDim2.new(1, -12, 0, 24)
statusBar.Position = UDim2.new(0, 6, 0, 50)
statusBar.BackgroundColor3 = currentTheme.SurfaceLight
statusBar.BorderSizePixel = 0
statusBar.ClipsDescendants = true
statusBar.Parent = mainFrame
Instance.new("UICorner", statusBar).CornerRadius = UDim.new(0, 8)

local statusDot = Instance.new("Frame")
statusDot.Size = UDim2.new(0, 8, 0, 8)
statusDot.Position = UDim2.new(0, 8, 0.5, -4)
statusDot.BackgroundColor3 = currentTheme.Success
statusDot.BorderSizePixel = 0
statusDot.Parent = statusBar
Instance.new("UICorner", statusDot).CornerRadius = UDim.new(1, 0)

local statusText = Instance.new("TextLabel")
statusText.Size = UDim2.new(1, -22, 1, 0)
statusText.Position = UDim2.new(0, 20, 0, 0)
statusText.BackgroundTransparency = 1
statusText.Text = "✅ Pronto"
statusText.TextColor3 = currentTheme.TextSecondary
statusText.TextSize = 10
statusText.Font = Enum.Font.GothamSemibold
statusText.TextXAlignment = Enum.TextXAlignment.Left
statusText.Parent = statusBar

-- Separador
local sep = Instance.new("Frame")
sep.Size = UDim2.new(1, -12, 0, 1)
sep.Position = UDim2.new(0, 6, 0, 79)
sep.BackgroundColor3 = currentTheme.Primary
sep.BackgroundTransparency = 0.6
sep.BorderSizePixel = 0
sep.Parent = mainFrame

-- Abas
local tabBar = Instance.new("Frame")
tabBar.Size = UDim2.new(1, -12, 0, 28)
tabBar.Position = UDim2.new(0, 6, 0, 84)
tabBar.BackgroundColor3 = currentTheme.Surface
tabBar.BackgroundTransparency = 0.4
tabBar.BorderSizePixel = 0
tabBar.ClipsDescendants = true
tabBar.Parent = mainFrame
Instance.new("UICorner", tabBar).CornerRadius = UDim.new(0, 8)

local contentArea = Instance.new("Frame")
contentArea.Size = UDim2.new(1, -12, 0, 255)
contentArea.Position = UDim2.new(0, 6, 0, 116)
contentArea.BackgroundTransparency = 1
contentArea.ClipsDescendants = true
contentArea.Parent = mainFrame

-- ABA JOGADORES
local playersFrame = Instance.new("Frame")
playersFrame.Size = UDim2.new(1, 0, 1, 0)
playersFrame.BackgroundTransparency = 1
playersFrame.Visible = true
playersFrame.Parent = contentArea

local searchInput = Instance.new("TextBox")
searchInput.Size = UDim2.new(1, 0, 0, 26)
searchInput.BackgroundColor3 = currentTheme.Surface
searchInput.PlaceholderText = "🔍 Buscar..."
searchInput.PlaceholderColor3 = currentTheme.TextSecondary
searchInput.Text = ""
searchInput.TextColor3 = Color3.new(1, 1, 1)
searchInput.TextSize = 11
searchInput.Font = Enum.Font.Gotham
searchInput.Parent = playersFrame
Instance.new("UICorner", searchInput).CornerRadius = UDim.new(0, 8)

local playersScroll = Instance.new("ScrollingFrame")
playersScroll.Size = UDim2.new(1, 0, 1, -32)
playersScroll.Position = UDim2.new(0, 0, 0, 32)
playersScroll.BackgroundColor3 = currentTheme.Surface
playersScroll.BackgroundTransparency = 0.4
playersScroll.BorderSizePixel = 0
playersScroll.ScrollBarThickness = 4
playersScroll.ScrollBarImageColor3 = currentTheme.Primary
playersScroll.Parent = playersFrame
Instance.new("UICorner", playersScroll).CornerRadius = UDim.new(0, 8)

local playersList = Instance.new("UIListLayout")
playersList.SortOrder = Enum.SortOrder.LayoutOrder
playersList.Padding = UDim.new(0, 4)
playersList.Parent = playersScroll

-- ABA CORPOS
local corpsesFrame = Instance.new("Frame")
corpsesFrame.Size = UDim2.new(1, 0, 1, 0)
corpsesFrame.BackgroundTransparency = 1
corpsesFrame.Visible = false
corpsesFrame.Parent = contentArea

local corpsesScroll = Instance.new("ScrollingFrame")
corpsesScroll.Size = UDim2.new(1, 0, 1, 0)
corpsesScroll.BackgroundColor3 = currentTheme.Surface
corpsesScroll.BackgroundTransparency = 0.4
corpsesScroll.BorderSizePixel = 0
corpsesScroll.ScrollBarThickness = 4
corpsesScroll.ScrollBarImageColor3 = currentTheme.Danger
corpsesScroll.Parent = corpsesFrame
Instance.new("UICorner", corpsesScroll).CornerRadius = UDim.new(0, 8)

local corpsesList = Instance.new("UIListLayout")
corpsesList.SortOrder = Enum.SortOrder.LayoutOrder
corpsesList.Padding = UDim.new(0, 4)
corpsesList.Parent = corpsesScroll

local function updateCorpses()
    for _, c in pairs(corpsesScroll:GetChildren()) do if c:IsA("TextButton") then c:Destroy() end end
    local folder = Workspace:FindFirstChild("Corpses") or Workspace
    for _, obj in pairs(folder:GetChildren()) do
        if obj:IsA("Model") then
            local btn = Instance.new("TextButton")
            btn.Size = UDim2.new(1, -4, 0, 28)
            btn.BackgroundColor3 = targetCorpse == obj and currentTheme.Danger or currentTheme.Surface
            btn.Text = "💀 " .. obj.Name
            btn.TextColor3 = Color3.new(1, 1, 1)
            btn.TextSize = 11
            btn.Font = Enum.Font.GothamSemibold
            btn.AutoButtonColor = false
            btn.Parent = corpsesScroll
            Instance.new("UICorner", btn).CornerRadius = UDim.new(0, 8)
            btn.MouseButton1Click:Connect(function()
                targetCorpse = obj
                for _, c in pairs(corpsesScroll:GetChildren()) do if c:IsA("TextButton") then c.BackgroundColor3 = currentTheme.Surface end end
                btn.BackgroundColor3 = currentTheme.Danger
            end)
        end
    end
    corpsesScroll.CanvasSize = UDim2.new(0, 0, 0, corpsesList.AbsoluteContentSize.Y + 8)
end

-- Switch Tab
local curTab = "players"
local function switchTab(t)
    curTab = t
    playersFrame.Visible = (t == "players")
    corpsesFrame.Visible = (t == "corpses")
    if t == "corpses" then updateCorpses() end
    for _, c in pairs(tabBar:GetChildren()) do
        if c:IsA("TextButton") then
            local act = (t == "players" and c == tabPlr) or (t == "corpses" and c == tabCrp)
            c.BackgroundColor3 = act and currentTheme.Primary or Color3.fromRGB(255,255,255)
            c.BackgroundTransparency = act and 0.1 or 0.95
            c.TextColor3 = act and Color3.new(1,1,1) or currentTheme.TextSecondary
        end
    end
end

local tabPlr = Instance.new("TextButton")
tabPlr.Size = UDim2.new(0.47, 0, 0.75, 0)
tabPlr.Position = UDim2.new(0.015, 0, 0.125, 0)
tabPlr.BackgroundColor3 = currentTheme.Primary
tabPlr.BackgroundTransparency = 0.08
tabPlr.Text = "🎮 Jogadores"
tabPlr.TextColor3 = Color3.new(1, 1, 1)
tabPlr.TextSize = 11
tabPlr.Font = Enum.Font.GothamBold
tabPlr.AutoButtonColor = false
tabPlr.Parent = tabBar
Instance.new("UICorner", tabPlr).CornerRadius = UDim.new(0, 7)
tabPlr.MouseButton1Click:Connect(function() switchTab("players") end)

local tabCrp = Instance.new("TextButton")
tabCrp.Size = UDim2.new(0.47, 0, 0.75, 0)
tabCrp.Position = UDim2.new(0.51, 0, 0.125, 0)
tabCrp.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
tabCrp.BackgroundTransparency = 0.94
tabCrp.Text = "💀 Corpos"
tabCrp.TextColor3 = currentTheme.TextSecondary
tabCrp.TextSize = 11
tabCrp.Font = Enum.Font.GothamBold
tabCrp.AutoButtonColor = false
tabCrp.Parent = tabBar
Instance.new("UICorner", tabCrp).CornerRadius = UDim.new(0, 7)
tabCrp.MouseButton1Click:Connect(function() switchTab("corpses") end)

-- ====================== BOTÕES ======================
local btnState = {}

local function makeBtn(x, y, w, h, icon, text, color, key, cb)
    btnState[key] = btnState[key] or false
    local btn = Instance.new("TextButton")
    btn.Size = UDim2.new(w, 0, 0, h)
    btn.Position = UDim2.new(x, 0, 0, y)
    btn.BackgroundColor3 = btnState[key] and currentTheme.Success or color
    btn.Text = ""
    btn.AutoButtonColor = false
    btn.ClipsDescendants = true
    btn.Parent = mainFrame
    Instance.new("UICorner", btn).CornerRadius = UDim.new(0, 10)
    
    local ic = Instance.new("TextLabel")
    ic.Size = UDim2.new(0, 18, 1, 0)
    ic.Position = UDim2.new(0, 7, 0, 0)
    ic.BackgroundTransparency = 1
    ic.Text = btnState[key] and "✅" or icon
    ic.TextSize = 13
    ic.Font = Enum.Font.Gotham
    ic.Parent = btn
    
    local tx = Instance.new("TextLabel")
    tx.Size = UDim2.new(1, -27, 1, 0)
    tx.Position = UDim2.new(0, 25, 0, 0)
    tx.BackgroundTransparency = 1
    tx.Text = text
    tx.TextColor3 = Color3.new(1, 1, 1)
    tx.TextSize = 11
    tx.Font = Enum.Font.GothamSemibold
    tx.TextXAlignment = Enum.TextXAlignment.Left
    tx.Parent = btn
    
    btn.MouseButton1Click:Connect(function()
        btnState[key] = not btnState[key]
        TweenService:Create(btn, TweenInfo.new(0.3), {BackgroundColor3 = btnState[key] and currentTheme.Success or color}):Play()
        ic.Text = btnState[key] and "✅" or icon
        pcall(function() cb(btnState[key]) end)
    end)
    
    btn.MouseEnter:Connect(function()
        if not btnState[key] then TweenService:Create(btn, TweenInfo.new(0.2), {BackgroundColor3 = color:Lerp(Color3.fromRGB(255,255,255), 0.1)}):Play() end
    end)
    btn.MouseLeave:Connect(function()
        if not btnState[key] then TweenService:Create(btn, TweenInfo.new(0.2), {BackgroundColor3 = color}):Play() end
    end)
    
    return btn
end

makeBtn(0.03, 380, 0.47, 34, "👁️", "ESP", Color3.fromRGB(130, 45, 180), "esp", function(on)
    if on then enableESP() else disableESP() end
    statusText.Text = on and "👁️ ESP ON" or "✅ Pronto"
end)

makeBtn(0.52, 380, 0.47, 34, "🎯", "Teleport", Color3.fromRGB(75, 35, 190), "tp", function(on)
    if on then
        if not targetPlayer then
            StarterGui:SetCore("SendNotification", {Title = "Teleport", Text = "Selecione um jogador!", Duration = 2})
            btnState.tp = false; return
        end
        startTP()
        statusText.Text = "🎯 " .. targetPlayer.DisplayName
    else stopTP(); statusText.Text = "✅ Pronto" end
end)

makeBtn(0.03, 422, 0.47, 34, "👥", "Team TP", Color3.fromRGB(55, 25, 140), "team", function(on)
    if on then startTeamTP(); statusText.Text = "👥 Team TP ON" else stopTeamTP(); statusText.Text = "✅ Pronto" end
end)

makeBtn(0.52, 422, 0.47, 34, "💀", "Corpse TP", Color3.fromRGB(200, 50, 50), "corpse", function(on)
    if on then
        if not targetCorpse then
            StarterGui:SetCore("SendNotification", {Title = "Corpse TP", Text = "Selecione um corpo!", Duration = 2})
            btnState.corpse = false; return
        end
        startCorpseTP(); statusText.Text = "💀 Corpse TP ON"
    else stopCorpseTP(); statusText.Text = "✅ Pronto" end
end)

makeBtn(0.03, 464, 0.47, 34, "👻", "NoClip", Color3.fromRGB(80, 80, 160), "noclip", function(on)
    toggleNoClip(on); statusText.Text = on and "👻 NoClip ON" or "✅ Pronto"
end)

makeBtn(0.52, 464, 0.47, 34, "🕊️", "Fly", Color3.fromRGB(100, 150, 255), "fly", function(on)
    toggleFly(on); statusText.Text = on and "🕊️ Fly ON" or "✅ Pronto"
end)

-- ====================== LISTA DE JOGADORES ======================
local function updatePlayers()
    for _, c in pairs(playersScroll:GetChildren()) do if c:IsA("TextButton") then c:Destroy() end end
    local s = searchInput.Text:lower()
    for _, p in pairs(Players:GetPlayers()) do
        if p ~= player and (s == "" or p.Name:lower():find(s) or p.DisplayName:lower():find(s)) then
            local btn = Instance.new("TextButton")
            btn.Size = UDim2.new(1, -4, 0, 30)
            btn.BackgroundColor3 = targetPlayer == p and currentTheme.Primary or currentTheme.Surface
            btn.Text = ""; btn.AutoButtonColor = false; btn.Parent = playersScroll
            Instance.new("UICorner", btn).CornerRadius = UDim.new(0, 8)
            
            local dot = Instance.new("Frame")
            dot.Size = UDim2.new(0, 8, 0, 8); dot.Position = UDim2.new(0, 8, 0.5, -4)
            dot.BackgroundColor3 = p.Team == player.Team and Color3.fromRGB(80,255,120) or Color3.fromRGB(255,80,80)
            dot.BorderSizePixel = 0; dot.Parent = btn; Instance.new("UICorner", dot).CornerRadius = UDim.new(1, 0)
            
            local nm = Instance.new("TextLabel")
            nm.Size = UDim2.new(1, -45, 1, 0); nm.Position = UDim2.new(0, 22, 0, 0)
            nm.BackgroundTransparency = 1; nm.Text = p.DisplayName
            nm.TextColor3 = Color3.new(1,1,1); nm.TextSize = 11
            nm.Font = Enum.Font.GothamSemibold; nm.TextXAlignment = Enum.TextXAlignment.Left; nm.Parent = btn
            
            btn.MouseEnter:Connect(function() if targetPlayer ~= p then TweenService:Create(btn, TweenInfo.new(0.2), {BackgroundColor3 = currentTheme.Primary:Lerp(Color3.fromRGB(0,0,0), 0.5)}):Play() end end)
            btn.MouseLeave:Connect(function() if targetPlayer ~= p then TweenService:Create(btn, TweenInfo.new(0.2), {BackgroundColor3 = currentTheme.Surface}):Play() end end)
            btn.MouseButton1Click:Connect(function()
                targetPlayer = p
                for _, c in pairs(playersScroll:GetChildren()) do if c:IsA("TextButton") then c.BackgroundColor3 = currentTheme.Surface end end
                btn.BackgroundColor3 = currentTheme.Primary
                statusText.Text = "👤 " .. p.DisplayName
            end)
        end
    end
    playersScroll.CanvasSize = UDim2.new(0, 0, 0, playersList.AbsoluteContentSize.Y + 8)
end

searchInput:GetPropertyChangedSignal("Text"):Connect(updatePlayers)
Players.PlayerAdded:Connect(updatePlayers)
Players.PlayerRemoving:Connect(function(p) wait(0.1); if targetPlayer == p then targetPlayer = nil end; updatePlayers() end)
spawn(function() while true do updatePlayers(); wait(3) end end)
updatePlayers()

-- ====================== APLICAR TEMA ======================
function applyTheme()
    currentTheme = Themes[Settings.UI_Theme]
    mainFrame.BackgroundColor3 = currentTheme.Background
    mainFrame.UIStroke.Color = currentTheme.Primary
    header.BackgroundColor3 = currentTheme.Surface
    logo.Text = currentTheme.Icon
    sub.TextColor3 = currentTheme.Accent
    statusBar.BackgroundColor3 = currentTheme.SurfaceLight
    statusText.TextColor3 = currentTheme.TextSecondary
    statusDot.BackgroundColor3 = currentTheme.Success
    sep.BackgroundColor3 = currentTheme.Primary
    searchInput.BackgroundColor3 = currentTheme.Surface
    playersScroll.BackgroundColor3 = currentTheme.Surface
    playersScroll.ScrollBarImageColor3 = currentTheme.Primary
    corpsesScroll.BackgroundColor3 = currentTheme.Surface
    corpsesScroll.ScrollBarImageColor3 = currentTheme.Danger
    updatePlayers()
end

-- ====================== COMANDO ======================
player.Chatted:Connect(function(msg)
    if msg:lower() == "/midhub" or msg:lower() == "/mh" then
        mainFrame.Visible = not mainFrame.Visible
    end
end)

StarterGui:SetCore("SendNotification", {
    Title = "✅ MIDHUB v10.2",
    Text = "100% Corrigido! /midhub",
    Duration = 4,
})

print("✅ MIDHUB v10.2 - 100% CORRIGIDO E FUNCIONAL!")
