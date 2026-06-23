-- LocalScript → StarterPlayer > StarterPlayerScripts
-- MIDHUB v7.4 - TELEPORT CORRIGIDO

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
    ESP_ShowHealth = true,
    ESP_ShowDistance = true,
    ESP_ShowBoxes = true,
    ESP_ShowTracers = true,
    ESP_ShowHeadDot = true,
    ESP_TextSize = 13,
    ESP_TeamCheck = false,
    
    Teleport_Enabled = false,
    Teleport_TeamMode = false,
    Teleport_Distance = 3,
    Teleport_Height = 0,
    
    AntiKick_Enabled = true,
    AntiTeleport_Enabled = true,
    Bypass_Enabled = true,
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
        Background = Color3.fromRGB(10, 8, 22),
        Surface = Color3.fromRGB(18, 14, 38),
        SurfaceLight = Color3.fromRGB(25, 20, 48),
        Accent = Color3.fromRGB(255, 80, 200),
        Text = Color3.fromRGB(240, 210, 255),
        TextSecondary = Color3.fromRGB(170, 150, 210),
        Success = Color3.fromRGB(60, 255, 100),
        Warning = Color3.fromRGB(255, 200, 50),
        Danger = Color3.fromRGB(255, 60, 60),
        Name = "Roxo Cósmico",
        Icon = "💜",
    },
    Midnight = {
        Primary = Color3.fromRGB(50, 120, 255),
        Secondary = Color3.fromRGB(30, 80, 200),
        Background = Color3.fromRGB(6, 10, 18),
        Surface = Color3.fromRGB(12, 18, 32),
        SurfaceLight = Color3.fromRGB(18, 26, 44),
        Accent = Color3.fromRGB(70, 190, 255),
        Text = Color3.fromRGB(210, 230, 255),
        TextSecondary = Color3.fromRGB(150, 180, 230),
        Success = Color3.fromRGB(60, 255, 170),
        Warning = Color3.fromRGB(255, 210, 60),
        Danger = Color3.fromRGB(255, 80, 80),
        Name = "Azul Meia-Noite",
        Icon = "🌙",
    },
    Crimson = {
        Primary = Color3.fromRGB(255, 50, 50),
        Secondary = Color3.fromRGB(200, 30, 30),
        Background = Color3.fromRGB(22, 8, 8),
        Surface = Color3.fromRGB(32, 12, 12),
        SurfaceLight = Color3.fromRGB(44, 18, 18),
        Accent = Color3.fromRGB(255, 140, 70),
        Text = Color3.fromRGB(255, 210, 210),
        TextSecondary = Color3.fromRGB(230, 150, 150),
        Success = Color3.fromRGB(100, 255, 100),
        Warning = Color3.fromRGB(255, 255, 60),
        Danger = Color3.fromRGB(255, 40, 40),
        Name = "Vermelho Carmesim",
        Icon = "❤️",
    },
    Emerald = {
        Primary = Color3.fromRGB(30, 210, 110),
        Secondary = Color3.fromRGB(20, 160, 80),
        Background = Color3.fromRGB(6, 18, 10),
        Surface = Color3.fromRGB(10, 26, 16),
        SurfaceLight = Color3.fromRGB(16, 36, 24),
        Accent = Color3.fromRGB(80, 255, 150),
        Text = Color3.fromRGB(190, 255, 220),
        TextSecondary = Color3.fromRGB(140, 230, 180),
        Success = Color3.fromRGB(60, 255, 140),
        Warning = Color3.fromRGB(255, 230, 60),
        Danger = Color3.fromRGB(255, 80, 80),
        Name = "Verde Esmeralda",
        Icon = "💚",
    },
    Gold = {
        Primary = Color3.fromRGB(255, 170, 30),
        Secondary = Color3.fromRGB(200, 130, 20),
        Background = Color3.fromRGB(18, 13, 4),
        Surface = Color3.fromRGB(28, 20, 6),
        SurfaceLight = Color3.fromRGB(38, 30, 10),
        Accent = Color3.fromRGB(255, 210, 80),
        Text = Color3.fromRGB(255, 240, 190),
        TextSecondary = Color3.fromRGB(230, 200, 150),
        Success = Color3.fromRGB(130, 255, 80),
        Warning = Color3.fromRGB(255, 255, 80),
        Danger = Color3.fromRGB(255, 80, 80),
        Name = "Dourado Real",
        Icon = "👑",
    },
}

local currentTheme = Themes[Settings.UI_Theme]

-- ====================== ANTI-KICK ======================
local AntiKick = {
    Enabled = true,
    AntiTeleportEnabled = true,
    LastSafePosition = nil,
    LastSafeTime = 0,
}

local function setupAntiKick()
    if AntiKick.Connection then return end
    AntiKick.Connection = RunService.Heartbeat:Connect(function()
        if not AntiKick.Enabled then return end
        
        if player.Character and player.Character:FindFirstChild("HumanoidRootPart") then
            local root = player.Character.HumanoidRootPart
            if not AntiKick.LastSafePosition or tick() - AntiKick.LastSafeTime > 5 then
                AntiKick.LastSafePosition = root.Position
                AntiKick.LastSafeTime = tick()
            end
        end
        
        pcall(function()
            if player.Character then
                local h = player.Character:FindFirstChild("Humanoid")
                if h then h.AutoRotate = true end
            end
        end)
        
        pcall(function()
            if AntiKick.AntiTeleportEnabled and AntiKick.LastSafePosition then
                if player.Character and player.Character:FindFirstChild("HumanoidRootPart") then
                    local root = player.Character.HumanoidRootPart
                    local dist = (root.Position - AntiKick.LastSafePosition).Magnitude
                    if dist > 500 and not isTeleporting and not Settings.Teleport_TeamMode and not isCorpseTeleporting then
                        root.CFrame = CFrame.new(AntiKick.LastSafePosition + Vector3.new(0, 5, 0))
                        StarterGui:SetCore("SendNotification", {Title = "🛡️ Anti-TP", Text = "Retornando...", Duration = 2})
                    end
                    if root.Position.Y < -100 then
                        root.CFrame = CFrame.new(AntiKick.LastSafePosition + Vector3.new(0, 10, 0))
                        root.Velocity = Vector3.zero
                    end
                end
            end
        end)
    end)
