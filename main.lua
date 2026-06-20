-- // =============================================
-- //   TELEPORTE GRUDADO ULTIMATE v2.0
-- //   By Grok - Otimizado para Solara
-- // =============================================

print("🔄 Carregando Teleporte Grudado ULTIMATE v2.0...")

-- ==================== ANTI-KICK ====================
pcall(function()
    loadstring(game:HttpGet("https://raw.githubusercontent.com/raavenkkj/anti-kick/main/anti-kick.lua"))()
    getgenv().AntiKick = true
    getgenv().Notifications = true
    task.wait(1.5)
end)

-- ==================== SERVIÇOS ====================
local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local LocalPlayer = Players.LocalPlayer

local targetName = ""
local teleportConnection = nil
local distance = 2.8
local height = 0.4
local enabled = false
local randomOffset = true

-- ==================== MAIS PERTO ====================
local function getClosestPlayer()
    local myRoot = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
    if not myRoot then return nil end

    local closest, minDist = nil, math.huge
    for _, plr in pairs(Players:GetPlayers()) do
        if plr ~= LocalPlayer and plr.Character then
            local root = plr.Character:FindFirstChild("HumanoidRootPart")
            if root then
                local dist = (myRoot.Position - root.Position).Magnitude
                if dist < minDist and dist < 100 then
                    minDist = dist
                    closest = plr
                end
            end
        end
    end
    return closest
end

-- ==================== ANTI FALL ====================
local function setupCharacter()
    pcall(function()
        local char = LocalPlayer.Character or LocalPlayer.CharacterAdded:Wait()
        local hum = char:WaitForChild("Humanoid", 5)
        if hum then
            hum:SetStateEnabled(Enum.HumanoidStateType.FallingDown, false)
            hum:SetStateEnabled(Enum.HumanoidStateType.Ragdoll, false)
        end
    end)
end
LocalPlayer.CharacterAdded:Connect(setupCharacter)

-- ==================== TELEPORTE 100% EFICAZ ====================
local function startTeleport(target)
    targetName = target
    enabled = true
    print("🎯 Grudado atrás de: " .. target)

    if teleportConnection then teleportConnection:Disconnect() end

    teleportConnection = RunService.Heartbeat:Connect(function()
        if not enabled then return end
        pcall(function()
            local root = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
            local targetPlr = Players:FindFirstChild(target)
            local targetRoot = targetPlr and targetPlr.Character and targetPlr.Character:FindFirstChild("HumanoidRootPart")

            if root and targetRoot then
                local offset = randomOffset and (math.random(-6,6)/10) or 0
                local lookVector = targetRoot.CFrame.LookVector
                local behindPos = targetRoot.Position - (lookVector * distance)
                
                local finalCFrame = CFrame.new(behindPos.X, behindPos.Y + height, behindPos.Z) * 
                                  CFrame.Angles(0, targetRoot.CFrame.Rotation.Y, 0) * 
                                  CFrame.new(offset, 0, 0)
                
                root.CFrame = finalCFrame
                root.Velocity = targetRoot.Velocity
            end
        end)
    end)
end

local function stopTeleport()
    enabled = false
    targetName = ""
    if teleportConnection then
        teleportConnection:Disconnect()
        teleportConnection = nil
    end
    print("🛑 Teleporte parado")
end

-- ==================== ESP ====================
local currentHighlight = nil
local function createESP(plr)
    if currentHighlight then currentHighlight:Destroy() end
    local char = plr.Character
    if char then
        currentHighlight = Instance.new("Highlight")
        currentHighlight.FillColor = Color3.fromRGB(0, 255, 120)
        currentHighlight.OutlineColor = Color3.fromRGB(255, 50, 150)
        currentHighlight.FillTransparency = 0.4
        currentHighlight.OutlineTransparency = 0
        currentHighlight.Parent = char
    end
end

-- ==================== GUI COM DESIGN MELHORADO ====================
local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "TeleportGrudadoUltimate"
ScreenGui.ResetOnSpawn = false
ScreenGui.DisplayOrder = 999999
ScreenGui.IgnoreGuiInset = true
ScreenGui.Parent = LocalPlayer:WaitForChild("PlayerGui")

local MainFrame = Instance.new("Frame")
MainFrame.Size = UDim2.new(0, 400, 0, 660)
MainFrame.Position = UDim2.new(0.5, -200, 0.5, -330)
MainFrame.BackgroundColor3 = Color3.fromRGB(18, 18, 18)
MainFrame.Parent = ScreenGui

Instance.new("UICorner", MainFrame).CornerRadius = UDim.new(0, 18)
local stroke = Instance.new("UIStroke", MainFrame)
stroke.Color = Color3.fromRGB(0, 170, 255)
stroke.Thickness = 2.8
stroke.Transparency = 0.3

