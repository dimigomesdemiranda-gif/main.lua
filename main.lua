-- LocalScript → StarterPlayer > StarterPlayerScripts
-- MIDHUB v6.1 - SEGURO (Sem Fly e Infinite Jump)

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
    ESP_ShowNames = true,
    ESP_ShowHealth = true,
    ESP_ShowDistance = true,
    ESP_ShowBoxes = true,
    ESP_ShowTracers = true,
    ESP_ShowHeadDot = true,
    ESP_ShowWeapon = false,
    ESP_TextSize = 13,
    ESP_TeamCheck = false,
    
    Teleport_Enabled = false,
    Teleport_TeamMode = false,
    Teleport_Distance = 3,
    Teleport_Height = 0,
    
    AntiFall_Enabled = true,
    NoClip_Enabled = false,
    FullBright_Enabled = false,
    AutoRespawn = false,
    
    UI_Theme = "Purple",
}

-- ====================== TEMAS ======================
local Themes = {
    Purple = {
        Primary = Color3.fromRGB(140, 70, 255),
        Secondary = Color3.fromRGB(100, 50, 200),
        Background = Color3.fromRGB(12, 10, 25),
        Surface = Color3.fromRGB(20, 16, 40),
        Accent = Color3.fromRGB(255, 80, 200),
        Text = Color3.fromRGB(230, 200, 255),
        TextSecondary = Color3.fromRGB(160, 140, 200),
        Success = Color3.fromRGB(80, 255, 120),
        Warning = Color3.fromRGB(255, 200, 60),
        Danger = Color3.fromRGB(255, 70, 70),
        Name = "Roxo Cósmico",
        Icon = "💜",
    },
    Midnight = {
        Primary = Color3.fromRGB(60, 130, 255),
        Secondary = Color3.fromRGB(40, 90, 200),
        Background = Color3.fromRGB(8, 12, 20),
        Surface = Color3.fromRGB(15, 20, 35),
        Accent = Color3.fromRGB(80, 200, 255),
        Text = Color3.fromRGB(200, 220, 255),
        TextSecondary = Color3.fromRGB(140, 170, 220),
        Success = Color3.fromRGB(80, 255, 180),
        Warning = Color3.fromRGB(255, 220, 80),
        Danger = Color3.fromRGB(255, 90, 90),
        Name = "Azul Meia-Noite",
        Icon = "🌙",
    },
    Crimson = {
        Primary = Color3.fromRGB(255, 60, 60),
        Secondary = Color3.fromRGB(200, 40, 40),
        Background = Color3.fromRGB(25, 10, 10),
        Surface = Color3.fromRGB(35, 15, 15),
        Accent = Color3.fromRGB(255, 150, 80),
        Text = Color3.fromRGB(255, 200, 200),
        TextSecondary = Color3.fromRGB(220, 140, 140),
        Success = Color3.fromRGB(120, 255, 120),
        Warning = Color3.fromRGB(255, 255, 80),
        Danger = Color3.fromRGB(255, 50, 50),
        Name = "Vermelho Carmesim",
        Icon = "❤️",
    },
    Emerald = {
        Primary = Color3.fromRGB(40, 220, 120),
        Secondary = Color3.fromRGB(30, 170, 90),
        Background = Color3.fromRGB(8, 20, 12),
        Surface = Color3.fromRGB(12, 28, 18),
        Accent = Color3.fromRGB(100, 255, 160),
        Text = Color3.fromRGB(180, 255, 210),
        TextSecondary = Color3.fromRGB(130, 220, 170),
        Success = Color3.fromRGB(80, 255, 150),
        Warning = Color3.fromRGB(255, 240, 80),
        Danger = Color3.fromRGB(255, 100, 100),
        Name = "Verde Esmeralda",
        Icon = "💚",
    },
    Gold = {
        Primary = Color3.fromRGB(255, 180, 40),
        Secondary = Color3.fromRGB(200, 140, 30),
        Background = Color3.fromRGB(20, 15, 5),
        Surface = Color3.fromRGB(30, 22, 8),
        Accent = Color3.fromRGB(255, 220, 100),
        Text = Color3.fromRGB(255, 230, 180),
        TextSecondary = Color3.fromRGB(220, 190, 140),
        Success = Color3.fromRGB(150, 255, 100),
        Warning = Color3.fromRGB(255, 255, 100),
        Danger = Color3.fromRGB(255, 100, 100),
        Name = "Dourado Real",
        Icon = "👑",
    },
}

local currentTheme = Themes[Settings.UI_Theme]

-- ====================== NOTIFICAÇÕES ======================
local function notify(title, message, duration)
    StarterGui:SetCore("SendNotification", {
        Title = title,
        Text = message,
        Duration = duration or 3,
    })
end

-- ====================== ANTI FALL ======================
local function applyAntiFall(character)
    if not character or not Settings.AntiFall_Enabled then return end
    local humanoid = character:WaitForChild("Humanoid", 5)
    if humanoid then
        humanoid:SetStateEnabled(Enum.HumanoidStateType.FallingDown, false)
        humanoid.StateChanged:Connect(function(_, newState)
            if newState == Enum.HumanoidStateType.FallingDown then
                humanoid:ChangeState(Enum.HumanoidStateType.GettingUp)
            end
        end)
    end
end
player.CharacterAdded:Connect(applyAntiFall)
if player.Character then applyAntiFall(player.Character) end