end

local function setupBypass()
    pcall(function()
        if player.Character then
            local h = player.Character:FindFirstChild("Humanoid")
            if h then h.WalkSpeed = 16; h.JumpPower = 50 end
        end
    end)
end

player.CharacterAdded:Connect(function(char)
    wait(0.5); setupBypass()
    local h = char:WaitForChild("Humanoid", 5)
    if h then
        h:GetPropertyChangedSignal("WalkSpeed"):Connect(function() if h.WalkSpeed < 16 then h.WalkSpeed = 16 end end)
        h:GetPropertyChangedSignal("JumpPower"):Connect(function() if h.JumpPower < 50 then h.JumpPower = 50 end end)
    end
end)

-- ====================== ANTI FALL ======================
player.CharacterAdded:Connect(function(char)
    local h = char:WaitForChild("Humanoid", 5)
    if h then
        h:SetStateEnabled(Enum.HumanoidStateType.FallingDown, false)
        h.StateChanged:Connect(function(_, ns) if ns == Enum.HumanoidStateType.FallingDown then h:ChangeState(Enum.HumanoidStateType.GettingUp) end end)
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
local noclipConn = nil
local function toggleNoClip(on)
    Settings.NoClip_Enabled = on
    if on then
        noclipConn = RunService.Stepped:Connect(function()
            if player.Character then for _, p in pairs(player.Character:GetDescendants()) do if p:IsA("BasePart") then p.CanCollide = false end end end
        end)
    else
        if noclipConn then noclipConn:Disconnect(); noclipConn = nil end
        if player.Character then for _, p in pairs(player.Character:GetDescendants()) do if p:IsA("BasePart") then p.CanCollide = true end end end
    end
end

-- ====================== AUTO RESPAWN ======================
player.CharacterAdded:Connect(function(char)
    local h = char:WaitForChild("Humanoid", 5)
    if h then h.Died:Connect(function() if Settings.AutoRespawn then wait(1); Players:Chat(":respawn " .. player.Name) end end) end
end)

-- ====================== TELEPORT (CORRIGIDO) ======================
local targetPlayer = nil
local isTeleporting = false
local teleportConnection = nil
local teamTPConnection = nil
local currentTeamTarget = nil
local targetCorpse = nil
local corpseTPConnection = nil
local isCorpseTeleporting = false

-- CORRIGIDO: Função de teleport simples e direta
local function teleportToPlayer(plr)
    if not plr then return false end
    
    local targetChar = plr.Character
    if not targetChar then return false end
    
    local targetHRP = targetChar:FindFirstChild("HumanoidRootPart")
    if not targetHRP then return false end
    
    local myChar = player.Character
    if not myChar then return false end
    
    local myHRP = myChar:FindFirstChild("HumanoidRootPart")
    if not myHRP then return false end
    
    -- Calcula posição atrás do alvo
    local behind = -targetHRP.CFrame.LookVector
    local newPos = targetHRP.Position + (behind * Settings.Teleport_Distance) + Vector3.new(0, Settings.Teleport_Height, 0)
    local myRot = myHRP.CFrame - myHRP.Position
    
    -- Teleporta
    myHRP.CFrame = CFrame.new(newPos) * myRot
    
    -- Atualiza posição segura
    AntiKick.LastSafePosition = newPos
    AntiKick.LastSafeTime = tick()
    
    return true
end

local function getRandomTeammate()
    local t = {}
    for _, p in pairs(Players:GetPlayers()) do
        if p ~= player and p.Team == player.Team and p.Character and p.Character:FindFirstChild("HumanoidRootPart") then
            local h = p.Character:FindFirstChild("Humanoid")
            if h and h.Health > 0 then table.insert(t, p) end
        end
    end
    if #t > 0 then
        if #t > 1 and currentTeamTarget then
            local f = {}; for _, x in pairs(t) do if x.Character ~= currentTeamTarget then table.insert(f, x) end end
            if #f > 0 then return f[math.random(1, #f)] end
        end
        return t[math.random(1, #t)]
    end
    return nil
end

local function teleportToCorpse(corpse)
    if not corpse or not corpse:IsA("Model") then return end
    if not player.Character or not player.Character:FindFirstChild("HumanoidRootPart") then return end
    
    local targetPart = corpse:FindFirstChild("HumanoidRootPart") or corpse:FindFirstChild("Head") or corpse:FindFirstChild("Torso")
    if not targetPart then
        for _, part in pairs(corpse:GetDescendants()) do
            if part:IsA("BasePart") then targetPart = part; break end
        end
    end
    
    if targetPart then
        local np = targetPart.Position + Vector3.new(0, 3, 0)
        local mr = player.Character.HumanoidRootPart
        mr.CFrame = CFrame.new(np) * (mr.CFrame - mr.Position)
        AntiKick.LastSafePosition = np; AntiKick.LastSafeTime = tick()
    end
end

local function startCorpseTP(corpseName)
    local folder = Workspace:FindFirstChild("Corpses") or Workspace
    for _, obj in pairs(folder:GetChildren()) do
        if obj:IsA("Model") and obj.Name:lower():find(corpseName:lower()) then targetCorpse = obj; break end
    end
    if not targetCorpse then return false end
    if corpseTPConnection then corpseTPConnection:Disconnect() end
    isCorpseTeleporting = true
    corpseTPConnection = RunService.Heartbeat:Connect(function()
        if not isCorpseTeleporting then if corpseTPConnection then corpseTPConnection:Disconnect(); corpseTPConnection = nil end; return end
        if targetCorpse and targetCorpse.Parent then teleportToCorpse(targetCorpse)
        else isCorpseTeleporting = false; if corpseTPConnection then corpseTPConnection:Disconnect(); corpseTPConnection = nil end end
    end)
    return true
end

local function stopCorpseTP()
    isCorpseTeleporting = false; targetCorpse = nil
    if corpseTPConnection then corpseTPConnection:Disconnect(); corpseTPConnection = nil end
end

local function startTeamTP()
    if teamTPConnection then return end
    local ft = getRandomTeammate(); if ft then currentTeamTarget = ft.Character end
    teamTPConnection = RunService.Heartbeat:Connect(function()
        if not Settings.Teleport_TeamMode then if teamTPConnection then teamTPConnection:Disconnect(); teamTPConnection = nil end; currentTeamTarget = nil; return end
        if currentTeamTarget and currentTeamTarget.Parent and currentTeamTarget:FindFirstChild("HumanoidRootPart") then
            local h = currentTeamTarget:FindFirstChild("Humanoid")
            if not h or h.Health <= 0 then
                local nt = getRandomTeammate(); if nt and nt.Character then currentTeamTarget = nt.Character else return end
            end
        else
            local nt = getRandomTeammate(); if nt and nt.Character then currentTeamTarget = nt.Character else return end
        end
        if currentTeamTarget then teleportToPlayer(currentTeamTarget.Parent and Players:GetPlayerFromCharacter(currentTeamTarget)) end
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
    local char = target.Character; local head = char:FindFirstChild("Head"); local humanoid = char:FindFirstChild("Humanoid")
    if not head then return end
    if Settings.ESP_TeamCheck and target.Team == player.Team then return end
    if espObjects[target] then
        local o = espObjects[target]
        pcall(function() if o.highlight then o.highlight:Destroy() end end)
        pcall(function() if o.billboard then o.billboard:Destroy() end end)
        pcall(function() if o.tracer then o.tracer:Remove() end end)
        pcall(function() if o.headDot then o.headDot:Remove() end end)
        if o.connections then for _, c in pairs(o.connections) do c:Disconnect() end end
    end
    local data = {connections = {}}
    if Settings.ESP_ShowBoxes then
        local hl = Instance.new("Highlight"); hl.FillColor = currentTheme.Accent; hl.FillTransparency = 0.82
        hl.OutlineColor = currentTheme.Primary; hl.OutlineTransparency = 0.18; hl.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop; hl.Parent = char; data.highlight = hl
    end
    if Settings.ESP_ShowHeadDot then
        local dot = Drawing.new("Circle"); dot.Color = Color3.fromRGB(255, 35, 35); dot.Filled = true; dot.Transparency = 0.35; dot.Radius = 5; dot.Visible = false
        local dc = RunService.RenderStepped:Connect(function()
            if not char or not char.Parent or not char:FindFirstChild("Head") then dot.Visible = false; return end
            local p, v = Camera:WorldToViewportPoint(char.Head.Position)
            if v and p.Z > 0 then dot.Position = Vector2.new(p.X, p.Y); dot.Visible = true else dot.Visible = false end
        end); table.insert(data.connections, dc); data.headDot = dot
    end
    local billboard = Instance.new("BillboardGui"); billboard.Size = UDim2.new(0, 190, 0, 50)
    billboard.StudsOffset = Vector3.new(0, 2.2 + (index * 0.5), 0); billboard.AlwaysOnTop = true
    billboard.MaxDistance = Settings.ESP_MaxDistance; billboard.Parent = head; data.billboard = billboard
    local frame = Instance.new("Frame", billboard); frame.Size = UDim2.new(1, 0, 1, 0)
    frame.BackgroundColor3 = currentTheme.Surface; frame.BackgroundTransparency = 0.25; frame.BorderSizePixel = 0
    Instance.new("UICorner", frame).CornerRadius = UDim.new(0, 8)
    Instance.new("UIStroke", frame).Color = currentTheme.Primary; frame.UIStroke.Thickness = 1.5; frame.UIStroke.Transparency = 0.35
    local nl = Instance.new("TextLabel", frame); nl.Size = UDim2.new(1, -8, 0.5, 0); nl.Position = UDim2.new(0, 4, 0, 2)
    nl.BackgroundTransparency = 1; nl.Text = target.DisplayName; nl.TextColor3 = Color3.new(1,1,1)
    nl.TextSize = Settings.ESP_TextSize; nl.Font = Enum.Font.GothamBlack; nl.TextXAlignment = Enum.TextXAlignment.Center
    local hl2 = Instance.new("TextLabel", frame); hl2.Size = UDim2.new(0.5, -4, 0.4, 0); hl2.Position = UDim2.new(0, 4, 0.5, 0)
    hl2.BackgroundTransparency = 1; hl2.Text = "❤️ " .. (humanoid and math.floor(humanoid.Health) or "?")
    hl2.TextColor3 = currentTheme.Success; hl2.TextSize = Settings.ESP_TextSize - 2; hl2.Font = Enum.Font.GothamBold; hl2.TextXAlignment = Enum.TextXAlignment.Left
    local dl = Instance.new("TextLabel", frame); dl.Size = UDim2.new(0.5, -4, 0.4, 0); dl.Position = UDim2.new(0.5, 0, 0.5, 0)
    dl.BackgroundTransparency = 1; dl.Text = "📏 0m"; dl.TextColor3 = currentTheme.TextSecondary
    dl.TextSize = Settings.ESP_TextSize - 2; dl.Font = Enum.Font.GothamBold; dl.TextXAlignment = Enum.TextXAlignment.Right
    if humanoid then
        local hc = humanoid.HealthChanged:Connect(function(hp)
            local pct = hp / humanoid.MaxHealth; hl2.Text = "❤️ " .. math.floor(hp)
            if pct > 0.6 then hl2.TextColor3 = currentTheme.Success elseif pct > 0.3 then hl2.TextColor3 = currentTheme.Warning else hl2.TextColor3 = currentTheme.Danger end
            if hp <= 0 then pcall(function() if data.highlight then data.highlight:Destroy() end end); pcall(function() if data.billboard then data.billboard:Destroy() end end) end
        end); table.insert(data.connections, hc)
    end
    local dc = RunService.RenderStepped:Connect(function()
        if not char or not char.Parent or not char:FindFirstChild("HumanoidRootPart") then return end
        local mr = player.Character and player.Character:FindFirstChild("HumanoidRootPart")
        local tr = char.HumanoidRootPart
        if mr and tr then local d = (mr.Position - tr.Position).Magnitude; dl.Text = "📏 " .. math.floor(d) .. "m"
            if d < 15 then dl.TextColor3 = currentTheme.Danger elseif d < 40 then dl.TextColor3 = currentTheme.Warning else dl.TextColor3 = currentTheme.Success end end
    end); table.insert(data.connections, dc)
    if Settings.ESP_ShowTracers then
        local tracer = Drawing.new("Line"); tracer.Color = currentTheme.Primary; tracer.Thickness = 0.5; tracer.Transparency = 0.7; tracer.Visible = false
        local tc = RunService.RenderStepped:Connect(function()
            if not char or not char.Parent or not char:FindFirstChild("HumanoidRootPart") then tracer.Visible = false; return end
            local p, v = Camera:WorldToViewportPoint(char.HumanoidRootPart.Position)
            if v and p.Z > 0 then tracer.From = Vector2.new(Camera.ViewportSize.X/2, Camera.ViewportSize.Y); tracer.To = Vector2.new(p.X, p.Y); tracer.Visible = true else tracer.Visible = false end
        end); table.insert(data.connections, tc); data.tracer = tracer
    end
    local cr = char.AncestryChanged:Connect(function()
        if not char.Parent then
            pcall(function() if data.highlight then data.highlight:Destroy() end end); pcall(function() if data.billboard then data.billboard:Destroy() end end)
            pcall(function() if data.tracer then data.tracer:Remove() end end); pcall(function() if data.headDot then data.headDot:Remove() end end)
            for _, c in pairs(data.connections) do c:Disconnect() end; espObjects[target] = nil
        end
    end); table.insert(data.connections, cr); espObjects[target] = data
end

local function refreshESP()
    if not Settings.ESP_Enabled then return end
    for _, d in pairs(espObjects) do
        pcall(function() if d.highlight then d.highlight:Destroy() end end); pcall(function() if d.billboard then d.billboard:Destroy() end end)
        pcall(function() if d.tracer then d.tracer:Remove() end end); pcall(function() if d.headDot then d.headDot:Remove() end end)
        if d.connections then for _, c in pairs(d.connections) do c:Disconnect() end end
    end; espObjects = {}
    local pl = {}; for _, p in pairs(Players:GetPlayers()) do if p ~= player then table.insert(pl, p) end end
    for i, p in ipairs(pl) do if p.Character then createESP(p, i) end end
end
local function enableESP() Settings.ESP_Enabled = true; refreshESP() end
local function disableESP()
    Settings.ESP_Enabled = false
    for _, d in pairs(espObjects) do
        pcall(function() if d.highlight then d.highlight:Destroy() end end); pcall(function() if d.billboard then d.billboard:Destroy() end end)
        pcall(function() if d.tracer then d.tracer:Remove() end end); pcall(function() if d.headDot then d.headDot:Remove() end end)
        if d.connections then for _, c in pairs(d.connections) do c:Disconnect() end end
    end; espObjects = {}
end

-- ====================== GUI ======================
local screenGui = Instance.new("ScreenGui")
screenGui.Name = "MIDHUB"
screenGui.ResetOnSpawn = false
screenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
screenGui.Parent = player:WaitForChild("PlayerGui")

local mainFrame = Instance.new("Frame")
mainFrame.Size = UDim2.new(0, 340, 0, 560)
mainFrame.Position = UDim2.new(0, 6, 0.5, -280)
mainFrame.BackgroundColor3 = currentTheme.Background
mainFrame.BackgroundTransparency = 0.02
mainFrame.BorderSizePixel = 0
mainFrame.Active = true
mainFrame.Draggable = true
mainFrame.ClipsDescendants = true
mainFrame.Parent = screenGui
Instance.new("UICorner", mainFrame).CornerRadius = UDim.new(0, 18)
Instance.new("UIStroke", mainFrame).Color = currentTheme.Primary
mainFrame.UIStroke.Thickness = 2.5
mainFrame.UIStroke.Transparency = 0.2

local header = Instance.new("Frame")
header.Size = UDim2.new(1, 0, 0, 50)
header.BackgroundColor3 = currentTheme.Surface
header.BackgroundTransparency = 0.1
header.BorderSizePixel = 0
header.Parent = mainFrame
Instance.new("UICorner", header).CornerRadius = UDim.new(0, 18)

local logoIcon = Instance.new("TextLabel")
logoIcon.Size = UDim2.new(0, 40, 0, 40)
logoIcon.Position = UDim2.new(0, 10, 0, 5)
logoIcon.BackgroundTransparency = 1
logoIcon.Text = currentTheme.Icon
logoIcon.TextSize = 24
logoIcon.Font = Enum.Font.GothamBlack
logoIcon.Parent = header

local titleMain = Instance.new("TextLabel")
titleMain.Size = UDim2.new(1, -100, 0, 24)
titleMain.Position = UDim2.new(0, 55, 0, 5)
titleMain.BackgroundTransparency = 1
titleMain.Text = "MIDHUB v7.4"
titleMain.TextColor3 = Color3.new(1,1,1)
titleMain.TextSize = 17
titleMain.Font = Enum.Font.GothamBlack
titleMain.TextXAlignment = Enum.TextXAlignment.Left
titleMain.Parent = header

local statusBar = Instance.new("Frame")
statusBar.Size = UDim2.new(1, -16, 0, 26)
statusBar.Position = UDim2.new(0, 8, 0, 55)
statusBar.BackgroundColor3 = currentTheme.SurfaceLight
statusBar.BorderSizePixel = 0
statusBar.Parent = mainFrame
Instance.new("UICorner", statusBar).CornerRadius = UDim.new(0, 10)

local statusText = Instance.new("TextLabel")
statusText.Size = UDim2.new(1, -10, 1, 0)
statusText.Position = UDim2.new(0, 5, 0, 0)
statusText.BackgroundTransparency = 1
statusText.Text = "✅ Selecione um jogador e ative o Teleport"
statusText.TextColor3 = currentTheme.TextSecondary
statusText.TextSize = 10
statusText.Font = Enum.Font.GothamSemibold
statusText.TextXAlignment = Enum.TextXAlignment.Left
statusText.Parent = statusBar

local sep = Instance.new("Frame")
sep.Size = UDim2.new(1, -16, 0, 1)
sep.Position = UDim2.new(0, 8, 0, 86)
sep.BackgroundColor3 = currentTheme.Primary
sep.BackgroundTransparency = 0.6
sep.BorderSizePixel = 0
sep.Parent = mainFrame

local tabBar = Instance.new("Frame")
tabBar.Size = UDim2.new(1, -16, 0, 30)
tabBar.Position = UDim2.new(0, 8, 0, 92)
tabBar.BackgroundColor3 = currentTheme.Surface
tabBar.BackgroundTransparency = 0.5
tabBar.BorderSizePixel = 0
tabBar.Parent = mainFrame
Instance.new("UICorner", tabBar).CornerRadius = UDim.new(0, 10)

local currentTab = "players"
local contentArea = Instance.new("Frame")
contentArea.Size = UDim2.new(1, -16, 0, 285)
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
            btn.Size = UDim2.new(1, -6, 0, 32)
            btn.BackgroundColor3 = targetCorpse == obj and currentTheme.Danger or currentTheme.Surface
            btn.Text = "💀 " .. obj.Name
            btn.TextColor3 = Color3.new(1,1,1)
            btn.TextSize = 12
            btn.Font = Enum.Font.GothamSemibold
            btn.AutoButtonColor = false
            btn.Parent = corpsesScroll
            Instance.new("UICorner", btn).CornerRadius = UDim.new(0, 10)
            btn.MouseButton1Click:Connect(function()
                targetCorpse = obj
                for _, c in pairs(corpsesScroll:GetChildren()) do if c:IsA("TextButton") then c.BackgroundColor3 = currentTheme.Surface end end
                btn.BackgroundColor3 = currentTheme.Danger
                statusText.Text = "💀 " .. obj.Name
            end)
        end
    end
    corpsesScroll.CanvasSize = UDim2.new(0, 0, 0, corpsesListLayout.AbsoluteContentSize.Y + 10)
end

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
configScroll.ScrollBarThickness = 5
configScroll.ScrollBarImageColor3 = currentTheme.Primary
configScroll.Parent = configFrame

local configLayout = Instance.new("UIListLayout")
configLayout.SortOrder = Enum.SortOrder.LayoutOrder
configLayout.Padding = UDim.new(0, 8)
configLayout.Parent = configScroll

local cfgT1 = Instance.new("TextLabel")
cfgT1.Size = UDim2.new(1, 0, 0, 22)
cfgT1.BackgroundTransparency = 1
cfgT1.Text = "🎨 Temas"
cfgT1.TextColor3 = Color3.new(1,1,1)
cfgT1.TextSize = 13
cfgT1.Font = Enum.Font.GothamBlack
cfgT1.Parent = configScroll

for _, tn in pairs({"Purple", "Midnight", "Crimson", "Emerald", "Gold"}) do
    local theme = Themes[tn]
    local btn = Instance.new("TextButton")
    btn.Size = UDim2.new(1, 0, 0, 36)
    btn.BackgroundColor3 = theme.Primary
    btn.Text = "  " .. theme.Icon .. "  " .. theme.Name
    btn.TextColor3 = Color3.new(1,1,1)
    btn.TextSize = 12
    btn.Font = Enum.Font.GothamBold
    btn.AutoButtonColor = false
    btn.Parent = configScroll
    Instance.new("UICorner", btn).CornerRadius = UDim.new(0, 12)
    if tn == Settings.UI_Theme then
        local ind = Instance.new("Frame", btn)
        ind.Size = UDim2.new(0, 5, 1, -10)
        ind.Position = UDim2.new(1, -10, 0, 5)
        ind.BackgroundColor3 = Color3.fromRGB(80, 255, 120)
        ind.BorderSizePixel = 0
        Instance.new("UICorner", ind).CornerRadius = UDim.new(0, 2)
    end
    btn.MouseButton1Click:Connect(function()
        Settings.UI_Theme = tn; applyTheme()
        for _, c in pairs(configScroll:GetChildren()) do
            if c:IsA("TextButton") then
                local old = c:FindFirstChild("Frame"); if old then old:Destroy() end
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
    end)
end

local function configToggle(text, icon, callback)
    local btn = Instance.new("TextButton")
    btn.Size = UDim2.new(1, 0, 0, 32)
    btn.BackgroundColor3 = currentTheme.Surface
    btn.Text = icon .. "  " .. text
    btn.TextColor3 = Color3.new(1,1,1)
    btn.TextSize = 12
    btn.Font = Enum.Font.GothamSemibold
    btn.AutoButtonColor = false
    btn.Parent = configScroll
    Instance.new("UICorner", btn).CornerRadius = UDim.new(0, 10)
    local on = false
    btn.MouseButton1Click:Connect(function()
        on = not on
        btn.BackgroundColor3 = on and currentTheme.Success or currentTheme.Surface
        pcall(function() callback(on) end)
    end)
    return btn
end

configToggle("Anti-Kick + Anti-TP", "🛡️", function(on)
    Settings.AntiKick_Enabled = on; AntiKick.Enabled = on
    Settings.AntiTeleport_Enabled = on; AntiKick.AntiTeleportEnabled = on
end)
configToggle("FullBright", "💡", toggleFullBright)
configToggle("NoClip", "👻", toggleNoClip)
configToggle("Auto Respawn", "🔄", function(on) Settings.AutoRespawn = on end)

configScroll.CanvasSize = UDim2.new(0, 0, 0, configLayout.AbsoluteContentSize.Y + 20)

-- ABA INFO
local infoFrame = Instance.new("Frame")
infoFrame.Size = UDim2.new(1, 0, 1, 0)
infoFrame.BackgroundTransparency = 1
infoFrame.Visible = false
infoFrame.Parent = contentArea

local infoBody = Instance.new("TextLabel")
infoBody.Size = UDim2.new(1, 0, 1, 0)
infoBody.BackgroundTransparency = 1
infoBody.Text = "MIDHUB v7.4\n\n✅ ESP\n✅ Teleport Corrigido\n✅ Team TP\n✅ Corpse TP\n✅ Anti-Kick\n✅ Anti-TP\n✅ NoClip\n✅ FullBright\n\n💬 /midhub"
infoBody.TextColor3 = currentTheme.TextSecondary
infoBody.TextSize = 11
infoBody.Font = Enum.Font.Gotham
infoBody.TextXAlignment = Enum.TextXAlignment.Center
infoBody.TextWrapped = true
infoBody.LineHeight = 1.6
infoBody.Parent = infoFrame

-- Switch Tab
local function switchTab(tab)
    currentTab = tab
    playersFrame.Visible = (tab == "players")
    corpsesFrame.Visible = (tab == "corpses")
    configFrame.Visible = (tab == "config")
    infoFrame.Visible = (tab == "info")
    if tab == "corpses" then updateCorpsesList() end
    for _, c in pairs(tabBar:GetChildren()) do
        if c:IsA("TextButton") then
            local isActive = (tab == "players" and c == tabPlayers) or (tab == "corpses" and c == tabCorpses) or (tab == "config" and c == tabConfig) or (tab == "info" and c == tabInfo)
            c.BackgroundColor3 = isActive and currentTheme.Primary or Color3.fromRGB(255,255,255)
            c.BackgroundTransparency = isActive and 0.1 or 0.95
            c.TextColor3 = isActive and Color3.new(1,1,1) or currentTheme.TextSecondary
        end
    end
end

local tabPlayers = Instance.new("TextButton")
tabPlayers.Size = UDim2.new(0.23, 0, 0.75, 0)
tabPlayers.Position = UDim2.new(0.01, 0, 0.125, 0)
tabPlayers.BackgroundColor3 = currentTheme.Primary
tabPlayers.BackgroundTransparency = 0.1
tabPlayers.Text = "🎮"
tabPlayers.TextColor3 = Color3.new(1,1,1)
tabPlayers.TextSize = 13
tabPlayers.Font = Enum.Font.GothamBold
tabPlayers.AutoButtonColor = false
tabPlayers.Parent = tabBar
Instance.new("UICorner", tabPlayers).CornerRadius = UDim.new(0, 8)
tabPlayers.MouseButton1Click:Connect(function() switchTab("players") end)

local tabCorpses = Instance.new("TextButton")
tabCorpses.Size = UDim2.new(0.23, 0, 0.75, 0)
tabCorpses.Position = UDim2.new(0.26, 0, 0.125, 0)
tabCorpses.BackgroundColor3 = Color3.fromRGB(255,255,255)
tabCorpses.BackgroundTransparency = 0.95
tabCorpses.Text = "💀"
tabCorpses.TextColor3 = currentTheme.TextSecondary
tabCorpses.TextSize = 13
tabCorpses.Font = Enum.Font.GothamBold
tabCorpses.AutoButtonColor = false
tabCorpses.Parent = tabBar
Instance.new("UICorner", tabCorpses).CornerRadius = UDim.new(0, 8)
tabCorpses.MouseButton1Click:Connect(function() switchTab("corpses") end)

local tabConfig = Instance.new("TextButton")
tabConfig.Size = UDim2.new(0.23, 0, 0.75, 0)
tabConfig.Position = UDim2.new(0.51, 0, 0.125, 0)
tabConfig.BackgroundColor3 = Color3.fromRGB(255,255,255)
tabConfig.BackgroundTransparency = 0.95
tabConfig.Text = "⚙️"
tabConfig.TextColor3 = currentTheme.TextSecondary
tabConfig.TextSize = 13
tabConfig.Font = Enum.Font.GothamBold
tabConfig.AutoButtonColor = false
tabConfig.Parent = tabBar
Instance.new("UICorner", tabConfig).CornerRadius = UDim.new(0, 8)
tabConfig.MouseButton1Click:Connect(function() switchTab("config") end)

local tabInfo = Instance.new("TextButton")
tabInfo.Size = UDim2.new(0.23, 0, 0.75, 0)
tabInfo.Position = UDim2.new(0.76, 0, 0.125, 0)
tabInfo.BackgroundColor3 = Color3.fromRGB(255,255,255)
tabInfo.BackgroundTransparency = 0.95
tabInfo.Text = "ℹ️"
tabInfo.TextColor3 = currentTheme.TextSecondary
tabInfo.TextSize = 13
tabInfo.Font = Enum.Font.GothamBold
tabInfo.AutoButtonColor = false
tabInfo.Parent = tabBar
Instance.new("UICorner", tabInfo).CornerRadius = UDim.new(0, 8)
tabInfo.MouseButton1Click:Connect(function() switchTab("info") end)

-- ====================== BOTÕES PRINCIPAIS (CORRIGIDOS) ======================
local espBtnOn = false
local teleportBtnOn = false
local teamTPBtnOn = false
local corpseTPBtnOn = false
local noclipBtnOn = false
local antikickBtnOn = true

local function makeButton(x, y, w, h, icon, text, color, isOn, callback)
    local btn = Instance.new("TextButton")
    btn.Size = UDim2.new(w, 0, 0, h)
    btn.Position = UDim2.new(x, 0, 0, y)
    btn.BackgroundColor3 = isOn and currentTheme.Success or color
    btn.Text = ""
    btn.AutoButtonColor = false
    btn.Parent = mainFrame
    Instance.new("UICorner", btn).CornerRadius = UDim.new(0, 12)
    
    local ic = Instance.new("TextLabel")
    ic.Size = UDim2.new(0, 22, 1, 0)
    ic.Position = UDim2.new(0, 8, 0, 0)
    ic.BackgroundTransparency = 1
    ic.Text = isOn and "✅" or icon
    ic.TextSize = 15
    ic.Font = Enum.Font.Gotham
    ic.Parent = btn
    
    local tx = Instance.new("TextLabel")
    tx.Size = UDim2.new(1, -32, 1, 0)
    tx.Position = UDim2.new(0, 30, 0, 0)
    tx.BackgroundTransparency = 1
    tx.Text = text
    tx.TextColor3 = Color3.new(1,1,1)
    tx.TextSize = 12
    tx.Font = Enum.Font.GothamSemibold
    tx.TextXAlignment = Enum.TextXAlignment.Left
    tx.Parent = btn
    
    btn.MouseButton1Click:Connect(function()
        isOn = not isOn
        btn.BackgroundColor3 = isOn and currentTheme.Success or color
        ic.Text = isOn and "✅" or icon
        pcall(function() callback(isOn) end)
    end)
    
    return btn, function() return isOn end
end

-- CORRIGIDO: Botão ESP
local espBtn = makeButton(0.03, 418, 0.47, 36, "👁️", "ESP", Color3.fromRGB(130, 45, 180), espBtnOn, function(on)
    espBtnOn = on
    if on then enableESP() else disableESP() end
    statusText.Text = on and "👁️ ESP Ativado" or "✅ Pronto"
end)

-- CORRIGIDO: Botão Teleport (AGORA FUNCIONA)
local teleportBtn = makeButton(0.52, 418, 0.47, 36, "🎯", "Teleport", Color3.fromRGB(75, 35, 190), teleportBtnOn, function(on)
    teleportBtnOn = on
    if on then
        if not targetPlayer then
            statusText.Text = "⚠️ Selecione um jogador primeiro!"
            StarterGui:SetCore("SendNotification", {Title = "Teleport", Text = "Selecione um jogador na lista!", Duration = 3})
            -- Reseta o botão
            teleportBtnOn = false
            return
        end
        if not targetPlayer.Character or not targetPlayer.Character:FindFirstChild("HumanoidRootPart") then
            statusText.Text = "⚠️ Jogador não tem personagem!"
            teleportBtnOn = false
            return
        end
        isTeleporting = true
        if teleportConnection then teleportConnection:Disconnect() end
        teleportConnection = RunService.Heartbeat:Connect(function()
            if not isTeleporting then
                if teleportConnection then teleportConnection:Disconnect(); teleportConnection = nil end
                return
            end
            if targetPlayer and targetPlayer.Character and targetPlayer.Character:FindFirstChild("HumanoidRootPart") then
                teleportToPlayer(targetPlayer)
            end
        end)
        statusText.Text = "🎯 Teleportando para " .. targetPlayer.DisplayName
        StarterGui:SetCore("SendNotification", {Title = "Teleport", Text = "Teleportando para " .. targetPlayer.DisplayName, Duration = 2})
    else
        isTeleporting = false
        if teleportConnection then teleportConnection:Disconnect(); teleportConnection = nil end
        statusText.Text = "✅ Teleport Parado"
    end
end)

-- CORRIGIDO: Botão Team TP
local teamTPBtn = makeButton(0.03, 462, 0.47, 36, "👥", "Team TP", Color3.fromRGB(55, 25, 140), teamTPBtnOn, function(on)
    teamTPBtnOn = on
    if on then
        Settings.Teleport_TeamMode = true
        startTeamTP()
        statusText.Text = "👥 Team TP Ativo"
    else
        stopTeamTP()
        statusText.Text = "✅ Pronto"
    end
end)

-- CORRIGIDO: Botão Corpse TP
local corpseTPBtn = makeButton(0.52, 462, 0.47, 36, "💀", "Corpse TP", Color3.fromRGB(200, 50, 50), corpseTPBtnOn, function(on)
    corpseTPBtnOn = on
    if on then
        if not targetCorpse then
            statusText.Text = "⚠️ Selecione um corpo na aba 💀!"
            corpseTPBtnOn = false
            return
        end
        startCorpseTP(targetCorpse.Name)
        statusText.Text = "💀 Corpse TP Ativo"
    else
        stopCorpseTP()
        statusText.Text = "✅ Pronto"
    end
end)

-- Botão NoClip
local noclipBtn = makeButton(0.03, 506, 0.47, 36, "👻", "NoClip", Color3.fromRGB(80, 80, 160), noclipBtnOn, function(on)
    noclipBtnOn = on
    toggleNoClip(on)
end)

-- Botão Anti-Kick
local antikickBtn = makeButton(0.52, 506, 0.47, 36, "🛡️", "Anti-Kick", Color3.fromRGB(100, 180, 100), antikickBtnOn, function(on)
    antikickBtnOn = on
    Settings.AntiKick_Enabled = on
    AntiKick.Enabled = on
    Settings.AntiTeleport_Enabled = on
    AntiKick.AntiTeleportEnabled = on
    statusText.Text = on and "🛡️ Proteção Ativa" or "⚠️ Proteção OFF"
end)

-- Aplicar tema
function applyTheme()
    currentTheme = Themes[Settings.UI_Theme]
    mainFrame.BackgroundColor3 = currentTheme.Background
    mainFrame.UIStroke.Color = currentTheme.Primary
    header.BackgroundColor3 = currentTheme.Surface
    logoIcon.Text = currentTheme.Icon
    statusBar.BackgroundColor3 = currentTheme.SurfaceLight
    statusText.TextColor3 = currentTheme.TextSecondary
    sep.BackgroundColor3 = currentTheme.Primary
    tabBar.BackgroundColor3 = currentTheme.Surface
    searchInput.BackgroundColor3 = currentTheme.Surface
    playersScroll.BackgroundColor3 = currentTheme.Surface
    playersScroll.ScrollBarImageColor3 = currentTheme.Primary
    corpsesScroll.BackgroundColor3 = currentTheme.Surface
    corpsesScroll.ScrollBarImageColor3 = currentTheme.Danger
    infoBody.TextColor3 = currentTheme.TextSecondary
    for _, c in pairs(tabBar:GetChildren()) do
        if c:IsA("TextButton") then
            local isActive = (currentTab == "players" and c == tabPlayers) or (currentTab == "corpses" and c == tabCorpses) or (currentTab == "config" and c == tabConfig) or (currentTab == "info" and c == tabInfo)
            c.BackgroundColor3 = isActive and currentTheme.Primary or Color3.fromRGB(255,255,255)
            c.BackgroundTransparency = isActive and 0.1 or 0.95
            c.TextColor3 = isActive and Color3.new(1,1,1) or currentTheme.TextSecondary
        end
    end
    if Settings.ESP_Enabled then refreshESP() end
    updatePlayerList()
end

-- Lista de jogadores
local function updatePlayerList()
    for _, c in pairs(playersScroll:GetChildren()) do if c:IsA("TextButton") then c:Destroy() end end
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
                Instance.new("UICorner", btn).CornerRadius = UDim.new(0, 10)
                
                local dot = Instance.new("Frame")
                dot.Size = UDim2.new(0, 10, 0, 10)
                dot.Position = UDim2.new(0, 10, 0.5, -5)
                dot.BackgroundColor3 = plr.Team == player.Team and Color3.fromRGB(80, 255, 120) or Color3.fromRGB(255, 80, 80)
                dot.BorderSizePixel = 0
                dot.Parent = btn
                Instance.new("UICorner", dot).CornerRadius = UDim.new(1, 0)
                
                local nm = Instance.new("TextLabel")
                nm.Size = UDim2.new(1, -55, 1, 0)
                nm.Position = UDim2.new(0, 26, 0, 0)
                nm.BackgroundTransparency = 1
                nm.Text = plr.DisplayName
                nm.TextColor3 = Color3.new(1,1,1)
                nm.TextSize = 12
                nm.Font = Enum.Font.GothamSemibold
                nm.TextXAlignment = Enum.TextXAlignment.Left
                nm.Parent = btn
                
                -- CORRIGIDO: Ao clicar no jogador, atualiza targetPlayer
                btn.MouseButton1Click:Connect(function()
                    targetPlayer = plr
                    for _, c in pairs(playersScroll:GetChildren()) do
                        if c:IsA("TextButton") then c.BackgroundColor3 = currentTheme.Surface end
                    end
                    btn.BackgroundColor3 = currentTheme.Primary
                    statusText.Text = "👤 Alvo: " .. plr.DisplayName .. " | Ative o Teleport!"
                end)
            end
        end
    end
    playersScroll.CanvasSize = UDim2.new(0, 0, 0, playersListLayout.AbsoluteContentSize.Y + 10)
end

searchInput:GetPropertyChangedSignal("Text"):Connect(updatePlayerList)
Players.PlayerAdded:Connect(updatePlayerList)
Players.PlayerRemoving:Connect(function(plr)
    wait(0.1)
    if targetPlayer == plr then
        targetPlayer = nil
        statusText.Text = "⚠️ Alvo saiu do jogo"
    end
    updatePlayerList()
end)
spawn(function() while true do updatePlayerList(); wait(3) end end)
updatePlayerList()

-- Inicializar
setupAntiKick()
setupBypass()

player.Chatted:Connect(function(msg)
    if msg:lower() == "/midhub" or msg:lower() == "/mh" then
        mainFrame.Visible = not mainFrame.Visible
    end
end)

StarterGui:SetCore("SendNotification", {
    Title = "MIDHUB v7.4",
    Text = "Teleport Corrigido! Selecione um jogador e ative o Teleport",
    Duration = 5,
})

print("✅ MIDHUB v7.4 - Teleport Corrigido!")
print("📋 Como usar: 1. Clique no jogador | 2. Ative o botão Teleport")