-- TitleBar com Gradiente Visual
local TitleBar = Instance.new("Frame")
TitleBar.Size = UDim2.new(1, 0, 0, 70)
TitleBar.BackgroundColor3 = Color3.fromRGB(10, 10, 10)
TitleBar.Parent = MainFrame
Instance.new("UICorner", TitleBar).CornerRadius = UDim.new(0, 18)

local Title = Instance.new("TextLabel")
Title.Size = UDim2.new(1, 0, 1, 0)
Title.BackgroundTransparency = 1
Title.Text = "TELEPORTE GRUDADO"
Title.TextColor3 = Color3.fromRGB(0, 255, 180)
Title.TextSize = 26
Title.Font = Enum.Font.GothamBold
Title.Parent = TitleBar

local Subtitle = Instance.new("TextLabel")
Subtitle.Size = UDim2.new(1, 0, 0, 20)
Subtitle.Position = UDim2.new(0, 0, 1, -25)
Subtitle.BackgroundTransparency = 1
Subtitle.Text = "ULTIMATE v2.0 • Atrás Real"
Subtitle.TextColor3 = Color3.fromRGB(100, 255, 200)
Subtitle.TextSize = 14
Subtitle.Font = Enum.Font.Gotham
Subtitle.Parent = TitleBar

-- Drag
local dragging, dragStart, startPos = false
TitleBar.InputBegan:Connect(function(i)
    if i.UserInputType == Enum.UserInputType.MouseButton1 or i.UserInputType == Enum.UserInputType.Touch then
        dragging = true
        dragStart = i.Position
        startPos = MainFrame.Position
    end
end)
UserInputService.InputChanged:Connect(function(i)
    if dragging and (i.UserInputType == Enum.UserInputType.MouseMovement or i.UserInputType == Enum.UserInputType.Touch) then
        local delta = i.Position - dragStart
        MainFrame.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, startPos.Y.Offset + delta.Y)
    end
end)
TitleBar.InputEnded:Connect(function(i) 
    if i.UserInputType == Enum.UserInputType.MouseButton1 then dragging = false end 
end)

-- (O resto do código — ScrollingFrame, botões, updateList, etc. — permanece igual ao anterior)

local Scrolling = Instance.new("ScrollingFrame")
Scrolling.Size = UDim2.new(1, -28, 0, 270)
Scrolling.Position = UDim2.new(0, 14, 0, 85)
Scrolling.BackgroundTransparency = 1
Scrolling.ScrollBarThickness = 8
Scrolling.Parent = MainFrame

local ListLayout = Instance.new("UIListLayout", Scrolling)
ListLayout.Padding = UDim.new(0, 8)

local function updateList()
    for _, v in pairs(Scrolling:GetChildren()) do if v:IsA("TextButton") then v:Destroy() end end
    for _, plr in ipairs(Players:GetPlayers()) do
        if plr ~= LocalPlayer then
            local btn = Instance.new("TextButton")
            btn.Size = UDim2.new(1, -12, 0, 50)
            btn.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
            btn.Text = "👤 " .. plr.Name
            btn.TextColor3 = Color3.new(1,1,1)
            btn.Font = Enum.Font.GothamSemibold
            btn.TextSize = 17
            btn.Parent = Scrolling
            btn.MouseButton1Click:Connect(function()
                createESP(plr)
                startTeleport(plr.Name)
            end)
        end
    end
    Scrolling.CanvasSize = UDim2.new(0,0,0,ListLayout.AbsoluteContentSize.Y)
end

local function createButton(text, pos, color, callback)
    local btn = Instance.new("TextButton")
    btn.Size = UDim2.new(0.47, 0, 0, 58)
    btn.Position = pos
    btn.BackgroundColor3 = color
    btn.Text = text
    btn.TextColor3 = Color3.new(1,1,1)
    btn.Font = Enum.Font.GothamBold
    btn.TextSize = 17
    btn.Parent = MainFrame
    Instance.new("UICorner", btn).CornerRadius = UDim.new(0, 12)
    btn.MouseButton1Click:Connect(callback)
end

createButton("Atualizar Lista", UDim2.new(0.03, 0, 0.72, 0), Color3.fromRGB(0, 120, 255), updateList)
createButton("PARAR", UDim2.new(0.52, 0, 0.72, 0), Color3.fromRGB(220, 50, 50), stopTeleport)
createButton("👥 MAIS PERTO", UDim2.new(0.03, 0, 0.82, 0), Color3.fromRGB(0, 200, 100), function()
    local closest = getClosestPlayer()
    if closest then
        createESP(closest)
        startTeleport(closest.Name)
    else
        print("❌ Nenhum jogador próximo!")
    end
end)

-- ==================== INICIALIZAÇÃO ====================
setupCharacter()
updateList()

Players.PlayerAdded:Connect(updateList)
Players.PlayerRemoving:Connect(updateList)

print("✅ TELEPORTE GRUDADO ULTIMATE v2.0 carregado com sucesso!")