-- ====================== FULLBRIGHT ======================
local function toggleFullBright(enabled)
    Settings.FullBright_Enabled = enabled
    if enabled then
        Lighting.Brightness = 3
        Lighting.ClockTime = 14
        Lighting.FogEnd = 9999
        Lighting.GlobalShadows = false
        Lighting.OutdoorAmbient = Color3.fromRGB(128, 128, 128)
    else
        Lighting.Brightness = 2
        Lighting.ClockTime = 14
        Lighting.FogEnd = 1000
        Lighting.GlobalShadows = true
        Lighting.OutdoorAmbient = Color3.fromRGB(70, 70, 70)
    end
end

-- ====================== NOCLIP ======================
local noclipConnection = nil
local function toggleNoClip(enabled)
    Settings.NoClip_Enabled = enabled
    if enabled then
        noclipConnection = RunService.Stepped:Connect(function()
            if not Settings.NoClip_Enabled then
                if noclipConnection then noclipConnection:Disconnect(); noclipConnection = nil end
                return
            end
            if player.Character then
                for _, part in pairs(player.Character:GetDescendants()) do
                    if part:IsA("BasePart") then
                        part.CanCollide = false
                    end
                end
            end
        end)
    else
        if noclipConnection then noclipConnection:Disconnect(); noclipConnection = nil end
        if player.Character then
            for _, part in pairs(player.Character:GetDescendants()) do
                if part:IsA("BasePart") then
                    part.CanCollide = true
                end
            end
        end
    end
end

-- ====================== AUTO RESPAWN ======================
player.CharacterAdded:Connect(function(char)
    local humanoid = char:WaitForChild("Humanoid", 5)
    if humanoid then
        humanoid.Died:Connect(function()
            if Settings.AutoRespawn then
                wait(1)
                Players:Chat(":respawn " .. player.Name)
            end
        end)
    end
end)

-- ====================== TELEPORT ======================
local targetPlayer = nil
local isTeleporting = false
local teleportConnection = nil
local teamTPConnection = nil
local currentTeamTarget = nil

