-- LocalScript → StarterPlayer > StarterPlayerScripts
-- MIDHUB v9.1 - Apocalypse Rising 2 Edition

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local Workspace = game:GetService("Workspace")
local Camera = Workspace.CurrentCamera
local Lighting = game:GetService("Lighting")
local StarterGui = game:GetService("StarterGui")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local player = Players.LocalPlayer

-- ====================== CONFIGURAÇÕES ======================
local Settings = {
    ESP_Enabled = false,
    ESP_MaxDistance = 9999,
    ESP_ShowBoxes = true,
    ESP_ShowTracers = true,
    ESP_ShowHeadDot = true,
    ESP_ShowHealth = true,
    ESP_ShowDistance = true,
    ESP_TextSize = 13,
    ESP_TeamCheck = false,
    
    Teleport_Enabled = false,
    Teleport_TeamMode = false,
    Teleport_Distance = 3,
    Teleport_Height = 0,
    
    NoClip_Enabled = false,
    FullBright_Enabled = false,
    AutoRespawn = false,
    
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

-- ====================== APOCALYPSE RISING 2 - SISTEMAS ESPECÍFICOS ======================

-- AR2: Coletar Itens (Loot ESP)
local function getAR2Loot()
    local loot = {}
    -- Procura por itens no chão (AR2 usa Model para itens)
    for _, obj in pairs(Workspace:GetDescendants()) do
        if obj:IsA("Model") or obj:IsA("Tool") then
            if obj.Name:lower():find("gun") or obj.Name:lower():find("rifle") or 
               obj.Name:lower():find("pistol") or obj.Name:lower():find("shotgun") or
               obj.Name:lower():find("ammo") or obj.Name:lower():find("magazine") or
               obj.Name:lower():find("med") or obj.Name:lower():find("bandage") or
               obj.Name:lower():find("food") or obj.Name:lower():find("drink") or
               obj.Name:lower():find("backpack") or obj.Name:lower():find("vest") or
               obj.Name:lower():find("helmet") or obj.Name:lower():find("armor") then
                table.insert(loot, obj)
            end
        end
    end
    return loot
end

-- AR2: Teleport para Item
local function teleportToLoot(lootItem)
    if not player.Character or not player.Character:FindFirstChild("HumanoidRootPart") then return end
    local myHRP = player.Character.HumanoidRootPart
    local targetPos = lootItem:GetPivot().Position
    myHRP.CFrame = CFrame.new(targetPos + Vector3.new(0, 3, 0)) * (myHRP.CFrame - myHRP.Position)
end

-- AR2: Pegar todos os itens próximos
local function collectNearbyItems()
    if not player.Character or not player.Character:FindFirstChild("HumanoidRootPart") then return end
    local root = player.Character.HumanoidRootPart
    local backpack = player:FindFirstChild("Backpack") or player.Character:FindFirstChild("Backpack")
    
    for _, item in pairs(getAR2Loot()) do
        if (item:GetPivot().Position - root.Position).Magnitude < 15 then
            if backpack then
                pcall(function() item.Parent = backpack end)
            end
        end
    end
end

-- AR2: ESP para Zumbis
local function findZombies()
    local zombies = {}
    for _, obj in pairs(Workspace:GetDescendants()) do
        if obj:IsA("Model") and obj:FindFirstChild("Humanoid") and obj:FindFirstChild("Head") then
            local humanoid = obj:FindFirstChild("Humanoid")
            if humanoid.Health > 0 and not Players:GetPlayerFromCharacter(obj) then
                table.insert(zombies, obj)
            end
        end
    end
    return zombies
end

-- AR2: ESP para Veículos
local function findVehicles()
    local vehicles = {}
    for _, obj in pairs(Workspace:GetDescendants()) do
        if obj:IsA("Model") and (obj:FindFirstChild("VehicleSeat") or obj:FindFirstChild("DriveSeat") or obj.Name:lower():find("car") or obj.Name:lower():find("truck") or obj.Name:lower():find("jeep")) then
            table.insert(vehicles, obj)
        end
    end
    return vehicles
end

-- AR2: God Mode (tentar)
local function ar2GodMode()
    if player.Character then
        local humanoid = player.Character:FindFirstChild("Humanoid")
        if humanoid then
            humanoid.MaxHealth = 9999
            humanoid.Health = 9999
        end
    end
end

-- AR2: Infinite Stamina
local function infiniteStamina()
    if player.Character then
        local humanoid = player.Character:FindFirstChild("Humanoid")
        if humanoid then
            -- Tenta acessar stamina se existir
            pcall(function()
                local stamina = humanoid:FindFirstChild("Stamina") or humanoid:FindFirstChild("StaminaValue")
                if stamina then stamina.Value = 100 end
            end)
        end
    end
end

-- AR2: Remover Fome/Sede
local function removeHungerThirst()
    if player.Character then
        for _, child in pairs(player.Character:GetDescendants()) do
            if child.Name:lower():find("hunger") or child.Name:lower():find("thirst") or child.Name:lower():find("stamina") then
                if child:IsA("NumberValue") or child:IsA("IntValue") then
                    child.Value = 100
                end
            end
        end
    end
end

-- AR2: Auto Farm Zumbis
local farmZombiesConnection = nil
local function toggleZombieFarm(on)
    if on then
        farmZombiesConnection = RunService.Heartbeat:Connect(function()
            if not player.Character or not player.Character:FindFirstChild("HumanoidRootPart") then return end
            local root = player.Character.HumanoidRootPart
            local nearestZombie = nil
            local nearestDist = 50
            
            for _, zombie in pairs(findZombies()) do
                if zombie:FindFirstChild("Head") then
                    local dist = (zombie.Head.Position - root.Position).Magnitude
                    if dist < nearestDist then
                        nearestDist = dist
                        nearestZombie = zombie
                    end
                end
            end
            
            if nearestZombie and nearestZombie:FindFirstChild("Head") then
                root.CFrame = CFrame.new(nearestZombie.Head.Position + Vector3.new(0, 2, 3))
            end
        end)
    else
        if farmZombiesConnection then farmZombiesConnection:Disconnect(); farmZombiesConnection = nil end
    end
end

-- ====================== ANTI FALL ======================
player.CharacterAdded:Connect(function(char)
    local h = char:WaitForChild("Humanoid", 5)
    if h then
        h:SetStateEnabled(Enum.HumanoidStateType.FallingDown, false)
        h.StateChanged:Connect(function(_, ns) if ns == Enum.HumanoidStateType.FallingDown then h:ChangeState(Enum.HumanoidStateType.GettingUp) end end)
        if Settings.AutoRespawn then h.Died:Connect(function() wait(1); Players:Chat(":respawn " .. player.Name) end) end
    end
    -- AR2: Aplica god mode e stamina infinita ao spawnar
    spawn(function() wait(0.5); ar2GodMode(); infiniteStamina() end)
end)
if player.Character then
    local h = player.Character:FindFirstChild("Humanoid")
    if h then h:SetStateEnabled(Enum.HumanoidStateType.FallingDown, false) end
end

local function toggleFullBright(on) Lighting.Brightness = on and 3 or 2; Lighting.GlobalShadows = not on end

local noclipConn = nil
local function toggleNoClip(on)
    if on then noclipConn = RunService.Stepped:Connect(function() if player.Character then for _, p in pairs(player.Character:GetDescendants()) do if p:IsA("BasePart") then p.CanCollide = false end end end end)
    else if noclipConn then noclipConn:Disconnect(); noclipConn = nil end; if player.Character then for _, p in pairs(player.Character:GetDescendants()) do if p:IsA("BasePart") then p.CanCollide = true end end end end
end

-- ====================== TELEPORT ======================
local targetPlayer = nil; local isTeleporting = false; local teleportConnection = nil
local function teleportToPlayer(plr)
    if not plr or not plr.Character or not plr.Character:FindFirstChild("HumanoidRootPart") then return false end
    if not player.Character or not player.Character:FindFirstChild("HumanoidRootPart") then return false end
    local myHRP = player.Character.HumanoidRootPart; local targetHRP = plr.Character.HumanoidRootPart
    local behind = -targetHRP.CFrame.LookVector
    local newPos = targetHRP.Position + (behind * Settings.Teleport_Distance) + Vector3.new(0, Settings.Teleport_Height, 0)
    myHRP.CFrame = CFrame.new(newPos) * (myHRP.CFrame - myHRP.Position)
    return true
end
local function startNormalTP()
    if not targetPlayer or not targetPlayer.Character or not targetPlayer.Character:FindFirstChild("HumanoidRootPart") then return false end
    if teleportConnection then teleportConnection:Disconnect() end; isTeleporting = true
    teleportConnection = RunService.Heartbeat:Connect(function()
        if not isTeleporting then if teleportConnection then teleportConnection:Disconnect(); teleportConnection = nil end; return end
        teleportToPlayer(targetPlayer)
    end); return true
end
local function stopNormalTP() isTeleporting = false; if teleportConnection then teleportConnection:Disconnect(); teleportConnection = nil end end

-- ====================== TEAM TP ======================
local isTeamTP = false; local teamTPConnection = nil; local currentTeamTarget = nil
local function getRandomTeammate()
    local t = {}
    for _, p in pairs(Players:GetPlayers()) do if p ~= player and p.Team == player.Team and p.Character and p.Character:FindFirstChild("HumanoidRootPart") then local h = p.Character:FindFirstChild("Humanoid"); if h and h.Health > 0 then table.insert(t, p) end end end
    if #t > 0 then if #t > 1 and currentTeamTarget then local f = {}; for _, x in pairs(t) do if x.Character ~= currentTeamTarget then table.insert(f, x) end end; if #f > 0 then return f[math.random(1, #f)] end end; return t[math.random(1, #t)] end
    return nil
end
local function startTeamTP()
    if teamTPConnection then teamTPConnection:Disconnect() end; local ft = getRandomTeammate(); if ft then currentTeamTarget = ft.Character end; isTeamTP = true
    teamTPConnection = RunService.Heartbeat:Connect(function()
        if not isTeamTP then if teamTPConnection then teamTPConnection:Disconnect(); teamTPConnection = nil end; return end
        local valid = false; if currentTeamTarget and currentTeamTarget.Parent and currentTeamTarget:FindFirstChild("HumanoidRootPart") then local h = currentTeamTarget:FindFirstChild("Humanoid"); if h and h.Health > 0 then valid = true end end
        if not valid then local nt = getRandomTeammate(); if nt and nt.Character then currentTeamTarget = nt.Character else return end end
        if currentTeamTarget then local targetHRP = currentTeamTarget.HumanoidRootPart; if player.Character and player.Character:FindFirstChild("HumanoidRootPart") then local myHRP = player.Character.HumanoidRootPart; local behind = -targetHRP.CFrame.LookVector; local newPos = targetHRP.Position + (behind * Settings.Teleport_Distance) + Vector3.new(0, Settings.Teleport_Height, 0); myHRP.CFrame = CFrame.new(newPos) * (myHRP.CFrame - myHRP.Position) end end
    end)
end
local function stopTeamTP() isTeamTP = false; if teamTPConnection then teamTPConnection:Disconnect(); teamTPConnection = nil end end

-- ====================== CORPSE TP ======================
local targetCorpse = nil; local isCorpseTP = false; local corpseTPConnection = nil
local function teleportToCorpse(corpse)
    if not corpse or not corpse:IsA("Model") then return false end; if not player.Character or not player.Character:FindFirstChild("HumanoidRootPart") then return false end
    local targetPart = corpse:FindFirstChild("HumanoidRootPart") or corpse:FindFirstChild("Head") or corpse:FindFirstChild("Torso")
    if not targetPart then for _, part in pairs(corpse:GetDescendants()) do if part:IsA("BasePart") then targetPart = part; break end end end
    if not targetPart then return false end
    local myHRP = player.Character.HumanoidRootPart; local newPos = targetPart.Position + Vector3.new(0, 3, 0)
    myHRP.CFrame = CFrame.new(newPos) * (myHRP.CFrame - myHRP.Position); return true
end
local function startCorpseTP(name)
    if corpseTPConnection then corpseTPConnection:Disconnect() end; local folder = Workspace:FindFirstChild("Corpses") or Workspace
    for _, obj in pairs(folder:GetChildren()) do if obj:IsA("Model") and obj.Name:lower():find(name:lower()) then targetCorpse = obj; break end end
    if not targetCorpse then return false end; isCorpseTP = true
    corpseTPConnection = RunService.Heartbeat:Connect(function()
        if not isCorpseTP then if corpseTPConnection then corpseTPConnection:Disconnect(); corpseTPConnection = nil end; return end
        if targetCorpse and targetCorpse.Parent then teleportToCorpse(targetCorpse) else isCorpseTP = false; if corpseTPConnection then corpseTPConnection:Disconnect(); corpseTPConnection = nil end end
    end); return true
end
local function stopCorpseTP() isCorpseTP = false; if corpseTPConnection then corpseTPConnection:Disconnect(); corpseTPConnection = nil end end

-- ====================== ESP ======================
local espObjects = {}
local function createESP(target, index)
    if not target.Character then return end; local char = target.Character; local head = char:FindFirstChild("Head")
    if not head then return end; if Settings.ESP_TeamCheck and target.Team == player.Team then return end
    if espObjects[target] then local o = espObjects[target]; pcall(function() if o.highlight then o.highlight:Destroy() end end); pcall(function() if o.billboard then o.billboard:Destroy() end end) end
    if Settings.ESP_ShowBoxes then local hl = Instance.new("Highlight"); hl.FillColor = currentTheme.Accent; hl.FillTransparency = 0.82; hl.OutlineColor = currentTheme.Primary; hl.OutlineTransparency = 0.18; hl.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop; hl.Parent = char end
    local billboard = Instance.new("BillboardGui"); billboard.Size = UDim2.new(0, 160, 0, 35); billboard.StudsOffset = Vector3.new(0, 2.2 + (index * 0.5), 0); billboard.AlwaysOnTop = true; billboard.MaxDistance = Settings.ESP_MaxDistance; billboard.Parent = head
    local frame = Instance.new("Frame", billboard); frame.Size = UDim2.new(1, 0, 1, 0); frame.BackgroundColor3 = currentTheme.Surface; frame.BackgroundTransparency = 0.25; frame.BorderSizePixel = 0; Instance.new("UICorner", frame).CornerRadius = UDim.new(0, 8)
    local nl = Instance.new("TextLabel", frame); nl.Size = UDim2.new(1, -6, 1, 0); nl.Position = UDim2.new(0, 3, 0, 0); nl.BackgroundTransparency = 1; nl.Text = target.DisplayName; nl.TextColor3 = Color3.new(1,1,1); nl.TextSize = Settings.ESP_TextSize; nl.Font = Enum.Font.GothamBlack; nl.TextXAlignment = Enum.TextXAlignment.Center
    char.AncestryChanged:Connect(function() if not char.Parent then pcall(function() if espObjects[target] and espObjects[target].billboard then espObjects[target].billboard:Destroy() end end); espObjects[target] = nil end end)
    espObjects[target] = {billboard = billboard}
end
local function refreshESP()
    if not Settings.ESP_Enabled then return end
    for _, d in pairs(espObjects) do pcall(function() if d.billboard then d.billboard:Destroy() end end) end; espObjects = {}
    local pl = {}; for _, p in pairs(Players:GetPlayers()) do if p ~= player then table.insert(pl, p) end end
    for i, p in ipairs(pl) do if p.Character then createESP(p, i) end end
end
local function enableESP() Settings.ESP_Enabled = true; refreshESP() end
local function disableESP() Settings.ESP_Enabled = false; for _, d in pairs(espObjects) do pcall(function() if d.billboard then d.billboard:Destroy() end end) end; espObjects = {} end

-- ====================== GUI ======================
local screenGui = Instance.new("ScreenGui")
screenGui.Name = "MIDHUB_AR2"
screenGui.ResetOnSpawn = false
screenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
screenGui.Parent = player:WaitForChild("PlayerGui")

local mainFrame = Instance.new("Frame")
mainFrame.Size = UDim2.new(0, 340, 0, 560)
mainFrame.Position = UDim2.new(0, 4, 1.2, 0)
mainFrame.BackgroundColor3 = currentTheme.Background
mainFrame.BackgroundTransparency = 0.03
mainFrame.BorderSizePixel = 0
mainFrame.Active = true
mainFrame.Draggable = true
mainFrame.ClipsDescendants = true
mainFrame.Parent = screenGui
Instance.new("UICorner", mainFrame).CornerRadius = UDim.new(0, 20)
Instance.new("UIStroke", mainFrame).Color = currentTheme.Primary
mainFrame.UIStroke.Thickness = 2.5
mainFrame.UIStroke.Transparency = 0.2

TweenService:Create(mainFrame, TweenInfo.new(0.6, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {Position = UDim2.new(0, 4, 0.5, -280)}):Play()

-- Header
local header = Instance.new("Frame")
header.Size = UDim2.new(1, 0, 0, 55)
header.BackgroundColor3 = currentTheme.Surface
header.BackgroundTransparency = 0.08
header.BorderSizePixel = 0
header.Parent = mainFrame
Instance.new("UICorner", header).CornerRadius = UDim.new(0, 20)

local logoIcon = Instance.new("TextLabel")
logoIcon.Size = UDim2.new(0, 42, 0, 42)
logoIcon.Position = UDim2.new(0, 10, 0, 6)
logoIcon.BackgroundTransparency = 1
logoIcon.Text = "🧟"
logoIcon.TextSize = 26
logoIcon.Font = Enum.Font.GothamBlack
logoIcon.Parent = header

local titleMain = Instance.new("TextLabel")
titleMain.Size = UDim2.new(1, -100, 0, 22)
titleMain.Position = UDim2.new(0, 58, 0, 8)
titleMain.BackgroundTransparency = 1
titleMain.Text = "MIDHUB AR2"
titleMain.TextColor3 = Color3.new(1,1,1)
titleMain.TextSize = 16
titleMain.Font = Enum.Font.GothamBlack
titleMain.TextXAlignment = Enum.TextXAlignment.Left
titleMain.Parent = header

local verLabel = Instance.new("TextLabel")
verLabel.Size = UDim2.new(0, 50, 0, 14)
verLabel.Position = UDim2.new(0, 108, 0, 30)
verLabel.BackgroundTransparency = 1
verLabel.Text = "AR2 v9.1"
verLabel.TextColor3 = currentTheme.Accent
verLabel.TextSize = 9
verLabel.Font = Enum.Font.GothamBold
verLabel.TextXAlignment = Enum.TextXAlignment.Left
verLabel.Parent = header

-- Status Bar
local statusBar = Instance.new("Frame")
statusBar.Size = UDim2.new(1, -16, 0, 28)
statusBar.Position = UDim2.new(0, 8, 0, 60)
statusBar.BackgroundColor3 = currentTheme.SurfaceLight
statusBar.BorderSizePixel = 0
statusBar.Parent = mainFrame
Instance.new("UICorner", statusBar).CornerRadius = UDim.new(0, 10)

local statusDot = Instance.new("Frame")
statusDot.Size = UDim2.new(0, 8, 0, 8)
statusDot.Position = UDim2.new(0, 10, 0.5, -4)
statusDot.BackgroundColor3 = currentTheme.Success
statusDot.BorderSizePixel = 0
statusDot.Parent = statusBar
Instance.new("UICorner", statusDot).CornerRadius = UDim.new(1, 0)

local statusText = Instance.new("TextLabel")
statusText.Size = UDim2.new(1, -28, 1, 0)
statusText.Position = UDim2.new(0, 24, 0, 0)
statusText.BackgroundTransparency = 1
statusText.Text = "🧟 Apocalypse Rising 2 Ready"
statusText.TextColor3 = currentTheme.TextSecondary
statusText.TextSize = 10
statusText.Font = Enum.Font.GothamSemibold
statusText.TextXAlignment = Enum.TextXAlignment.Left
statusText.Parent = statusBar

-- Separador
local sep = Instance.new("Frame")
sep.Size = UDim2.new(1, -16, 0, 1)
sep.Position = UDim2.new(0, 8, 0, 94)
sep.BackgroundColor3 = currentTheme.Primary
sep.BackgroundTransparency = 0.6
sep.BorderSizePixel = 0
sep.Parent = mainFrame

-- Abas
local tabBar = Instance.new("Frame")
tabBar.Size = UDim2.new(1, -16, 0, 30)
tabBar.Position = UDim2.new(0, 8, 0, 100)
tabBar.BackgroundColor3 = currentTheme.Surface
tabBar.BackgroundTransparency = 0.4
tabBar.BorderSizePixel = 0
tabBar.Parent = mainFrame
Instance.new("UICorner", tabBar).CornerRadius = UDim.new(0, 10)

local currentTab = "players"
local contentArea = Instance.new("Frame")
contentArea.Size = UDim2.new(1, -16, 0, 295)
contentArea.Position = UDim2.new(0, 8, 0, 134)
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
searchInput.Text = ""; searchInput.TextColor3 = Color3.new(1,1,1)
searchInput.TextSize = 12; searchInput.Font = Enum.Font.Gotham
searchInput.Parent = playersFrame
Instance.new("UICorner", searchInput).CornerRadius = UDim.new(0, 10)

local playersScroll = Instance.new("ScrollingFrame")
playersScroll.Size = UDim2.new(1, 0, 1, -34)
playersScroll.Position = UDim2.new(0, 0, 0, 34)
playersScroll.BackgroundColor3 = currentTheme.Surface
playersScroll.BackgroundTransparency = 0.4
playersScroll.BorderSizePixel = 0
playersScroll.ScrollBarThickness = 5
playersScroll.ScrollBarImageColor3 = currentTheme.Primary
playersScroll.Parent = playersFrame
Instance.new("UICorner", playersScroll).CornerRadius = UDim.new(0, 10)

local playersListLayout = Instance.new("UIListLayout")
playersListLayout.SortOrder = Enum.SortOrder.LayoutOrder
playersListLayout.Padding = UDim.new(0, 4)
playersListLayout.Parent = playersScroll

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
corpsesScroll.ScrollBarThickness = 5
corpsesScroll.ScrollBarImageColor3 = currentTheme.Danger
corpsesScroll.Parent = corpsesFrame
Instance.new("UICorner", corpsesScroll).CornerRadius = UDim.new(0, 10)

local corpsesListLayout = Instance.new("UIListLayout")
corpsesListLayout.SortOrder = Enum.SortOrder.LayoutOrder
corpsesListLayout.Padding = UDim.new(0, 4)
corpsesListLayout.Parent = corpsesScroll

local function updateCorpsesList()
    for _, c in pairs(corpsesScroll:GetChildren()) do if c:IsA("TextButton") then c:Destroy() end end
    local folder = Workspace:FindFirstChild("Corpses") or Workspace
    for _, obj in pairs(folder:GetChildren()) do
        if obj:IsA("Model") then
            local btn = Instance.new("TextButton")
            btn.Size = UDim2.new(1, -6, 0, 30)
            btn.BackgroundColor3 = targetCorpse == obj and currentTheme.Danger or currentTheme.Surface
            btn.Text = "💀 " .. obj.Name; btn.TextColor3 = Color3.new(1,1,1); btn.TextSize = 11
            btn.Font = Enum.Font.GothamSemibold; btn.AutoButtonColor = false
            btn.Parent = corpsesScroll; Instance.new("UICorner", btn).CornerRadius = UDim.new(0, 10)
            btn.MouseButton1Click:Connect(function()
                targetCorpse = obj
                for _, c in pairs(corpsesScroll:GetChildren()) do if c:IsA("TextButton") then c.BackgroundColor3 = currentTheme.Surface end end
                btn.BackgroundColor3 = currentTheme.Danger
            end)
        end
    end
    corpsesScroll.CanvasSize = UDim2.new(0, 0, 0, corpsesListLayout.AbsoluteContentSize.Y + 10)
end

-- Switch Tab
local function switchTab(tab)
    currentTab = tab
    playersFrame.Visible = (tab == "players")
    corpsesFrame.Visible = (tab == "corpses")
    if tab == "corpses" then updateCorpsesList() end
    for _, c in pairs(tabBar:GetChildren()) do
        if c:IsA("TextButton") then
            local isActive = (tab == "players" and c == tabPlayers) or (tab == "corpses" and c == tabCorpses)
            c.BackgroundColor3 = isActive and currentTheme.Primary or Color3.fromRGB(255,255,255)
            c.BackgroundTransparency = isActive and 0.1 or 0.95
            c.TextColor3 = isActive and Color3.new(1,1,1) or currentTheme.TextSecondary
        end
    end
end

local tabPlayers = Instance.new("TextButton")
tabPlayers.Size = UDim2.new(0.45, 0, 0.75, 0); tabPlayers.Position = UDim2.new(0.02, 0, 0.125, 0)
tabPlayers.BackgroundColor3 = currentTheme.Primary; tabPlayers.BackgroundTransparency = 0.1
tabPlayers.Text = "🎮 Jogadores"; tabPlayers.TextColor3 = Color3.new(1,1,1); tabPlayers.TextSize = 12
tabPlayers.Font = Enum.Font.GothamBold; tabPlayers.AutoButtonColor = false; tabPlayers.Parent = tabBar
Instance.new("UICorner", tabPlayers).CornerRadius = UDim.new(0, 8)
tabPlayers.MouseButton1Click:Connect(function() switchTab("players") end)

local tabCorpses = Instance.new("TextButton")
tabCorpses.Size = UDim2.new(0.45, 0, 0.75, 0); tabCorpses.Position = UDim2.new(0.51, 0, 0.125, 0)
tabCorpses.BackgroundColor3 = Color3.fromRGB(255,255,255); tabCorpses.BackgroundTransparency = 0.95
tabCorpses.Text = "💀 Corpos"; tabCorpses.TextColor3 = currentTheme.TextSecondary; tabCorpses.TextSize = 12
tabCorpses.Font = Enum.Font.GothamBold; tabCorpses.AutoButtonColor = false; tabCorpses.Parent = tabBar
Instance.new("UICorner", tabCorpses).CornerRadius = UDim.new(0, 8)
tabCorpses.MouseButton1Click:Connect(function() switchTab("corpses") end)

-- Botões
local btnStates = {esp = false, teleport = false, teamTP = false, corpseTP = false, noclip = false, zombieFarm = false}

local function makeButton(x, y, w, h, icon, text, color, stateKey, callback)
    local btn = Instance.new("TextButton")
    btn.Size = UDim2.new(w, 0, 0, h); btn.Position = UDim2.new(x, 0, 0, y)
    btn.BackgroundColor3 = btnStates[stateKey] and currentTheme.Success or color
    btn.Text = ""; btn.AutoButtonColor = false; btn.ClipsDescendants = true; btn.Parent = mainFrame
    Instance.new("UICorner", btn).CornerRadius = UDim.new(0, 12)
    
    local ic = Instance.new("TextLabel")
    ic.Size = UDim2.new(0, 20, 1, 0); ic.Position = UDim2.new(0, 8, 0, 0)
    ic.BackgroundTransparency = 1; ic.Text = btnStates[stateKey] and "✅" or icon
    ic.TextSize = 14; ic.Font = Enum.Font.Gotham; ic.Parent = btn
    
    local tx = Instance.new("TextLabel")
    tx.Size = UDim2.new(1, -30, 1, 0); tx.Position = UDim2.new(0, 28, 0, 0)
    tx.BackgroundTransparency = 1; tx.Text = text; tx.TextColor3 = Color3.new(1,1,1)
    tx.TextSize = 11; tx.Font = Enum.Font.GothamSemibold; tx.TextXAlignment = Enum.TextXAlignment.Left; tx.Parent = btn
    
    btn.MouseButton1Click:Connect(function()
        btnStates[stateKey] = not btnStates[stateKey]
        TweenService:Create(btn, TweenInfo.new(0.3), {BackgroundColor3 = btnStates[stateKey] and currentTheme.Success or color}):Play()
        ic.Text = btnStates[stateKey] and "✅" or icon
        pcall(function() callback(btnStates[stateKey]) end)
    end)
    return btn
end

makeButton(0.03, 438, 0.47, 34, "👁️", "ESP", Color3.fromRGB(130, 45, 180), "esp", function(on) if on then enableESP() else disableESP() end end)
makeButton(0.52, 438, 0.47, 34, "🎯", "Teleport", Color3.fromRGB(75, 35, 190), "teleport", function(on)
    if on then if not targetPlayer then StarterGui:SetCore("SendNotification", {Title = "Teleport", Text = "Selecione um jogador!", Duration = 2}); btnStates.teleport = false; return end; startNormalTP() else stopNormalTP() end
end)
makeButton(0.03, 480, 0.47, 34, "👥", "Team TP", Color3.fromRGB(55, 25, 140), "teamTP", function(on) if on then startTeamTP() else stopTeamTP() end end)
makeButton(0.52, 480, 0.47, 34, "💀", "Corpse TP", Color3.fromRGB(200, 50, 50), "corpseTP", function(on)
    if on then if not targetCorpse then StarterGui:SetCore("SendNotification", {Title = "Corpse TP", Text = "Selecione um corpo!", Duration = 2}); btnStates.corpseTP = false; return end; startCorpseTP(targetCorpse.Name) else stopCorpseTP() end
end)
makeButton(0.03, 522, 0.47, 34, "👻", "NoClip", Color3.fromRGB(80, 80, 160), "noclip", function(on) toggleNoClip(on) end)
makeButton(0.52, 522, 0.47, 34, "🧟", "Zombie Farm", Color3.fromRGB(180, 100, 50), "zombieFarm", function(on)
    toggleZombieFarm(on)
    statusText.Text = on and "🧟 Zombie Farm ON" or "🧟 AR2 Ready"
end)

-- Lista de jogadores
local function updatePlayerList()
    for _, c in pairs(playersScroll:GetChildren()) do if c:IsA("TextButton") then c:Destroy() end end
    local search = searchInput.Text:lower()
    for _, plr in pairs(Players:GetPlayers()) do
        if plr ~= player then
            if search == "" or plr.Name:lower():find(search) or plr.DisplayName:lower():find(search) then
                local btn = Instance.new("TextButton")
                btn.Size = UDim2.new(1, -6, 0, 30)
                btn.BackgroundColor3 = targetPlayer == plr and currentTheme.Primary or currentTheme.Surface
                btn.Text = ""; btn.AutoButtonColor = false; btn.Parent = playersScroll
                Instance.new("UICorner", btn).CornerRadius = UDim.new(0, 10)
                local dot = Instance.new("Frame")
                dot.Size = UDim2.new(0, 8, 0, 8); dot.Position = UDim2.new(0, 10, 0.5, -4)
                dot.BackgroundColor3 = plr.Team == player.Team and Color3.fromRGB(80, 255, 120) or Color3.fromRGB(255, 80, 80)
                dot.BorderSizePixel = 0; dot.Parent = btn; Instance.new("UICorner", dot).CornerRadius = UDim.new(1, 0)
                local nm = Instance.new("TextLabel")
                nm.Size = UDim2.new(1, -55, 1, 0); nm.Position = UDim2.new(0, 24, 0, 0)
                nm.BackgroundTransparency = 1; nm.Text = plr.DisplayName; nm.TextColor3 = Color3.new(1,1,1); nm.TextSize = 12
                nm.Font = Enum.Font.GothamSemibold; nm.TextXAlignment = Enum.TextXAlignment.Left; nm.Parent = btn
                btn.MouseButton1Click:Connect(function()
                    targetPlayer = plr
                    for _, c in pairs(playersScroll:GetChildren()) do if c:IsA("TextButton") then c.BackgroundColor3 = currentTheme.Surface end end
                    btn.BackgroundColor3 = currentTheme.Primary
                end)
            end
        end
    end
    playersScroll.CanvasSize = UDim2.new(0, 0, 0, playersListLayout.AbsoluteContentSize.Y + 10)
end

searchInput:GetPropertyChangedSignal("Text"):Connect(updatePlayerList)
Players.PlayerAdded:Connect(updatePlayerList)
Players.PlayerRemoving:Connect(function(plr) wait(0.1); if targetPlayer == plr then targetPlayer = nil end; updatePlayerList() end)
spawn(function() while true do updatePlayerList(); wait(3) end end)
updatePlayerList()

player.Chatted:Connect(function(msg)
    local cmd = msg:lower()
    if cmd == "/midhub" or cmd == "/mh" then mainFrame.Visible = not mainFrame.Visible end
    if cmd == "/ar2loot" then teleportToLoot(getAR2Loot()[1]) end
    if cmd == "/ar2collect" then collectNearbyItems() end
    if cmd == "/ar2god" then ar2GodMode() end
end)

StarterGui:SetCore("SendNotification", {Title = "MIDHUB AR2 v9.1", Text = "Apocalypse Rising 2 Edition! /midhub", Duration = 5})
print("✅ MIDHUB AR2 v9.1 - Apocalypse Rising 2 Edition!")
print("🧟 Comandos: /midhub | /ar2loot | /ar2collect | /ar2god")