local function getRandomTeammate()
    local teammates = {}
    for _, plr in pairs(Players:GetPlayers()) do
        if plr ~= player and plr.Team == player.Team and plr.Character and plr.Character:FindFirstChild("HumanoidRootPart") then
            local humanoid = plr.Character:FindFirstChild("Humanoid")
            if humanoid and humanoid.Health > 0 then table.insert(teammates, plr) end
        end
    end
    if #teammates > 0 then
        if #teammates > 1 and currentTeamTarget then
            local filtered = {}
            for _, t in pairs(teammates) do
                if t.Character ~= currentTeamTarget then table.insert(filtered, t) end
            end
            if #filtered > 0 then return filtered[math.random(1, #filtered)] end
        end
        return teammates[math.random(1, #teammates)]
    end
    return nil
end

local function teleportBehind(target)
    if not target or not target.Character or not target.Character:FindFirstChild("HumanoidRootPart") then return end
    if not player.Character or not player.Character:FindFirstChild("HumanoidRootPart") then return end
    local targetHRP = target.Character.HumanoidRootPart
    local behindDirection = -targetHRP.CFrame.LookVector
    local newPosition = targetHRP.Position + (behindDirection * Settings.Teleport_Distance) + Vector3.new(0, Settings.Teleport_Height, 0)
    local playerRotation = player.Character.HumanoidRootPart.CFrame - player.Character.HumanoidRootPart.Position
    player.Character.HumanoidRootPart.CFrame = CFrame.new(newPosition) * playerRotation
end

local function startTeamTP()
    if teamTPConnection then return end
    local firstTarget = getRandomTeammate()
    if firstTarget then currentTeamTarget = firstTarget.Character end
    teamTPConnection = RunService.Heartbeat:Connect(function()
        if not Settings.Teleport_TeamMode then
            if teamTPConnection then teamTPConnection:Disconnect(); teamTPConnection = nil end
            currentTeamTarget = nil; return
        end
        local targetValid = false
        if currentTeamTarget and currentTeamTarget.Parent and currentTeamTarget:FindFirstChild("HumanoidRootPart") then
            local humanoid = currentTeamTarget:FindFirstChild("Humanoid")
            if humanoid and humanoid.Health > 0 then targetValid = true end
        end
        if not targetValid then
            local newTarget = getRandomTeammate()
            if newTarget and newTarget.Character then currentTeamTarget = newTarget.Character else return end
        end
        if currentTeamTarget and player.Character and player.Character:FindFirstChild("HumanoidRootPart") then
            local targetHRP = currentTeamTarget.HumanoidRootPart
            local behindDirection = -targetHRP.CFrame.LookVector
            local newPosition = targetHRP.Position + (behindDirection * Settings.Teleport_Distance) + Vector3.new(0, Settings.Teleport_Height, 0)
            local playerRotation = player.Character.HumanoidRootPart.CFrame - player.Character.HumanoidRootPart.Position
            player.Character.HumanoidRootPart.CFrame = CFrame.new(newPosition) * playerRotation
        end
    end)
end

local function stopTeamTP()
    Settings.Teleport_TeamMode = false
    if teamTPConnection then teamTPConnection:Disconnect(); teamTPConnection = nil end
    currentTeamTarget = nil
end

-- ====================== ESP ======================
local espObjects = {}

local function createESP(target, index)
    if not target.Character then return end
    local char = target.Character
    local head = char:FindFirstChild("Head")
    local humanoid = char:FindFirstChild("Humanoid")
    if not head then return end

    if Settings.ESP_TeamCheck and target.Team == player.Team then return end

    if espObjects[target] then
        local old = espObjects[target]
        pcall(function() if old.highlight then old.highlight:Destroy() end end)
        pcall(function() if old.billboard then old.billboard:Destroy() end end)
        pcall(function() if old.tracer then old.tracer:Remove() end end)
        pcall(function() if old.headDot then old.headDot:Remove() end end)
        if old.connections then for _, c in pairs(old.connections) do c:Disconnect() end end
    end

    local data = {connections = {}}

    if Settings.ESP_ShowBoxes then
        local hl = Instance.new("Highlight")
        hl.FillColor = currentTheme.Accent
        hl.FillTransparency = 0.8
        hl.OutlineColor = currentTheme.Primary
        hl.OutlineTransparency = 0.2
        hl.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
        hl.Parent = char
        data.highlight = hl
    end

    if Settings.ESP_ShowHeadDot then
        local dot = Drawing.new("Circle")
        dot.Color = Color3.fromRGB(255, 40, 40)
        dot.Filled = true
        dot.Transparency = 0.4
        dot.Radius = 5
        dot.Visible = false
        local dotConn = RunService.RenderStepped:Connect(function()
            if not char or not char.Parent or not char:FindFirstChild("Head") then dot.Visible = false; return end
            local p, v = Camera:WorldToViewportPoint(char.Head.Position)
            if v and p.Z > 0 then dot.Position = Vector2.new(p.X, p.Y); dot.Visible = true else dot.Visible = false end
        end)
        table.insert(data.connections, dotConn)
        data.headDot = dot
    end

    local billboard = Instance.new("BillboardGui")
    billboard.Size = UDim2.new(0, 200, 0, 65)
    billboard.StudsOffset = Vector3.new(0, 2.2 + (index * 0.55), 0)
    billboard.AlwaysOnTop = true
    billboard.MaxDistance = Settings.ESP_MaxDistance
    billboard.Parent = head
    data.billboard = billboard

    local frame = Instance.new("Frame", billboard)
    frame.Size = UDim2.new(1, 0, 1, 0)
    frame.BackgroundColor3 = currentTheme.Surface
    frame.BackgroundTransparency = 0.3
    frame.BorderSizePixel = 0
    Instance.new("UICorner", frame).CornerRadius = UDim.new(0, 8)
    Instance.new("UIStroke", frame).Color = currentTheme.Primary
    frame.UIStroke.Thickness = 1.5
    frame.UIStroke.Transparency = 0.4

    local nameLabel = Instance.new("TextLabel", frame)
    nameLabel.Size = UDim2.new(1, -10, 0.35, 0)
    nameLabel.Position = UDim2.new(0, 5, 0, 2)
    nameLabel.BackgroundTransparency = 1
    nameLabel.Text = target.DisplayName
    nameLabel.TextColor3 = Color3.new(1,1,1)
    nameLabel.TextSize = Settings.ESP_TextSize
    nameLabel.Font = Enum.Font.GothamBlack
    nameLabel.TextXAlignment = Enum.TextXAlignment.Center

    local healthLabel = Instance.new("TextLabel", frame)
    healthLabel.Size = UDim2.new(0.5, -5, 0.3, 0)
    healthLabel.Position = UDim2.new(0, 5, 0.38, 0)
    healthLabel.BackgroundTransparency = 1
    healthLabel.Text = "❤️ " .. (humanoid and math.floor(humanoid.Health) or "?")
    healthLabel.TextColor3 = currentTheme.Success
    healthLabel.TextSize = Settings.ESP_TextSize - 2
    healthLabel.Font = Enum.Font.GothamBold
    healthLabel.TextXAlignment = Enum.TextXAlignment.Left

    local distLabel = Instance.new("TextLabel", frame)
    distLabel.Size = UDim2.new(0.5, -5, 0.3, 0)
    distLabel.Position = UDim2.new(0.5, 0, 0.38, 0)
    distLabel.BackgroundTransparency = 1
    distLabel.Text = "📏 0m"
    distLabel.TextColor3 = currentTheme.TextSecondary
    distLabel.TextSize = Settings.ESP_TextSize - 2
    distLabel.Font = Enum.Font.GothamBold
    distLabel.TextXAlignment = Enum.TextXAlignment.Right

    if Settings.ESP_ShowWeapon then
        local weaponLabel = Instance.new("TextLabel", frame)
        weaponLabel.Size = UDim2.new(1, -10, 0.2, 0)
        weaponLabel.Position = UDim2.new(0, 5, 0, 0.72)
        weaponLabel.BackgroundTransparency = 1
        weaponLabel.Text = "🔫 ?"
        weaponLabel.TextColor3 = currentTheme.Warning
        weaponLabel.TextSize = 9
        weaponLabel.Font = Enum.Font.Gotham
        weaponLabel.TextXAlignment = Enum.TextXAlignment.Center
        
        local function updateWeapon()
            local tool = char:FindFirstChildOfClass("Tool")
            weaponLabel.Text = tool and "🔫 " .. tool.Name or "🔫 None"
        end
        local wc1 = char.ChildAdded:Connect(function(c) if c:IsA("Tool") then updateWeapon() end end)
        local wc2 = char.ChildRemoved:Connect(function(c) if c:IsA("Tool") then updateWeapon() end end)
        table.insert(data.connections, wc1)
        table.insert(data.connections, wc2)
        updateWeapon()
    end

    if humanoid then
        local hc = humanoid.HealthChanged:Connect(function(hp)
            local pct = hp / humanoid.MaxHealth
            healthLabel.Text = "❤️ " .. math.floor(hp)
            if pct > 0.6 then healthLabel.TextColor3 = currentTheme.Success
            elseif pct > 0.3 then healthLabel.TextColor3 = currentTheme.Warning
            else healthLabel.TextColor3 = currentTheme.Danger end
            if hp <= 0 then
                pcall(function() if data.highlight then data.highlight:Destroy() end end)
                pcall(function() if data.billboard then data.billboard:Destroy() end end)
            end
        end)
        table.insert(data.connections, hc)
    end

    local dc = RunService.RenderStepped:Connect(function()
        if not char or not char.Parent or not char:FindFirstChild("HumanoidRootPart") then return end
        local myRoot = player.Character and player.Character:FindFirstChild("HumanoidRootPart")
        local targetRoot = char.HumanoidRootPart
        if myRoot and targetRoot then
            local dist = (myRoot.Position - targetRoot.Position).Magnitude
            distLabel.Text = "📏 " .. math.floor(dist) .. "m"
            if dist < 15 then distLabel.TextColor3 = currentTheme.Danger
            elseif dist < 40 then distLabel.TextColor3 = currentTheme.Warning
            else distLabel.TextColor3 = currentTheme.Success end
        end
    end)
    table.insert(data.connections, dc)

    if Settings.ESP_ShowTracers then
        local tracer = Drawing.new("Line")
        tracer.Color = currentTheme.Primary
        tracer.Thickness = 0.6
        tracer.Transparency = 0.65
        tracer.Visible = false
        local tc = RunService.RenderStepped:Connect(function()
            if not char or not char.Parent or not char:FindFirstChild("HumanoidRootPart") then tracer.Visible = false; return end
            local p, v = Camera:WorldToViewportPoint(char.HumanoidRootPart.Position)
            if v and p.Z > 0 then
                tracer.From = Vector2.new(Camera.ViewportSize.X / 2, Camera.ViewportSize.Y)
                tracer.To = Vector2.new(p.X, p.Y)
                tracer.Visible = true
            else tracer.Visible = false end
        end)
        table.insert(data.connections, tc)
        data.tracer = tracer
    end

    local cr = char.AncestryChanged:Connect(function()
        if not char.Parent then
            pcall(function() if data.highlight then data.highlight:Destroy() end end)
            pcall(function() if data.billboard then data.billboard:Destroy() end end)
            pcall(function() if data.tracer then data.tracer:Remove() end end)
            pcall(function() if data.headDot then data.headDot:Remove() end end)
            for _, c in pairs(data.connections) do c:Disconnect() end
            espObjects[target] = nil
        end
    end)
    table.insert(data.connections, cr)

    espObjects[target] = data
end

local function refreshESP()
    if not Settings.ESP_Enabled then return end
    for _, d in pairs(espObjects) do
        pcall(function() if d.highlight then d.highlight:Destroy() end end)
        pcall(function() if d.billboard then d.billboard:Destroy() end end)
        pcall(function() if d.tracer then d.tracer:Remove() end end)
        pcall(function() if d.headDot then d.headDot:Remove() end end)
        if d.connections then for _, c in pairs(d.connections) do c:Disconnect() end end
    end
    espObjects = {}
    local players = {}
    for _, p in pairs(Players:GetPlayers()) do
        if p ~= player then table.insert(players, p) end
    end
    for i, p in ipairs(players) do
        if p.Character then createESP(p, i) end
    end
end

local function enableESP() Settings.ESP_Enabled = true; refreshESP() end
local function disableESP()
    Settings.ESP_Enabled = false
    for _, d in pairs(espObjects) do
        pcall(function() if d.highlight then d.highlight:Destroy() end end)
        pcall(function() if d.billboard then d.billboard:Destroy() end end)
        pcall(function() if d.tracer then d.tracer:Remove() end end)
        pcall(function() if d.headDot then d.headDot:Remove() end end)
        if d.connections then for _, c in pairs(d.connections) do c:Disconnect() end end
    end
    espObjects = {}
end

-- ====================== GUI ======================
local screenGui = Instance.new("ScreenGui")
screenGui.Name = "MIDHUB"
screenGui.ResetOnSpawn = false
screenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
screenGui.Parent = player:WaitForChild("PlayerGui")

local mainFrame = Instance.new("Frame")
mainFrame.Size = UDim2.new(0, 330, 0, 540)
mainFrame.Position = UDim2.new(0, 8, 0.5, -270)
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
header.Size = UDim2.new(1, 0, 0, 50)
header.BackgroundColor3 = currentTheme.Surface
header.BorderSizePixel = 0
header.Parent = mainFrame
Instance.new("UICorner", header).CornerRadius = UDim.new(0, 16)

local headerLine = Instance.new("Frame")
headerLine.Size = UDim2.new(1, 0, 0, 3)
headerLine.Position = UDim2.new(0, 0, 1, -3)
headerLine.BackgroundColor3 = currentTheme.Primary
headerLine.BorderSizePixel = 0
headerLine.Parent = header

local logoIcon = Instance.new("TextLabel")
logoIcon.Size = UDim2.new(0, 36, 0, 36)
logoIcon.Position = UDim2.new(0, 10, 0, 7)
logoIcon.BackgroundTransparency = 1
logoIcon.Text = currentTheme.Icon
logoIcon.TextSize = 24
logoIcon.Font = Enum.Font.GothamBlack
logoIcon.Parent = header

local titleText = Instance.new("TextLabel")
titleText.Size = UDim2.new(1, -60, 0, 28)
titleText.Position = UDim2.new(0, 52, 0, 5)
titleText.BackgroundTransparency = 1
titleText.Text = "MIDHUB v6.1"
titleText.TextColor3 = Color3.new(1,1,1)
titleText.TextSize = 16
titleText.Font = Enum.Font.GothamBlack
titleText.TextXAlignment = Enum.TextXAlignment.Left
titleText.Parent = header

-- Status
local statusBar = Instance.new("Frame")
statusBar.Size = UDim2.new(1, -16, 0, 26)
statusBar.Position = UDim2.new(0, 8, 0, 56)
statusBar.BackgroundColor3 = currentTheme.Surface
statusBar.BorderSizePixel = 0
statusBar.Parent = mainFrame
Instance.new("UICorner", statusBar).CornerRadius = UDim.new(0, 8)

local statusText = Instance.new("TextLabel")
statusText.Size = UDim2.new(1, -10, 1, 0)
statusText.Position = UDim2.new(0, 5, 0, 0)
statusText.BackgroundTransparency = 1
statusText.Text = "✅ Sistema Pronto"
statusText.TextColor3 = currentTheme.TextSecondary
statusText.TextSize = 10
statusText.Font = Enum.Font.GothamSemibold
statusText.TextXAlignment = Enum.TextXAlignment.Left
statusText.Parent = statusBar

-- Separador
local sep = Instance.new("Frame")
sep.Size = UDim2.new(1, -16, 0, 1)
sep.Position = UDim2.new(0, 8, 0, 88)
sep.BackgroundColor3 = currentTheme.Primary
sep.BackgroundTransparency = 0.6
sep.BorderSizePixel = 0
sep.Parent = mainFrame

-- Abas
local tabBar = Instance.new("Frame")
tabBar.Size = UDim2.new(1, -16, 0, 28)
tabBar.Position = UDim2.new(0, 8, 0, 94)
tabBar.BackgroundTransparency = 1
tabBar.Parent = mainFrame

local currentTab = "players"

local contentArea = Instance.new("Frame")
contentArea.Size = UDim2.new(1, -16, 0, 290)
contentArea.Position = UDim2.new(0, 8, 0, 126)
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
searchInput.Size = UDim2.new(1, 0, 0, 28)
searchInput.BackgroundColor3 = currentTheme.Surface
searchInput.PlaceholderText = "🔍 Buscar jogador..."
searchInput.PlaceholderColor3 = currentTheme.TextSecondary
searchInput.Text = ""
searchInput.TextColor3 = Color3.new(1,1,1)
searchInput.TextSize = 12
searchInput.Font = Enum.Font.Gotham
searchInput.Parent = playersFrame
Instance.new("UICorner", searchInput).CornerRadius = UDim.new(0, 8)

local playersScroll = Instance.new("ScrollingFrame")
playersScroll.Size = UDim2.new(1, 0, 1, -34)
playersScroll.Position = UDim2.new(0, 0, 0, 34)
playersScroll.BackgroundColor3 = currentTheme.Surface
playersScroll.BackgroundTransparency = 0.5
playersScroll.BorderSizePixel = 0
playersScroll.ScrollBarThickness = 4
playersScroll.ScrollBarImageColor3 = currentTheme.Primary
playersScroll.Parent = playersFrame
Instance.new("UICorner", playersScroll).CornerRadius = UDim.new(0, 10)

local playersListLayout = Instance.new("UIListLayout")
playersListLayout.SortOrder = Enum.SortOrder.LayoutOrder
playersListLayout.Padding = UDim.new(0, 4)
playersListLayout.Parent = playersScroll

-- ABA CONFIG
local configFrame = Instance.new("Frame")
configFrame.Size = UDim2.new(1, 0, 1, 0)
configFrame.BackgroundTransparency = 1
configFrame.Visible = false
configFrame.Parent = contentArea

local configScroll = Instance.new("ScrollingFrame")
configScroll.Size = UDim2.new(1, 0, 1, 0)
configScroll.BackgroundTransparency = 1
configScroll.BorderSizePixel = 0
configScroll.ScrollBarThickness = 4
configScroll.ScrollBarImageColor3 = currentTheme.Primary
configScroll.Parent = configFrame

local configLayout = Instance.new("UIListLayout")
configLayout.SortOrder = Enum.SortOrder.LayoutOrder
configLayout.Padding = UDim.new(0, 6)
configLayout.Parent = configScroll

local cfgTitle1 = Instance.new("TextLabel")
cfgTitle1.Size = UDim2.new(1, 0, 0, 20)
cfgTitle1.BackgroundTransparency = 1
cfgTitle1.Text = "🎨 Temas"
cfgTitle1.TextColor3 = Color3.new(1,1,1)
cfgTitle1.TextSize = 13
cfgTitle1.Font = Enum.Font.GothamBlack
cfgTitle1.TextXAlignment = Enum.TextXAlignment.Left
cfgTitle1.Parent = configScroll

for _, themeName in pairs({"Purple", "Midnight", "Crimson", "Emerald", "Gold"}) do
    local theme = Themes[themeName]
    local btn = Instance.new("TextButton")
    btn.Size = UDim2.new(1, 0, 0, 38)
    btn.BackgroundColor3 = theme.Primary
    btn.Text = theme.Icon .. "  " .. theme.Name
    btn.TextColor3 = Color3.new(1,1,1)
    btn.TextSize = 12
    btn.Font = Enum.Font.GothamBold
    btn.AutoButtonColor = false
    btn.Parent = configScroll
    Instance.new("UICorner", btn).CornerRadius = UDim.new(0, 10)
    
    if themeName == Settings.UI_Theme then
        local ind = Instance.new("Frame", btn)
        ind.Size = UDim2.new(0, 5, 1, -10)
        ind.Position = UDim2.new(1, -10, 0, 5)
        ind.BackgroundColor3 = Color3.fromRGB(80, 255, 120)
        ind.BorderSizePixel = 0
        Instance.new("UICorner", ind).CornerRadius = UDim.new(0, 2)
    end
    
    btn.MouseButton1Click:Connect(function()
        Settings.UI_Theme = themeName
        applyTheme()
        for _, c in pairs(configScroll:GetChildren()) do
            if c:IsA("TextButton") and c ~= cfgTitle1 then
                local old = c:FindFirstChild("Frame")
                if old then old:Destroy() end
                if c == btn then
                    local ind = Instance.new("Frame", c)
                    ind.Size = UDim2.new(0, 5, 1, -10)
                    ind.Position = UDim2.new(1, -10, 0, 5)
                    ind.BackgroundColor3 = Color3.fromRGB(80, 255, 120)
                    ind.BorderSizePixel = 0
                    Instance.new("UICorner", ind).CornerRadius = UDim.new(0, 2)
                end
            end
        end
        statusText.Text = "Tema: " .. theme.Name
    end)
end

local cfgTitle2 = Instance.new("TextLabel")
cfgTitle2.Size = UDim2.new(1, 0, 0, 20)
cfgTitle2.BackgroundTransparency = 1
cfgTitle2.Text = "⚡ Funções"
cfgTitle2.TextColor3 = Color3.new(1,1,1)
cfgTitle2.TextSize = 13
cfgTitle2.Font = Enum.Font.GothamBlack
cfgTitle2.TextXAlignment = Enum.TextXAlignment.Left
cfgTitle2.Parent = configScroll

local function configToggle(text, icon, callback)
    local btn = Instance.new("TextButton")
    btn.Size = UDim2.new(1, 0, 0, 34)
    btn.BackgroundColor3 = currentTheme.Surface
    btn.Text = ""
    btn.AutoButtonColor = false
    btn.Parent = configScroll
    Instance.new("UICorner", btn).CornerRadius = UDim.new(0, 8)
    
    local ic = Instance.new("TextLabel")
    ic.Size = UDim2.new(0, 24, 1, 0)
    ic.Position = UDim2.new(0, 8, 0, 0)
    ic.BackgroundTransparency = 1
    ic.Text = icon
    ic.TextSize = 14
    ic.Font = Enum.Font.Gotham
    ic.Parent = btn
    
    local tx = Instance.new("TextLabel")
    tx.Size = UDim2.new(1, -40, 1, 0)
    tx.Position = UDim2.new(0, 34, 0, 0)
    tx.BackgroundTransparency = 1
    tx.Text = text
    tx.TextColor3 = Color3.new(1,1,1)
    tx.TextSize = 11
    tx.Font = Enum.Font.GothamSemibold
    tx.TextXAlignment = Enum.TextXAlignment.Left
    tx.Parent = btn
    
    local on = false
    btn.MouseButton1Click:Connect(function()
        on = not on
        btn.BackgroundColor3 = on and currentTheme.Success or currentTheme.Surface
        ic.Text = on and "✅" or icon
        pcall(function() callback(on) end)
    end)
    return btn
end

configToggle("FullBright", "💡", toggleFullBright)
configToggle("NoClip", "👻", toggleNoClip)
configToggle("Auto Respawn", "🔄", function(on) Settings.AutoRespawn = on end)
configToggle("ESP Time Check", "🛡️", function(on) Settings.ESP_TeamCheck = on; if Settings.ESP_Enabled then refreshESP() end end)
configToggle("ESP Weapon", "🔫", function(on) Settings.ESP_ShowWeapon = on; if Settings.ESP_Enabled then refreshESP() end end)

configScroll.CanvasSize = UDim2.new(0, 0, 0, configLayout.AbsoluteContentSize.Y + 20)

-- ABA INFO
local infoFrame = Instance.new("Frame")
infoFrame.Size = UDim2.new(1, 0, 1, 0)
infoFrame.BackgroundTransparency = 1
infoFrame.Visible = false
infoFrame.Parent = contentArea

local infoContent = Instance.new("TextLabel")
infoContent.Size = UDim2.new(1, 0, 1, 0)
infoContent.BackgroundTransparency = 1
infoContent.Text = [[
🚀 MIDHUB v6.1

⭐ FUNCIONALIDADES ⭐

👁️ ESP Avançado
🎯 Teleport
👥 Team TP Grudado
👻 NoClip
💡 FullBright
🔄 Auto Respawn
🎨 5 Temas
🛡️ Anti-Fall

💬 /midhub - Abrir/Fechar

Desenvolvido com 💜
]]
infoContent.TextColor3 = currentTheme.TextSecondary
infoContent.TextSize = 11
infoContent.Font = Enum.Font.Gotham
infoContent.TextXAlignment = Enum.TextXAlignment.Left
infoContent.TextWrapped = true
infoContent.LineHeight = 1.6
infoContent.Parent = infoFrame

-- Switch Tab
local function switchTab(tab)
    currentTab = tab
    playersFrame.Visible = (tab == "players")
    configFrame.Visible = (tab == "config")
    infoFrame.Visible = (tab == "info")
    
    for _, child in pairs(tabBar:GetChildren()) do
        if child:IsA("TextButton") then
            local isActive = false
            if tab == "players" and child.Text:find("Jogadores") then isActive = true
            elseif tab == "config" and child.Text:find("Config") then isActive = true
            elseif tab == "info" and child.Text:find("Info") then isActive = true end
            
            child.BackgroundColor3 = isActive and currentTheme.Primary or currentTheme.Surface
            child.TextColor3 = isActive and Color3.new(1,1,1) or currentTheme.TextSecondary
        end
    end
end

local tabPlayers = Instance.new("TextButton")
tabPlayers.Size = UDim2.new(0.3, 0, 1, 0)
tabPlayers.Position = UDim2.new(0, 0, 0, 0)
tabPlayers.BackgroundColor3 = currentTheme.Primary
tabPlayers.Text = "🎮 Jogadores"
tabPlayers.TextColor3 = Color3.new(1,1,1)
tabPlayers.TextSize = 11
tabPlayers.Font = Enum.Font.GothamBold
tabPlayers.AutoButtonColor = false
tabPlayers.Parent = tabBar
Instance.new("UICorner", tabPlayers).CornerRadius = UDim.new(0, 8)
tabPlayers.MouseButton1Click:Connect(function() switchTab("players") end)

local tabConfig = Instance.new("TextButton")
tabConfig.Size = UDim2.new(0.3, 0, 1, 0)
tabConfig.Position = UDim2.new(0.33, 0, 0, 0)
tabConfig.BackgroundColor3 = currentTheme.Surface
tabConfig.Text = "⚙️ Config"
tabConfig.TextColor3 = currentTheme.TextSecondary
tabConfig.TextSize = 11
tabConfig.Font = Enum.Font.GothamBold
tabConfig.AutoButtonColor = false
tabConfig.Parent = tabBar
Instance.new("UICorner", tabConfig).CornerRadius = UDim.new(0, 8)
tabConfig.MouseButton1Click:Connect(function() switchTab("config") end)

local tabInfo = Instance.new("TextButton")
tabInfo.Size = UDim2.new(0.3, 0, 1, 0)
tabInfo.Position = UDim2.new(0.66, 0, 0, 0)
tabInfo.BackgroundColor3 = currentTheme.Surface
tabInfo.Text = "ℹ️ Info"
tabInfo.TextColor3 = currentTheme.TextSecondary
tabInfo.TextSize = 11
tabInfo.Font = Enum.Font.GothamBold
tabInfo.AutoButtonColor = false
tabInfo.Parent = tabBar
Instance.new("UICorner", tabInfo).CornerRadius = UDim.new(0, 8)
tabInfo.MouseButton1Click:Connect(function() switchTab("info") end)

-- Botões principais
local function makeButton(x, y, icon, text, color, callback)
    local btn = Instance.new("TextButton")
    btn.Size = UDim2.new(0.47, 0, 0, 36)
    btn.Position = UDim2.new(x, 0, 0, y)
    btn.BackgroundColor3 = color
    btn.Text = ""
    btn.AutoButtonColor = false
    btn.Parent = mainFrame
    Instance.new("UICorner", btn).CornerRadius = UDim.new(0, 10)
    
    local ic = Instance.new("TextLabel")
    ic.Size = UDim2.new(0, 20, 1, 0)
    ic.Position = UDim2.new(0, 6, 0, 0)
    ic.BackgroundTransparency = 1
    ic.Text = icon
    ic.TextSize = 14
    ic.Font = Enum.Font.Gotham
    ic.Parent = btn
    
    local tx = Instance.new("TextLabel")
    tx.Size = UDim2.new(1, -28, 1, 0)
    tx.Position = UDim2.new(0, 26, 0, 0)
    tx.BackgroundTransparency = 1
    tx.Text = text
    tx.TextColor3 = Color3.new(1,1,1)
    tx.TextSize = 11
    tx.Font = Enum.Font.GothamSemibold
    tx.TextXAlignment = Enum.TextXAlignment.Left
    tx.Parent = btn
    
    local on = false
    btn.MouseButton1Click:Connect(function()
        on = not on
        btn.BackgroundColor3 = on and currentTheme.Success or color
        ic.Text = on and "✅" or icon
        pcall(function() callback(on) end)
    end)
    return btn
end

makeButton(0.03, 422, "👁️", "ESP", Color3.fromRGB(140, 50, 180), function(on)
    if on then enableESP() else disableESP() end
    statusText.Text = on and "👁️ ESP Ativado" or "✅ Sistema Pronto"
end)

makeButton(0.52, 422, "🎯", "Teleport", Color3.fromRGB(80, 40, 200), function(on)
    if on and not targetPlayer then statusText.Text = "⚠️ Selecione um jogador!"; return end
    isTeleporting = on
    if on then
        teleportConnection = RunService.Heartbeat:Connect(function()
            if not isTeleporting then return end
            if targetPlayer then teleportBehind(targetPlayer) end
        end)
        statusText.Text = "🎯 Teleport Ativo"
    else
        if teleportConnection then teleportConnection:Disconnect(); teleportConnection = nil end
        statusText.Text = "✅ Sistema Pronto"
    end
end)

makeButton(0.03, 466, "👥", "Team TP", Color3.fromRGB(60, 30, 150), function(on)
    if on then
        Settings.Teleport_TeamMode = true
        startTeamTP()
        statusText.Text = "👥 Team TP Ativo"
    else
        stopTeamTP()
        statusText.Text = "✅ Sistema Pronto"
    end
end)

-- Distâncias
local function distBtn(x, y, icon, text, dist, height)
    local btn = Instance.new("TextButton")
    btn.Size = UDim2.new(0.22, 0, 0, 26)
    btn.Position = UDim2.new(x, 0, 0, y)
    btn.BackgroundColor3 = currentTheme.Surface
    btn.Text = icon .. " " .. text
    btn.TextColor3 = currentTheme.TextSecondary
    btn.TextSize = 10
    btn.Font = Enum.Font.GothamBold
    btn.AutoButtonColor = false
    btn.Parent = mainFrame
    Instance.new("UICorner", btn).CornerRadius = UDim.new(0, 8)
    btn.MouseButton1Click:Connect(function()
        Settings.Teleport_Distance = dist
        Settings.Teleport_Height = height
        statusText.Text = "📏 " .. text
        for _, c in pairs(mainFrame:GetChildren()) do
            if c:IsA("TextButton") and c ~= btn then
                if c.Text:find("m") then
                    c.BackgroundColor3 = currentTheme.Surface
                    c.TextColor3 = currentTheme.TextSecondary
                end
            end
        end
        btn.BackgroundColor3 = currentTheme.Primary
        btn.TextColor3 = Color3.new(1,1,1)
    end)
end

distBtn(0.03, 510, "🔴", "1m", 1, 0)
distBtn(0.27, 510, "🟡", "2m", 2, 0.5)
distBtn(0.51, 510, "🔵", "4m", 4, 1.5)
distBtn(0.75, 510, "🟣", "7m", 7, 2.5)

-- Aplicar tema
function applyTheme()
    currentTheme = Themes[Settings.UI_Theme]
    mainFrame.BackgroundColor3 = currentTheme.Background
    mainFrame.UIStroke.Color = currentTheme.Primary
    header.BackgroundColor3 = currentTheme.Surface
    headerLine.BackgroundColor3 = currentTheme.Primary
    logoIcon.Text = currentTheme.Icon
    statusBar.BackgroundColor3 = currentTheme.Surface
    statusText.TextColor3 = currentTheme.TextSecondary
    sep.BackgroundColor3 = currentTheme.Primary
    searchInput.BackgroundColor3 = currentTheme.Surface
    playersScroll.BackgroundColor3 = currentTheme.Surface
    playersScroll.ScrollBarImageColor3 = currentTheme.Primary
    
    for _, child in pairs(tabBar:GetChildren()) do
        if child:IsA("TextButton") then
            local isActive = false
            if currentTab == "players" and child.Text:find("Jogadores") then isActive = true
            elseif currentTab == "config" and child.Text:find("Config") then isActive = true
            elseif currentTab == "info" and child.Text:find("Info") then isActive = true end
            child.BackgroundColor3 = isActive and currentTheme.Primary or currentTheme.Surface
            child.TextColor3 = isActive and Color3.new(1,1,1) or currentTheme.TextSecondary
        end
    end
    
    if Settings.ESP_Enabled then refreshESP() end
    updatePlayerList()
end

-- Lista de jogadores
local function updatePlayerList()
    for _, c in pairs(playersScroll:GetChildren()) do
        if c:IsA("TextButton") then c:Destroy() end
    end
    local search = searchInput.Text:lower()
    for _, plr in pairs(Players:GetPlayers()) do
        if plr ~= player then
            if search == "" or plr.Name:lower():find(search) or plr.DisplayName:lower():find(search) then
                local btn = Instance.new("TextButton")
                btn.Size = UDim2.new(1, -6, 0, 32)
                btn.BackgroundColor3 = targetPlayer == plr and currentTheme.Primary or currentTheme.Surface
                btn.Text = ""
                btn.AutoButtonColor = false
                btn.Parent = playersScroll
                Instance.new("UICorner", btn).CornerRadius = UDim.new(0, 8)
                
                local dot = Instance.new("Frame")
                dot.Size = UDim2.new(0, 10, 0, 10)
                dot.Position = UDim2.new(0, 8, 0.5, -5)
                dot.BackgroundColor3 = plr.Team == player.Team and Color3.fromRGB(80, 255, 120) or Color3.fromRGB(255, 80, 80)
                dot.BorderSizePixel = 0
                dot.Parent = btn
                Instance.new("UICorner", dot).CornerRadius = UDim.new(1, 0)
                
                local name = Instance.new("TextLabel")
                name.Size = UDim2.new(1, -50, 1, 0)
                name.Position = UDim2.new(0, 24, 0, 0)
                name.BackgroundTransparency = 1
                name.Text = plr.DisplayName
                name.TextColor3 = Color3.new(1,1,1)
                name.TextSize = 12
                name.Font = Enum.Font.GothamSemibold
                name.TextXAlignment = Enum.TextXAlignment.Left
                name.Parent = btn
                
                btn.MouseEnter:Connect(function()
                    if targetPlayer ~= plr then
                        TweenService:Create(btn, TweenInfo.new(0.2), {BackgroundColor3 = currentTheme.Primary:Lerp(Color3.fromRGB(0,0,0), 0.5)}):Play()
                    end
                end)
                btn.MouseLeave:Connect(function()
                    if targetPlayer ~= plr then
                        TweenService:Create(btn, TweenInfo.new(0.2), {BackgroundColor3 = currentTheme.Surface}):Play()
                    end
                end)
                btn.MouseButton1Click:Connect(function()
                    targetPlayer = plr
                    for _, c in pairs(playersScroll:GetChildren()) do
                        if c:IsA("TextButton") then c.BackgroundColor3 = currentTheme.Surface end
                    end
                    btn.BackgroundColor3 = currentTheme.Primary
                    statusText.Text = "👤 Alvo: " .. plr.DisplayName
                end)
            end
        end
    end
    playersScroll.CanvasSize = UDim2.new(0, 0, 0, playersListLayout.AbsoluteContentSize.Y + 10)
end

searchInput:GetPropertyChangedSignal("Text"):Connect(updatePlayerList)
Players.PlayerAdded:Connect(updatePlayerList)
Players.PlayerRemoving:Connect(function() wait(0.1); updatePlayerList() end)
spawn(function() while true do updatePlayerList(); wait(3) end end)
updatePlayerList()

-- Comando
player.Chatted:Connect(function(msg)
    if msg:lower() == "/midhub" or msg:lower() == "/mh" then
        mainFrame.Visible = not mainFrame.Visible
    end
end)

notify("MIDHUB v6.1", "Carregado com sucesso! /midhub", 4)
print("✅ MIDHUB v6.1 - SEGURO (Sem Fly e Infinite Jump)")
