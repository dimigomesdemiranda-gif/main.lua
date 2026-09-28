-- URIEL | Obsidian UI
-- Docs: https://docs.mspaint.cc/obsidian

if getgenv().TSG_OBSIDIAN_LOADED then
	return warn("[TSG] Script already loaded - rejoin to re-execute.")
end
getgenv().TSG_OBSIDIAN_LOADED = true

-- Services
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService("UserInputService")
local CollectionService = game:GetService("CollectionService")

local LocalPlayer = Players.LocalPlayer

local joinLowPingServer

-- Obsidian
local repo = "https://raw.githubusercontent.com/deividcomsono/Obsidian/main/"
local Library = loadstring(game:HttpGet(repo .. "Library.lua"))()
local ThemeManager = loadstring(game:HttpGet(repo .. "addons/ThemeManager.lua"))()
local SaveManager = loadstring(game:HttpGet(repo .. "addons/SaveManager.lua"))()

-- Ensure Lucide Icons are properly loaded for tabs & groupboxes
pcall(function()
	local lucideModule = nil
	pcall(function()
		lucideModule = loadstring(game:HttpGet("https://raw.githubusercontent.com/mstudio45/lucide-roblox-direct/main/source.lua"))()
	end)
	if not lucideModule then
		pcall(function()
			lucideModule = loadstring(game:HttpGet("https://raw.githubusercontent.com/mstudio45/lucide-roblox/main/src/modules/util/lucide.lua"))()
		end)
	end
	if lucideModule and Library.SetIconModule then
		Library:SetIconModule(lucideModule)
	end
end)

local Options = Library.Options
local Toggles = Library.Toggles
local lastDeathPosition = nil
local shouldTeleportBack = false
local updateAutoSwingSliderVisibility
local updatePVPModulesVisibility
local updateTouchFlingVisibility
local updateHelicopterVisibility
local updateAutoPickupVisibility
local updatePlayerESPVisibility
local updateFlightVisibility
local updateImmortalModeVisibility
local updatePhantomModeVisibility
local updateSwimBoostVisibility

Library.ShowToggleFrameInKeybinds = true


-- Helpers
local function waitForChild(parent, name, timeout)
	timeout = timeout or 10
	local start = tick()
	local child = parent:FindFirstChild(name)
	while not child and tick() - start < timeout do
		task.wait()
		child = parent:FindFirstChild(name)
	end
	return child
end

local function resolvePath(parent, ...)
	local current = parent
	for _, name in {...} do
		current = waitForChild(current, name)
		if not current then
			return nil
		end
	end
	return current
end

local function getCharacter()
	return LocalPlayer.Character
end

local function getHumanoid()
	local character = getCharacter()
	return character and character:FindFirstChildOfClass("Humanoid")
end

local function getRootPart()
	local character = getCharacter()
	return character and character:FindFirstChild("HumanoidRootPart")
end

local function isAlive()
	local humanoid = getHumanoid()
	return humanoid and humanoid.Health > 0
end

local function isHoldingSelectedSlot(selectedSlot)
	if not selectedSlot then return false end
	local character = getCharacter()
	if not character then return false end
	local tool = character:FindFirstChildOfClass("Tool")
	if not tool then return false end

	local slotStr = tostring(selectedSlot)
	local slotNum = tonumber(selectedSlot)

	if tool.Name == slotStr then
		return true
	end
	if slotNum and tonumber(tool.Name) == slotNum then
		return true
	end
	if slotNum then
		local attrSlot = tool:GetAttribute("slot") or tool:GetAttribute("Slot") or tool:GetAttribute("HotbarSlot")
		if attrSlot and (attrSlot == slotNum or tostring(attrSlot) == slotStr) then
			return true
		end
		if tool:FindFirstChild("toolModel") then
			local tmSlot = tool.toolModel:GetAttribute("slot") or tool.toolModel:GetAttribute("Slot") or tool.toolModel:GetAttribute("HotbarSlot")
			if tmSlot and (tmSlot == slotNum or tostring(tmSlot) == slotStr) then
				return true
			end
		end
	end
	if tool.Name:match("^Slot%s*" .. slotStr .. "$") or tool.Name:match("^slot%s*" .. slotStr .. "$") then
		return true
	end

	return false
end

local function getCharacterFolder()
	local characters = workspace:FindFirstChild("Characters")
	return characters and characters:FindFirstChild(LocalPlayer.Name)
end

local function getCharacterBehavior(name)
	local folder = getCharacterFolder()
	return folder and folder:FindFirstChild(name)
end

local function setBehaviorDisabled(instance, disabled)
	if not instance then
		return false
	end
	local ok = pcall(function()
		instance.Disabled = disabled
	end)
	return ok
end

local function getKeyedRemotes()
	local keyed
	local ok = pcall(function()
		if typeof(filtergc) == "function" then
			for _, fn in next, filtergc("function", { Constants = { "Destroy", "new" } }) do
				for _, upvalue in next, debug.getupvalues(fn) do
					if typeof(upvalue) == "table" and rawget(upvalue, "meleePlayer") then
						keyed = upvalue
						return
					end
				end
			end
		end
	end)
	if keyed then
		return keyed
	end
	pcall(function()
		for _, fn in next, getgc(true) do
			if typeof(fn) == "function" and islclosure(fn) then
				local constants = debug.getconstants(fn)
				if rawget(constants, 1) == "Destroy" and rawget(constants, 2) == "new" then
					for _, upvalue in next, debug.getupvalues(fn) do
						if typeof(upvalue) == "table" and rawget(upvalue, "meleePlayer") then
							keyed = upvalue
							return
						end
					end
				end
			end
		end
	end)
	return keyed
end

-- Game modules & remotes
local TSG = {}
local Crypt = nil
pcall(function()
	Crypt = require(ReplicatedStorage:WaitForChild("Crypt", 5))
end)
local AiController = nil
pcall(function()
	local playerScripts = LocalPlayer:WaitForChild("PlayerScripts", 5)
	if playerScripts then
		AiController = require(playerScripts:WaitForChild("AIController", 5))
	end
end)

local function getChopTargetPart(obj)
	if not obj then return nil end
	local primary = obj.PrimaryPart
	if primary and primary:IsA("BasePart") then
		return primary
	end
	local part = obj:FindFirstChildWhichIsA("BasePart")
	if part then
		return part
	end
	for _, desc in ipairs(obj:GetDescendants()) do
		if desc:IsA("BasePart") then
			return desc
		end
	end
	return nil
end

local function getFlatDistance(a, b)
	local delta = Vector3.new(a.X, 0, a.Z) - Vector3.new(b.X, 0, b.Z)
	return delta.Magnitude
end

pcall(function()
	TSG.ClientData = require(resolvePath(ReplicatedStorage, "modules", "player", "ClientData"))
	TSG.Items = require(resolvePath(ReplicatedStorage, "game", "Items"))
	TSG.Sounds = require(resolvePath(ReplicatedStorage, "modules", "misc", "Sounds"))
end)

local keyedRemotes = getKeyedRemotes()
local interactionsFolder = ReplicatedStorage:FindFirstChild("remoteInterface") and ReplicatedStorage.remoteInterface:FindFirstChild("interactions")

TSG.EatRemote = resolvePath(ReplicatedStorage, "remoteInterface", "interactions", "eat")
TSG.MeleeAnimalRemote = resolvePath(ReplicatedStorage, "remoteInterface", "interactions", "meleeAnimal")
TSG.PickupRemote = resolvePath(ReplicatedStorage, "remoteInterface", "inventory", "pickupItem")
TSG.EquipHotbarRemote = resolvePath(ReplicatedStorage, "remoteInterface", "inventory", "equipHotbar")
TSG.SetHungerEvent = resolvePath(ReplicatedStorage, "remoteInterface", "playerData", "setHunger")

TSG.MeleePlayerRemote = (keyedRemotes and rawget(keyedRemotes, "meleePlayer")) or (interactionsFolder and interactionsFolder:FindFirstChild("meleePlayer"))
TSG.MineRemote = (keyedRemotes and rawget(keyedRemotes, "mine")) or (interactionsFolder and interactionsFolder:FindFirstChild("mine"))
TSG.ChopRemote = (keyedRemotes and rawget(keyedRemotes, "chop")) or (interactionsFolder and interactionsFolder:FindFirstChild("chop"))
TSG.MeleeAI = interactionsFolder and interactionsFolder:FindFirstChild("meleeAI")

-- No Bear Trap DMG Remote Interception
pcall(function()
	local Event = resolvePath(ReplicatedStorage, "remoteInterface", "traps", "Run") or (ReplicatedStorage:FindFirstChild("remoteInterface") and ReplicatedStorage.remoteInterface:FindFirstChild("traps") and ReplicatedStorage.remoteInterface.traps:FindFirstChild("Run"))
	if not Event then return end

	local mtHook; mtHook = hookmetamethod(game, "__namecall", function(...)
		local self = ...

		if Toggles.NoBearTrapDMG and Toggles.NoBearTrapDMG.Value and rawequal(self, Event) and getnamecallmethod() == "InvokeServer" then
			print(`Intercepted (__namecall) {Event.Name}:InvokeServer() - BLOCKED`, ...)
			return nil
		end

		return mtHook(...)
	end)

	if typeof(hookfunction) == "function" and Event.InvokeServer then
		local OldInvokeServer; OldInvokeServer = hookfunction(Event.InvokeServer, function(...)
			local self = ...

			if Toggles.NoBearTrapDMG and Toggles.NoBearTrapDMG.Value and rawequal(self, Event) then
				print(`Intercepted (__index) {Event.Name}:InvokeServer() - BLOCKED`, ...)
				return nil
			end

			return OldInvokeServer(self, ...)
		end)
	end
end)


Library.Font = Enum.Font.Gotham
Library.CornerRadius = 15

-- Window
local Window = Library:CreateWindow({
	Title = "♠ URIEL",
	Footer = "CODENAME: ♠ URIEL",
	Icon = nil,
	Center = true,
	AutoShow = true,
	Resizable = true,
	NotifySide = "Right",
	ShowCustomCursor = true,
	CornerRadius = 15,
})

local Tabs = {
	Main = Window:AddTab("CENTRAL", "badge-info"),
	Player = Window:AddTab("PLAYER", "user"),
	Combat = Window:AddTab("COMBAT", "swords"),
	Movement = Window:AddTab("MOVEMENT", "move"),
	Farming = Window:AddTab("AURAS", "sparkles"),
	Teleport = Window:AddTab("TELEPORT", "map-pin"),
	Visuals = Window:AddTab("ESP", "scan-eye"),
	["UI Settings"] = Window:AddTab("UI MODULES", "settings"),
}
Tabs["UI MODULES"] = Tabs["UI Settings"]

-- Connections (clean up on unload)
local Connections = {}

local function track(name, connection)
	Connections[name] = connection
end

local function disconnect(name)
	if Connections[name] then
		Connections[name]:Disconnect()
		Connections[name] = nil
	end
end

local ToiletBedGroup = Tabs.Player:AddLeftGroupbox("Toilet/Bed", "bed")

ToiletBedGroup:AddButton({
	Text = "Toilet Bed",
	Func = function()
		local character = LocalPlayer.Character
		local root = character and character:FindFirstChild("HumanoidRootPart")
		if not root then return end
		local playerPosition = root.Position

		local buildRemote = game:GetService("ReplicatedStorage").remoteInterface.interactions.build

		pcall(function()
			buildRemote:InvokeServer(
				90,
				CFrame.new(playerPosition.X, playerPosition.Y - 3, playerPosition.Z),
				0,
				nil
			)
		end)

		pcall(function()
			buildRemote:InvokeServer(
				85,
				CFrame.new(playerPosition.X, playerPosition.Y - 3, playerPosition.Z),
				0,
				nil
			)
		end)
	end,
})

-- ==========================================
-- MAIN
-- ==========================================
local PlayerTabBox = Tabs.Player:AddLeftTabbox()
local MainLeft = PlayerTabBox:AddTab("Player", "user")
local ImmuneTab = PlayerTabBox:AddTab("Immune", "shield")

local AdvanceHealGroup = Tabs.Player:AddRightGroupbox("Advance Heal", "heart")

AdvanceHealGroup:AddToggle("AutoEatCustom", {
	Text = "Auto Eat",
	Default = false,
})

AdvanceHealGroup:AddDropdown("AutoEatFood", {
	Text = "Food Type",
	Values = {"Cabbage", "Banana", "Spicy Meal", "Hearty Stew", "Cabbage Meal"},
	Default = "Cabbage",
})

AdvanceHealGroup:AddSlider("AutoEatThreshold", {
	Text = "Eat HP Threshold",
	Default = 100,
	Min = 10,
	Max = 130,
	Rounding = 0,
	Compact = true,
})

AdvanceHealGroup:AddSlider("AutoEatCooldown", {
	Text = "Eat Cooldown (s)",
	Default = 0.3,
	Min = 0.3,
	Max = 5.0,
	Rounding = 1,
	Compact = true,
})

local MainRight = Tabs.Player:AddRightGroupbox("Settings", "settings")

-- ============================================================================
-- MAIN TAB (IMMORTAL AURA / SPECTATE)
-- ============================================================================
local CombatAutoBlock = Tabs.Main:AddLeftGroupbox("Immortal Aura", "shield")

CombatAutoBlock:AddToggle("ImmortalMode", {
	Text = "Immortal Aura",
	Default = false,
})

CombatAutoBlock:AddCheckbox("BypassShield", {
	Text = "Bypass Shield",
	Default = false,
})

CombatAutoBlock:AddSlider("ImmortalModeStuds", {
	Text = "Block Distance",
	Default = 18,
	Min = 5,
	Max = 50,
	Rounding = 0,
	Compact = true,
})

CombatAutoBlock:AddSlider("ImmortalShieldSpeed", {
	Text = "SetShield Speed",
	Default = 0.1,
	Min = 0.01,
	Max = 1,
	Rounding = 2,
	Compact = true,
})

CombatAutoBlock:AddToggle("QuickVanish", {
	Text = "Quick Vanish",
	Default = false,
})

CombatAutoBlock:AddSlider("QuickVanishThreshold", {
	Text = "Health Threshold",
	Min = 5,
	Max = 130,
	Default = 35,
	Rounding = 0,
	Compact = true,
})

updateImmortalModeVisibility = function()
	local isImmortal = (Toggles.ImmortalMode and Toggles.ImmortalMode.Value) or false
	if Options.ImmortalModeStuds then
		if Options.ImmortalModeStuds.Visible ~= nil then
			Options.ImmortalModeStuds.Visible = isImmortal
		end
		if Options.ImmortalModeStuds.Holder then
			Options.ImmortalModeStuds.Holder.Visible = isImmortal
		end
	end
	if Options.ImmortalShieldSpeed then
		if Options.ImmortalShieldSpeed.Visible ~= nil then
			Options.ImmortalShieldSpeed.Visible = isImmortal
		end
		if Options.ImmortalShieldSpeed.Holder then
			Options.ImmortalShieldSpeed.Holder.Visible = isImmortal
		end
	end
	if Toggles.BypassShield then
		if Toggles.BypassShield.Visible ~= nil then
			Toggles.BypassShield.Visible = isImmortal
		end
		if Toggles.BypassShield.Holder then
			Toggles.BypassShield.Holder.Visible = isImmortal
		end
	end
	if not isImmortal and Toggles.BypassShield and Toggles.BypassShield.Value then
		Toggles.BypassShield:SetValue(false)
	end
	CombatAutoBlock:Resize()
end

updateImmortalModeVisibility()
task.spawn(function()
	task.wait(0.05)
	if updateImmortalModeVisibility then
		updateImmortalModeVisibility()
	end
end)

local FunAttach = Tabs.Main:AddLeftGroupbox("ATTACH", "link")

FunAttach:AddToggle("AttachToggle", {
        Text = "Attach",
        Default = false,
})

FunAttach:AddDropdown("AttachPlayerList", {
        Text = "Target Player",
        Values = {},
        Default = "",
})

FunAttach:AddDivider()

local PlusKillPlayerToggle = FunAttach:AddCheckbox("PlusKillPlayerToggle", {
        Text = "+ Kill player",
        Default = false,
})
if PlusKillPlayerToggle.TextLabel then
        PlusKillPlayerToggle.TextLabel.TextColor3 = Color3.fromRGB(255, 0, 0)
end

FunAttach:AddCheckbox("HideBeneathToggle", {
        Text = "Hide Beneath",
        Default = false,
})

FunAttach:AddCheckbox("FloatOverToggle", {
        Text = "Float Over",
        Default = false,
})

local TeleportGroup = Tabs.Main:AddRightGroupbox("TELEPORT", "map-pin")

TeleportGroup:AddDropdown("TeleportPlayerList", {
	Text = "Select Player",
	Values = {},
	Default = "",
})

TeleportGroup:AddButton({
	Text = "Teleport",
	Func = function()
		local player = game.Players.LocalPlayer
		local savedName = Options.TeleportPlayerList.Value

		local function notify(title, content, duration)
			if Fluent and Fluent.Notify then
				Fluent:Notify({ Title = title, Content = content, Duration = duration })
			elseif Library and Library.Notify then
				Library:Notify({ Title = title, Description = content, Time = duration })
			end
		end

		if savedName == "" or not savedName then
			notify("Tp Error", "Write a player name.", 5)
			return
		end

		local matchedPlayers = {}

		for _, targetPlayer in ipairs(game.Players:GetPlayers()) do
			if targetPlayer ~= player and (targetPlayer.Name:lower():sub(1, #savedName) == savedName:lower() or targetPlayer.DisplayName:lower():sub(1, #savedName) == savedName:lower()) then
				table.insert(matchedPlayers, targetPlayer)
			end
		end

		if #matchedPlayers == 0 then
			notify("Tp Error", "This player cant found on the server.", 5)
			return
		elseif #matchedPlayers > 1 then
			notify("Tp Error", "There is multiple players with the same name.", 5)
			return
		end

		local targetCharacter = matchedPlayers[1].Character

		if not targetCharacter or not targetCharacter:FindFirstChild("Humanoid") or targetCharacter:FindFirstChild("Humanoid").Health <= 0 then
			notify("Tp Error", "This player is not alive.", 5)
			return
		end

		if targetCharacter:FindFirstChild("HumanoidRootPart") and player.Character and player.Character:FindFirstChild("HumanoidRootPart") then
			player.Character.HumanoidRootPart.CFrame = targetCharacter.HumanoidRootPart.CFrame + Vector3.new(0, 3, 0)
		end
	end,
})

local SpectateGroup = Tabs.Main:AddRightGroupbox("SPECTATE", "scan-eye")

SpectateGroup:AddToggle("SpectateToggle", {
	Text = "Spectate",
	Default = false,
})

SpectateGroup:AddDropdown("SpectatePlayerList", {
	Text = "Select Player",
	Values = {},
	Default = "",
})

local FunLeft = Tabs.Main:AddRightGroupbox("FLING A BULLY", "swords")

FunLeft:AddCheckbox("TouchFling", {
	Text = "Touch Fling",
	Default = false,
})

FunLeft:AddSlider("TouchFlingPower", {
	Text = "Fling Power",
	Default = 5000,
	Min = 500,
	Max = 5000,
	Rounding = 0,
	Compact = true,
})

FunLeft:AddCheckbox("HelicopterTroll", {
	Text = "Fling Your Victim",
	Default = false,
})

FunLeft:AddDropdown("HelicopterPlayerList", {
	Text = "Select Target",
	Values = {},
	Default = "",
})

updateTouchFlingVisibility = function()
	local isFling = (Toggles.TouchFling and Toggles.TouchFling.Value) or false

	if Options.TouchFlingPower then
		Options.TouchFlingPower.Visible = isFling
		if Options.TouchFlingPower.Holder then
			Options.TouchFlingPower.Holder.Visible = isFling
		end
	end

	if Options.HelicopterPlayerList then
		Options.HelicopterPlayerList.Visible = true
		if Options.HelicopterPlayerList.Holder then
			Options.HelicopterPlayerList.Holder.Visible = true
		end
	end

	FunLeft:Resize()
end
updateHelicopterVisibility = updateTouchFlingVisibility

updateTouchFlingVisibility()
task.spawn(function()
	task.wait(0.05)
	if updateTouchFlingVisibility then
		updateTouchFlingVisibility()
	end
end)

MainLeft:AddCheckbox("InfiniteBackpack", {
	Text = "Infinite Backpack",
	Default = false,
})

MainLeft:AddCheckbox("InfiniteStamina", {
	Text = "Infinite Stamina",
	Default = false,
})

MainLeft:AddCheckbox("InfiniteJump", {
	Text = "Infinite Jump",
	Default = false,
})


MainLeft:AddCheckbox("WalkOnWater", {
	Text = "Walk On Water",
	Default = false,
})

MainLeft:AddCheckbox("FastPickup", {
	Text = "Auto Pickup",
	Default = false,
})

MainLeft:AddCheckbox("VacuumPickup", {
	Text = "Vacuum (Far Reach)",
	Default = false,
})

MainLeft:AddSlider("AutoPickupRange", {
	Text = "Pickup Range",
	Default = 20,
	Min = 5,
	Max = 600,
	Rounding = 1,
	Compact = true,
})

MainLeft:AddCheckbox("Noclip", {
	Text = "Noclip",
	Default = false,
})

updateAutoPickupVisibility = function()
	local isPickup = (Toggles.FastPickup and Toggles.FastPickup.Value) or false
	if Options.AutoPickupRange then
		Options.AutoPickupRange.Visible = isPickup
		if Options.AutoPickupRange.Holder then
			Options.AutoPickupRange.Holder.Visible = isPickup
		end
	end
	if Toggles.VacuumPickup then
		Toggles.VacuumPickup.Visible = isPickup
		if Toggles.VacuumPickup.Holder then
			Toggles.VacuumPickup.Holder.Visible = isPickup
		end
	end
	if MainLeft.Resize then
		pcall(function() MainLeft:Resize() end)
	end
	if PlayerTabBox and PlayerTabBox.Resize then
		pcall(function() PlayerTabBox:Resize() end)
	end
end

updateAutoPickupVisibility()
task.spawn(function()
	task.wait(0.05)
	if updateAutoPickupVisibility then
		updateAutoPickupVisibility()
	end
end)

ImmuneTab:AddCheckbox("NoBossDamage", {
	Text = "No Boss damage",
	Default = false,
})

ImmuneTab:AddCheckbox("NoFallDamage", {
	Text = "No Fall Damage",
	Default = false,
})

ImmuneTab:AddCheckbox("NoBearTrapDMG", {
	Text = "No Bear Trap DMG",
	Default = false,
})

ImmuneTab:AddCheckbox("AntiLava", {
	Text = "Anti Fire / Lava",
	Default = false,
})

ImmuneTab:AddCheckbox("AutoAirBubbles", {
	Text = "Auto Air Bubbles",
	Default = false,
})

ImmuneTab:AddCheckbox("AntiAFK", {
	Text = "Anti-AFK",
	Default = false,
})


MainRight:AddButton({
	Text = "Low Ping Server",
	Func = function()
		task.spawn(function()
			local HttpService = game:GetService("HttpService")
			local TeleportService = game:GetService("TeleportService")
			local PlaceId = game.PlaceId
			local JobId = game.JobId

			local url = "https://games.roblox.com/v1/games/" .. PlaceId .. "/servers/Public?limit=100"
			local success, result = pcall(function()
				return game:HttpGet(url)
			end)

			if not success or not result then
				Library:Notify({ Title = "Low Ping Server", Description = "Failed to fetch server list.", Time = 3 })
				return
			end

			local dataSuccess, decoded = pcall(function()
				return HttpService:JSONDecode(result)
			end)

			if not dataSuccess or not decoded or not decoded.data then
				Library:Notify({ Title = "Low Ping Server", Description = "Failed to parse server list.", Time = 3 })
				return
			end

			local servers = {}
			for _, server in ipairs(decoded.data) do
				if typeof(server) == "table" and server.id and server.id ~= JobId and server.playing and server.maxPlayers then
					if server.playing < server.maxPlayers and server.playing > 0 then
						table.insert(servers, server)
					end
				end
			end

			if #servers == 0 then
				Library:Notify({ Title = "Low Ping Server", Description = "No alternative servers found.", Time = 3 })
				return
			end

			table.sort(servers, function(a, b)
				return a.playing < b.playing
			end)

			local bestServer = servers[1]
			Library:Notify({ Title = "Low Ping Server", Description = "Teleporting to smallest server (" .. tostring(bestServer.playing) .. "/" .. tostring(bestServer.maxPlayers) .. " players)...", Time = 3 })

			task.wait(0.5)
			pcall(function()
				TeleportService:TeleportToPlaceInstance(PlaceId, bestServer.id, LocalPlayer)
			end)
		end)
	end,
})

MainRight:AddButton({
	Text = "Ping Spoofer",
	Func = function()
		if getgenv().PingSpoofer then
			getgenv().PingSpoofer.SpoofPing = true
			Library:Notify({ Title = "Ping Spoofer", Description = "Ping spoofing activated!", Time = 2 })
			return
		end

		getgenv().PingSpoofer = {
			SpoofPing = true,
			StartOfPingSpoofer = 31,
			EndOfPingSpoofer = 69
		}

		local Memory
		pcall(function()
			for __, v in pairs(game.CoreGui.RobloxGui.PerformanceStats:GetChildren()) do
				if v.Name == 'PS_Button' and v.StatsMiniTextPanelClass.TitleLabel.Text == 'Ping' then
					Memory = v.StatsMiniTextPanelClass.ValueLabel
				end
			end
		end)

		if Memory then
			Memory:GetPropertyChangedSignal('Text'):Connect(function()
				if getgenv().PingSpoofer and getgenv().PingSpoofer.SpoofPing then
					local Random = math.random(getgenv().PingSpoofer.StartOfPingSpoofer, getgenv().PingSpoofer.EndOfPingSpoofer)
					Random = Random * 1.23
					Memory.Text = Random .. ' ms'
				end
			end)
		end

		Library:Notify({ Title = "Ping Spoofer", Description = "Ping spoofing activated!", Time = 2 })
	end,
})

MainRight:AddButton({
	Text = "Rejoin Server",
	Func = function()
		game:GetService("TeleportService"):TeleportToPlaceInstance(game.PlaceId, game.JobId, LocalPlayer)
	end,
})

MainRight:AddButton({
	Text = "Switch Server",
	Func = function()
		task.spawn(joinLowPingServer)
	end,
})


-- Infinite stamina, no fall damage, anti lava (Behavior > Disabled on workspace.Characters.[name] or Character itself)
local function applyCharacterModuleToggles()
	if Toggles.InfiniteStamina.Value then
		setBehaviorDisabled(getCharacterBehavior("stamina"), true)
	end
	if Toggles.NoFallDamage.Value then
		setBehaviorDisabled(getCharacterBehavior("fallDamage"), true)
	end
	if Toggles.AntiLava.Value then
		local char = getCharacter()
		if char then
			setBehaviorDisabled(char:FindFirstChild("worldHazards"), true)
		end
	end
	if Toggles.InfiniteBackpack and Toggles.InfiniteBackpack.Value then
		local hum = getHumanoid()
		if hum and hum.WalkSpeed < 16 then
			hum.WalkSpeed = 16
		end
		local charFolder = getCharacterFolder()
		if charFolder then
			for _, name in ipairs({"weight", "overweight", "backpack", "slowdown", "speedModifier"}) do
				local b = charFolder:FindFirstChild(name)
				if b then
					setBehaviorDisabled(b, true)
				end
			end
		end
	end
end

Toggles.InfiniteBackpack:OnChanged(function()
	disconnect("InfiniteBackpack")
	disconnect("InfiniteBackpack_WS")
	disconnect("InfiniteBackpack_CharAdded")
	if Toggles.InfiniteBackpack.Value then
		local function enforceBackpackSpeed()
			if not isAlive() then return end
			local humanoid = getHumanoid()
			if humanoid and humanoid.WalkSpeed < 16 then
				humanoid.WalkSpeed = 16
			end
			local charFolder = getCharacterFolder()
			if charFolder then
				for _, name in ipairs({"weight", "overweight", "backpack", "slowdown", "speedModifier"}) do
					local b = charFolder:FindFirstChild(name)
					if b then
						setBehaviorDisabled(b, true)
					end
				end
			end
		end

		track("InfiniteBackpack", RunService.Heartbeat:Connect(enforceBackpackSpeed))

		local function setupHumanoid(char)
			if not char then return end
			local hum = char:WaitForChild("Humanoid", 10)
			if hum then
				disconnect("InfiniteBackpack_WS")
				track("InfiniteBackpack_WS", hum:GetPropertyChangedSignal("WalkSpeed"):Connect(function()
					if Toggles.InfiniteBackpack and Toggles.InfiniteBackpack.Value and hum.WalkSpeed < 16 then
						hum.WalkSpeed = 16
					end
				end))
			end
		end

		if LocalPlayer.Character then
			setupHumanoid(LocalPlayer.Character)
		end
		track("InfiniteBackpack_CharAdded", LocalPlayer.CharacterAdded:Connect(setupHumanoid))

		Library:Notify({ Title = "Infinite Backpack", Description = "Enabled (No Weight Slowdown)", Time = 2 })
	else
		Library:Notify({ Title = "Infinite Backpack", Description = "Disabled", Time = 2 })
	end
end)



Toggles.InfiniteStamina:OnChanged(function()
	disconnect("InfiniteStamina")
	if Toggles.InfiniteStamina.Value then
		applyCharacterModuleToggles()
		track("InfiniteStamina", RunService.Heartbeat:Connect(applyCharacterModuleToggles))
		Library:Notify({ Title = "Infinite Stamina", Description = "Enabled", Time = 2 })
	else
		setBehaviorDisabled(getCharacterBehavior("stamina"), false)
	end
end)

Toggles.InfiniteJump:OnChanged(function()
	disconnect("InfiniteJump")
	if Toggles.InfiniteJump.Value then
		track("InfiniteJump", game:GetService("UserInputService").JumpRequest:Connect(function()
			pcall(function()
				game:GetService("Players").LocalPlayer.Character:FindFirstChildOfClass("Humanoid"):ChangeState("Jumping")
			end)
		end))
		Library:Notify({ Title = "Infinite Jump", Description = "Enabled", Time = 2 })
	end
end)

Toggles.NoFallDamage:OnChanged(function()
	disconnect("NoFallDamage")
	if Toggles.NoFallDamage.Value then
		applyCharacterModuleToggles()
		track("NoFallDamage", RunService.Heartbeat:Connect(applyCharacterModuleToggles))
		Library:Notify({ Title = "No Fall Damage", Description = "Enabled", Time = 2 })
	else
		setBehaviorDisabled(getCharacterBehavior("fallDamage"), false)
	end
end)


Toggles.NoBearTrapDMG:OnChanged(function()
	if Toggles.NoBearTrapDMG.Value then
		Library:Notify({ Title = "No Bear Trap DMG", Description = "Enabled", Time = 2 })
	else
		Library:Notify({ Title = "No Bear Trap DMG", Description = "Disabled", Time = 2 })
	end
end)

Toggles.AntiLava:OnChanged(function()
	disconnect("AntiLava")
	if Toggles.AntiLava.Value then
		applyCharacterModuleToggles()
		track("AntiLava", RunService.Heartbeat:Connect(applyCharacterModuleToggles))
		Library:Notify({ Title = "Anti Fire / Lava", Description = "Enabled", Time = 2 })
	else
		local char = getCharacter()
		if char then
			setBehaviorDisabled(char:FindFirstChild("worldHazards"), false)
		end
	end
end)

Toggles.AutoAirBubbles:OnChanged(function()
	disconnect("AutoAirBubbles")
	if Toggles.AutoAirBubbles.Value then
		local lastUpdate = 0
		track("AutoAirBubbles", RunService.Heartbeat:Connect(function()
			local now = os.clock()
			if now - lastUpdate < (1 / 20) then return end
			lastUpdate = now

			local character = getCharacter()
			local head = character and character:FindFirstChild("Head")
			local airBubbles = workspace:FindFirstChild("AirBubbles")
			if head and airBubbles then
				local humanoid = getHumanoid()
				local isSwimming = humanoid and (humanoid:GetState() == Enum.HumanoidStateType.Swimming)
				if isSwimming or character:GetAttribute("inWater") or head.Position.Y < 5 then
					for _, bubble in ipairs(airBubbles:GetChildren()) do
						if bubble:IsA("BasePart") then
							bubble.Position = head.Position + Vector3.new(0, 0.5, 0)
						end
					end
				end
			end
		end))
		Library:Notify({ Title = "Auto Air Bubbles", Description = "Enabled", Time = 2 })
	end
end)

-- Switch Server (Low Ping Hop)
joinLowPingServer = function()
	local HttpService = game:GetService("HttpService")
	local TeleportService = game:GetService("TeleportService")
	local PlaceId = game.PlaceId
	local JobId = game.JobId

	local url = "https://games.roblox.com/v1/games/" .. PlaceId .. "/servers/Public?limit=100"
	local success, result = pcall(function()
		return game:HttpGet(url)
	end)

	if not success or not result then
		Library:Notify({ Title = "Switch Server", Description = "Failed to fetch server list.", Time = 3 })
		return
	end

	local dataSuccess, decoded = pcall(function()
		return HttpService:JSONDecode(result)
	end)

	if not dataSuccess or not decoded or not decoded.data then
		Library:Notify({ Title = "Switch Server", Description = "Failed to parse server list.", Time = 3 })
		return
	end

	local servers = {}
	for _, server in ipairs(decoded.data) do
		if typeof(server) == "table" and server.id and server.id ~= JobId and server.playing and server.maxPlayers then
			if server.playing < server.maxPlayers and server.playing > 0 then
				table.insert(servers, server)
			end
		end
	end

	if #servers == 0 then
		Library:Notify({ Title = "Switch Server", Description = "No alternative servers found.", Time = 3 })
		return
	end

	table.sort(servers, function(a, b)
		return (a.ping or 999) < (b.ping or 999)
	end)

	local bestServer = servers[1]
	Library:Notify({ Title = "Switch Server", Description = "Teleporting to server (" .. tostring(bestServer.playing) .. "/" .. tostring(bestServer.maxPlayers) .. ") with " .. tostring(bestServer.ping) .. "ms ping...", Time = 3 })

	task.wait(0.5)
	pcall(function()
		TeleportService:TeleportToPlaceInstance(PlaceId, bestServer.id, LocalPlayer)
	end)
end

track("CharacterModuleRespawn", LocalPlayer.CharacterAdded:Connect(function()
	task.wait(0.5)
	applyCharacterModuleToggles()
	if shouldTeleportBack and lastDeathPosition then
		shouldTeleportBack = false
		local root = getRootPart()
		if root then
			root.CFrame = CFrame.new(lastDeathPosition + Vector3.new(0, 3, 0))
			Library:Notify({ Title = "Reset & Teleport", Description = "Teleported back to last location!", Time = 2 })
		end
	end
end))

-- No Boss Damage Hook Setup
local BossDamageEvent = resolvePath(ReplicatedStorage, "remoteInterface", "character", "hurtByAIAttack")
local originalNamecall
if BossDamageEvent then
	originalNamecall = hookmetamethod(game, "__namecall", function(...)
		local self = ...
		local method = getnamecallmethod()

		if rawequal(self, BossDamageEvent) and method == "FireServer" then
			if Toggles.NoBossDamage and Toggles.NoBossDamage.Value then
				return -- Block the attack to prevent damage
			end
		end

		return originalNamecall(...)
	end)
end

local function noBossDamageToggle(state)
	if state then
		Library:Notify({ Title = "No Boss Damage", Description = "Enabled", Time = 2 })
	else
		Library:Notify({ Title = "No Boss Damage", Description = "Disabled", Time = 2 })
	end
end

Toggles.NoBossDamage:OnChanged(noBossDamageToggle)

 -- Auto pickup (CollectionService tag DROPPED_ITEM -> inventory.pickupItem)
local droppedItemSpawnTimes = {}
local lastAutoPickup = 0
local AUTO_PICKUP_RANGE = 20
local AUTO_PICKUP_COOLDOWN = 0

local function canAutoPickup(item, isVacuum)
	if not item:IsA("BasePart") or not item:GetAttribute("itemId") then
		return false
	end
	if not isVacuum then
		local owner = item:GetAttribute("owner")
		if owner and owner ~= LocalPlayer.UserId then
			return false
		end
	end
	local from = item:GetAttribute("from")
	local spawnTime = droppedItemSpawnTimes[item] or 0
	if from == LocalPlayer.UserId and time() - spawnTime < 0.5 then
		return false
	end
	return true
end

local function trackDroppedItem(item)
	if not item:IsA("BasePart") then
		return
	end
	droppedItemSpawnTimes[item] = time()
	item.Destroying:Once(function()
		droppedItemSpawnTimes[item] = nil
	end)

	-- Instant vacuum pickup if in range
	if Toggles and Toggles.FastPickup and Toggles.FastPickup.Value and isAlive() and TSG.PickupRemote then
		local root = getRootPart()
		if root then
			local isVacuum = (Toggles.VacuumPickup and Toggles.VacuumPickup.Value) or false
			local maxRange = (Options and Options.AutoPickupRange and Options.AutoPickupRange.Value) or AUTO_PICKUP_RANGE
			if isVacuum and maxRange < 100 then
				maxRange = 100
			end
			task.defer(function()
				if item and item.Parent and canAutoPickup(item, isVacuum) then
					local dist = (item.Position - root.Position).Magnitude
					if dist <= maxRange then
						if isVacuum then
							pcall(function() item.CFrame = root.CFrame end)
						end
						pcall(TSG.PickupRemote.FireServer, TSG.PickupRemote, item)
					end
				end
			end)
		end
	end
end

CollectionService:GetInstanceAddedSignal("DROPPED_ITEM"):Connect(trackDroppedItem)
for _, item in ipairs(CollectionService:GetTagged("DROPPED_ITEM")) do
	trackDroppedItem(item)
end

local function tryAutoPickup()
	if time() - lastAutoPickup < 0.35 then
		return
	end
	if not isAlive() or not TSG.PickupRemote then
		return
	end
	local root = getRootPart()
	if not root then
		return
	end

	local isVacuum = (Toggles.VacuumPickup and Toggles.VacuumPickup.Value) or false
	local maxRange = (Options.AutoPickupRange and Options.AutoPickupRange.Value) or AUTO_PICKUP_RANGE
	if isVacuum and maxRange < 100 then
		maxRange = 100
	end

	local rootPos = root.Position
	local candidateItems = {}

	for _, item in ipairs(CollectionService:GetTagged("DROPPED_ITEM")) do
		if item and item.Parent and canAutoPickup(item, isVacuum) then
			local dist = (item.Position - rootPos).Magnitude
			if dist <= maxRange then
				table.insert(candidateItems, { item = item, dist = dist })
			end
		end
	end

	if #candidateItems == 0 then
		lastAutoPickup = time()
		return
	end

	if #candidateItems > 1 then
		table.sort(candidateItems, function(a, b)
			return a.dist < b.dist
		end)
	end

	local pickedCount = 0
	local maxBatch = isVacuum and 25 or 8
	for _, entry in ipairs(candidateItems) do
		local item = entry.item
		if item and item.Parent then
			pickedCount += 1
			if isVacuum then
				pcall(function()
					item.CFrame = root.CFrame
				end)
			end
			pcall(TSG.PickupRemote.FireServer, TSG.PickupRemote, item)
			if pickedCount >= maxBatch then
				break
			end
		end
	end

	lastAutoPickup = time()
end

Toggles.FastPickup:OnChanged(function()
	disconnect("FastPickup")
	if updateAutoPickupVisibility then
		updateAutoPickupVisibility()
	end
	if Toggles.FastPickup.Value then
		if not TSG.PickupRemote then
			Library:Notify({ Title = "Auto Pickup", Description = "Pickup remote not found.", Time = 4 })
			Toggles.FastPickup:SetValue(false)
			return
		end
		track("FastPickup", RunService.Heartbeat:Connect(tryAutoPickup))
		Library:Notify({ Title = "Auto Pickup", Description = "Enabled", Time = 2 })
	else
		Library:Notify({ Title = "Auto Pickup", Description = "Disabled", Time = 2 })
	end
end)

local FoodIdMap = {
	["Cabbage"] = 210,
	["Banana"] = 367,
	["Spicy Meal"] = 214,
	["Hearty Stew"] = 217,
	["Cabbage Meal"] = 213,
}

local lastEatCustom = 0
local function tryEatCustom()
	local cooldown = Options and Options.AutoEatCooldown and Options.AutoEatCooldown.Value or 0.3
	if tick() - lastEatCustom < cooldown then
		return
	end
	local humanoid = getHumanoid()
	local threshold = Options and Options.AutoEatThreshold and Options.AutoEatThreshold.Value or 100
	if humanoid and humanoid.Health < threshold then
		local selectedFood = Options and Options.AutoEatFood and Options.AutoEatFood.Value
		local foodId = FoodIdMap[selectedFood] or 210
		lastEatCustom = tick()
		pcall(function()
			local args = {
				foodId
			}
			game:GetService("ReplicatedStorage"):WaitForChild("remoteInterface"):WaitForChild("interactions"):WaitForChild("eat"):FireServer(unpack(args))
		end)
	end
end

Toggles.AutoEatCustom:OnChanged(function()
	disconnect("AutoEatCustom")
	if Toggles.AutoEatCustom.Value then
		track("AutoEatCustom", RunService.Heartbeat:Connect(tryEatCustom))
		Library:Notify({ Title = "Auto Eat", Description = "Enabled", Time = 2 })
	end
end)

-- ==========================================
-- COMBAT
-- ==========================================
local CombatLeft = Tabs.Combat:AddLeftGroupbox("Kill Aura", "swords")

local AimbotTabBox = Tabs.Combat:AddRightTabbox()
local CombatAimbot = AimbotTabBox:AddTab("AIMBOT", "crosshair")
local CombatCamlock = AimbotTabBox:AddTab("Camlock", "video")

CombatAimbot:AddToggle("AimbotLockOn", {
	Text = "Lock On",
	Default = false,
}):AddColorPicker("AimbotFOVCircleColor", {
	Default = Color3.fromRGB(255, 0, 0),
	Title = "FOV Circle Color",
})

CombatAimbot:AddSlider("AimbotFOV", {
	Text = "FOV Slider",
	Default = 100,
	Min = 10,
	Max = 600,
	Rounding = 0,
	Compact = true,
})

CombatCamlock:AddToggle("Camlock", {
	Text = "Camlock",
	Default = false,
})

CombatCamlock:AddCheckbox("Outline", {
	Text = "Outline",
	Default = false,
})

CombatCamlock:AddCheckbox("CamlockIgnoreTeam", {
	Text = "Ignore Team",
	Default = true,
})

CombatCamlock:AddCheckbox("SpearSword", {
	Text = "Spear/Sword(Slot 3/5)",
	Default = false,
})

CombatCamlock:AddDropdown("CamlockTarget", {
	Text = "Target Player",
	Values = {"All"},
	Default = "All",
})

CombatCamlock:AddSlider("CamlockStuds", {
	Text = "Camlock Studs",
	Default = 20,
	Min = 1,
	Max = 100,
	Rounding = 0,
	Compact = true,
})

CombatCamlock:AddDropdown("OutlineTarget", {
	Text = "Outline Target",
	Values = {"All"},
	Default = "All",
})

CombatCamlock:AddSlider("OutlineStuds", {
	Text = "Outline Studs",
	Default = 7,
	Min = 1,
	Max = 50,
	Rounding = 0,
	Compact = true,
})

CombatLeft:AddToggle("KillAura", {
	Text = "Kill Aura",
	Default = false,
})

CombatLeft:AddCheckbox("PhantomMode", {
	Text = "Rage Mode",
	Default = false,
})

CombatLeft:AddSlider("OrbitAdjust", {
	Text = "Orbit Adjust",
	Default = 2,
	Min = -10,
	Max = 15,
	Rounding = 1,
	Compact = true,
})

CombatLeft:AddSlider("OrbitSpeed", {
	Text = "Orbit Speed",
	Default = 60,
	Min = 1,
	Max = 60,
	Rounding = 0,
	Compact = true,
})

CombatLeft:AddDropdown("KillAuraTarget", {
	Text = "Target Player",
	Values = {"All"},
	Default = "All",
})

CombatLeft:AddDropdown("KillAuraSlot", {
	Text = "Tool Slot",
	Values = {"1","2","3","4","5","6","7","8","9","10"},
	Default = "1",
})

CombatLeft:AddSlider("KillAuraRange", {
	Text = "Range",
	Default = 15,
	Min = 5,
	Max = 30,
	Rounding = 1,
	Compact = true,
})

CombatLeft:AddSlider("KillAuraAngle", {
	Text = "Max Angle",
	Default = 90,
	Min = 15,
	Max = 180,
	Rounding = 0,
	Compact = true,
})

CombatLeft:AddCheckbox("HighlightTarget", {
	Text = "Highlight Target",
	Default = true,
}):AddColorPicker("HighlightTargetColor", {
	Default = Color3.fromRGB(255, 60, 60),
	Title = "Highlight Target Color",
})

updatePhantomModeVisibility = function()
	local isPhantom = (Toggles.PhantomMode and Toggles.PhantomMode.Value) or false

	if Options.OrbitAdjust then
		if Options.OrbitAdjust.Visible ~= nil then
			Options.OrbitAdjust.Visible = isPhantom
		end
		if Options.OrbitAdjust.Holder then
			Options.OrbitAdjust.Holder.Visible = isPhantom
		end
	end
	if Options.OrbitSpeed then
		if Options.OrbitSpeed.Visible ~= nil then
			Options.OrbitSpeed.Visible = isPhantom
		end
		if Options.OrbitSpeed.Holder then
			Options.OrbitSpeed.Holder.Visible = isPhantom
		end
	end
	CombatLeft:Resize()
end

updatePhantomModeVisibility()
task.spawn(function()
	task.wait(0.05)
	if updatePhantomModeVisibility then
		updatePhantomModeVisibility()
	end
end)

local CombatAutoSwingGroup = Tabs.Combat:AddLeftGroupbox("Auto Swing", "swords")

CombatAutoSwingGroup:AddToggle("AutoSwing", {
	Text = "Auto Swing",
	Default = false,
})

CombatAutoSwingGroup:AddCheckbox("SmartSwing", {
	Text = "+ Smart Swing",
	Default = false,
})

CombatAutoSwingGroup:AddDropdown("AutoSwingSlot", {
	Text = "Tool Slot",
	Values = { "Normal", "1", "2", "3", "4", "5", "6", "7", "8", "9", "10" },
	Default = { "Normal" },
	Multi = true,
})

CombatAutoSwingGroup:AddSlider("AutoSwingSpeed", {
	Text = "Auto Swing Speed",
	Default = 10,
	Min = 0.5,
	Max = 10,
	Rounding = 1,
	Compact = true,
})

CombatAutoSwingGroup:AddSlider("PlayerStuds", {
	Text = "Player Studs",
	Default = 20,
	Min = 1,
	Max = 100,
	Rounding = 0,
	Compact = true,
})

CombatAutoSwingGroup:AddToggle("SmartSwingIgnoreTeam", {
	Text = "Ignore Team",
	Default = true,
})

updateAutoSwingSliderVisibility = function()
	local isAutoSwingToggled = (Toggles.AutoSwing and Toggles.AutoSwing.Value) or false
	local isSmartSwingToggled = (Toggles.SmartSwing and Toggles.SmartSwing.Value) or false
	local isAnyToggled = isAutoSwingToggled or isSmartSwingToggled

	if Options.AutoSwingSlot then
		Options.AutoSwingSlot.Visible = isAutoSwingToggled
		if Options.AutoSwingSlot.Holder then
			Options.AutoSwingSlot.Holder.Visible = isAutoSwingToggled
		end
	end
	if Options.AutoSwingSpeed then
		Options.AutoSwingSpeed.Visible = isAnyToggled
		if Options.AutoSwingSpeed.Holder then
			Options.AutoSwingSpeed.Holder.Visible = isAnyToggled
		end
	end
	if Options.PlayerStuds then
		Options.PlayerStuds.Visible = isSmartSwingToggled
		if Options.PlayerStuds.Holder then
			Options.PlayerStuds.Holder.Visible = isSmartSwingToggled
		end
	end
	if Toggles.SmartSwingIgnoreTeam then
		if Toggles.SmartSwingIgnoreTeam.Visible ~= nil then
			Toggles.SmartSwingIgnoreTeam.Visible = isSmartSwingToggled
		end
		if Toggles.SmartSwingIgnoreTeam.Holder then
			Toggles.SmartSwingIgnoreTeam.Holder.Visible = isSmartSwingToggled
		end
	end
	CombatAutoSwingGroup:Resize()
end

updateAutoSwingSliderVisibility()
task.spawn(function()
	task.wait(0.05)
	if updateAutoSwingSliderVisibility then
		updateAutoSwingSliderVisibility()
	end
end)

local CombatSwordBot = Tabs.Combat:AddLeftGroupbox("Sword Bot", "swords")

CombatSwordBot:AddToggle("SwordBot", {
	Text = "Sword Hunter",
	Default = false,
})

CombatSwordBot:AddDropdown("ChooseVictim", {
	Text = "Choose a Victim",
	Values = {},
	Default = "",
})

local CombatAutoPVP = Tabs.Combat:AddRightGroupbox("PVP Modules", "swords")

CombatAutoPVP:AddCheckbox("AutoShiftlock", {
	Text = "+ Shiftlock",
	Default = false,
})

CombatAutoPVP:AddCheckbox("SwingSpeedToggle", {
	Text = "+ Swing Speed",
	Default = false,
})

CombatAutoPVP:AddSlider("SwingSpeedVal", {
	Text = "Swing Speed Value",
	Default = 1,
	Min = 1,
	Max = 15,
	Rounding = 1,
	Compact = true,
})

CombatAutoPVP:AddCheckbox("AutoHop", {
	Text = "+ Auto Hop",
	Default = false,
})

CombatAutoPVP:AddCheckbox("AutoHopIgnoreTeam", {
	Text = "Ignore Team",
	Default = true,
})

CombatAutoPVP:AddSlider("AutoHopStuds", {
	Text = "Auto Hop Studs",
	Default = 20,
	Min = 1,
	Max = 100,
	Rounding = 0,
	Compact = true,
})

CombatAutoPVP:AddCheckbox("PlusSpeedBoost", {
	Text = "+ Speed Boost",
	Default = false,
})

CombatAutoPVP:AddDropdown("SpeedBoostSlot", {
	Text = "Tool Slot",
	Values = {"1", "2", "3", "4", "5", "6", "7", "8", "9", "10"},
	Default = {"1"},
	Multi = true,
})

CombatAutoPVP:AddSlider("SpeedBoostValue", {
	Text = "Speed Boost Value",
	Default = 16,
	Min = 16,
	Max = 30,
	Rounding = 1,
	Compact = true,
})



CombatAutoPVP:AddCheckbox("LookDownFloor", {
	Text = "+ Look at Floor",
	Default = false,
})

CombatAutoPVP:AddDropdown("LookDownSlot", {
	Text = "Tool Slot",
	Values = {"1", "2", "3", "4", "5", "6", "7", "8", "9", "10"},
	Default = {"1"},
	Multi = true,
})

CombatAutoPVP:AddSlider("LookDownZoom", {
	Text = "Floor Zoom Distance",
	Default = 20,
	Min = 5,
	Max = 60,
	Rounding = 0,
	Compact = true,
})

CombatAutoPVP:AddSlider("LookDownSens", {
	Text = "Floor Turn Sensitivity",
	Default = 12,
	Min = 1,
	Max = 30,
	Rounding = 0,
	Compact = true,
})

updatePVPModulesVisibility = function()
	local isHop = (Toggles.AutoHop and Toggles.AutoHop.Value) or false
	local isCam = (Toggles.Camlock and Toggles.Camlock.Value) or false
	local isSpeedBoost = (Toggles.PlusSpeedBoost and Toggles.PlusSpeedBoost.Value) or false
	local isAnySpeedBoost = isSpeedBoost
	local isSwingSpeed = (Toggles.SwingSpeedToggle and Toggles.SwingSpeedToggle.Value) or false

	local isOutline = isCam and ((Toggles.Outline and Toggles.Outline.Value) or (Toggles.Cutline and Toggles.Cutline.Value) or false)

	if Options.SwingSpeedVal then
		Options.SwingSpeedVal.Visible = isSwingSpeed
		if Options.SwingSpeedVal.Holder then
			Options.SwingSpeedVal.Holder.Visible = isSwingSpeed
		end
	end

	if Options.AutoHopStuds then
		Options.AutoHopStuds.Visible = isHop
		if Options.AutoHopStuds.Holder then
			Options.AutoHopStuds.Holder.Visible = isHop
		end
	end
	if Toggles.AutoHopIgnoreTeam then
		if Toggles.AutoHopIgnoreTeam.Visible ~= nil then
			Toggles.AutoHopIgnoreTeam.Visible = isHop
		end
		if Toggles.AutoHopIgnoreTeam.Holder then
			Toggles.AutoHopIgnoreTeam.Holder.Visible = isHop
		end
	end
	if Options.CamlockTarget then
		Options.CamlockTarget.Visible = isCam
		if Options.CamlockTarget.Holder then
			Options.CamlockTarget.Holder.Visible = isCam
		end
	end
	if Options.CamlockStuds then
		Options.CamlockStuds.Visible = isCam
		if Options.CamlockStuds.Holder then
			Options.CamlockStuds.Holder.Visible = isCam
		end
	end
	if Toggles.Outline then
		if Toggles.Outline.Visible ~= nil then
			Toggles.Outline.Visible = isCam
		end
		if Toggles.Outline.Holder then
			Toggles.Outline.Holder.Visible = isCam
		end
	end
	if Toggles.CamlockIgnoreTeam then
		if Toggles.CamlockIgnoreTeam.Visible ~= nil then
			Toggles.CamlockIgnoreTeam.Visible = isCam
		end
		if Toggles.CamlockIgnoreTeam.Holder then
			Toggles.CamlockIgnoreTeam.Holder.Visible = isCam
		end
	end
	if Toggles.SpearSword then
		if Toggles.SpearSword.Visible ~= nil then
			Toggles.SpearSword.Visible = isCam
		end
		if Toggles.SpearSword.Holder then
			Toggles.SpearSword.Holder.Visible = isCam
		end
	end
	local isLookDown = (Toggles.LookDownFloor and Toggles.LookDownFloor.Value) or false
	if Options.LookDownSlot then
		Options.LookDownSlot.Visible = isLookDown
		if Options.LookDownSlot.Holder then
			Options.LookDownSlot.Holder.Visible = isLookDown
		end
	end
	if Options.LookDownZoom then
		Options.LookDownZoom.Visible = isLookDown
		if Options.LookDownZoom.Holder then
			Options.LookDownZoom.Holder.Visible = isLookDown
		end
	end
	if Options.LookDownSens then
		Options.LookDownSens.Visible = isLookDown
		if Options.LookDownSens.Holder then
			Options.LookDownSens.Holder.Visible = isLookDown
		end
	end
	if Options.OutlineTarget then
		Options.OutlineTarget.Visible = isOutline
		if Options.OutlineTarget.Holder then
			Options.OutlineTarget.Holder.Visible = isOutline
		end
	end
	if Options.OutlineStuds then
		Options.OutlineStuds.Visible = isOutline
		if Options.OutlineStuds.Holder then
			Options.OutlineStuds.Holder.Visible = isOutline
		end
	end
	if Options.SpeedBoostSlot then
		Options.SpeedBoostSlot.Visible = isAnySpeedBoost
		if Options.SpeedBoostSlot.Holder then
			Options.SpeedBoostSlot.Holder.Visible = isAnySpeedBoost
		end
	end
	if Options.SpeedBoostValue then
		Options.SpeedBoostValue.Visible = isAnySpeedBoost
		if Options.SpeedBoostValue.Holder then
			Options.SpeedBoostValue.Holder.Visible = isAnySpeedBoost
		end
	end
	CombatAutoPVP:Resize()
	if CombatCamlock and CombatCamlock.Resize then
		pcall(function() CombatCamlock:Resize() end)
	end
	if AimbotTabBox and AimbotTabBox.Resize then
		pcall(function() AimbotTabBox:Resize() end)
	end
end

updatePVPModulesVisibility()
task.spawn(function()
	task.wait(0.05)
	if updatePVPModulesVisibility then
		updatePVPModulesVisibility()
	end
end)

local CombatReach = Tabs.Combat:AddRightGroupbox("Advance Reach", "expand")

CombatReach:AddToggle("Reach", {
	Text = "Reach",
	Default = false,
})

CombatReach:AddDropdown("ReachTarget", {
	Text = "Target Player",
	Values = {"All"},
	Default = "All",
})

CombatReach:AddDropdown("AdvancePreset", {
	Text = "Advance PRESET",
	Values = { "Sword", "Spear" },
	Default = "",
})

CombatReach:AddSlider("ReachRange", {
	Text = "Reach Range",
	Default = 15,
	Min = 1,
	Max = 30,
	Rounding = 1,
	Compact = true,
})

CombatReach:AddSlider("ReachAngle", {
	Text = "Hitbox Angle",
	Default = 35,
	Min = 5,
	Max = 120,
	Rounding = 0,
	Compact = true,
})

local function isSwingAnimation(trackObj)
	local anim = trackObj.Animation
	if not anim then return false end
	local id = anim.AnimationId
	local name = anim.Name:lower()

	if name:find("idle") or name:find("walk") or name:find("run") or name:find("jump") or
	   name:find("fall") or name:find("swim") or name:find("climb") or name:find("strafe") then
		return false
	end

	local movementIds = {
		["507766388"] = true, ["507777826"] = true, ["507767714"] = true,
		["507765000"] = true, ["507767968"] = true, ["507765644"] = true,
		["507784064"] = true, ["180426354"] = true, ["180415668"] = true,
		["180419271"] = true, ["180435571"] = true
	}
	for mId in pairs(movementIds) do
		if id:find(mId) then
			return false
		end
	end

	return true
end

local isShielding = false
local lastShieldFire = 0
local multiSnapIndex = 1
local function updateImmortalMode()
	if not isAlive() or not Toggles.ImmortalMode.Value then
		if isShielding then
			isShielding = false
			pcall(function()
				game:GetService("ReplicatedStorage").remoteInterface.character.setShield:FireServer(false)
			end)
		end
		return
	end

	local root = getRootPart()
	if not root then return end

	local shouldShield = false
	local checkDistance = (Options.ImmortalModeStuds and Options.ImmortalModeStuds.Value) or 18
	local nearestEnemy = nil
	local nearestDist = math.huge
	local activeAttackers = {}

	for _, player in ipairs(Players:GetPlayers()) do
		if player ~= LocalPlayer and player.Character then
			local targetRoot = player.Character:FindFirstChild("HumanoidRootPart")
			local hum = player.Character:FindFirstChildOfClass("Humanoid")
			if targetRoot and hum and hum.Health > 0 then
				local dist = (targetRoot.Position - root.Position).Magnitude
				if dist <= checkDistance then
					shouldShield = true
					if dist < nearestDist then
						nearestDist = dist
						nearestEnemy = targetRoot
					end

					local animator = hum:FindFirstChild("Animator")
					if animator then
						for _, trackObj in ipairs(animator:GetPlayingAnimationTracks()) do
							if trackObj.Speed > 0 and isSwingAnimation(trackObj) then
								table.insert(activeAttackers, { root = targetRoot, dist = dist })
								break
							end
						end
					end
				end
			end
		end
	end

	if shouldShield then
		local targetToFace = nil
		if #activeAttackers > 0 then
			table.sort(activeAttackers, function(a, b) return a.dist < b.dist end)
			if #activeAttackers == 1 then
				targetToFace = activeAttackers[1].root
			else
				multiSnapIndex = (multiSnapIndex % #activeAttackers) + 1
				targetToFace = activeAttackers[multiSnapIndex].root
			end
		else
			targetToFace = nearestEnemy
		end

		if targetToFace then
			local targetPos = targetToFace.Position
			root.CFrame = CFrame.lookAt(root.Position, Vector3.new(targetPos.X, root.Position.Y, targetPos.Z))
		end

		local shieldSpeed = (Options.ImmortalShieldSpeed and Options.ImmortalShieldSpeed.Value) or 0.1
		if tick() - lastShieldFire >= shieldSpeed then
			lastShieldFire = tick()
			pcall(function()
				game:GetService("ReplicatedStorage").remoteInterface.character.setShield:FireServer(true)
			end)
		end
		isShielding = true
	else
		if isShielding then
			isShielding = false
			pcall(function()
				game:GetService("ReplicatedStorage").remoteInterface.character.setShield:FireServer(false)
			end)
		end
	end
end

Toggles.ImmortalMode:OnChanged(function()
	if updateImmortalModeVisibility then
		updateImmortalModeVisibility()
	end
	disconnect("ImmortalMode")
	if Toggles.ImmortalMode.Value then
		track("ImmortalMode", RunService.Heartbeat:Connect(updateImmortalMode))
	else
		if isShielding then
			isShielding = false
			pcall(function()
				game:GetService("ReplicatedStorage").remoteInterface.character.setShield:FireServer(false)
			end)
		end
	end
end)

Toggles.BypassShield:OnChanged(function()
	if Toggles.KillAura then
		Toggles.KillAura:SetValue(Toggles.BypassShield.Value)
	end
end)

local function updateHighlight(hl, target, toggleValue)
	if target and toggleValue then
		hl.Adornee = target
		hl.Enabled = true
	else
		hl.Adornee = nil
		hl.Enabled = false
	end
end

local highlightTarget = Instance.new("Highlight")
highlightTarget.FillColor = (Options.HighlightTargetColor and Options.HighlightTargetColor.Value) or Color3.fromRGB(255, 60, 60)
highlightTarget.OutlineColor = Color3.fromRGB(255, 255, 255)
highlightTarget.FillTransparency = 0.65
highlightTarget.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
highlightTarget.Enabled = false
highlightTarget.Parent = workspace

if Options.HighlightTargetColor then
	Options.HighlightTargetColor:OnChanged(function()
		if highlightTarget then
			highlightTarget.FillColor = Options.HighlightTargetColor.Value
		end
	end)
end

Toggles.HighlightTarget:OnChanged(function()
	if not Toggles.HighlightTarget.Value then
		updateHighlight(highlightTarget, nil, false)
	end
end)

local function getBestMeleeWeapon()
	if not TSG.ClientData or not TSG.Items then
		return nil
	end
	local bestId, bestDamage = nil, 0
	for itemId in pairs(TSG.ClientData.getInventory()) do
		local data = TSG.Items.getItemData(itemId)
		if data and table.find(data.itemType, "Melee Weapon") then
			local dmg = data.meleeDamage or 0
			if dmg > bestDamage then
				bestDamage = dmg
				bestId = itemId
			end
		end
	end
	return bestId
end

local lastKillAuraHit = 0

local function attackNPC(slot, target)
	if not target then return end
	local isServerModel = false
	local aiServer = workspace:FindFirstChild("AI_Server")
	if aiServer and target:IsDescendantOf(aiServer) then
		isServerModel = true
	end

	if isServerModel then
		-- It's already the server model! Fire meleeAI directly with target
		if TSG.MeleeAI then
			pcall(TSG.MeleeAI.FireServer, TSG.MeleeAI, slot, target)
		else
			pcall(TSG.MeleeAnimalRemote.FireServer, TSG.MeleeAnimalRemote, slot, target)
		end
	else
		-- It's a client model (from AI_Client or animals folder)
		if AiController and TSG.MeleeAI then
			local serverModel = AiController:GetServerModelFromClientModel(target)
			if serverModel then
				pcall(TSG.MeleeAI.FireServer, TSG.MeleeAI, slot, serverModel)
			else
				pcall(TSG.MeleeAnimalRemote.FireServer, TSG.MeleeAnimalRemote, slot, target)
			end
		else
			pcall(TSG.MeleeAnimalRemote.FireServer, TSG.MeleeAnimalRemote, slot, target)
		end
	end
end

local function killAuraLoop()
	local delayVal = Options.KillAuraSpeed and Options.KillAuraSpeed.Value or 0.2
	if not isAlive() or tick() - lastKillAuraHit < delayVal then return end
	local root = getRootPart()
	if not root then return end

	local slot = tonumber(Options.KillAuraSlot.Value) or 1
	local range = Options.KillAuraRange.Value
	local pos = root.Position
	local nearestDist = range
	local nearestTarget = nil

	local maxAngle = (Options.KillAuraAngle and Options.KillAuraAngle.Value) or 90
	local coneThreshold = math.cos(math.rad(maxAngle / 2))
	local forward = Vector3.new(root.CFrame.LookVector.X, 0, root.CFrame.LookVector.Z).Unit

	local function passesAngleCheck(targetPos)
		local dir = Vector3.new(targetPos.X - pos.X, 0, targetPos.Z - pos.Z)
		if dir.Magnitude <= 0 then return true end
		return forward:Dot(dir.Unit) >= coneThreshold
	end

	local targetSetting = Options.KillAuraTarget and Options.KillAuraTarget.Value or "All"

	-- Scan Players
	for _, otherPlayer in ipairs(Players:GetPlayers()) do
		if otherPlayer ~= LocalPlayer and otherPlayer.Character then
			local otherHum = otherPlayer.Character:FindFirstChildOfClass("Humanoid")
			local otherRoot = otherPlayer.Character:FindFirstChild("HumanoidRootPart") or otherPlayer.Character.PrimaryPart
			if otherHum and otherHum.Health > 0 and otherRoot then
				if targetSetting == "All" or otherPlayer.Name == targetSetting then
					local d = (otherRoot.Position - pos).Magnitude
					if d < nearestDist and passesAngleCheck(otherRoot.Position) then
						nearestDist = d
						nearestTarget = otherPlayer.Character
					end
				end
			end
		end
	end

	updateHighlight(highlightTarget, nearestTarget, Toggles.HighlightTarget.Value)
	if not nearestTarget then
		return
	end

	lastKillAuraHit = tick()
	local targetPlayer = Players:GetPlayerFromCharacter(nearestTarget)
	if targetPlayer then
		-- Player: use Crypt encryption, fire (slot, encryptedUserId)
		if Crypt then
			pcall(function()
				local k1, k2, k3 = Crypt.checkpublickeys()
				if k1 and k2 and k3 then
					local encryptedUserId = Crypt.crypt(k1, math.abs(targetPlayer.UserId) + k3, k2)
					TSG.MeleePlayerRemote:FireServer(slot, encryptedUserId)
				end
			end)
		else
			pcall(TSG.MeleePlayerRemote.FireServer, TSG.MeleePlayerRemote, slot, targetPlayer)
		end
	else
		attackNPC(slot, nearestTarget)
	end
end

-- Aimbot Script
local fovCircle = nil
pcall(function()
   if typeof(Drawing) ~= "nil" then
		fovCircle = Drawing.new("Circle")
		fovCircle.Thickness = 1.5
		fovCircle.Color = (Options and Options.AimbotFOVCircleColor and Options.AimbotFOVCircleColor.Value) or Color3.fromRGB(255, 0, 0)
		fovCircle.Filled = false
		fovCircle.Transparency = 1
		fovCircle.Visible = false
	end
end)

local function getClosestPlayerToCenter()
	local closestPlayer = nil
	local shortestDistance = math.huge
	local camera = workspace.CurrentCamera
	local viewportSize = camera.ViewportSize
	local center = Vector2.new(viewportSize.X / 2, viewportSize.Y / 2)

	for _, player in ipairs(Players:GetPlayers()) do
		if player ~= LocalPlayer and player.Character then
			local torso = player.Character:FindFirstChild("LowerTorso") or player.Character:FindFirstChild("UpperTorso") or player.Character:FindFirstChild("Torso") or player.Character:FindFirstChild("HumanoidRootPart")
			local humanoid = player.Character:FindFirstChildOfClass("Humanoid")
			if torso and humanoid and humanoid.Health > 0 then
				local screenPos, onScreen = camera:WorldToViewportPoint(torso.Position)
				if onScreen then
					local distance = (Vector2.new(screenPos.X, screenPos.Y) - center).Magnitude
					local fovRadius = (Options.AimbotFOV and Options.AimbotFOV.Value) or 100
					if distance < shortestDistance and distance <= fovRadius then
						shortestDistance = distance
						closestPlayer = torso
					end
				end
			end
		end
	end
	return closestPlayer
end

Toggles.AimbotLockOn:OnChanged(function()
	disconnect("AimbotLoop")
	disconnect("AimbotFOVCircleUpdate")
	if fovCircle then fovCircle.Visible = false end

	if Toggles.AimbotLockOn.Value then
		track("AimbotFOVCircleUpdate", RunService.RenderStepped:Connect(function()
			if fovCircle then
				local viewportSize = workspace.CurrentCamera.ViewportSize
				fovCircle.Position = Vector2.new(viewportSize.X / 2, viewportSize.Y / 2)
				fovCircle.Radius = (Options.AimbotFOV and Options.AimbotFOV.Value) or 100
				fovCircle.Color = (Options.AimbotFOVCircleColor and Options.AimbotFOVCircleColor.Value) or Color3.fromRGB(255, 0, 0)
				fovCircle.Visible = true
			end
		end))

		track("AimbotLoop", RunService.RenderStepped:Connect(function()
			if Toggles.AimbotLockOn.Value then
				local target = getClosestPlayerToCenter()
				if target then
					local camera = workspace.CurrentCamera
					camera.CFrame = CFrame.new(camera.CFrame.Position, target.Position)
				end
			end
		end))
		Library:Notify({ Title = "AIMBOT", Description = "Aimbot Enabled (Locking to Torso)", Time = 2 })
	end
end)

Options.AimbotFOVCircleColor:OnChanged(function(newColor)
	if fovCircle then
		fovCircle.Color = newColor
	end
end)

Toggles.KillAura:OnChanged(function()
	disconnect("KillAura")
	if Toggles.KillAura.Value then
		if not TSG.MeleePlayerRemote and not TSG.MeleeAnimalRemote then
			Library:Notify({
				Title = "Kill Aura",
				Description = "Combat remotes not found. Your executor may not support this feature.",
				Time = 5,
			})
			Toggles.KillAura:SetValue(false)
			return
		end
		track("KillAura", RunService.Heartbeat:Connect(killAuraLoop))
		Library:Notify({ Title = "Kill Aura", Description = "Enabled", Time = 2 })
	end
end)

local function isAutoSwingSlotAllowed(slotOption)
	if not slotOption then return true end
	local val = slotOption.Value
	if val == nil then return true end

	if typeof(val) == "table" then
		if val["Normal"] == true or val["Free swing"] == true or table.find(val, "Normal") or table.find(val, "Free swing") then
			return true
		end

		for slotKey, isSelected in pairs(val) do
			if isSelected == true or (typeof(slotKey) == "number" and typeof(isSelected) == "string") then
				local targetSlot = (isSelected == true) and slotKey or isSelected
				if targetSlot ~= "Normal" and targetSlot ~= "Free swing" then
					if isHoldingSelectedSlot(targetSlot) then
						return true
					end
				end
			end
		end
		return false
	elseif typeof(val) == "string" then
		if val == "Normal" or val == "Free swing" or val == "" then
			return true
		end
		return isHoldingSelectedSlot(val)
	end

	return true
end

local lastAutoSwing = 0
Toggles.AutoSwing:OnChanged(function()
	disconnect("AutoSwing")
	if updateAutoSwingSliderVisibility then
		updateAutoSwingSliderVisibility()
	end
	if Toggles.AutoSwing.Value then
		_G.T = true
		track("AutoSwing", RunService.Heartbeat:Connect(function()
			local speedVal = Options.AutoSwingSpeed and Options.AutoSwingSpeed.Value or 10
			local delay = 1 / math.max(0.1, speedVal)
			if _G.T and tick() - lastAutoSwing >= delay then
				local tool = LocalPlayer.Character and LocalPlayer.Character:FindFirstChildOfClass("Tool")
				if tool and isAutoSwingSlotAllowed(Options.AutoSwingSlot) then
					tool:Activate()
					lastAutoSwing = tick()
				end
			end
		end))
	else
		_G.T = false
	end
end)

local function isTeammate(otherPlayer)
	if not otherPlayer or otherPlayer == LocalPlayer then
		return true
	end

	if LocalPlayer.Team and otherPlayer.Team and LocalPlayer.Team == otherPlayer.Team then
		return true
	end
	if LocalPlayer.TeamColor and otherPlayer.TeamColor and LocalPlayer.TeamColor == otherPlayer.TeamColor and LocalPlayer.TeamColor ~= BrickColor.new("White") then
		return true
	end

	local success, kingdomMatch = pcall(function()
		if TSG.ClientData and TSG.ClientData.getKingdom then
			local myKingdom = TSG.ClientData.getKingdom()
			local otherKingdom = otherPlayer:GetAttribute("Kingdom") or otherPlayer:GetAttribute("Clan") or otherPlayer:GetAttribute("Team")
			if myKingdom and otherKingdom and myKingdom == otherKingdom then
				return true
			end
		end
		return false
	end)
	if success and kingdomMatch then
		return true
	end

	local myClan = LocalPlayer:GetAttribute("Clan") or LocalPlayer:GetAttribute("Kingdom") or LocalPlayer:GetAttribute("Tribe") or LocalPlayer:GetAttribute("Team")
	local theirClan = otherPlayer:GetAttribute("Clan") or otherPlayer:GetAttribute("Kingdom") or otherPlayer:GetAttribute("Tribe") or otherPlayer:GetAttribute("Team")
	if myClan and theirClan and myClan ~= "" and myClan == theirClan then
		return true
	end

	if LocalPlayer.Character and otherPlayer.Character then
		local myCharClan = LocalPlayer.Character:GetAttribute("Clan") or LocalPlayer.Character:GetAttribute("Kingdom") or LocalPlayer.Character:GetAttribute("Tribe")
		local theirCharClan = otherPlayer.Character:GetAttribute("Clan") or otherPlayer.Character:GetAttribute("Kingdom") or otherPlayer.Character:GetAttribute("Tribe")
		if myCharClan and theirCharClan and myCharClan ~= "" and myCharClan == theirCharClan then
			return true
		end
	end

	return false
end

local lastSmartSwing = 0
Toggles.SmartSwing:OnChanged(function()
	disconnect("SmartSwing")
	if updateAutoSwingSliderVisibility then
		updateAutoSwingSliderVisibility()
	end
	if Toggles.SmartSwing.Value then
		track("SmartSwing", RunService.Heartbeat:Connect(function()
			if not isAlive() then return end
			local root = getRootPart()
			if not root then return end

			local speedVal = Options.AutoSwingSpeed and Options.AutoSwingSpeed.Value or 10
			local delay = 1 / math.max(0.1, speedVal)
			if tick() - lastSmartSwing < delay then return end

			local maxDist = Options.PlayerStuds and Options.PlayerStuds.Value or 20
			local ignoreTeam = Toggles.SmartSwingIgnoreTeam and Toggles.SmartSwingIgnoreTeam.Value
			local pos = root.Position
			local playerNearby = false

			for _, otherPlayer in ipairs(Players:GetPlayers()) do
				if otherPlayer ~= LocalPlayer and otherPlayer.Character then
					if not ignoreTeam or not isTeammate(otherPlayer) then
						local otherRoot = otherPlayer.Character:FindFirstChild("HumanoidRootPart") or otherPlayer.Character.PrimaryPart
						local otherHum = otherPlayer.Character:FindFirstChildOfClass("Humanoid")
						if otherRoot and otherHum and otherHum.Health > 0 then
							local dist = (otherRoot.Position - pos).Magnitude
							if dist <= maxDist then
								playerNearby = true
								break
							end
						end
					end
				end
			end

			if playerNearby then
				local tool = LocalPlayer.Character and LocalPlayer.Character:FindFirstChildOfClass("Tool")
				if tool then
					tool:Activate()
					lastSmartSwing = tick()
				end
			end
		end))
		local studs = Options.PlayerStuds and Options.PlayerStuds.Value or 20
		Library:Notify({ Title = "Smart Swing", Description = "Enabled (Within " .. tostring(studs) .. " Studs)", Time = 2 })
	else
		Library:Notify({ Title = "Smart Swing", Description = "Disabled", Time = 2 })
	end
end)

Toggles.AutoHop:OnChanged(function()
	disconnect("AutoHop")
	if updatePVPModulesVisibility then
		updatePVPModulesVisibility()
	end
	if Toggles.AutoHop.Value then
		track("AutoHop", RunService.Heartbeat:Connect(function()
			if not isAlive() then return end
			local root = getRootPart()
			local hum = getHumanoid()
			if not root or not hum then return end

			if not hum:GetAttribute("JumpAdjusted") then
				hum:SetAttribute("JumpAdjusted", true)
				hum:SetAttribute("OrigJumpPower", hum.JumpPower)
				hum:SetAttribute("OrigJumpHeight", hum.JumpHeight)
				if hum.UseJumpPower then
					hum.JumpPower = math.max(0, hum.JumpPower - 2)
				else
					hum.JumpHeight = math.max(0, hum.JumpHeight - 2)
				end
			end

			local maxDist = Options.AutoHopStuds and Options.AutoHopStuds.Value or 20
			local ignoreTeam = Toggles.AutoHopIgnoreTeam and Toggles.AutoHopIgnoreTeam.Value
			local pos = root.Position
			local playerNearby = false
			for _, otherPlayer in ipairs(Players:GetPlayers()) do
				if otherPlayer ~= LocalPlayer and otherPlayer.Character then
					if not ignoreTeam or not isTeammate(otherPlayer) then
						local otherRoot = otherPlayer.Character:FindFirstChild("HumanoidRootPart")
						local otherHum = otherPlayer.Character:FindFirstChildOfClass("Humanoid")
						if otherRoot and otherHum and otherHum.Health > 0 then
							local dist = (otherRoot.Position - pos).Magnitude
							if dist <= maxDist then
								playerNearby = true
								break
							end
						end
					end
				end
			end

			if playerNearby then
				if hum.FloorMaterial ~= Enum.Material.Air then
					hum.Jump = true
					pcall(function()
						hum:ChangeState(Enum.HumanoidStateType.Jumping)
					end)
				end
			end
		end))
	else
		local hum = getHumanoid()
		if hum and hum:GetAttribute("JumpAdjusted") then
			hum.JumpPower = hum:GetAttribute("OrigJumpPower") or hum.JumpPower
			hum.JumpHeight = hum:GetAttribute("OrigJumpHeight") or hum.JumpHeight
			hum:SetAttribute("JumpAdjusted", nil)
		end
	end
end)

local autoShiftlockVars = {
	origCameraOffset = nil,
	screenGui = nil,
	toggleButton = nil,
	crosshair = nil,
	shiftLockEnabled = false,
	cameraOffset = Vector3.new(1.7, 0.5, 0),
	dragging = false,
	dragInput = nil,
	dragStart = nil,
	startPos = nil,
	dragCon1 = nil,
	dragCon2 = nil,
	dragCon3 = nil,
	activatedCon = nil,
	renderCon = nil,
	charAddedCon = nil
}

local function destroyMobileShiftlockGui()
	if autoShiftlockVars.charAddedCon then
		autoShiftlockVars.charAddedCon:Disconnect()
		autoShiftlockVars.charAddedCon = nil
	end
	if autoShiftlockVars.dragCon1 then autoShiftlockVars.dragCon1:Disconnect() end
	if autoShiftlockVars.dragCon2 then autoShiftlockVars.dragCon2:Disconnect() end
	if autoShiftlockVars.dragCon3 then autoShiftlockVars.dragCon3:Disconnect() end
	if autoShiftlockVars.activatedCon then autoShiftlockVars.activatedCon:Disconnect() end
	if autoShiftlockVars.renderCon then autoShiftlockVars.renderCon:Disconnect() end
	autoShiftlockVars.dragCon1 = nil
	autoShiftlockVars.dragCon2 = nil
	autoShiftlockVars.dragCon3 = nil
	autoShiftlockVars.activatedCon = nil
	autoShiftlockVars.renderCon = nil
	if autoShiftlockVars.screenGui then
		pcall(function() autoShiftlockVars.screenGui:Destroy() end)
	end
	autoShiftlockVars.screenGui = nil
	autoShiftlockVars.toggleButton = nil
	autoShiftlockVars.crosshair = nil
end

local function resetMobileShiftlockState()
	autoShiftlockVars.shiftLockEnabled = false
	local hum = getHumanoid()
	if hum then
		hum.AutoRotate = true
		hum.CameraOffset = autoShiftlockVars.origCameraOffset or Vector3.zero
	end
end

Toggles.AutoShiftlock:OnChanged(function()
	disconnect("AutoShiftlock")
	destroyMobileShiftlockGui()
	resetMobileShiftlockState()

	if Toggles.AutoShiftlock.Value then
		local hum = getHumanoid()
		if hum then
			autoShiftlockVars.origCameraOffset = hum.CameraOffset
		end

		local playerGui = LocalPlayer:WaitForChild("PlayerGui")
		local screenGui = Instance.new("ScreenGui")
		screenGui.Name = "MobileShiftlockGUI"
		screenGui.ResetOnSpawn = false
		screenGui.Parent = playerGui
		autoShiftlockVars.screenGui = screenGui

		local toggleButton = Instance.new("ImageButton")
		toggleButton.Name = "ShiftlockButton"
		toggleButton.Parent = screenGui
		toggleButton.BackgroundTransparency = 1
		toggleButton.Size = UDim2.new(0, 60, 0, 60)
		toggleButton.Position = UDim2.new(0.85, -30, 0.5, -30)
		toggleButton.Image = "rbxasset://textures/ui/mouseLock_off@2x.png"
		autoShiftlockVars.toggleButton = toggleButton

		local crosshair = Instance.new("ImageLabel")
		crosshair.Name = "ShiftlockCursor"
		crosshair.Parent = screenGui
		crosshair.BackgroundTransparency = 1
		crosshair.Position = UDim2.new(0.5, 0, 0.5, 0)
		crosshair.AnchorPoint = Vector2.new(0.5, 0.5)
		crosshair.Size = UDim2.new(0, 22, 0, 22)
		crosshair.Image = "rbxasset://textures/MouseLockedCursor.png"
		crosshair.Visible = false
		autoShiftlockVars.crosshair = crosshair

		local function update(input)
			local delta = input.Position - autoShiftlockVars.dragStart
			toggleButton.Position = UDim2.new(
				autoShiftlockVars.startPos.X.Scale,
				autoShiftlockVars.startPos.X.Offset + delta.X,
				autoShiftlockVars.startPos.Y.Scale,
				autoShiftlockVars.startPos.Y.Offset + delta.Y
			)
		end

		autoShiftlockVars.dragCon1 = toggleButton.InputBegan:Connect(function(input)
			if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
				autoShiftlockVars.dragging = true
				autoShiftlockVars.dragStart = input.Position
				autoShiftlockVars.startPos = toggleButton.Position

				input.Changed:Connect(function()
					if input.UserInputState == Enum.UserInputState.End then
						autoShiftlockVars.dragging = false
					end
				end)
			end
		end)

		autoShiftlockVars.dragCon2 = toggleButton.InputChanged:Connect(function(input)
			if input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch then
				autoShiftlockVars.dragInput = input
			end
		end)

		autoShiftlockVars.dragCon3 = UserInputService.InputChanged:Connect(function(input)
			if input == autoShiftlockVars.dragInput and autoShiftlockVars.dragging then
				update(input)
			end
		end)

		autoShiftlockVars.activatedCon = toggleButton.Activated:Connect(function()
			autoShiftlockVars.shiftLockEnabled = not autoShiftlockVars.shiftLockEnabled

			if autoShiftlockVars.shiftLockEnabled then
				toggleButton.Image = "rbxasset://textures/ui/mouseLock_on@2x.png"
				crosshair.Visible = true
				if LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("Humanoid") then
					LocalPlayer.Character.Humanoid.AutoRotate = false
				end
			else
				toggleButton.Image = "rbxasset://textures/ui/mouseLock_off@2x.png"
				crosshair.Visible = false
				if LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("Humanoid") then
					LocalPlayer.Character.Humanoid.AutoRotate = true
					LocalPlayer.Character.Humanoid.CameraOffset = Vector3.new(0, 0, 0)
				end
			end
		end)

		autoShiftlockVars.renderCon = RunService.RenderStepped:Connect(function()
			if autoShiftlockVars.shiftLockEnabled then
				if LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart") and LocalPlayer.Character:FindFirstChild("Humanoid") then
					LocalPlayer.Character.Humanoid.CameraOffset = autoShiftlockVars.cameraOffset

					local rootPart = LocalPlayer.Character.HumanoidRootPart
					local camera = workspace.CurrentCamera
					if not camera then return end
					local lookVector = camera.CFrame.LookVector

					rootPart.CFrame = CFrame.new(
						rootPart.Position,
						rootPart.Position + Vector3.new(lookVector.X, 0, lookVector.Z)
					)
				end
			end
		end)

		autoShiftlockVars.charAddedCon = LocalPlayer.CharacterAdded:Connect(function()
			if autoShiftlockVars.shiftLockEnabled and autoShiftlockVars.toggleButton then
				autoShiftlockVars.toggleButton.Image = "rbxasset://textures/ui/mouseLock_off@2x.png"
			end
			if autoShiftlockVars.crosshair then
				autoShiftlockVars.crosshair.Visible = false
			end
			autoShiftlockVars.shiftLockEnabled = false
		end)
	else
		local hum = getHumanoid()
		if hum then
			hum.AutoRotate = true
			hum.CameraOffset = autoShiftlockVars.origCameraOffset or Vector3.zero
		end
	end
end)

Toggles.Camlock:OnChanged(function()
	disconnect("Camlock")
	if updatePVPModulesVisibility then
		updatePVPModulesVisibility()
	end
	if Toggles.Camlock.Value then
		track("Camlock", RunService.Heartbeat:Connect(function()
			if not isAlive() then return end
			local root = getRootPart()
			local hum = getHumanoid()
			if not root or not hum then return end

			local maxDist = Options.CamlockStuds and Options.CamlockStuds.Value or 20
			local myPos = root.Position
			local closestPlayer = nil
			local closestDist = math.huge
			local targetSetting = Options.CamlockTarget and Options.CamlockTarget.Value or "All"
			local ignoreTeam = Toggles.CamlockIgnoreTeam and Toggles.CamlockIgnoreTeam.Value

			for _, otherPlayer in ipairs(Players:GetPlayers()) do
				if otherPlayer ~= LocalPlayer and otherPlayer.Character then
					if not ignoreTeam or not isTeammate(otherPlayer) then
						local otherRoot = otherPlayer.Character:FindFirstChild("HumanoidRootPart")
						local otherHum = otherPlayer.Character:FindFirstChildOfClass("Humanoid")
						if otherRoot and otherHum and otherHum.Health > 0 then
							if targetSetting == "All" or otherPlayer.Name == targetSetting then
								local dist = (otherRoot.Position - myPos).Magnitude
								if dist <= maxDist and dist < closestDist then
									closestDist = dist
									closestPlayer = otherPlayer
								end
							end
						end
					end
				end
			end

			-- Outline: Stop player from getting closer than studs to players while using Camlock
			local outlineActive = (Toggles.Outline and Toggles.Outline.Value) or (Toggles.Cutline and Toggles.Cutline.Value)
			if outlineActive then
				local minOutlineStuds = (Options.OutlineStuds and Options.OutlineStuds.Value) or (Options.CutlineStuds and Options.CutlineStuds.Value) or 7
				local outlineTargetSetting = (Options.OutlineTarget and Options.OutlineTarget.Value) or "All"
				for _, otherPlayer in ipairs(Players:GetPlayers()) do
					if otherPlayer ~= LocalPlayer and otherPlayer.Character then
						if not ignoreTeam or not isTeammate(otherPlayer) then
							local otherRoot = otherPlayer.Character:FindFirstChild("HumanoidRootPart")
							local otherHum = otherPlayer.Character:FindFirstChildOfClass("Humanoid")
							if otherRoot and otherHum and otherHum.Health > 0 then
								if outlineTargetSetting == "All" or otherPlayer.Name == outlineTargetSetting then
									local otherPos = otherRoot.Position
									local offset = myPos - otherPos
									local flatOffset = Vector3.new(offset.X, 0, offset.Z)
									local flatDist = flatOffset.Magnitude

									if flatDist < minOutlineStuds then
										local pushDir
										if flatDist > 0.001 then
											pushDir = flatOffset.Unit
										else
											local backDir = -root.CFrame.LookVector
											local flatBack = Vector3.new(backDir.X, 0, backDir.Z)
											pushDir = flatBack.Magnitude > 0.001 and flatBack.Unit or Vector3.new(0, 0, 1)
										end

										myPos = Vector3.new(
											otherPos.X + pushDir.X * minOutlineStuds,
											myPos.Y,
											otherPos.Z + pushDir.Z * minOutlineStuds
										)

										pcall(function()
											local vel = root.AssemblyLinearVelocity or root.Velocity
											if vel then
												local moveTowards = vel.X * (-pushDir.X) + vel.Z * (-pushDir.Z)
												if moveTowards > 0 then
													local correctedVel = Vector3.new(
														vel.X - (-pushDir.X * moveTowards),
														vel.Y,
														vel.Z - (-pushDir.Z * moveTowards)
													)
													root.AssemblyLinearVelocity = correctedVel
													root.Velocity = correctedVel
												end
											end
										end)
									end
								end
							end
						end
					end
				end
			end

			if closestPlayer then
				UserInputService.MouseBehavior = Enum.MouseBehavior.LockCenter
				UserInputService.MouseIconEnabled = false

				local targetRoot = closestPlayer.Character:FindFirstChild("HumanoidRootPart")
				if targetRoot then
					local targetPos = targetRoot.Position
					local lookDir = Vector3.new(targetPos.X - myPos.X, 0, targetPos.Z - myPos.Z).Unit
					if lookDir.Magnitude > 0 then
						hum.AutoRotate = false
						root.CFrame = CFrame.new(myPos, myPos + lookDir)
					else
						root.CFrame = CFrame.new(myPos, myPos + root.CFrame.LookVector)
					end
				end
			else
				UserInputService.MouseBehavior = Enum.MouseBehavior.Default
				UserInputService.MouseIconEnabled = true
				hum.AutoRotate = true
				if outlineActive and (root.Position - myPos).Magnitude > 0.01 then
					root.CFrame = CFrame.new(myPos, myPos + root.CFrame.LookVector)
				end
			end
		end))
	else
		UserInputService.MouseBehavior = Enum.MouseBehavior.Default
		UserInputService.MouseIconEnabled = true
		local hum = getHumanoid()
		if hum then
			hum.AutoRotate = true
		end
	end
end)

if Toggles.Outline then
	Toggles.Outline:OnChanged(function()
		if updatePVPModulesVisibility then
			updatePVPModulesVisibility()
		end
	end)
end

if Toggles.CamlockIgnoreTeam then
	Toggles.CamlockIgnoreTeam:OnChanged(function()
		if updatePVPModulesVisibility then
			updatePVPModulesVisibility()
		end
	end)
end

local function applySpearSwordSlot(slot)
	if not (Toggles.SpearSword and Toggles.SpearSword.Value) then return end
	if slot == 3 or slot == "3" then
		if Options.CamlockStuds then
			Options.CamlockStuds:SetValue(15)
		end
		if Options.OutlineStuds then
			Options.OutlineStuds:SetValue(8)
		end
	elseif slot == 5 or slot == "5" then
		if Options.CamlockStuds then
			Options.CamlockStuds:SetValue(15)
		end
		if Options.OutlineStuds then
			Options.OutlineStuds:SetValue(1)
		end
	end
end

local function checkCurrentSpearSwordHeld()
	if not (Toggles.SpearSword and Toggles.SpearSword.Value) then return end
	if isHoldingSelectedSlot(3) then
		applySpearSwordSlot(3)
	elseif isHoldingSelectedSlot(5) then
		applySpearSwordSlot(5)
	end
end

if Toggles.SpearSword then
	Toggles.SpearSword:OnChanged(function()
		disconnect("SpearSword_Input")
		disconnect("SpearSword_ChildAdded")
		disconnect("SpearSword_CharAdded")
		if updatePVPModulesVisibility then
			updatePVPModulesVisibility()
		end
		if Toggles.SpearSword.Value then
			checkCurrentSpearSwordHeld()

			track("SpearSword_Input", UserInputService.InputBegan:Connect(function(input, gameProcessed)
				if not (Toggles.SpearSword and Toggles.SpearSword.Value) then return end
				if not gameProcessed and not UserInputService:GetFocusedTextBox() then
					if input.KeyCode == Enum.KeyCode.Three or input.KeyCode == Enum.KeyCode.KeypadThree then
						applySpearSwordSlot(3)
						return
					elseif input.KeyCode == Enum.KeyCode.Five or input.KeyCode == Enum.KeyCode.KeypadFive then
						applySpearSwordSlot(5)
						return
					end
				end
				task.delay(0.05, function()
					checkCurrentSpearSwordHeld()
				end)
			end))

			local function hookChar(char)
				if not char then return end
				disconnect("SpearSword_ChildAdded")
				track("SpearSword_ChildAdded", char.ChildAdded:Connect(function(child)
					if child:IsA("Tool") then
						task.wait()
						checkCurrentSpearSwordHeld()
					end
				end))
			end

			if LocalPlayer.Character then
				hookChar(LocalPlayer.Character)
			end
			track("SpearSword_CharAdded", LocalPlayer.CharacterAdded:Connect(hookChar))
		end
	end)
end

local floorLookYaw = 0

local function getFloorLookTouchSens()
	local multiplier = (Options.LookDownSens and Options.LookDownSens.Value) or 12
	return multiplier * 0.0014
end

local function getFloorLookMouseSens()
	local base = 0.008
	pcall(function()
		local userSens = UserSettings():GetService("UserGameSettings").MouseSensitivity
		if typeof(userSens) == "number" and userSens > 0 then
			base = userSens * 0.006
		end
	end)
	local multiplier = (Options.LookDownSens and (Options.LookDownSens.Value / 12)) or 1
	return base * multiplier
end

local function isLookDownSlotAllowed(slotOption)
	if not slotOption then return false end
	local val = slotOption.Value
	if val == nil then return false end

	if typeof(val) == "table" then
		for slotKey, isSelected in pairs(val) do
			if isSelected == true or (typeof(slotKey) == "number" and typeof(isSelected) == "string") then
				local targetSlot = (isSelected == true) and slotKey or isSelected
				if isHoldingSelectedSlot(targetSlot) then
					return true
				end
			end
		end
		return false
	elseif typeof(val) == "string" or typeof(val) == "number" then
		return isHoldingSelectedSlot(val)
	end

	return false
end

local isLookDownEngaged = false

if Toggles.LookDownFloor then
	Toggles.LookDownFloor:OnChanged(function()
		disconnect("LookDownFloor")
		disconnect("LookDownFloor_Input")
		disconnect("LookDownFloor_TouchMoved")
		isLookDownEngaged = false

		if updatePVPModulesVisibility then
			updatePVPModulesVisibility()
		end

		if Toggles.LookDownFloor.Value then
			local root = getRootPart()
			if root then
				local look = root.CFrame.LookVector
				local flatLook = Vector3.new(look.X, 0, look.Z)
				if flatLook.Magnitude > 0.001 then
					floorLookYaw = math.atan2(-flatLook.X, -flatLook.Z)
				else
					floorLookYaw = 0
				end
			else
				floorLookYaw = 0
			end

			-- Helper to apply horizontal turn delta from thumb or mouse
			local function applyTurnDelta(deltaX, posX, isTouch)
				if not deltaX or math.abs(deltaX) < 0.0001 then return end
				if isTouch then
					local viewportWidth = (workspace.CurrentCamera and workspace.CurrentCamera.ViewportSize.X) or 1000
					-- Ignore touch on the virtual joystick area (left 35% of the screen)
					if posX and posX < viewportWidth * 0.35 then
						return
					end
					local sens = getFloorLookTouchSens()
					floorLookYaw = floorLookYaw - deltaX * sens
				else
					local sens = getFloorLookMouseSens()
					floorLookYaw = floorLookYaw - deltaX * sens
				end
			end

			-- Touch turning for mobile / tablet
			track("LookDownFloor_TouchMoved", UserInputService.TouchMoved:Connect(function(touch, gameProcessed)
				if not (Toggles.LookDownFloor and Toggles.LookDownFloor.Value) then return end
				if not isLookDownSlotAllowed(Options.LookDownSlot) then return end
				applyTurnDelta(touch.Delta.X, touch.Position.X, true)
			end))

			-- Mouse & general input changed
			track("LookDownFloor_Input", UserInputService.InputChanged:Connect(function(input, gameProcessed)
				if not (Toggles.LookDownFloor and Toggles.LookDownFloor.Value) then return end
				if not isLookDownSlotAllowed(Options.LookDownSlot) then return end
				if input.UserInputType == Enum.UserInputType.Touch then
					applyTurnDelta(input.Delta.X, input.Position.X, true)
				elseif input.UserInputType == Enum.UserInputType.MouseMovement then
					local isLocked = UserInputService.MouseBehavior ~= Enum.MouseBehavior.Default
					local isRightDown = false
					pcall(function()
						isRightDown = UserInputService:IsMouseButtonPressed(Enum.UserInputType.MouseButton2)
					end)
					if isLocked or isRightDown then
						applyTurnDelta(input.Delta.X, input.Position.X, false)
					end
				end
			end))

			track("LookDownFloor", RunService.RenderStepped:Connect(function(dt)
				if not isAlive() then return end
				local r = getRootPart()
				local h = getHumanoid()
				local camera = workspace.CurrentCamera
				if not r or not h or not camera then return end

				local isHolding = isLookDownSlotAllowed(Options.LookDownSlot)

				if isHolding then
					if not isLookDownEngaged then
						isLookDownEngaged = true
						local look = r.CFrame.LookVector
						local flatLook = Vector3.new(look.X, 0, look.Z)
						if flatLook.Magnitude > 0.001 then
							floorLookYaw = math.atan2(-flatLook.X, -flatLook.Z)
						end
					end

					-- Disable AutoRotate so joystick only moves/strafes without twisting character facing direction
					h.AutoRotate = false

					-- Arrow key rotation support
					pcall(function()
						if UserInputService:IsKeyDown(Enum.KeyCode.Left) then
							floorLookYaw = floorLookYaw + 4.5 * dt
						elseif UserInputService:IsKeyDown(Enum.KeyCode.Right) then
							floorLookYaw = floorLookYaw - 4.5 * dt
						end
					end)

					local zoomDist = (Options.LookDownZoom and Options.LookDownZoom.Value) or 20
					local rootPos = r.Position

					local camRotation = CFrame.Angles(0, floorLookYaw, 0) * CFrame.Angles(-math.rad(89.5), 0, 0)
					camera.CFrame = CFrame.new(rootPos + Vector3.new(0, zoomDist, 0)) * camRotation

					-- Rotate character body to face the thumb aim direction
					r.CFrame = CFrame.new(rootPos) * CFrame.Angles(0, floorLookYaw, 0)
				else
					if isLookDownEngaged then
						isLookDownEngaged = false
						h.AutoRotate = true
						camera.CameraSubject = h
						camera.CameraType = Enum.CameraType.Custom
					end
				end
			end))
		else
			isLookDownEngaged = false
			local hum = getHumanoid()
			if hum then
				hum.AutoRotate = true
				workspace.CurrentCamera.CameraSubject = hum
			end
			workspace.CurrentCamera.CameraType = Enum.CameraType.Custom
		end
	end)
end

Toggles.SwordBot:OnChanged(function()
	disconnect("SwordBot")
	if Toggles.SwordBot.Value then
		local lastSwing = 0
		local orbitAngle = 0
		track("SwordBot", RunService.Heartbeat:Connect(function(dt)
			if not isAlive() then return end
			local root = getRootPart()
			local hum = getHumanoid()
			if not root or not hum then return end

			local targetName = Options.ChooseVictim and Options.ChooseVictim.Value
			local targetPlayer = targetName and Players:FindFirstChild(targetName)
			if not targetPlayer or not targetPlayer.Character or not targetPlayer.Character:FindFirstChild("HumanoidRootPart") then
				local closest, cDist = nil, math.huge
				for _, p in ipairs(Players:GetPlayers()) do
					if p ~= LocalPlayer and p.Character and p.Character:FindFirstChild("HumanoidRootPart") then
						local phum = p.Character:FindFirstChildOfClass("Humanoid")
						if phum and phum.Health > 0 then
							local d = (p.Character.HumanoidRootPart.Position - root.Position).Magnitude
							if d < cDist then
								cDist = d
								closest = p
							end
						end
					end
				end
				targetPlayer = closest
			end

			local targetChar = targetPlayer and targetPlayer.Character
			local targetRoot = targetChar and targetChar:FindFirstChild("HumanoidRootPart")
			local targetHum = targetChar and targetChar:FindFirstChildOfClass("Humanoid")

			if not targetRoot or not targetHum or targetHum.Health <= 0 then
				UserInputService.MouseBehavior = Enum.MouseBehavior.Default
				UserInputService.MouseIconEnabled = true
				hum.AutoRotate = true
				return
			end

			local targetPos = targetRoot.Position
			local myPos = root.Position
			local dist = (targetPos - myPos).Magnitude

			-- Camlock functionality when within 10 studs
			if dist <= 10 then
				UserInputService.MouseBehavior = Enum.MouseBehavior.LockCenter
				UserInputService.MouseIconEnabled = false
				hum.AutoRotate = false

				local lookDir = Vector3.new(targetPos.X - myPos.X, 0, targetPos.Z - myPos.Z).Unit
				if lookDir.Magnitude > 0 then
					root.CFrame = CFrame.new(myPos, myPos + lookDir)
				end
			else
				UserInputService.MouseBehavior = Enum.MouseBehavior.Default
				UserInputService.MouseIconEnabled = true
				hum.AutoRotate = true

				-- Force camera/body lock-on facing target on Y axis
				root.CFrame = CFrame.lookAt(root.Position, Vector3.new(targetPos.X, root.Position.Y, targetPos.Z))
			end

			-- Determine movement position (prevent getting closer than 20 studs)
			local movePos
			if dist > 20.5 then
				-- Head directly to the closest point on the 20-stud perimeter
				local dir = (myPos - targetPos)
				local flatDir = Vector3.new(dir.X, 0, dir.Z)
				if flatDir.Magnitude > 0.1 then
					movePos = targetPos + flatDir.Unit * 20
				else
					movePos = targetPos + Vector3.new(20, 0, 0)
				end
			else
				-- Orbit smoothly at exactly 20 studs
				orbitAngle = orbitAngle + (dt * 5)
				local offset = Vector3.new(math.cos(orbitAngle) * 20, 0, math.sin(orbitAngle) * 20)
				movePos = targetPos + offset
			end

			-- Move to calculated position
			hum:MoveTo(movePos)

			-- Check distance for auto hop and attack (jumping around their body in circles)
			if dist <= 22 then
				-- Constantly Hop
				if hum.FloorMaterial ~= Enum.Material.Air then
					hum.Jump = true
					pcall(function()
						hum:ChangeState(Enum.HumanoidStateType.Jumping)
					end)
				end

				-- Constant auto swing
				local delay = 0.2
				if tick() - lastSwing >= delay then
					local tool = LocalPlayer.Character and LocalPlayer.Character:FindFirstChildOfClass("Tool")
					if tool then
						tool:Activate()
						lastSwing = tick()
					end
				end
			end
		end))
	else
		UserInputService.MouseBehavior = Enum.MouseBehavior.Default
		UserInputService.MouseIconEnabled = true
		local hum = getHumanoid()
		local root = getRootPart()
		if hum then
			hum.AutoRotate = true
			if root then
				hum:MoveTo(root.Position)
			end
		end
	end
end)

local function updateVictimDropdown()
	local names = {}
	for _, player in ipairs(Players:GetPlayers()) do
		if player ~= LocalPlayer then
			table.insert(names, player.Name)
		end
	end
	Options.ChooseVictim:SetValues(names)
end

track("VictimPlayerAdded", Players.PlayerAdded:Connect(updateVictimDropdown))
track("VictimPlayerRemoving", Players.PlayerRemoving:Connect(updateVictimDropdown))
task.spawn(updateVictimDropdown)

-- Phantom Mode Logic
local phantomModeVars = {
	active = false,
	orbitAngle = 0,
	orbitRadius = 5,
	orbitHeight = Options.OrbitAdjust and Options.OrbitAdjust.Value or 2,
	orbitSpeed = Options.OrbitSpeed and Options.OrbitSpeed.Value or 60,
	targetPlayer = nil
}

local function getClosestPlayerInRange()
	local root = getRootPart()
	if not root then return nil end
	local range = Options.KillAuraRange and Options.KillAuraRange.Value or 15
	local closestPlayer = nil
	local closestDistance = math.huge
	local targetSetting = Options.KillAuraTarget and Options.KillAuraTarget.Value or "All"

	for _, player in ipairs(Players:GetPlayers()) do
		if player ~= LocalPlayer and player.Character and player.Character:FindFirstChild("HumanoidRootPart") then
			if targetSetting == "All" or player.Name == targetSetting then
				local targetRoot = player.Character.HumanoidRootPart
				local distance = (targetRoot.Position - root.Position).Magnitude
				if distance < closestDistance and distance <= range then
					closestPlayer = player
					closestDistance = distance
				end
			end
		end
	end

	return closestPlayer
end

local function phantomModeLoop(dt)
	if not Toggles.PhantomMode.Value or not isAlive() then
		return
	end

	local myRoot = getRootPart()
	if not myRoot then return end

	-- Find closest player in range
	local closestPlayer = getClosestPlayerInRange()
	if closestPlayer and closestPlayer.Character and closestPlayer.Character:FindFirstChild("HumanoidRootPart") then
		phantomModeVars.targetPlayer = closestPlayer
		local targetRoot = closestPlayer.Character.HumanoidRootPart
		local targetHum = closestPlayer.Character:FindFirstChildOfClass("Humanoid")

		-- Spectate the target
		if targetHum then
			workspace.CurrentCamera.CameraSubject = targetHum
		end

		-- Orbit around the target's head
		phantomModeVars.orbitAngle += phantomModeVars.orbitSpeed * dt
		local offsetX = math.cos(phantomModeVars.orbitAngle) * phantomModeVars.orbitRadius
		local offsetZ = math.sin(phantomModeVars.orbitAngle) * phantomModeVars.orbitRadius
		local orbitPosition = targetRoot.Position + Vector3.new(offsetX, phantomModeVars.orbitHeight, offsetZ)
		myRoot.CFrame = CFrame.new(orbitPosition, targetRoot.Position)

		-- Enable Kill Aura and set best weapon
		if not Toggles.KillAura.Value then
			Toggles.KillAura:SetValue(true)
		end

		-- Find and set best melee weapon
		local bestWeaponId = getBestMeleeWeapon()
		if bestWeaponId then
			local wantedSlot = nil
			local backpack = LocalPlayer:FindFirstChild("Backpack")
			local char = LocalPlayer.Character
			for i = 1, 10 do
				local slotStr = tostring(i)
				local slotTool = (backpack and backpack:FindFirstChild(slotStr)) or (char and char:FindFirstChild(slotStr))
				if slotTool and slotTool:FindFirstChild("toolModel") then
					local toolId = slotTool.toolModel:GetAttribute("itemId")
					if toolId == bestWeaponId then
						wantedSlot = slotStr
						break
					end
				end
			end
			if wantedSlot and Options.KillAuraSlot and Options.KillAuraSlot.Value ~= wantedSlot then
				Options.KillAuraSlot:SetValue(wantedSlot)
			end
		end
	else
		-- If no target, reset camera and disable kill aura
		phantomModeVars.targetPlayer = nil
		local myHum = getHumanoid()
		if myHum then
			workspace.CurrentCamera.CameraSubject = myHum
		end
	end
end

Toggles.PhantomMode:OnChanged(function()
	if updatePhantomModeVisibility then
		updatePhantomModeVisibility()
	end
	disconnect("PhantomMode")
	if Toggles.PhantomMode.Value then
		if Toggles.KillAura and not Toggles.KillAura.Value then
			Toggles.KillAura:SetValue(true)
		end
		track("PhantomMode", RunService.Heartbeat:Connect(phantomModeLoop))
		Library:Notify({ Title = "Rage Mode", Description = "Enabled", Time = 2 })
	else
		-- Reset
		phantomModeVars.targetPlayer = nil
		local myHum = getHumanoid()
		if myHum then
			workspace.CurrentCamera.CameraSubject = myHum
		end
		if Toggles.KillAura and Toggles.KillAura.Value then
			Toggles.KillAura:SetValue(false)
		end
		Library:Notify({ Title = "Rage Mode", Description = "Disabled", Time = 2 })
	end
end)

Options.OrbitAdjust:OnChanged(function()
	phantomModeVars.orbitHeight = Options.OrbitAdjust.Value
end)

Options.OrbitSpeed:OnChanged(function()
	phantomModeVars.orbitSpeed = Options.OrbitSpeed.Value
end)

Toggles.Reach:OnChanged(function()
	if Toggles.Reach.Value then
		Library:Notify({ Title = "Reach", Description = "Enabled", Time = 2 })
	end
end)

Options.AdvancePreset:OnChanged(function()
	local val = Options.AdvancePreset.Value
	local slider = Options.ReachRange
	if slider then
		if val == "Sword" then
			slider:SetValue(11)
			Library:Notify({ Title = "Advance Preset", Description = "Preset: Sword (11) applied!", Time = 2 })
		elseif val == "Spear" then
			slider:SetValue(13)
			Library:Notify({ Title = "Advance Preset", Description = "Preset: Spear (13) applied!", Time = 2 })
		end
	end
end)

local function connectReachTool(tool)
	disconnect("ReachToolConn")
	track("ReachToolConn", tool.Activated:Connect(function()
		if Toggles.Reach.Value then
			local range = Options.ReachRange.Value
			local maxAngle = (Options.ReachAngle and Options.ReachAngle.Value) or 35
			local coneThreshold = math.cos(math.rad(maxAngle / 2))
			local root = getRootPart()
			if root then
				local pos = root.Position
				local rawLook = Vector3.new(root.CFrame.LookVector.X, 0, root.CFrame.LookVector.Z)
				local forward = rawLook.Magnitude > 0 and rawLook.Unit or root.CFrame.LookVector
				local nearestTarget = nil
				local nearestDist = range
				local reachTargetSetting = (Options.ReachTarget and Options.ReachTarget.Value) or "All"

				local function passesAngleCheck(targetPos)
					local dir = Vector3.new(targetPos.X - pos.X, 0, targetPos.Z - pos.Z)
					if dir.Magnitude <= 0 then return true end
					return forward:Dot(dir.Unit) >= coneThreshold
				end

				-- Scan Players
				for _, otherPlayer in ipairs(Players:GetPlayers()) do
					if otherPlayer ~= LocalPlayer and otherPlayer.Character then
						if reachTargetSetting == "All" or otherPlayer.Name == reachTargetSetting then
							local otherHum = otherPlayer.Character:FindFirstChildOfClass("Humanoid")
							local otherRoot = otherPlayer.Character:FindFirstChild("HumanoidRootPart")
							if otherHum and otherHum.Health > 0 and otherRoot then
								local d = (otherRoot.Position - pos).Magnitude
								if d < nearestDist and passesAngleCheck(otherRoot.Position) then
									nearestDist = d
									nearestTarget = otherPlayer.Character
								end
							end
						end
					end
				end

				-- Scan NPC AI Models (when Target is "All")
				if reachTargetSetting == "All" then
					local aiClient = workspace:FindFirstChild("AI_Client")
					if aiClient then
						for _, npc in ipairs(aiClient:GetChildren()) do
							local npcHum = npc:FindFirstChildOfClass("Humanoid")
							local npcRoot = npc:FindFirstChild("HumanoidRootPart") or npc.PrimaryPart
							if npcHum and npcHum.Health > 0 and npcRoot then
								local d = (npcRoot.Position - pos).Magnitude
								if d < nearestDist and passesAngleCheck(npcRoot.Position) then
									nearestDist = d
									nearestTarget = npc
								end
							end
						end
					end

					local aiServer = workspace:FindFirstChild("AI_Server")
					if aiServer then
						for _, npc in ipairs(aiServer:GetChildren()) do
							local npcHum = npc:FindFirstChildOfClass("Humanoid")
							local npcRoot = npc:FindFirstChild("HumanoidRootPart") or npc.PrimaryPart
							if (not npcHum or npcHum.Health > 0) and npcRoot then
								local d = (npcRoot.Position - pos).Magnitude
								if d < nearestDist and passesAngleCheck(npcRoot.Position) then
									nearestDist = d
									nearestTarget = npc
								end
							end
						end
					end
				end

				if nearestTarget then
					local slot = tonumber(tool.Name) or 1
					local targetPlayer = Players:GetPlayerFromCharacter(nearestTarget)
					if targetPlayer then
						if Crypt then
							pcall(function()
								local k1, k2, k3 = Crypt.checkpublickeys()
								if k1 and k2 and k3 then
									local encryptedUserId = Crypt.crypt(k1, math.abs(targetPlayer.UserId) + k3, k2)
									TSG.MeleePlayerRemote:FireServer(slot, encryptedUserId)
								end
							end)
						else
                                                        pcall(TSG.MeleePlayerRemote.FireServer, TSG.MeleePlayerRemote, slot, targetPlayer)
						end
					else
						attackNPC(slot, nearestTarget)
					end
				end
			end
		end
end))
end

local function setupReachTracking()
	disconnect("ReachToolEquipped")
	disconnect("ReachChildAdded")

	local char = LocalPlayer.Character
	if char then
		track("ReachChildAdded", char.ChildAdded:Connect(function(child)
			if child:IsA("Tool") then
				connectReachTool(child)
			end
		end))
		local tool = char:FindFirstChildOfClass("Tool")
		if tool then
			connectReachTool(tool)
		end
	end
end

track("ReachCharacterAdded", LocalPlayer.CharacterAdded:Connect(function()
	task.wait(1)
	setupReachTracking()
end))
setupReachTracking()

-- ==========================================
-- MOVEMENT
-- ==========================================
local MoveLeft = Tabs.Movement:AddLeftGroupbox("Speed", "gauge")
local MoveRight = Tabs.Movement:AddRightGroupbox("Flight", "plane")

MoveLeft:AddToggle("SpeedHack", {
	Text = "Speed",
	Default = false,
})



MoveLeft:AddSlider("SpeedValue", {
	Text = "Speed Value",
	Default = 24,
	Min = 16,
	Max = 50,
	Rounding = 1,
	Compact = true,
})

local MoveSwimBoost = Tabs.Movement:AddLeftGroupbox("Swim Boost", "droplet")

MoveSwimBoost:AddToggle("SwimBoost", {
	Text = "Swim Boost",
	Default = false,
})

MoveSwimBoost:AddCheckbox("SwimSlotBoost", {
	Text = "Slot Boost",
	Default = false,
})

MoveSwimBoost:AddDropdown("SwimSlotBoostSlot", {
	Text = "Tool Slot",
	Values = {"1", "2", "3", "4", "5", "6", "7", "8", "9", "10"},
	Default = {"1"},
	Multi = true,
})

MoveSwimBoost:AddSlider("SwimBoostValue", {
	Text = "Swim Speed Value",
	Default = 30,
	Min = 16,
	Max = 50,
	Rounding = 1,
	Compact = true,
})

MoveSwimBoost:AddDivider()

MoveSwimBoost:AddCheckbox("SinkFastPVP", {
	Text = "+ Sink Fast PVP",
	Default = false,
})

MoveSwimBoost:AddSlider("SinkFastPVPSpeed", {
	Text = "Sink Speed",
	Default = 60,
	Min = 10,
	Max = 200,
	Rounding = 0,
	Compact = true,
})

MoveSwimBoost:AddCheckbox("RiseFastPVP", {
	Text = "+ Rise Fast PVP",
	Default = false,
})

MoveSwimBoost:AddSlider("RiseFastPVPSpeed", {
	Text = "Rise Speed",
	Default = 60,
	Min = 10,
	Max = 200,
	Rounding = 0,
	Compact = true,
})

updateSwimBoostVisibility = function()
	local isSink = (Toggles.SinkFastPVP and Toggles.SinkFastPVP.Value) or false
	local isRise = (Toggles.RiseFastPVP and Toggles.RiseFastPVP.Value) or false
	local isSlotBoost = (Toggles.SwimSlotBoost and Toggles.SwimSlotBoost.Value) or false

	if Options.SwimSlotBoostSlot then
		Options.SwimSlotBoostSlot.Visible = isSlotBoost
		if Options.SwimSlotBoostSlot.Holder then
			Options.SwimSlotBoostSlot.Holder.Visible = isSlotBoost
		end
	end

	if Options.SinkFastPVPSpeed then
		Options.SinkFastPVPSpeed.Visible = isSink
		if Options.SinkFastPVPSpeed.Holder then
			Options.SinkFastPVPSpeed.Holder.Visible = isSink
		end
	end

	if Options.RiseFastPVPSpeed then
		Options.RiseFastPVPSpeed.Visible = isRise
		if Options.RiseFastPVPSpeed.Holder then
			Options.RiseFastPVPSpeed.Holder.Visible = isRise
		end
	end

	MoveSwimBoost:Resize()
end

updateSwimBoostVisibility()
task.spawn(function()
	task.wait(0.05)
	if updateSwimBoostVisibility then
		updateSwimBoostVisibility()
	end
end)

local MoveBoatSpeed = Tabs.Movement:AddLeftGroupbox("Boat Speed", "anchor")

MoveBoatSpeed:AddToggle("BoatSpeedToggle", {
	Text = "Boat Speed",
	Default = false,
})

MoveBoatSpeed:AddSlider("BoatSpeedValue", {
	Text = "Boat Speed Value",
	Default = 0.9,
	Min = 0.1,
	Max = 5,
	Rounding = 1,
	Compact = true,
})

do
	local boatPlatform = nil

	local function destroyBoatPlatform()
		if boatPlatform then
			pcall(function() boatPlatform:Destroy() end)
			boatPlatform = nil
		end
	end

	Toggles.BoatSpeedToggle:OnChanged(function()
		local function getCurrentBoat()
			local humanoid = getHumanoid()
			if humanoid and humanoid.SeatPart then
				local folder = humanoid.SeatPart:FindFirstAncestorOfClass("Folder")
				if folder and folder == workspace.boats then
					return humanoid.SeatPart:FindFirstAncestorOfClass("Model")
				end
			end
		end

		local originalY = nil
		local boatCFrame = nil

		local function enableBoatSpeed()
			disconnect("boat_hover")
			originalY = nil
			boatCFrame = nil

			pcall(function()
				boatPlatform = Instance.new("Part")
				boatPlatform.Name = "BoatPlatform"
				boatPlatform.Anchored = true
				boatPlatform.Size = Vector3.new(20, 1, 20)
				boatPlatform.Transparency = 1
				boatPlatform.CanCollide = true
				boatPlatform.CanTouch = false
				boatPlatform.CanQuery = false
				boatPlatform.CastShadow = false
				boatPlatform.Parent = workspace
			end)

			track("boat_hover",
				RunService.Stepped:Connect(
					function()
						local humanoid = getHumanoid()
						local boat = getCurrentBoat()
						if not boat or not humanoid then
							originalY = nil
							boatCFrame = nil
							if boatPlatform then
								boatPlatform.Position = Vector3.new(0, -500, 0)
							end
							return
						end
						if not boatCFrame then
							boatCFrame = boat:GetPivot()
						end
						if not originalY then
							originalY = boatCFrame.Position.Y
						end
						for _, v in pairs(boat:GetDescendants()) do
							if v:IsA("Part") or v:IsA("MeshPart") or v:IsA("Union") then
								v.Velocity = Vector3.new(0, 0, 0)
							end
						end
						boat:PivotTo(boatCFrame)
						local extraY = 0
						if humanoid.Parent:GetAttribute("inTerrain") then
							extraY = 0
						else
							extraY = 0
							boatCFrame =
								boatCFrame - Vector3.new(0, boatCFrame.Position.Y - originalY, 0)
						end
						local speedMult = Options.BoatSpeedValue and Options.BoatSpeedValue.Value or 0.9
						boatCFrame = boatCFrame + Vector3.new(0, extraY, 0) + humanoid.MoveDirection * speedMult

						if boatPlatform then
							local pos = boatCFrame.Position
							boatPlatform.CFrame = CFrame.new(pos.X, pos.Y - 3, pos.Z)
						end
					end
				)
			)
		end

		local function disableBoatSpeed()
			disconnect("boat_hover")
			destroyBoatPlatform()
		end

		if Toggles.BoatSpeedToggle.Value then
			enableBoatSpeed()
		else
			disableBoatSpeed()
		end
	end)
end

do
	local waterPlatform = nil

	local function destroyWaterPlatform()
		disconnect("WalkOnWater")
		if waterPlatform then
			pcall(function() waterPlatform:Destroy() end)
			waterPlatform = nil
		end
	end

	Toggles.WalkOnWater:OnChanged(function()
		destroyWaterPlatform()
		if not Toggles.WalkOnWater.Value then return end

		local HeightLookup = nil
		pcall(function()
			HeightLookup = require(game:GetService("ReplicatedStorage")
				:WaitForChild("Gerstner")
				:WaitForChild("HeightLookup"))
		end)
		if not HeightLookup then
			Library:Notify({ Title = "Walk On Water", Description = "Gerstner HeightLookup not found.", Time = 3 })
			Toggles.WalkOnWater:SetValue(false)
			return
		end

		pcall(function()
			waterPlatform = Instance.new("Part")
			waterPlatform.Name = "WaterPlatform"
			waterPlatform.Anchored = true
			waterPlatform.Size = Vector3.new(6, 1, 6)
			waterPlatform.Transparency = 1
			waterPlatform.CanCollide = true
			waterPlatform.CanTouch = false
			waterPlatform.CanQuery = false
			waterPlatform.Parent = workspace
		end)
		if not waterPlatform then
			Toggles.WalkOnWater:SetValue(false)
			return
		end

		track("WalkOnWater", RunService.Heartbeat:Connect(function()
			local character = getCharacter()
			local hrp = character and character:FindFirstChild("HumanoidRootPart")
			if not hrp or not waterPlatform then return end
			local pos = hrp.Position
			local ok, waterHeight = pcall(function()
				return HeightLookup.Lookup(pos, "PRECISE", false)
			end)
			if ok and typeof(waterHeight) == "number" then
				if pos.Y < waterHeight + 5 then
					waterPlatform.CFrame = CFrame.new(pos.X, waterHeight + 0.5, pos.Z)
				else
					waterPlatform.Position = Vector3.new(0, -500, 0)
				end
			end
		end))
	end)
end

MoveRight:AddToggle("Fly", {
	Text = "Fly",
	Default = false,
})

MoveRight:AddToggle("InvisibleFlyToggle", {
	Text = "Invis Fly",
	Default = false,
})

MoveRight:AddSlider("FlySpeed", {
	Text = "Fly Speed",
	Default = 50,
	Min = 10,
	Max = 150,
	Rounding = 0,
	Compact = true,
})

MoveRight:AddSlider("InvisibleFlySpeedSlider", {
	Text = "Invis Slider",
	Min = 1,
	Max = 15,
	Default = 5,
	Rounding = 1,
	Compact = true,
})

local invisFillLabel = MoveRight:AddLabel("Highlight Fill Color")
invisFillLabel:AddColorPicker("InvisibleFlyFillColor", {
	Default = Color3.fromRGB(0, 255, 0),
	Title = "Invisible Fly Highlight Fill Color",
})

local invisOutlineLabel = MoveRight:AddLabel("Highlight Outline Color")
invisOutlineLabel:AddColorPicker("InvisibleFlyOutlineColor", {
	Default = Color3.fromRGB(255, 255, 255),
	Title = "Invisible Fly Highlight Outline Color",
})

updateFlightVisibility = function()
	local isFly = (Toggles.Fly and Toggles.Fly.Value) or false
	local isInvisFly = (Toggles.InvisibleFlyToggle and Toggles.InvisibleFlyToggle.Value) or false

	if Options.FlySpeed then
		Options.FlySpeed.Visible = isFly
		if Options.FlySpeed.Holder then
			Options.FlySpeed.Holder.Visible = isFly
		end
	end

	if Options.InvisibleFlySpeedSlider then
		Options.InvisibleFlySpeedSlider.Visible = isInvisFly
		if Options.InvisibleFlySpeedSlider.Holder then
			Options.InvisibleFlySpeedSlider.Holder.Visible = isInvisFly
		end
	end

	if invisFillLabel then
		invisFillLabel.Visible = isInvisFly
		if invisFillLabel.Holder then
			invisFillLabel.Holder.Visible = isInvisFly
		end
	end

	if invisOutlineLabel then
		invisOutlineLabel.Visible = isInvisFly
		if invisOutlineLabel.Holder then
			invisOutlineLabel.Holder.Visible = isInvisFly
		end
	end

	MoveRight:Resize()
end

updateFlightVisibility()
task.spawn(function()
	task.wait(0.05)
	if updateFlightVisibility then
		updateFlightVisibility()
	end
end)

local MoveMountAura = Tabs.Movement:AddRightGroupbox("Mount Aura", "paw-print")

MoveMountAura:AddCheckbox("MountSpeedBoost", {
	Text = "Mount Speed",
	Default = false,
})

MoveMountAura:AddCheckbox("MountFly", {
	Text = "Mount Fly",
	Default = false,
})

MoveMountAura:AddSlider("MountSpeedValue", {
	Text = "Mount Speed Value",
	Default = 35,
	Min = 16,
	Max = 100,
	Rounding = 1,
	Compact = true,
})

MoveMountAura:AddSlider("MountFlySpeed", {
	Text = "Mount Fly Speed",
	Default = 50,
	Min = 10,
	Max = 200,
	Rounding = 0,
	Compact = true,
})






local noclipCorePartNames = {
	["HumanoidRootPart"] = true,
	["Head"] = true,
	["Torso"] = true,
	["UpperTorso"] = true,
	["LowerTorso"] = true,
}
local noclipCoreParts = {}

local function updateNoclipParts(character)
	table.clear(noclipCoreParts)
	if not character then return end
	for _, child in ipairs(character:GetChildren()) do
		if child:IsA("BasePart") and noclipCorePartNames[child.Name] then
			table.insert(noclipCoreParts, child)
		end
	end
end

local function restoreCharacterCollisions(character)
	if not character then return end
	for _, part in ipairs(character:GetDescendants()) do
		if part:IsA("BasePart") then
			if part.Name == "Torso" or part.Name == "UpperTorso" or part.Name == "LowerTorso" or part.Name == "Head" then
				part.CanCollide = true
			else
				part.CanCollide = false
			end
		end
	end
end

LocalPlayer.CharacterAdded:Connect(function(char)
	updateNoclipParts(char)
	if not (Toggles.Noclip and Toggles.Noclip.Value) then
		restoreCharacterCollisions(char)
	end
end)
if LocalPlayer.Character then
	updateNoclipParts(LocalPlayer.Character)
	if not (Toggles.Noclip and Toggles.Noclip.Value) then
		restoreCharacterCollisions(LocalPlayer.Character)
	end
end

Toggles.Noclip:OnChanged(function()
	disconnect("Noclip")
	if Toggles.Noclip.Value then
		updateNoclipParts(getCharacter())
		track("Noclip", RunService.Stepped:Connect(function()
			for _, part in ipairs(noclipCoreParts) do
				if part and part.CanCollide then
					part.CanCollide = false
				end
			end
		end))
	else
		restoreCharacterCollisions(getCharacter())
	end
end)




Toggles.SpeedHack:OnChanged(function()
	disconnect("SpeedHack")
	if Toggles.SpeedHack.Value then
		Library:Notify({ Title = "Speed", Description = "Enabled", Time = 2 })
		track("SpeedHack", RunService.Heartbeat:Connect(function(dt)
			if not isAlive() then return end
			local humanoid = getHumanoid()
			local root = getRootPart()
			if not humanoid or not root then return end
			local isSwimming = humanoid:GetState() == Enum.HumanoidStateType.Swimming or (LocalPlayer.Character and LocalPlayer.Character:GetAttribute("inWater"))
			if not isSwimming then
				local factor = Options.SpeedValue.Value - humanoid.WalkSpeed
				if factor > 0 and humanoid.MoveDirection.Magnitude > 0 then
					LocalPlayer.Character:TranslateBy(humanoid.MoveDirection * dt * factor)
				end
			end
		end))
	else
		Library:Notify({ Title = "Speed", Description = "Disabled", Time = 2 })
	end
end)



local originalMountSpeeds = {}

local function getCurrentMount()
	local humanoid = getHumanoid()
	if humanoid and humanoid.SeatPart then
		local seat = humanoid.SeatPart
		local folder = seat:FindFirstAncestorOfClass("Folder")
		if folder and folder == workspace:FindFirstChild("boats") then
			return nil, nil
		end
		local mountModel = seat:FindFirstAncestorOfClass("Model")
		return mountModel, seat
	end
	return nil, nil
end

Toggles.MountSpeedBoost:OnChanged(function()
	disconnect("MountSpeedBoost")
	if Toggles.MountSpeedBoost.Value then
		Library:Notify({ Title = "Mount Speed", Description = "Enabled", Time = 2 })
		track("MountSpeedBoost", RunService.Heartbeat:Connect(function(dt)
			if not isAlive() then return end
			local humanoid = getHumanoid()
			local mountModel, seat = getCurrentMount()
			if not mountModel or not humanoid then return end

			local targetSpeed = (Options.MountSpeedValue and Options.MountSpeedValue.Value) or 35
			local mountHum = mountModel:FindFirstChildOfClass("Humanoid")
			local mountRoot = mountModel.PrimaryPart or mountModel:FindFirstChild("HumanoidRootPart") or seat

			if mountHum then
				if not originalMountSpeeds[mountHum] then
					originalMountSpeeds[mountHum] = mountHum.WalkSpeed
				end
				if mountHum.WalkSpeed ~= targetSpeed then
					mountHum.WalkSpeed = targetSpeed
				end
			end

			if seat and seat:IsA("VehicleSeat") then
				if seat.MaxSpeed < targetSpeed then
					seat.MaxSpeed = targetSpeed
				end
			end

			local moveDir = humanoid.MoveDirection
			if moveDir.Magnitude > 0 and mountRoot then
				local currentSpeed = (mountHum and mountHum.WalkSpeed) or 16
				local factor = targetSpeed - currentSpeed
				if factor > 0 then
					mountModel:TranslateBy(moveDir * dt * factor)
				end
			end
		end))
	else
		for hum, origSpeed in pairs(originalMountSpeeds) do
			if hum and hum.Parent then
				pcall(function() hum.WalkSpeed = origSpeed end)
			end
		end
		table.clear(originalMountSpeeds)
		Library:Notify({ Title = "Mount Speed", Description = "Disabled", Time = 2 })
	end
end)

local function isSpeedBoostSlotAllowed(slotOption)
	if not slotOption then return false end
	local val = slotOption.Value
	if val == nil then return false end

	if typeof(val) == "table" then
		for slotKey, isSelected in pairs(val) do
			if isSelected == true or (typeof(slotKey) == "number" and typeof(isSelected) == "string") then
				local targetSlot = (isSelected == true) and slotKey or isSelected
				if isHoldingSelectedSlot(targetSlot) then
					return true
				end
			end
		end
		return false
	elseif typeof(val) == "string" or typeof(val) == "number" then
		return isHoldingSelectedSlot(val)
	end

	return false
end

Toggles.PlusSpeedBoost:OnChanged(function()
	disconnect("PlusSpeedBoost")
	if updatePVPModulesVisibility then
		updatePVPModulesVisibility()
	end
	if Toggles.PlusSpeedBoost.Value then
		Library:Notify({ Title = "+ Speed Boost", Description = "Enabled", Time = 2 })
		track("PlusSpeedBoost", RunService.Heartbeat:Connect(function(dt)
			if not isAlive() then return end
			if Toggles.SpeedHack and Toggles.SpeedHack.Value then return end
			local humanoid = getHumanoid()
			local root = getRootPart()
			if not humanoid or not root then return end
			local isSwimming = humanoid:GetState() == Enum.HumanoidStateType.Swimming or (LocalPlayer.Character and LocalPlayer.Character:GetAttribute("inWater"))
			if not isSwimming then
				if isSpeedBoostSlotAllowed(Options.SpeedBoostSlot) then
					local targetSpeed = Options.SpeedBoostValue and Options.SpeedBoostValue.Value or 16
					local factor = targetSpeed - humanoid.WalkSpeed
					if factor > 0 and humanoid.MoveDirection.Magnitude > 0 then
						LocalPlayer.Character:TranslateBy(humanoid.MoveDirection * dt * factor)
					end
				end
			end
		end))
	else
		Library:Notify({ Title = "+ Speed Boost", Description = "Disabled", Time = 2 })
	end
end)



Toggles.SwimBoost:OnChanged(function()
	disconnect("SwimBoost")
	if updateSwimBoostVisibility then
		updateSwimBoostVisibility()
	end
	if Toggles.SwimBoost.Value then
		Library:Notify({ Title = "Swim Boost", Description = "Enabled", Time = 2 })
		track("SwimBoost", RunService.Heartbeat:Connect(function(dt)
			if not isAlive() then return end
			local humanoid = getHumanoid()
			local root = getRootPart()
			if not humanoid or not root then return end
			local isSwimming = humanoid:GetState() == Enum.HumanoidStateType.Swimming or (LocalPlayer.Character and LocalPlayer.Character:GetAttribute("inWater"))
			if isSwimming then
				local factor = (Options.SwimBoostValue and Options.SwimBoostValue.Value or 30) - humanoid.WalkSpeed
				if factor > 0 and humanoid.MoveDirection.Magnitude > 0 then
					LocalPlayer.Character:TranslateBy(humanoid.MoveDirection * dt * factor)
				end
			end
		end))
	else
		Library:Notify({ Title = "Swim Boost", Description = "Disabled", Time = 2 })
	end
end)

Toggles.SwimSlotBoost:OnChanged(function()
	disconnect("SwimSlotBoost")
	if updateSwimBoostVisibility then
		updateSwimBoostVisibility()
	end
	if Toggles.SwimSlotBoost.Value then
		Library:Notify({ Title = "Swim Slot Boost", Description = "Enabled", Time = 2 })
		track("SwimSlotBoost", RunService.Heartbeat:Connect(function(dt)
			if not isAlive() then return end
			if Toggles.SwimBoost and Toggles.SwimBoost.Value then return end
			local humanoid = getHumanoid()
			local root = getRootPart()
			if not humanoid or not root then return end
			local isSwimming = humanoid:GetState() == Enum.HumanoidStateType.Swimming or (LocalPlayer.Character and LocalPlayer.Character:GetAttribute("inWater"))
			if isSwimming then
				if isSpeedBoostSlotAllowed(Options.SwimSlotBoostSlot) then
					local targetSpeed = Options.SwimBoostValue and Options.SwimBoostValue.Value or 30
					local factor = targetSpeed - humanoid.WalkSpeed
					if factor > 0 and humanoid.MoveDirection.Magnitude > 0 then
						LocalPlayer.Character:TranslateBy(humanoid.MoveDirection * dt * factor)
					end
				end
			end
		end))
	else
		Library:Notify({ Title = "Swim Slot Boost", Description = "Disabled", Time = 2 })
	end
end)

Toggles.SinkFastPVP:OnChanged(function()
	if updateSwimBoostVisibility then
		updateSwimBoostVisibility()
	end
	disconnect("SinkFastPVP")
	if Toggles.SinkFastPVP.Value then
		track("SinkFastPVP", RunService.Heartbeat:Connect(function()
			local character = getCharacter()
			local root = character and character:FindFirstChild("HumanoidRootPart")
			local humanoid = character and character:FindFirstChildOfClass("Humanoid")
			if root and humanoid then
				local isSwimming = humanoid:GetState() == Enum.HumanoidStateType.Swimming or character:GetAttribute("inWater")
				if isSwimming then
					local cam = workspace.CurrentCamera
					local lookY = cam and cam.CFrame.LookVector.Y or 0
					if lookY <= -0.9 then
						local speed = (Options.SinkFastPVPSpeed and Options.SinkFastPVPSpeed.Value) or 60
						root.AssemblyLinearVelocity = Vector3.new(
							root.AssemblyLinearVelocity.X,
							-speed,
							root.AssemblyLinearVelocity.Z
						)
					end
				end
			end
		end))
		Library:Notify({ Title = "+ Sink Fast PVP", Description = "Enabled", Time = 2 })
	else
		Library:Notify({ Title = "+ Sink Fast PVP", Description = "Disabled", Time = 2 })
	end
end)

Toggles.RiseFastPVP:OnChanged(function()
	if updateSwimBoostVisibility then
		updateSwimBoostVisibility()
	end
	disconnect("RiseFastPVP")
	if Toggles.RiseFastPVP.Value then
		track("RiseFastPVP", RunService.Heartbeat:Connect(function()
			local character = getCharacter()
			local root = character and character:FindFirstChild("HumanoidRootPart")
			local humanoid = character and character:FindFirstChildOfClass("Humanoid")
			if root and humanoid then
				local isSwimming = humanoid:GetState() == Enum.HumanoidStateType.Swimming or character:GetAttribute("inWater")
				if isSwimming then
					local cam = workspace.CurrentCamera
					local lookY = cam and cam.CFrame.LookVector.Y or 0
					if lookY >= 0.85 then
						local speed = (Options.RiseFastPVPSpeed and Options.RiseFastPVPSpeed.Value) or 60
						root.AssemblyLinearVelocity = Vector3.new(
							root.AssemblyLinearVelocity.X,
							speed,
							root.AssemblyLinearVelocity.Z
						)
					end
				end
			end
		end))
		Library:Notify({ Title = "+ Rise Fast PVP", Description = "Enabled", Time = 2 })
	else
		Library:Notify({ Title = "+ Rise Fast PVP", Description = "Disabled", Time = 2 })
	end
end)

local flyKeys = { W = false, A = false, S = false, D = false, Space = false, LeftControl = false, LeftShift = false }
local flyInputBegan = UserInputService.InputBegan:Connect(function(input, processed)
	if processed then
		return
	end
	if flyKeys[input.KeyCode.Name] ~= nil then
		flyKeys[input.KeyCode.Name] = true
	end
end)
local flyInputEnded = UserInputService.InputEnded:Connect(function(input)
	if flyKeys[input.KeyCode.Name] ~= nil then
		flyKeys[input.KeyCode.Name] = false
	end
end)
track("FlyInputBegan", flyInputBegan)
track("FlyInputEnded", flyInputEnded)

Toggles.Fly:OnChanged(function()
	if updateFlightVisibility then
		updateFlightVisibility()
	end
	disconnect("Fly")
	if Toggles.Fly.Value then
		track("Fly", RunService.Heartbeat:Connect(function()
			if not isAlive() then
				return
			end
			local root = getRootPart()
			if not root then
				return
			end
			local cam = workspace.CurrentCamera
			local direction = Vector3.zero
			if flyKeys.W then
				direction += cam.CFrame.LookVector
			end
			if flyKeys.S then
				direction -= cam.CFrame.LookVector
			end
			if flyKeys.A then
				direction -= cam.CFrame.RightVector
			end
			if flyKeys.D then
				direction += cam.CFrame.RightVector
			end
			if flyKeys.Space then
				direction += Vector3.yAxis
			end
			if flyKeys.LeftControl or flyKeys.LeftShift then
				direction -= Vector3.yAxis
			end
			if direction.Magnitude > 0 then
				root.Velocity = direction.Unit * Options.FlySpeed.Value
			else
				root.Velocity = Vector3.zero
			end
		end))
	end
end)

Toggles.MountFly:OnChanged(function()
	disconnect("MountFly")
	if Toggles.MountFly.Value then
		Library:Notify({ Title = "Mount Fly", Description = "Enabled", Time = 2 })
		track("MountFly", RunService.Heartbeat:Connect(function()
			if not isAlive() then return end
			local humanoid = getHumanoid()
			local mountModel, seat = getCurrentMount()
			if not mountModel or not humanoid then return end

			local mountRoot = mountModel.PrimaryPart or mountModel:FindFirstChild("HumanoidRootPart") or seat
			if not mountRoot then return end

			local flySpeed = (Options.MountFlySpeed and Options.MountFlySpeed.Value) or 50
			local cam = workspace.CurrentCamera
			local direction = Vector3.zero

			if flyKeys.W then direction += cam.CFrame.LookVector end
			if flyKeys.S then direction -= cam.CFrame.LookVector end
			if flyKeys.A then direction -= cam.CFrame.RightVector end
			if flyKeys.D then direction += cam.CFrame.RightVector end
			if flyKeys.Space then direction += Vector3.yAxis end
			if flyKeys.LeftControl or flyKeys.LeftShift then direction -= Vector3.yAxis end

			if direction.Magnitude == 0 and humanoid.MoveDirection.Magnitude > 0 then
				direction += humanoid.MoveDirection
			end

			if direction.Magnitude > 0 then
				mountRoot.AssemblyLinearVelocity = direction.Unit * flySpeed
			else
				mountRoot.AssemblyLinearVelocity = Vector3.zero
			end
			mountRoot.AssemblyAngularVelocity = Vector3.zero
		end))
	else
		local mountModel, seat = getCurrentMount()
		if mountModel then
			local mountRoot = mountModel.PrimaryPart or mountModel:FindFirstChild("HumanoidRootPart") or seat
			if mountRoot then
				mountRoot.AssemblyLinearVelocity = Vector3.zero
				mountRoot.AssemblyAngularVelocity = Vector3.zero
			end
		end
		Library:Notify({ Title = "Mount Fly", Description = "Disabled", Time = 2 })
	end
end)

local antiAfkConn = nil

Toggles.AntiAFK:OnChanged(function()
	if antiAfkConn then
		antiAfkConn:Disconnect()
		antiAfkConn = nil
	end
	if Toggles.AntiAFK.Value then
		local virtualUser = game:GetService("VirtualUser")
		antiAfkConn = LocalPlayer.Idled:Connect(function()
			pcall(function()
				virtualUser:CaptureController()
				virtualUser:ClickButton2(Vector2.zero)
				Library:Notify({ Title = "Anti-AFK", Description = "Prevented AFK disconnect!", Time = 2 })
			end)
		end)
		Library:Notify({ Title = "Anti-AFK", Description = "Anti-AFK Enabled", Time = 2 })
	end
end)

Toggles.SwingSpeedToggle:OnChanged(function()
	if updatePVPModulesVisibility then
		updatePVPModulesVisibility()
	end
	if Toggles.SwingSpeedToggle.Value then
		Library:Notify({ Title = "Swing Speed", Description = "Enabled", Time = 2 })
	end
	local char = getCharacter()
	local hum = char and char:FindFirstChildOfClass("Humanoid")
	local animator = hum and hum:FindFirstChild("Animator")
	if animator then
		for _, trackObj in ipairs(animator:GetPlayingAnimationTracks()) do
			local targetSpeed = Toggles.SwingSpeedToggle.Value and Options.SwingSpeedVal.Value or 1
			trackObj:AdjustSpeed(targetSpeed)
		end
	end
end)

Options.SwingSpeedVal:OnChanged(function()
	if Toggles.SwingSpeedToggle.Value then
		local char = getCharacter()
		local hum = char and char:FindFirstChildOfClass("Humanoid")
		local animator = hum and hum:FindFirstChild("Animator")
		if animator then
			for _, trackObj in ipairs(animator:GetPlayingAnimationTracks()) do
				trackObj:AdjustSpeed(Options.SwingSpeedVal.Value)
			end
		end
	end
end)

local function applyAnimationSpeed(trackObj)
	local targetSpeed = (Toggles.SwingSpeedToggle and Toggles.SwingSpeedToggle.Value) and (Options.SwingSpeedVal and Options.SwingSpeedVal.Value or 1) or 1
	trackObj:AdjustSpeed(targetSpeed)
end

local function setupAnimationSpeedHacks(char)
	local hum = char:WaitForChild("Humanoid", 10)
	local animator = hum and hum:WaitForChild("Animator", 10)
	if animator then
		disconnect("AnimSpeedPlayed")
		track("AnimSpeedPlayed", animator.AnimationPlayed:Connect(function(trackObj)
			local adjusting = false
			local function enforceSpeed()
				if adjusting then return end
				local targetSpeed = (Toggles.SwingSpeedToggle and Toggles.SwingSpeedToggle.Value) and (Options.SwingSpeedVal and Options.SwingSpeedVal.Value or 1) or 1
				if math.abs(trackObj.Speed - targetSpeed) > 0.01 then
					adjusting = true
					trackObj:AdjustSpeed(targetSpeed)
					adjusting = false
				end
			end
			enforceSpeed()
			trackObj:GetPropertyChangedSignal("Speed"):Connect(enforceSpeed)
		end))
		for _, trackObj in ipairs(animator:GetPlayingAnimationTracks()) do
			applyAnimationSpeed(trackObj)
		end
	end
end

track("SwingCharacterAdded", LocalPlayer.CharacterAdded:Connect(function(char)
	setupAnimationSpeedHacks(char)
end))

if LocalPlayer.Character then
	setupAnimationSpeedHacks(LocalPlayer.Character)
end

-- ==========================================
-- FARMING
-- ==========================================
local function makeAuraHighlight(defaultColor)
	local h = Instance.new("Highlight")
	h.FillColor = defaultColor or Color3.fromRGB(255, 200, 0)
	h.OutlineColor = Color3.fromRGB(255, 255, 255)
	h.FillTransparency = 0.65
	h.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
	h.Enabled = false
	h.Parent = workspace
	return h
end

-- ==========================================
local BossFarm = Tabs.Farming:AddLeftGroupbox("Boss Farm", "swords")

BossFarm:AddCheckbox("TitanAura", {
	Text = "Titan Aura",
	Default = false,
})

BossFarm:AddCheckbox("SamuraiAura", {
	Text = "Samurai Aura",
	Default = false,
})

BossFarm:AddCheckbox("JuggernautAura", {
	Text = "Juggernaut Aura",
	Default = false,
})

-- ==========================================
local FarmMine = Tabs.Farming:AddLeftGroupbox("Auto Mine", "gem")

FarmMine:AddToggle("AutoMine", {
	Text = "Auto Mine",
	Default = false,
})

FarmMine:AddSlider("AutoMineRange", {
	Text = "Range",
	Default = 30,
	Min = 5,
	Max = 60,
	Rounding = 1,
	Compact = true,
})

FarmMine:AddDropdown("AutoMineSlot", {
	Text = "Tool Slot",
	Values = {"1","2","3","4","5","6","7","8","9","10"},
	Default = "1",
})

FarmMine:AddCheckbox("HighlightMine", {
	Text = "Highlight Target",
	Default = true,
}):AddColorPicker("HighlightMineColor", {
	Default = Color3.fromRGB(255, 200, 0),
	Title = "Highlight Target Color",
})

-- ==========================================
local FarmChop = Tabs.Farming:AddLeftGroupbox("Auto Chop", "axe")

FarmChop:AddToggle("AutoChop", {
	Text = "Auto Chop",
	Default = false,
})

FarmChop:AddSlider("AutoChopRange", {
	Text = "Range",
	Default = 30,
	Min = 5,
	Max = 60,
	Rounding = 1,
	Compact = true,
})

FarmChop:AddDropdown("AutoChopSlot", {
	Text = "Tool Slot",
	Values = {"1","2","3","4","5","6","7","8","9","10"},
	Default = "1",
})

FarmChop:AddCheckbox("HighlightChop", {
	Text = "Highlight Target",
	Default = true,
}):AddColorPicker("HighlightChopColor", {
	Default = Color3.fromRGB(255, 200, 0),
	Title = "Highlight Target Color",
})

-- ==========================================
local OreESPGroup = Tabs.Farming:AddLeftGroupbox("Ore ESP", "gem")

OreESPGroup:AddToggle("OreESPToggle", {
	Text = "Ore ESP",
	Default = false,
})

OreESPGroup:AddCheckbox("OreESPRemoveNames", {
	Text = "+ Remove Names",
	Default = false,
})

OreESPGroup:AddCheckbox("OreESPHighlights", {
	Text = "Ore Highlights (Chams)",
	Default = false,
})

OreESPGroup:AddSlider("OreESPDistance", {
	Text = "Max Distance",
	Default = 500,
	Min = 50,
	Max = 1500,
	Rounding = 10,
	Compact = true,
})

-- ==========================================
local FarmAI = Tabs.Farming:AddRightGroupbox("AI Aura", "zap")

FarmAI:AddToggle("AiAura", {
	Text = "AI Aura",
	Default = false,
})

FarmAI:AddDropdown("AiAuraSlot", {
	Text = "Tool Slot",
	Values = {"1","2","3","4","5","6","7","8","9","10"},
	Default = "1",
})

FarmAI:AddSlider("AiAuraRange", {
	Text = "Range",
	Default = 30,
	Min = 5,
	Max = 60,
	Rounding = 1,
	Compact = true,
})

FarmAI:AddCheckbox("HighlightAI", {
	Text = "Highlight Target",
	Default = true,
}):AddColorPicker("HighlightAIColor", {
	Default = Color3.fromRGB(255, 200, 0),
	Title = "Highlight Target Color",
})

-- ==========================================
local OreFarm = Tabs.Farming:AddRightGroupbox("Ore Farm", "gem")

OreFarm:AddButton({
	Text = "Reset Character",
	Func = function()
		local root = getRootPart()
		if root then
			lastDeathPosition = root.Position
		end

		local remoteInterface = ReplicatedStorage:FindFirstChild("remoteInterface")
		if remoteInterface then
			local characterFolder = remoteInterface:FindFirstChild("character")
			if characterFolder then
				local resetRemote = characterFolder:FindFirstChild("reset")
				if resetRemote then
					pcall(function()
						resetRemote:InvokeServer()
					end)
				end
			end
		end
	end,
})

local goldLocations = {
	{ name = "Gold 1",  pos = Vector3.new(1732.94, 113.13, 2295.19) },
	{ name = "Gold 2",  pos = Vector3.new(1447.98, 39.83,  2400.27) },
	{ name = "Gold 3",  pos = Vector3.new(1837.06, 29.36,  2471.74) },
	{ name = "Gold 4",  pos = Vector3.new(1177.61, 29.01,  -609.47) },
	{ name = "Gold 5",  pos = Vector3.new(1188.42, 20.58,  -563.03) },
	{ name = "Gold 6",  pos = Vector3.new(-651.84, 226.09, 654.28)  },
	{ name = "Gold 7",  pos = Vector3.new(-540.20, 76.40,  297.97)  },
	{ name = "Gold 8",  pos = Vector3.new(-2202.22, 51.01, 22.08)   },
	{ name = "Gold 9",  pos = Vector3.new(-1182.86, 54.42, 6608.34) },
	{ name = "Gold 10", pos = Vector3.new(-2015.67, 30.73, -39.95)  },
	{ name = "Gold 11", pos = Vector3.new(-912.17, 125.72, -408.72) },
	{ name = "Gold 12", pos = Vector3.new(-264.65, 47.32,  1427.81) },
    { name = "Gold 13", pos = Vector3.new(245.51,  45.00,  460.77)  },
	{ name = "Gold 14", pos = Vector3.new(-1261.77, 43.72, 6281.94) },
	{ name = "Gold 15", pos = Vector3.new(-1765.08, 95.91, 7158.15) },
	{ name = "Gold 16", pos = Vector3.new(1686.60, 41.64, -917.39)  },
	{ name = "Gold 17", pos = Vector3.new(1566.16, 23.19, -946.35)  },
	{ name = "Gold 18", pos = Vector3.new(252.14, 22.06, 811.69)    },
	{ name = "Gold 19", pos = Vector3.new(50.11, 125.73, -1040.40)  },
	{ name = "Gold 20", pos = Vector3.new(462.81, 100.69, -455.26)  },
	{ name = "Coal 1",  pos = Vector3.new(1130.93, 24.94, -601.55)  },
	{ name = "Coal 2",  pos = Vector3.new(1319.54, 25.26, -1129.08) },
	{ name = "Coal 3",  pos = Vector3.new(-681.19, 173.56, 657.90)  },
	{ name = "Coal 4",  pos = Vector3.new(-886.51, 75.31, 192.70)   },
	{ name = "Coal 5",  pos = Vector3.new(-1351.22, 31.18, -167.99) },
	{ name = "Coal 6",  pos = Vector3.new(-1872.79, 30.78, 194.66)  },
	{ name = "Coal 7",  pos = Vector3.new(-2255.10, 29.20, 964.32)  },
	{ name = "Coal 8",  pos = Vector3.new(331.57, 47.36, 492.03)    },
	{ name = "Coal 9",  pos = Vector3.new(264.71, 27.19, 267.24)    },
	{ name = "Coal 10", pos = Vector3.new(-680.98, 26.07, 254.45)   },
	{ name = "Coal 11", pos = Vector3.new(182.10, 25.26, -934.94)   },
	{ name = "Coal 12", pos = Vector3.new(11.22, 36.86, -1008.32)   },
}

local function filterLocations(prefix)
	local names = {}
	for _, loc in ipairs(goldLocations) do
		if loc.name:sub(1, #prefix) == prefix then
			table.insert(names, loc.name)
		end
	end
	return names
end

OreFarm:AddDropdown("SelectOreDropdown", {
	Text = "Select Ore",
	Values = { "Gold", "Coal" },
	Default = "Gold",
})

OreFarm:AddDropdown("GoldLocationsDropdown", {
	Text = "Select Ore Location",
	Values = filterLocations("Gold"),
	Default = "Gold 1",
})

Options.SelectOreDropdown:OnChanged(function()
	local value = Options.SelectOreDropdown.Value
	local filtered = filterLocations(value)
	Options.GoldLocationsDropdown:SetValues(filtered)
	if value == "Gold" then
		Options.GoldLocationsDropdown:SetValue("Gold 1")
	elseif value == "Coal" then
		Options.GoldLocationsDropdown:SetValue("Coal 1")
	end
end)

OreFarm:AddButton({
	Text = "Teleport to Selected",
	Func = function()
           local selected = Options.GoldLocationsDropdown.Value
           local targetPos = nil
           for _, loc in ipairs(goldLocations) do
                   if loc.name == selected then
                           targetPos = loc.pos
                           break
                   end
           end
           if targetPos then
                   local root = getRootPart()
                   if root then
                           root.CFrame = CFrame.new(targetPos)
                           Library:Notify({ Title = "Teleport", Description = "Teleported to " .. selected, Time = 1.5 })
                   else
                           Library:Notify({ Title = "Teleport", Description = "Character not found.", Time = 3 })
                   end
           end
   end,
})

-- ==========================================
-- Aura highlights (one per aura type, created after makeAuraHighlight is defined)
local hlMine = makeAuraHighlight(Options.HighlightMineColor and Options.HighlightMineColor.Value)
local hlChop = makeAuraHighlight(Options.HighlightChopColor and Options.HighlightChopColor.Value)
local hlAI   = makeAuraHighlight(Options.HighlightAIColor and Options.HighlightAIColor.Value)

if Options.HighlightMineColor then
	Options.HighlightMineColor:OnChanged(function()
		if hlMine then
			hlMine.FillColor = Options.HighlightMineColor.Value
		end
	end)
end

if Options.HighlightChopColor then
	Options.HighlightChopColor:OnChanged(function()
		if hlChop then
			hlChop.FillColor = Options.HighlightChopColor.Value
		end
	end)
end

if Options.HighlightAIColor then
	Options.HighlightAIColor:OnChanged(function()
		if hlAI then
			hlAI.FillColor = Options.HighlightAIColor.Value
		end
	end)
end

Toggles.HighlightMine:OnChanged(function()
	if not Toggles.HighlightMine.Value then
		updateHighlight(hlMine, nil, false)
	end
end)
Toggles.HighlightChop:OnChanged(function()
	if not Toggles.HighlightChop.Value then
		updateHighlight(hlChop, nil, false)
	end
end)
Toggles.HighlightAI:OnChanged(function()
	if not Toggles.HighlightAI.Value then
		updateHighlight(hlAI, nil, false)
	end
end)

-- ==========================================
local isAutoMineRunning = false
local isAutoChopRunning = false
local isAiAuraRunning   = false
local lastAutoMineHit   = 0
local lastAutoChopHit   = 0

local function mineObject(obj)
	local slot = tonumber(Options.AutoMineSlot.Value) or 1
	if obj and obj.PrimaryPart then
		updateHighlight(hlMine, obj, Toggles.HighlightMine.Value)
		pcall(function()
			TSG.MineRemote:FireServer(slot, obj, CFrame.new(obj.PrimaryPart.Position))
		end)
	end
end

local function autoMine()
	if not isAlive() or not isAutoMineRunning then return end
	if tick() - lastAutoMineHit < 0.2 then return end

	local root = getRootPart()
	if not root then return end
	local folder = workspace:FindFirstChild("worldResources") and workspace.worldResources:FindFirstChild("mineable")
	if not folder then return end
	local maxRange = (Options.AutoMineRange and Options.AutoMineRange.Value) or 30
	local closest, dist = nil, maxRange
	for _, subfolder in ipairs(folder:GetChildren()) do
		if subfolder:IsA("Folder") then
			for _, obj in ipairs(subfolder:GetChildren()) do
				if obj.PrimaryPart then
					local d = (root.Position - obj.PrimaryPart.Position).Magnitude
					if d < dist then
						closest, dist = obj, d
					end
				end
			end
		end
	end
	if closest then
		lastAutoMineHit = tick()
		mineObject(closest)
	else
		updateHighlight(hlMine, nil, false)
	end
end

Toggles.AutoMine:OnChanged(function()
	disconnect("AutoMine")
	updateHighlight(hlMine, nil, false)
	if Toggles.AutoMine.Value then
		if not TSG.MineRemote then
			Library:Notify({ Title = "Auto Mine", Description = "Mine remote not found.", Time = 4 })
			Toggles.AutoMine:SetValue(false)
			return
		end
		isAutoMineRunning = true
		track("AutoMine", RunService.Heartbeat:Connect(function()
			if not isAlive() or not isAutoMineRunning then return end
			autoMine()
		end))
		Library:Notify({ Title = "Auto Mine", Description = "Enabled", Time = 2 })
	else
		isAutoMineRunning = false
		updateHighlight(hlMine, nil, false)
	end
end)

-- ==========================================
local function chopObject(obj)
	local slot = tonumber(Options.AutoChopSlot.Value) or 1
	local part = getChopTargetPart(obj)
	if part then
		updateHighlight(hlChop, obj, Toggles.HighlightChop.Value)
		pcall(function()
			TSG.ChopRemote:FireServer(slot, obj, part.CFrame)
		end)
	end
end

local function autoChop()
	if not isAlive() or not isAutoChopRunning then return end
	if tick() - lastAutoChopHit < 0.2 then return end

	local root = getRootPart()
	if not root then return end
	local folder = workspace:FindFirstChild("worldResources") and workspace.worldResources:FindFirstChild("choppable")
	if not folder then return end
	local maxRange = (Options.AutoChopRange and Options.AutoChopRange.Value) or 30
	local closest, dist = nil, maxRange
	for _, subfolder in ipairs(folder:GetChildren()) do
		if subfolder:IsA("Folder") then
			for _, obj in ipairs(subfolder:GetChildren()) do
				local part = getChopTargetPart(obj)
				if part then
					local d = getFlatDistance(root.Position, part.Position)
					if d < dist then
						closest, dist = obj, d
					end
				end
			end
		end
	end
	if closest then
		lastAutoChopHit = tick()
		chopObject(closest)
	else
		updateHighlight(hlChop, nil, false)
	end
end

Toggles.AutoChop:OnChanged(function()
	disconnect("AutoChop")
	updateHighlight(hlChop, nil, false)
	if Toggles.AutoChop.Value then
		if not TSG.ChopRemote then
			Library:Notify({ Title = "Auto Chop", Description = "Chop remote not found.", Time = 4 })
			Toggles.AutoChop:SetValue(false)
			return
		end
		isAutoChopRunning = true
		track("AutoChop", RunService.Heartbeat:Connect(function()
			if not isAlive() or not isAutoChopRunning then return end
			autoChop()
		end))
		Library:Notify({ Title = "Auto Chop", Description = "Enabled", Time = 2 })
	else
		isAutoChopRunning = false
		updateHighlight(hlChop, nil, false)
	end
end)

-- ==========================================
local lastAiAuraHit = 0

local function aiAuraLoop()
	if not isAlive() or tick() - lastAiAuraHit < 0.25 then return end
	local root = getRootPart()
	if not root then return end

	local range = Options.AiAuraRange.Value
	local closest, dist = nil, range
	local pos = root.Position

	-- Check AI_Server
	local aiServer = workspace:FindFirstChild("AI_Server")
	if aiServer then
		for _, ai in ipairs(aiServer:GetChildren()) do
			local aiHRP = ai:FindFirstChild("HumanoidRootPart") or ai.PrimaryPart
			local hum = ai:FindFirstChildOfClass("Humanoid")
			if ai:IsA("Model") and aiHRP and (not hum or hum.Health > 0) then
				local d = (aiHRP.Position - pos).Magnitude
				if d < dist then
					closest, dist = ai, d
				end
			end
		end
	end

	-- Check AI_Client (like KillAura does)
	local aiClient = workspace:FindFirstChild("AI_Client")
	if aiClient then
		for _, ai in ipairs(aiClient:GetChildren()) do
			local aiHRP = ai:FindFirstChild("HumanoidRootPart") or ai.PrimaryPart
			local hum = ai:FindFirstChildOfClass("Humanoid")
			if ai:IsA("Model") and aiHRP and (not hum or hum.Health > 0) then
				local d = (aiHRP.Position - pos).Magnitude
				if d < dist then
					closest, dist = ai, d
				end
			end
		end
	end

	updateHighlight(hlAI, closest, Toggles.HighlightAI.Value)
	if not closest then
		return
	end

	local slot = tonumber(Options.AiAuraSlot.Value) or 1
	lastAiAuraHit = tick()

	attackNPC(slot, closest) -- Use attackNPC for proper server model handling
end

Toggles.AiAura:OnChanged(function()
	disconnect("AiAura")
	updateHighlight(hlAI, nil, false)
	if Toggles.AiAura.Value then
		if not TSG.MeleeAI and not TSG.MeleeAnimalRemote then
			Library:Notify({ Title = "AI Aura", Description = "AI remote not found.", Time = 4 })
			Toggles.AiAura:SetValue(false)
			return
		end
		isAiAuraRunning = true
		track("AiAura", RunService.Heartbeat:Connect(function()
			if not isAlive() or not isAiAuraRunning then return end
			aiAuraLoop()
		end))
		Library:Notify({ Title = "AI Aura", Description = "Enabled", Time = 2 })
	else
		isAiAuraRunning = false
		updateHighlight(hlAI, nil, false)
	end
end)

-- ==========================================
-- Ore ESP (reads ore names from workspace.worldResources.mineable, per-ore filters)
local oreESP = {
	highlights = {},
	oreToggles = {},
	oreColors = {},
	oreColorPickers = {},
	fixedOreColors = {
		["Coal"]    = Color3.fromRGB(0, 0, 0),
		["Ice"]     = Color3.fromRGB(150, 210, 255),
		["Bluesteel"] = Color3.fromRGB(40, 120, 255),
		["Copper"]  = Color3.fromRGB(255, 140, 60),
		["Coral"]   = Color3.fromRGB(160, 40, 220),
		["Gold"]    = Color3.fromRGB(255, 190, 50),
		["Iron"]    = Color3.fromRGB(230, 232, 238),
		["Stone"]   = Color3.fromRGB(140, 140, 146),
	},
	orePalette = {
		Color3.fromRGB(255, 80, 80),
		Color3.fromRGB(80, 255, 120),
		Color3.fromRGB(80, 160, 255),
		Color3.fromRGB(255, 220, 80),
		Color3.fromRGB(220, 100, 255),
		Color3.fromRGB(255, 160, 80),
		Color3.fromRGB(80, 255, 220),
		Color3.fromRGB(255, 100, 180),
		Color3.fromRGB(180, 255, 80),
		Color3.fromRGB(160, 160, 255),
		Color3.fromRGB(255, 140, 120),
		Color3.fromRGB(120, 220, 255),
	},
}

local function getOreColor(oreName, index)
	if oreESP.oreColors[oreName] then
		return oreESP.oreColors[oreName]
	end
	if oreESP.fixedOreColors[oreName] then
		oreESP.oreColors[oreName] = oreESP.fixedOreColors[oreName]
		return oreESP.oreColors[oreName]
	end
	local palette = oreESP.orePalette
	local hue = (string.byte(oreName, 1) or 0) * 3.7 + (index or 0) * 29
	hue = hue % 360 / 360
	local c = Color3.fromHSV(hue, 0.75, 0.95)
	oreESP.oreColors[oreName] = c
	return c
end

local function clearOreESPHighlights()
	for _, entry in pairs(oreESP.highlights) do
		pcall(function() entry.hl:Destroy() end)
		pcall(function() entry.bill:Destroy() end)
	end
	table.clear(oreESP.highlights)
end

local function isOreFilterEnabled(oreName)
	local t = oreESP.oreToggles[oreName]
	if t == nil then return true end
	return t
end

local lastOreESPUpdate = 0

local function oreESPLoop()
	local now = tick()
	if now - lastOreESPUpdate < 0.5 then return end
	lastOreESPUpdate = now

	local folder = workspace:FindFirstChild("worldResources") and workspace.worldResources:FindFirstChild("mineable")
	if not folder then return end

	local root = getRootPart()
	local rootPos = root and root.Position
	if not rootPos then return end

	local maxDist = (Options and Options.OreESPDistance and Options.OreESPDistance.Value) or 500
	local showNames = not (Toggles and Toggles.OreESPRemoveNames and Toggles.OreESPRemoveNames.Value)
	local chamsEnabled = (Toggles and Toggles.OreESPHighlights and Toggles.OreESPHighlights.Value) ~= false
	local seen = {}
	local candidateHighlights = {}

	for _, chunkFolder in ipairs(folder:GetChildren()) do
		if not chunkFolder:IsA("Folder") then continue end
		for _, obj in ipairs(chunkFolder:GetChildren()) do
			if not obj or not obj.Parent then continue end
			local oreName = obj.Name or "Unknown"
			local enabled = isOreFilterEnabled(oreName)

			local anchor = obj:IsA("Model") and (obj.PrimaryPart or obj:FindFirstChildWhichIsA("BasePart")) or (obj:IsA("BasePart") and obj)
			local dist = anchor and (anchor.Position - rootPos).Magnitude or 9999

			-- Distance and filter culling: Skip processing if disabled or out of range
			if not enabled or dist > maxDist then
				local existing = oreESP.highlights[obj]
				if existing then
					if existing.hl and existing.hl.Enabled then existing.hl.Enabled = false end
					if existing.bill and existing.bill.Enabled then existing.bill.Enabled = false end
				end
				continue
			end

			seen[obj] = oreName
			local oreColor = getOreColor(oreName)
			local entry = oreESP.highlights[obj]

			if not entry then
				local bill = nil
				local lbl = nil
				if anchor then
					bill = Instance.new("BillboardGui")
					bill.Size = UDim2.fromOffset(160, 28)
					bill.AlwaysOnTop = true
					bill.Adornee = anchor
					bill.StudsOffset = Vector3.new(0, 3.2, 0)
					bill.MaxDistance = maxDist

					lbl = Instance.new("TextLabel")
					lbl.Size = UDim2.fromScale(1, 1)
					lbl.BackgroundTransparency = 1
					lbl.TextColor3 = oreColor
					lbl.TextStrokeTransparency = 0.4
					lbl.Font = Enum.Font.Gotham
					lbl.TextSize = 16
					lbl.RichText = true
					lbl.Text = '<font color="#' .. oreColor:ToHex() .. '">' .. oreName .. '</font>'
					lbl.Parent = bill

					bill.Enabled = showNames
					bill.Parent = workspace
				end

				entry = { hl = nil, bill = bill, lbl = lbl, oreName = oreName, lastColor = oreColor, lastEnabled = enabled, lastShowNames = showNames, dist = dist }
				oreESP.highlights[obj] = entry
			else
				entry.dist = dist
				if entry.bill then
					if entry.bill.MaxDistance ~= maxDist then
						entry.bill.MaxDistance = maxDist
					end
					if entry.lastShowNames ~= showNames then
						entry.lastShowNames = showNames
						entry.bill.Enabled = showNames
					end
				end
				if entry.lastColor ~= oreColor then
					entry.lastColor = oreColor
					if entry.hl then entry.hl.FillColor = oreColor end
					if entry.lbl then
						entry.lbl.TextColor3 = oreColor
						entry.lbl.Text = '<font color="#' .. oreColor:ToHex() .. '">' .. oreName .. '</font>'
					end
				end
				if entry.bill and entry.bill.Adornee == nil and anchor then
					entry.bill.Adornee = anchor
				end
			end

			if chamsEnabled and dist <= 60 then
				table.insert(candidateHighlights, { entry = entry, obj = obj, color = oreColor, dist = dist })
			elseif entry and entry.hl and entry.hl.Enabled then
				entry.hl.Enabled = false
			end
		end
	end

	-- Cap active highlights strictly to the closest 3 ores (to protect engine FPS and avoid GPU stencil lag)
	if #candidateHighlights > 1 then
		table.sort(candidateHighlights, function(a, b) return a.dist < b.dist end)
	end

	for i, item in ipairs(candidateHighlights) do
		local entry = item.entry
		if i <= 3 then
			if not entry.hl then
				local hl = Instance.new("Highlight")
				hl.FillColor = item.color
				hl.OutlineColor = Color3.fromRGB(255, 255, 255)
				hl.FillTransparency = 0.65
				hl.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
				hl.Adornee = item.obj
				hl.Enabled = true
				hl.Parent = workspace
				entry.hl = hl
			elseif not entry.hl.Enabled then
				entry.hl.Enabled = true
			end
		else
			if entry.hl and entry.hl.Enabled then
				entry.hl.Enabled = false
			end
		end
	end

	for obj, entry in pairs(oreESP.highlights) do
		if not seen[obj] or not obj or not obj.Parent then
			if entry.hl then pcall(function() entry.hl:Destroy() end) end
			if entry.bill then pcall(function() entry.bill:Destroy() end) end
			oreESP.highlights[obj] = nil
		end
	end
end

local function scanOreTypesAndBuildUI()
	local folder = workspace:FindFirstChild("worldResources") and workspace.worldResources:FindFirstChild("mineable")
	if not folder then return end

	local found = {}
	for _, chunkFolder in ipairs(folder:GetChildren()) do
		if not chunkFolder:IsA("Folder") then continue end
		for _, obj in ipairs(chunkFolder:GetChildren()) do
			local n = obj.Name
			if n and not found[n] then
				found[n] = true
			end
		end
	end

	local names = {}
	for n in pairs(found) do table.insert(names, n) end
	table.sort(names)
	if #names == 0 then return end

	local anyAdded = false
	for i, oreName in ipairs(names) do
		if oreESP.oreToggles[oreName] == nil then
			oreESP.oreToggles[oreName] = true
			local defaultColor = oreESP.fixedOreColors[oreName] or getOreColor(oreName, i)
			oreESP.oreColors[oreName] = defaultColor
			oreESP.fixedOreColors[oreName] = defaultColor

			local colorPickerKey = "OreESPColor_" .. oreName
			oreESP.oreColorPickers[oreName] = colorPickerKey

			local toggleKey = "OreESPFilter_" .. oreName
			OreESPGroup:AddToggle(toggleKey, {
				Text = oreName,
				Default = true,
			}):AddColorPicker(colorPickerKey, {
				Default = defaultColor,
				Title = oreName .. " Color",
			})
			if Toggles[toggleKey] then
				Toggles[toggleKey]:OnChanged(function(val)
					oreESP.oreToggles[oreName] = val
				end)
			end
			if Options[colorPickerKey] then
				Options[colorPickerKey]:OnChanged(function(newColor)
					oreESP.fixedOreColors[oreName] = newColor
					oreESP.oreColors[oreName] = newColor
				end)
			end

			anyAdded = true
		end
	end
	return anyAdded
end

Toggles.OreESPToggle:OnChanged(function()
	disconnect("OreESP")
	disconnect("OreESPScan")
	if not Toggles.OreESPToggle.Value then
		clearOreESPHighlights()
		return
	end

	scanOreTypesAndBuildUI()
	local folder = workspace:FindFirstChild("worldResources") and workspace.worldResources:FindFirstChild("mineable")
	if folder then
		track("OreESPScan", folder.ChildAdded:Connect(function()
			task.wait(0.5)
			pcall(scanOreTypesAndBuildUI)
		end))
	end

	track("OreESP", RunService.Heartbeat:Connect(function()
		if not isAlive() or not Toggles.OreESPToggle.Value then return end
		oreESPLoop()
	end))

	Library:Notify({ Title = "Ore ESP", Description = "Enabled", Time = 2 })
end)

Toggles.TitanAura:OnChanged(function()
	disconnect("TitanAuraFloat")
	if Toggles.TitanAura.Value then
		local root = getRootPart()
		if root then
			root.Velocity = Vector3.zero
			root.CFrame = CFrame.new(1654.57, 35, 2312.14)
		end
		track("TitanAuraFloat", RunService.Heartbeat:Connect(function()
			if not isAlive() then return end
			local r = getRootPart()
			if not r then return end
			r.Velocity = Vector3.new(r.Velocity.X, 0, r.Velocity.Z)
			r.CFrame = CFrame.new(r.Position.X, 35, r.Position.Z) * r.CFrame.Rotation
		end))
		if Toggles.AiAura and not Toggles.AiAura.Value then
			Toggles.AiAura:SetValue(true)
		end
		Library:Notify({ Title = "Titan Aura", Description = "Enabled", Time = 2 })
	else
		disconnect("TitanAuraFloat")
		if Toggles.AiAura and Toggles.AiAura.Value then
			Toggles.AiAura:SetValue(false)
		end
		Library:Notify({ Title = "Titan Aura", Description = "Disabled", Time = 2 })
	end
end)

Toggles.SamuraiAura:OnChanged(function()
	disconnect("SamuraiAuraFloat")
	if Toggles.SamuraiAura.Value then
		local root = getRootPart()
		if root then
			root.Velocity = Vector3.zero
			root.CFrame = CFrame.new(-1727.48, 528, 7305.50)
		end
		track("SamuraiAuraFloat", RunService.Heartbeat:Connect(function()
			if not isAlive() then return end
			local r = getRootPart()
			if not r then return end
			r.Velocity = Vector3.new(r.Velocity.X, 0, r.Velocity.Z)
			r.CFrame = CFrame.new(r.Position.X, 528, r.Position.Z) * r.CFrame.Rotation
		end))
		if Toggles.AiAura and not Toggles.AiAura.Value then
			Toggles.AiAura:SetValue(true)
		end
		Library:Notify({ Title = "Samurai Aura", Description = "Enabled", Time = 2 })
	else
		disconnect("SamuraiAuraFloat")
		if Toggles.AiAura and Toggles.AiAura.Value then
			Toggles.AiAura:SetValue(false)
		end
		Library:Notify({ Title = "Samurai Aura", Description = "Disabled", Time = 2 })
	end
end)

Toggles.JuggernautAura:OnChanged(function()
	disconnect("JuggernautAuraFloat")
	if Toggles.JuggernautAura.Value then
		local root = getRootPart()
		if root then
			root.Velocity = Vector3.zero
			root.CFrame = CFrame.new(-1601.49, 118, -2890.59)
		end
		track("JuggernautAuraFloat", RunService.Heartbeat:Connect(function()
			if not isAlive() then return end
			local r = getRootPart()
			if not r then return end
			r.Velocity = Vector3.new(r.Velocity.X, 0, r.Velocity.Z)
			r.CFrame = CFrame.new(r.Position.X, 118, r.Position.Z) * r.CFrame.Rotation
		end))
		if Toggles.AiAura and not Toggles.AiAura.Value then
			Toggles.AiAura:SetValue(true)
		end
		Library:Notify({ Title = "Juggernaut Aura", Description = "Enabled", Time = 2 })
	else
		disconnect("JuggernautAuraFloat")
		if Toggles.AiAura and Toggles.AiAura.Value then
			Toggles.AiAura:SetValue(false)
		end
		Library:Notify({ Title = "Juggernaut Aura", Description = "Disabled", Time = 2 })
	end
end)

-- ==========================================
-- TELEPORT
-- ==========================================
-- Boss Locations
local BossLocationsGroup = Tabs.Teleport:AddLeftGroupbox("Boss locations", "swords")

local bossLocations = {
	{ name = "Samurai",         pos = Vector3.new(-1727.48, 520.01, 7305.50) },
	{ name = "Juggernaut",      pos = Vector3.new(-1601.49, 113.27, -2890.59) },
	{ name = "Spider",          pos = Vector3.new(-330.32, -90.12, 382.67) },
	{ name = "Titan",           pos = Vector3.new(1654.57, 23.20, 2312.14) },
	{ name = "Kraken",          pos = Vector3.new(802.42, 19.35, -1999.35) },
	{ name = "Marvin",          pos = Vector3.new(-663.22, 26.14, 741.84) },
	{ name = "Hacker Platform", pos = Vector3.new(3811.73, 1546.83, -977.48) },
}

for _, loc in ipairs(bossLocations) do
	BossLocationsGroup:AddButton({
		Text = loc.name,
		Func = function()
			local root = getRootPart()
			if root then
				root.CFrame = CFrame.new(loc.pos)
				Library:Notify({ Title = "Teleport", Description = "Teleported to " .. loc.name, Time = 1.5 })
			else
				Library:Notify({ Title = "Teleport", Description = "Character not found.", Time = 3 })
			end
		end,
	})
end

-- Extra Locations
local TeleportExtra = Tabs.Teleport:AddLeftGroupbox("Extra Locations", "map-pin")

local extraLocations = {
	{ name = "Desert",        pos = Vector3.new(1459.50, 26.26, -204.70) },
	{ name = "Desert Hill",   pos = Vector3.new(1548.35, 145.47, 196.68) },
	{ name = "MainLand",      pos = Vector3.new(-170.20, 25.26, 430.70) },
	{ name = "Below ML",      pos = Vector3.new(-177, 25.26, -1014.83) },
	{ name = "Arena",         pos = Vector3.new(-1315.59, 41.19, 1972.84) },
	{ name = "Bamboo",        pos = Vector3.new(-1330.92, 39.43, 5798.47) },
	{ name = "Volcano",       pos = Vector3.new(1769.70, 36.43, 1832.10) },
	{ name = "Asia Cave",     pos = Vector3.new(-2108.44, 210, 6823.05) },
	{ name = "Juggernaut 2",  pos = Vector3.new(-1645.06, 336.32, -2874.34) },
	{ name = "Waterfall",     pos = Vector3.new(-1949.89, 25.29, 345.83) },
}

for _, loc in ipairs(extraLocations) do
	TeleportExtra:AddButton({
		Text = loc.name,
		Func = function()
			local root = getRootPart()
			if root then
				root.CFrame = CFrame.new(loc.pos)
				Library:Notify({ Title = "Teleport", Description = "Teleported to " .. loc.name, Time = 1.5 })
			else
				Library:Notify({ Title = "Teleport", Description = "Character not found.", Time = 3 })
			end
		end,
	})
end

-- Mounts Groupbox
local MountsGroup = Tabs.Teleport:AddRightGroupbox("Mounts", "paw-print")

local mountLocations = {
	{ name = "Lion",          pos = Vector3.new(1327.79, 25.26, -756.75) },
	{ name = "White Wolf",    pos = Vector3.new(-1447.88, 25.26, -1566.85) },
	{ name = "Horse",         pos = Vector3.new(-215.30, 25.26, 496.58) },
	{ name = "Grey Wolf",     pos = Vector3.new(84.67, 25.26, 442.49) },
	{ name = "Elephant",      pos = Vector3.new(1495.75, 25.26, -313.55) },
	{ name = "Snow Bear",     pos = Vector3.new(-879.8, 25.3, -2062.5) },
}

for _, loc in ipairs(mountLocations) do
	MountsGroup:AddButton({
		Text = loc.name,
		Func = function()
			local root = getRootPart()
			if root then
				root.CFrame = CFrame.new(loc.pos)
				Library:Notify({ Title = "Teleport", Description = "Teleported to " .. loc.name, Time = 1.5 })
			else
				Library:Notify({ Title = "Teleport", Description = "Character not found.", Time = 3 })
			end
		end,
	})
end

-- Merchants Groupbox
local MerchantsGroup = Tabs.Teleport:AddRightGroupbox("Merchants", "map-pin")

local merchantLocations = {
	{ name = "Mainland",   pos = Vector3.new(-144.60, 25.26, 429.38) },
	{ name = "Desert",     pos = Vector3.new(1428.14, 25.26, -593.17) },
	{ name = "Asia",       pos = Vector3.new(-744.10, 329.20, 7134.18) },
	{ name = "Arctic",     pos = Vector3.new(-1251.90, 25.25, -1997.17) },
	{ name = "Below Main", pos = Vector3.new(-166.28, 25.26, -1043.86) },
	{ name = "Secret",     pos = Vector3.new(-1171.82, 24.40, 90.70) },
}

for _, loc in ipairs(merchantLocations) do
	MerchantsGroup:AddButton({
		Text = loc.name,
		Func = function()
			local root = getRootPart()
			if root then
				root.CFrame = CFrame.new(loc.pos)
				Library:Notify({ Title = "Teleport", Description = "Teleported to " .. loc.name, Time = 1.5 })
			else
				Library:Notify({ Title = "Teleport", Description = "Character not found.", Time = 3 })
			end
		end,
	})
end

-- ==========================================
-- VISUALS
-- ==========================================
local VisualLeft = Tabs.Visuals:AddLeftGroupbox("Player ESP", "scan-eye")
local VisualFPS = Tabs.Visuals:AddRightGroupbox("FPS Booster", "zap")

-- ==========================================
local function setPlayerShadows(castShadow)
	for _, player in ipairs(Players:GetPlayers()) do
		if player.Character then
			for _, part in ipairs(player.Character:GetDescendants()) do
				if part:IsA("BasePart") then
					pcall(function() part.CastShadow = castShadow end)
				end
			end
		end
	end
end

VisualFPS:AddToggle("DisableRenderFog", {
	Text = "Disable Render Fog",
	Default = false,
	Callback = function(state)
		local lighting = game:GetService("Lighting")
		lighting.GlobalShadows = not state

		pcall(function()
			if state then
				lighting.FogEnd = 100000
				lighting.FogStart = 0
				lighting.FogColor = Color3.new(1, 1, 1)
			else
				lighting.FogEnd = 1000
				lighting.FogStart = 50
				lighting.FogColor = Color3.new(0.5, 0.6, 0.7)
			end
		end)

		disconnect("DisableRenderFog_PlayerAdded")
		for name, _ in pairs(Connections) do
			if typeof(name) == "string" and name:match("^DisableRenderFog_CharAdded") then
				disconnect(name)
			end
		end

		if state then
			-- Disable player shadows
			setPlayerShadows(false)

			local function hookPlayerShadows(player)
				if not player then return end
				local connName = "DisableRenderFog_CharAdded_" .. tostring(player.UserId or player.Name)
				disconnect(connName)
				track(connName, player.CharacterAdded:Connect(function(char)
					if Toggles.DisableRenderFog and Toggles.DisableRenderFog.Value then
						for _, part in ipairs(char:GetDescendants()) do
							if part:IsA("BasePart") then
								pcall(function() part.CastShadow = false end)
							end
						end
					end
				end))
			end

			track("DisableRenderFog_PlayerAdded", Players.PlayerAdded:Connect(hookPlayerShadows))

			for _, player in ipairs(Players:GetPlayers()) do
				hookPlayerShadows(player)
			end
		else
			-- Re-enable player shadows
			setPlayerShadows(true)
			disconnect("DisableRenderFog_PlayerAdded")
			for name, _ in pairs(Connections) do
				if typeof(name) == "string" and name:match("^DisableRenderFog_CharAdded") then
					disconnect(name)
				end
			end
		end
	end,
})

VisualFPS:AddToggle("NoWaterBlur", {
	Text = "No Water Blur",
	Default = false,
	Callback = function(state)
		disconnect("NoWaterBlur_ChildAdded")
		disconnect("NoWaterBlur_WaterChanged")
		disconnect("NoWaterBlur_BlurChanged")
		local lighting = game:GetService("Lighting")
		local water = lighting:FindFirstChild("water")
		local waterBlur = lighting:FindFirstChild("waterBlur")

		if state then
			local function disableWater(child)
				if child and child.Name == "water" then
					pcall(function() child.Enabled = false end)
					disconnect("NoWaterBlur_WaterChanged")
					track("NoWaterBlur_WaterChanged", child:GetPropertyChangedSignal("Enabled"):Connect(function()
						if Toggles.NoWaterBlur and Toggles.NoWaterBlur.Value and child.Enabled then
							pcall(function() child.Enabled = false end)
						end
					end))
				end
			end

			local function disableBlur(child)
				if child and child.Name == "waterBlur" then
					pcall(function() child.Enabled = false end)
					disconnect("NoWaterBlur_BlurChanged")
					track("NoWaterBlur_BlurChanged", child:GetPropertyChangedSignal("Enabled"):Connect(function()
						if Toggles.NoWaterBlur and Toggles.NoWaterBlur.Value and child.Enabled then
							pcall(function() child.Enabled = false end)
						end
					end))
				end
			end

			if water then
				disableWater(water)
			end
			if waterBlur then
				disableBlur(waterBlur)
			end

			track("NoWaterBlur_ChildAdded", lighting.ChildAdded:Connect(function(child)
				disableWater(child)
				disableBlur(child)
			end))
		else
			if water then
				pcall(function() water.Enabled = true end)
			end
			if waterBlur then
				pcall(function() waterBlur.Enabled = true end)
			end
		end
	end,
})

VisualFPS:AddToggle("NoGrass", {
	Text = "No Grass",
	Default = false,
	Callback = function(state)
		if state then
			pcall(function()
				loadstring(game:HttpGet("https://raw.githubusercontent.com/joashwalrond273-boop/Silent-Aim/refs/heads/main/No%20grass"))()
			end)
		else
			pcall(function()
				local terrain = workspace:FindFirstChildOfClass("Terrain")
				if terrain then
					if sethiddenproperty then
						sethiddenproperty(terrain, "Decoration", true)
					else
						terrain.Decoration = true
					end
				end
			end)
		end
	end,
})

VisualFPS:AddToggle("FullBright", {
	Text = "Full Bright",
	Default = false,
	Callback = function(state)
		pcall(function()
			local lighting = game:GetService("Lighting")
			if state then
				lighting.Brightness = 1.2
				lighting.GlobalShadows = false
				lighting.Ambient = Color3.new(0.55, 0.55, 0.55)
				lighting.OutdoorAmbient = Color3.new(0.65, 0.65, 0.65)
			else
				lighting.Brightness = 1
				lighting.GlobalShadows = true
				lighting.Ambient = Color3.new(0.4, 0.4, 0.4)
				lighting.OutdoorAmbient = Color3.new(0.6, 0.6, 0.6)
			end
		end)
	end,
})

pcall(function()
	local lighting = game:GetService("Lighting")
	local oldBlur = lighting:FindFirstChild("TSG_Smoothness_Blur")
	if oldBlur then oldBlur:Destroy() end
	local oldBloom = lighting:FindFirstChild("TSG_Smoothness_Bloom")
	if oldBloom then oldBloom:Destroy() end
	local oldCC = lighting:FindFirstChild("TSG_Smoothness_Color")
	if oldCC then oldCC:Destroy() end
end)

do
	local PBR_TYPES = { SurfaceAppearance = true, Texture = true, Decal = true }

	local function simplifyObject(v)
		if not v or not v.Parent then return end
		local c = v.ClassName
		if c == "MeshPart" or c == "Part" or c == "WedgePart" or c == "CornerWedgePart" or c == "TrussPart" then
			if v.Material ~= Enum.Material.Plastic then
				pcall(function()
					v.Material = Enum.Material.Plastic
					v.Reflectance = 0
				end)
			end
		elseif PBR_TYPES[c] then
			pcall(v.Destroy, v)
		end
	end

	VisualFPS:AddToggle("LowTextures", {
		Text = "Low Textures PBR",
		Default = false,
		Callback = function(state)
			disconnect("LowTextures")
			if state then
				-- Process workspace smoothly in micro-chunks without memory bloat or FPS freeze
				task.spawn(function()
					local descendants = workspace:GetDescendants()
					for i = 1, #descendants do
						if not (Toggles.LowTextures and Toggles.LowTextures.Value) then break end
						local v = descendants[i]
						simplifyObject(v)
						if i % 300 == 0 then
							task.wait()
						end
					end
				end)

				-- Fast direct check: skip non-visual objects instantly with zero overhead
				track("LowTextures", workspace.DescendantAdded:Connect(function(v)
					if not (Toggles.LowTextures and Toggles.LowTextures.Value) then return end
					local c = v.ClassName
					if PBR_TYPES[c] or c == "MeshPart" or c == "Part" or c == "WedgePart" or c == "CornerWedgePart" or c == "TrussPart" then
						simplifyObject(v)
					end
				end))
			end
		end,
	})
end

VisualFPS:AddToggle("DisableEffects", {
	Text = "Disable Effects",
	Default = false,
	Callback = function(state)
		for _, v in ipairs(game:GetService("Lighting"):GetChildren()) do
			if v:IsA("PostEffect") then
				v.Enabled = not state
			end
		end
	end,
})

do
	local PARTICLE_CLASSES = {
		ParticleEmitter = true,
		Fire = true,
		Smoke = true,
		Sparkles = true,
		Trail = true,
		Beam = true,
	}

	local originalStates = setmetatable({}, { __mode = "k" })

	local function disableParticle(v)
		if not v or not PARTICLE_CLASSES[v.ClassName] then return end

		if originalStates[v] == nil then
			originalStates[v] = {
				Enabled = v.Enabled,
				Rate = v:IsA("ParticleEmitter") and v.Rate or nil,
			}
		end

		pcall(function()
			v.Enabled = false
			if v:IsA("ParticleEmitter") then
				v.Rate = 0
				v:Clear()
			end
		end)
	end

	VisualFPS:AddToggle("RemoveParticles", {
		Text = "Remove Particles",
		Default = false,
		Callback = function(state)
			disconnect("RemoveParticles_Workspace")
			disconnect("RemoveParticles_Lighting")

			if state then
				-- Process workspace & lighting smoothly in chunks without freeze/stutter
				task.spawn(function()
					local containers = { workspace, game:GetService("Lighting") }
					for _, container in ipairs(containers) do
						local descendants = container:GetDescendants()
						for i = 1, #descendants do
							if not (Toggles.RemoveParticles and Toggles.RemoveParticles.Value) then break end
							local v = descendants[i]
							if v and v.Parent and PARTICLE_CLASSES[v.ClassName] then
								disableParticle(v)
							end
							if i % 300 == 0 then
								task.wait()
							end
						end
					end
				end)

				-- Direct fast class check without spawning leaking sub-connections per instance
				track("RemoveParticles_Workspace", workspace.DescendantAdded:Connect(function(v)
					if Toggles.RemoveParticles and Toggles.RemoveParticles.Value and PARTICLE_CLASSES[v.ClassName] then
						disableParticle(v)
					end
				end))

				track("RemoveParticles_Lighting", game:GetService("Lighting").ChildAdded:Connect(function(v)
					if Toggles.RemoveParticles and Toggles.RemoveParticles.Value and PARTICLE_CLASSES[v.ClassName] then
						disableParticle(v)
					end
				end))

				Library:Notify({ Title = "Remove Particles", Description = "Enabled", Time = 2 })
			else
				for v, stateInfo in pairs(originalStates) do
					if v and v.Parent then
						pcall(function()
							if stateInfo.Enabled ~= nil then
								v.Enabled = stateInfo.Enabled
							end
							if stateInfo.Rate ~= nil and v:IsA("ParticleEmitter") then
								v.Rate = stateInfo.Rate
							end
						end)
					end
				end
				table.clear(originalStates)
				Library:Notify({ Title = "Remove Particles", Description = "Disabled", Time = 2 })
			end
		end,
	})
end

VisualFPS:AddToggle("UncapFPS", {
	Text = "Uncap FPS",
	Default = false,
	Callback = function(state)
		pcall(function()
			if state then
				setfpscap(999)
			else
				setfpscap(60)
			end
		end)
	end,
})

do
	local HEAVY_POST_CLASSES = {
		DepthOfFieldEffect = true,
		SunRaysEffect = true,
		BloomEffect = true,
		ColorCorrectionEffect = true,
		MotionBlurEffect = true,
	}
	local originalPostEnabled = setmetatable({}, { __mode = "k" })
	local postPropConnections = {}

	local function isHeavyPost(v)
		return v and HEAVY_POST_CLASSES[v.ClassName]
	end

	local function disablePost(v)
		if not isHeavyPost(v) then return end
		if originalPostEnabled[v] == nil then
			originalPostEnabled[v] = v.Enabled
		end
		pcall(function() v.Enabled = false end)
		local conn = v:GetPropertyChangedSignal("Enabled"):Connect(function()
			if Toggles.KillHeavyPostEffects and Toggles.KillHeavyPostEffects.Value and v.Enabled then
				pcall(function() v.Enabled = false end)
			end
		end)
		table.insert(postPropConnections, conn)
	end

	local function restorePost(v)
		if not isHeavyPost(v) then return end
		local original = originalPostEnabled[v]
		if original ~= nil then
			pcall(function() v.Enabled = original end)
		end
	end

	VisualFPS:AddToggle("KillHeavyPostEffects", {
		Text = "Kill Heavy Post FX",
		Default = false,
		Callback = function(state)
			disconnect("KillHeavyPostEffects_ChildAdded")
			for _, conn in ipairs(postPropConnections) do
				pcall(function() conn:Disconnect() end)
			end
			table.clear(postPropConnections)

			local Lighting = game:GetService("Lighting")

			if state then
				local children = nil
				pcall(function() children = Lighting:GetChildren() end)
				if children then
					for _, v in ipairs(children) do
						disablePost(v)
					end
				end

				track("KillHeavyPostEffects_ChildAdded", Lighting.ChildAdded:Connect(function(child)
					if Toggles.KillHeavyPostEffects and Toggles.KillHeavyPostEffects.Value then
						task.defer(function() disablePost(child) end)
					end
				end))

				Library:Notify({ Title = "Kill Heavy Post FX", Description = "Enabled", Time = 2 })
			else
				local children = nil
				pcall(function() children = Lighting:GetChildren() end)
				if children then
					for _, v in ipairs(children) do
						restorePost(v)
					end
				end
				table.clear(originalPostEnabled)
				Library:Notify({ Title = "Kill Heavy Post FX", Description = "Disabled", Time = 2 })
			end
		end,
	})
end

VisualLeft:AddToggle("PlayerESP", {
	Text = "Enabled",
	Default = false,
}):AddColorPicker("PlayerESPColor", {
	Default = Color3.fromRGB(255, 255, 255),
	Title = "Player ESP Color",
})

VisualLeft:AddCheckbox("ShowDistance", {
	Text = "Show Distance",
	Default = false,
}):AddColorPicker("ShowDistanceColor", {
	Default = Color3.fromRGB(255, 255, 255),
	Title = "Show Distance Color",
})

VisualLeft:AddCheckbox("OutlineESP", {
	Text = "Outline ESP",
	Default = false,
}):AddColorPicker("OutlineESPColor", {
	Default = Color3.fromRGB(255, 255, 255),
	Title = "Outline ESP Color",
})

VisualLeft:AddCheckbox("PlayerTracers", {
	Text = "Tracers",
	Default = false,
}):AddColorPicker("PlayerTracersColor", {
	Default = Color3.fromRGB(255, 255, 255),
	Title = "Tracers Color",
})

VisualLeft:AddCheckbox("PlayerBoxes", {
	Text = "2D Boxes",
	Default = false,
}):AddColorPicker("PlayerBoxesColor", {
	Default = Color3.fromRGB(255, 255, 255),
	Title = "2D Boxes Color",
})

VisualLeft:AddCheckbox("PlayerChams", {
	Text = "Chams",
	Default = false,
}):AddColorPicker("PlayerChamsColor", {
	Default = Color3.fromRGB(255, 255, 255),
	Title = "Chams Color",
})

VisualLeft:AddCheckbox("PlayerHealthBar", {
	Text = "Health Bar",
	Default = false,
})

VisualLeft:AddDivider()

VisualLeft:AddCheckbox("MerchantESP", {
	Text = "Show Merchant ESP",
	Default = false,
})

do
	local merchantESPConns = {}
	local merchantESPObjects = {}

	local function addMerchantHighlight(merchantModel)
		if merchantESPObjects[merchantModel] then return end

		local hl = Instance.new("Highlight")
		hl.Name = "MerchantESP_Highlight"
		hl.Adornee = merchantModel
		hl.FillColor = Color3.fromRGB(255, 200, 0)
		hl.OutlineColor = Color3.fromRGB(255, 255, 255)
		hl.FillTransparency = 0.65
		hl.OutlineTransparency = 0
		hl.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
		hl.Parent = merchantModel

		local bbg = Instance.new("BillboardGui")
		bbg.Name = "MerchantESP_Label"
		bbg.Size = UDim2.new(0, 200, 0, 30)
		bbg.StudsOffset = Vector3.new(0, 6, 0)
		bbg.AlwaysOnTop = true
		bbg.MaxDistance = math.huge
		bbg.Parent = merchantModel:FindFirstChild("HumanoidRootPart") or merchantModel.PrimaryPart or merchantModel

		local tl = Instance.new("TextLabel")
		tl.Name = "TextLabel"
		tl.BackgroundTransparency = 1
		tl.Size = UDim2.new(1, 0, 1, 0)
		tl.Text = merchantModel.Name
		tl.TextColor3 = Color3.fromRGB(255, 200, 0)
		tl.Font = Enum.Font.Gotham
		tl.TextScaled = true
		tl.Parent = bbg

		merchantESPObjects[merchantModel] = { hl = hl, bbg = bbg }
	end

	local function clearMerchantESP()
		for _, conn in ipairs(merchantESPConns) do pcall(function() conn:Disconnect() end) end
		merchantESPConns = {}
		for model, objs in pairs(merchantESPObjects) do
			pcall(function() if objs.hl then objs.hl:Destroy() end end)
			pcall(function() if objs.bbg then objs.bbg:Destroy() end end)
		end
		merchantESPObjects = {}

		local merchantsFolder = workspace:FindFirstChild("Merchants")
		if merchantsFolder then
			for _, model in ipairs(merchantsFolder:GetChildren()) do
				if model:IsA("Model") then
					pcall(function()
						for _, d in ipairs(model:GetDescendants()) do
							if d.Name == "MerchantESP_Highlight" or d.Name == "MerchantESP_Label" then
								d:Destroy()
							end
						end
						if model:FindFirstChild("MerchantESP_Highlight") then
							model.MerchantESP_Highlight:Destroy()
						end
						if model:FindFirstChild("MerchantESP_Label") then
							model.MerchantESP_Label:Destroy()
						end
					end)
				end
			end
		end
	end

	local function enableMerchantESP()
		clearMerchantESP()
		local merchantsFolder = workspace:FindFirstChild("Merchants")
		if not merchantsFolder then return end
		for _, child in ipairs(merchantsFolder:GetChildren()) do
			if child:IsA("Model") then addMerchantHighlight(child) end
		end
		table.insert(merchantESPConns, merchantsFolder.ChildAdded:Connect(function(child)
			if child:IsA("Model") then addMerchantHighlight(child) end
		end))
	end

	Toggles.MerchantESP:OnChanged(function()
		if Toggles.MerchantESP.Value then
			enableMerchantESP()
		else
			clearMerchantESP()
		end
	end)
end

VisualLeft:AddSlider("ESPDistance", {
	Text = "Max Distance",
	Default = 500,
	Min = 50,
	Max = 2000,
	Rounding = 0,
	Compact = true,
})

local updatePlayerESPVisibility = function()
	local isPlayerESP = (Toggles.PlayerESP and Toggles.PlayerESP.Value) or false
	if Options.ESPDistance then
		Options.ESPDistance.Visible = isPlayerESP
		if Options.ESPDistance.Holder then
			Options.ESPDistance.Holder.Visible = isPlayerESP
		end
	end
	VisualLeft:Resize()
end

updatePlayerESPVisibility()
task.spawn(function()
	task.wait(0.05)
	if updatePlayerESPVisibility then
		updatePlayerESPVisibility()
	end
end)

local VisualEnv = Tabs.Visuals:AddLeftGroupbox("ENVIRONMENT", "sun")

VisualEnv:AddToggle("AlwaysDay", {
	Text = "Always Day",
	Default = false,
})

VisualEnv:AddToggle("Midday", {
	Text = "Midday",
	Default = false,
})

VisualEnv:AddToggle("AlwaysNight", {
	Text = "Always Night",
	Default = false,
})

VisualEnv:AddToggle("InfiniteZoom", {
	Text = "Infinite Zoom",
	Default = false,
})

VisualEnv:AddSlider("ControlTheHours", {
	Text = "Control The Hours",
	Default = 12,
	Min = 0,
	Max = 24,
	Rounding = 1,
	Compact = true,
})

local espObjects = {}
local espFolder = nil

local function getESPFolder()
	if espFolder and espFolder.Parent then
		return espFolder
	end
	pcall(function()
		local safeParent = nil
		if typeof(gethui) == "function" then
			safeParent = gethui()
		elseif typeof(CoreGui) == "Instance" then
			safeParent = CoreGui
		else
			safeParent = workspace
		end
		espFolder = Instance.new("Folder")
		espFolder.Name = "TSG_PlayerESP_Folder"
		espFolder.Parent = safeParent
	end)
	return espFolder or workspace
end

local function removePlayerESP(player)
	local entry = espObjects[player]
	if entry then
		if entry.billboard then pcall(function() entry.billboard:Destroy() end) end
		if entry.highlight then pcall(function() entry.highlight:Destroy() end) end
		if entry.tracer then pcall(function() entry.tracer:Remove() end) end
		if entry.box then pcall(function() entry.box:Remove() end) end
		if entry.healthBarOutline then pcall(function() entry.healthBarOutline:Remove() end) end
		if entry.healthBar then pcall(function() entry.healthBar:Remove() end) end
		if entry.charCon then pcall(function() entry.charCon:Disconnect() end) end
		espObjects[player] = nil
	end
end

local function clearESP()
	for player in pairs(espObjects) do
		removePlayerESP(player)
	end
	table.clear(espObjects)
	if espFolder then
		pcall(function() espFolder:ClearAllChildren() end)
	end
end

local function getOrCreateESP(player)
	if player == LocalPlayer then return nil end
	local entry = espObjects[player]
	local character = player.Character
	if not character then
		if entry then
			if entry.billboard then entry.billboard.Enabled = false end
			if entry.highlight then entry.highlight.Enabled = false end
			if entry.tracer then entry.tracer.Visible = false end
			if entry.box then entry.box.Visible = false end
			if entry.healthBarOutline then entry.healthBarOutline.Visible = false end
			if entry.healthBar then entry.healthBar.Visible = false end
		end
		return nil
	end

	local root = character:FindFirstChild("HumanoidRootPart")
	local hum = character:FindFirstChildOfClass("Humanoid")
	if not root or not hum or hum.Health <= 0 then
		if entry then
			if entry.billboard then entry.billboard.Enabled = false end
			if entry.highlight then entry.highlight.Enabled = false end
			if entry.tracer then entry.tracer.Visible = false end
			if entry.box then entry.box.Visible = false end
			if entry.healthBarOutline then entry.healthBarOutline.Visible = false end
			if entry.healthBar then entry.healthBar.Visible = false end
		end
		return nil
	end

	if not entry or entry.character ~= character then
		if entry then
			if entry.billboard then pcall(function() entry.billboard:Destroy() end) end
			if entry.highlight then pcall(function() entry.highlight:Destroy() end) end
			if entry.tracer then pcall(function() entry.tracer:Remove() end) end
			if entry.box then pcall(function() entry.box:Remove() end) end
			if entry.healthBarOutline then pcall(function() entry.healthBarOutline:Remove() end) end
			if entry.healthBar then pcall(function() entry.healthBar:Remove() end) end
		end

		local billboard = Instance.new("BillboardGui")
		billboard.Size = UDim2.fromOffset(140, 36)
		billboard.AlwaysOnTop = true
		billboard.Adornee = root
		billboard.MaxDistance = (Options and Options.ESPDistance and Options.ESPDistance.Value) or 2000
		billboard.Enabled = false
		billboard.Parent = getESPFolder()

		local label = Instance.new("TextLabel")
		label.Size = UDim2.fromScale(1, 1)
		label.BackgroundTransparency = 1
		label.TextColor3 = (Options and Options.PlayerESPColor and Options.PlayerESPColor.Value) or Color3.new(1, 1, 1)
		label.TextStrokeTransparency = 0.4
		label.Font = Enum.Font.Gotham
		label.TextSize = 14
		label.RichText = true
		label.Parent = billboard

		local highlight = Instance.new("Highlight")
		highlight.FillColor = (Options and Options.PlayerChamsColor and Options.PlayerChamsColor.Value) or Color3.fromRGB(255, 255, 255)
		highlight.OutlineColor = (Options and Options.OutlineESPColor and Options.OutlineESPColor.Value) or Color3.fromRGB(255, 255, 255)
		highlight.FillTransparency = ((Toggles and Toggles.PlayerChams and Toggles.PlayerChams.Value) and 0.65) or 1
		highlight.OutlineTransparency = ((Toggles and Toggles.OutlineESP and Toggles.OutlineESP.Value) and 0) or 1
		highlight.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
		highlight.Adornee = character
		highlight.Enabled = false
		highlight.Parent = getESPFolder()

		local tracer = nil
		local box = nil
		local healthBarOutline = nil
		local healthBar = nil
		if typeof(Drawing) ~= "nil" then
			pcall(function()
				tracer = Drawing.new("Line")
				tracer.Thickness = 1.5
				tracer.Color = (Options and Options.PlayerTracersColor and Options.PlayerTracersColor.Value) or Color3.fromRGB(255, 255, 255)
				tracer.Transparency = 1
				tracer.Visible = false
			end)
			pcall(function()
				box = Drawing.new("Square")
				box.Thickness = 1.5
				box.Color = (Options and Options.PlayerBoxesColor and Options.PlayerBoxesColor.Value) or Color3.fromRGB(255, 255, 255)
				box.Filled = false
				box.Transparency = 1
				box.Visible = false
			end)
			pcall(function()
				healthBarOutline = Drawing.new("Line")
				healthBarOutline.Thickness = 3
				healthBarOutline.Color = Color3.fromRGB(0, 0, 0)
				healthBarOutline.Transparency = 1
				healthBarOutline.Visible = false
			end)
			pcall(function()
				healthBar = Drawing.new("Line")
				healthBar.Thickness = 1.5
				healthBar.Color = Color3.fromRGB(0, 255, 0)
				healthBar.Transparency = 1
				healthBar.Visible = false
			end)
		end

		entry = {
			player = player,
			character = character,
			root = root,
			hum = hum,
			billboard = billboard,
			label = label,
			highlight = highlight,
			tracer = tracer,
			box = box,
			healthBarOutline = healthBarOutline,
			healthBar = healthBar,
			lastDist = -1,
			lastShowDist = nil,
			lastText = "",
		}
		espObjects[player] = entry
	else
		entry.root = root
		entry.hum = hum
		if not entry.tracer and typeof(Drawing) ~= "nil" then
			pcall(function()
				entry.tracer = Drawing.new("Line")
				entry.tracer.Thickness = 1.5
				entry.tracer.Color = (Options and Options.PlayerTracersColor and Options.PlayerTracersColor.Value) or Color3.fromRGB(255, 255, 255)
				entry.tracer.Transparency = 1
				entry.tracer.Visible = false
			end)
		end
		if not entry.box and typeof(Drawing) ~= "nil" then
			pcall(function()
				entry.box = Drawing.new("Square")
				entry.box.Thickness = 1.5
				entry.box.Color = (Options and Options.PlayerBoxesColor and Options.PlayerBoxesColor.Value) or Color3.fromRGB(255, 255, 255)
				entry.box.Filled = false
				entry.box.Transparency = 1
				entry.box.Visible = false
			end)
		end
		if not entry.healthBarOutline and typeof(Drawing) ~= "nil" then
			pcall(function()
				entry.healthBarOutline = Drawing.new("Line")
				entry.healthBarOutline.Thickness = 3
				entry.healthBarOutline.Color = Color3.fromRGB(0, 0, 0)
				entry.healthBarOutline.Transparency = 1
				entry.healthBarOutline.Visible = false
			end)
		end
		if not entry.healthBar and typeof(Drawing) ~= "nil" then
			pcall(function()
				entry.healthBar = Drawing.new("Line")
				entry.healthBar.Thickness = 1.5
				entry.healthBar.Color = Color3.fromRGB(0, 255, 0)
				entry.healthBar.Transparency = 1
				entry.healthBar.Visible = false
			end)
		end
	end

	return entry
end

local function updateAllESP()
	if not Toggles.PlayerESP or not Toggles.PlayerESP.Value then return end

	local myRoot = getRootPart()
	if not myRoot then
		for _, entry in pairs(espObjects) do
			if entry.billboard and entry.billboard.Enabled then entry.billboard.Enabled = false end
			if entry.highlight and entry.highlight.Enabled then entry.highlight.Enabled = false end
			if entry.tracer and entry.tracer.Visible then entry.tracer.Visible = false end
			if entry.box and entry.box.Visible then entry.box.Visible = false end
			if entry.healthBarOutline and entry.healthBarOutline.Visible then entry.healthBarOutline.Visible = false end
			if entry.healthBar and entry.healthBar.Visible then entry.healthBar.Visible = false end
		end
		return
	end

	local maxDist = (Options and Options.ESPDistance and Options.ESPDistance.Value) or 500
	local showDist = (Toggles.ShowDistance and Toggles.ShowDistance.Value) or false
	local outlineEnabled = (Toggles.OutlineESP and Toggles.OutlineESP.Value) or false
	local chamsEnabled = (Toggles.PlayerChams and Toggles.PlayerChams.Value) or false
	local tracersEnabled = (Toggles.PlayerTracers and Toggles.PlayerTracers.Value) or false
	local boxesEnabled = (Toggles.PlayerBoxes and Toggles.PlayerBoxes.Value) or false
	local healthBarEnabled = (Toggles.PlayerHealthBar and Toggles.PlayerHealthBar.Value) or false
	local myPos = myRoot.Position

	local pColor = (Options and Options.PlayerESPColor and Options.PlayerESPColor.Value) or Color3.new(1, 1, 1)
	local dColor = (Options and Options.ShowDistanceColor and Options.ShowDistanceColor.Value) or Color3.new(1, 1, 1)
	local oColor = (Options and Options.OutlineESPColor and Options.OutlineESPColor.Value) or Color3.new(1, 1, 1)
	local cColor = (Options and Options.PlayerChamsColor and Options.PlayerChamsColor.Value) or Color3.new(1, 1, 1)
	local tColor = (Options and Options.PlayerTracersColor and Options.PlayerTracersColor.Value) or Color3.new(1, 1, 1)
	local bColor = (Options and Options.PlayerBoxesColor and Options.PlayerBoxesColor.Value) or Color3.new(1, 1, 1)

	local pColorHex = pColor:ToHex()
	local dColorHex = dColor:ToHex()

	local camera = workspace.CurrentCamera
	local tracerOrigin = nil
	if camera then
		local viewportSize = camera.ViewportSize
		tracerOrigin = Vector2.new(viewportSize.X / 2, viewportSize.Y)
	end

	local activeCandidates = {}

	for _, player in ipairs(Players:GetPlayers()) do
		if player ~= LocalPlayer then
			local entry = getOrCreateESP(player)
			if entry and entry.root and entry.hum and entry.hum.Health > 0 and entry.character.Parent then
				local dist = (entry.root.Position - myPos).Magnitude
				if dist <= maxDist then
					table.insert(activeCandidates, { entry = entry, dist = dist })
				else
					if entry.billboard.Enabled then entry.billboard.Enabled = false end
					if entry.highlight.Enabled then entry.highlight.Enabled = false end
					if entry.tracer and entry.tracer.Visible then entry.tracer.Visible = false end
					if entry.box and entry.box.Visible then entry.box.Visible = false end
					if entry.healthBarOutline and entry.healthBarOutline.Visible then entry.healthBarOutline.Visible = false end
					if entry.healthBar and entry.healthBar.Visible then entry.healthBar.Visible = false end
				end
			end
		end
	end

	if #activeCandidates > 1 then
		table.sort(activeCandidates, function(a, b) return a.dist < b.dist end)
	end

	for i, cand in ipairs(activeCandidates) do
		local entry = cand.entry
		local dist = cand.dist

		if not entry.billboard.Enabled then
			entry.billboard.Enabled = true
		end
		if entry.billboard.Adornee ~= entry.root then
			entry.billboard.Adornee = entry.root
		end

		local roundedDist = math.floor(dist)
		if entry.lastDist ~= roundedDist or entry.lastShowDist ~= showDist then
			entry.lastDist = roundedDist
			entry.lastShowDist = showDist
			local text = '<font color="#' .. pColorHex .. '">' .. entry.player.Name .. '</font>'
			if showDist then
				text = text .. '\n<font color="#' .. dColorHex .. '">' .. roundedDist .. 'm</font>'
			end
			entry.label.Text = text
		end

		local shouldHighlight = (outlineEnabled or chamsEnabled) and (i <= 6) and (dist <= 150)
		if shouldHighlight then
			if entry.highlight.Adornee ~= entry.character then
				entry.highlight.Adornee = entry.character
			end
			if entry.highlight.OutlineColor ~= oColor then
				entry.highlight.OutlineColor = oColor
			end
			if entry.highlight.FillColor ~= cColor then
				entry.highlight.FillColor = cColor
			end
			local targetOutlineTrans = outlineEnabled and 0 or 1
			if entry.highlight.OutlineTransparency ~= targetOutlineTrans then
				entry.highlight.OutlineTransparency = targetOutlineTrans
			end
			local targetFillTrans = chamsEnabled and 0.65 or 1
			if entry.highlight.FillTransparency ~= targetFillTrans then
				entry.highlight.FillTransparency = targetFillTrans
			end
			if not entry.highlight.Enabled then
				entry.highlight.Enabled = true
			end
		else
			if entry.highlight.Enabled then
				entry.highlight.Enabled = false
			end
		end

		if entry.tracer then
			if tracersEnabled and camera and tracerOrigin then
				local screenPos, onScreen = camera:WorldToViewportPoint(entry.root.Position)
				if onScreen and screenPos.Z > 0 then
					entry.tracer.From = tracerOrigin
					entry.tracer.To = Vector2.new(screenPos.X, screenPos.Y)
					if entry.tracer.Color ~= tColor then
						entry.tracer.Color = tColor
					end
					if not entry.tracer.Visible then
						entry.tracer.Visible = true
					end
				else
					if entry.tracer.Visible then
						entry.tracer.Visible = false
					end
				end
			else
				if entry.tracer.Visible then
					entry.tracer.Visible = false
				end
			end
		end

		local onScreen2D = false
		local height, width, leftX, topY, botY = 0, 0, 0, 0, 0

		if camera and (boxesEnabled or healthBarEnabled) then
			local rootPos = entry.root.Position
			local head = entry.character:FindFirstChild("Head")
			local topPos = (head and (head.Position + Vector3.new(0, 0.6, 0))) or (rootPos + Vector3.new(0, 2.8, 0))
			local botPos = rootPos - Vector3.new(0, 3.2, 0)

			local topScreen, topVisible = camera:WorldToViewportPoint(topPos)
			local botScreen, botVisible = camera:WorldToViewportPoint(botPos)

			if (topVisible or botVisible) and topScreen.Z > 0 and botScreen.Z > 0 then
				onScreen2D = true
				height = math.abs(botScreen.Y - topScreen.Y)
				width = math.max(height * 0.65, 4)
				topY = math.min(topScreen.Y, botScreen.Y)
				botY = math.max(topScreen.Y, botScreen.Y)
				leftX = math.floor(topScreen.X - width * 0.5)
			end
		end

		if entry.box then
			if boxesEnabled and onScreen2D then
				local boxPos = Vector2.new(leftX, math.floor(topY))
				local boxSize = Vector2.new(math.floor(width), math.floor(height))

				entry.box.Position = boxPos
				entry.box.Size = boxSize
				if entry.box.Color ~= bColor then
					entry.box.Color = bColor
				end
				if not entry.box.Visible then
					entry.box.Visible = true
				end
			else
				if entry.box.Visible then
					entry.box.Visible = false
				end
			end
		end

		if entry.healthBar and entry.healthBarOutline then
			if healthBarEnabled and onScreen2D then
				local health = (entry.hum and entry.hum.Health) or 0
				local maxHealth = (entry.hum and entry.hum.MaxHealth) or 100
				if maxHealth <= 0 then maxHealth = 100 end
				local healthPct = math.clamp(health / maxHealth, 0, 1)
				local healthColor = Color3.fromHSV(healthPct * 0.33, 1, 1)

				local barX = leftX - 4
				local fillY = botY - (botY - topY) * healthPct

				entry.healthBarOutline.From = Vector2.new(barX, botY)
				entry.healthBarOutline.To = Vector2.new(barX, topY)
				if not entry.healthBarOutline.Visible then
					entry.healthBarOutline.Visible = true
				end

				entry.healthBar.From = Vector2.new(barX, botY)
				entry.healthBar.To = Vector2.new(barX, fillY)
				entry.healthBar.Color = healthColor
				if not entry.healthBar.Visible then
					entry.healthBar.Visible = true
				end
			else
				if entry.healthBarOutline.Visible then
					entry.healthBarOutline.Visible = false
				end
				if entry.healthBar.Visible then
					entry.healthBar.Visible = false
				end
			end
		end
	end
end

Toggles.PlayerESP:OnChanged(function()
	if updatePlayerESPVisibility then
		updatePlayerESPVisibility()
	end
	disconnect("ESP_Loop")
	disconnect("ESP_PlayerAdded")
	disconnect("ESP_PlayerRemoving")
	if not Toggles.PlayerESP.Value then
		clearESP()
		return
	end

	track("ESP_Loop", RunService.RenderStepped:Connect(updateAllESP))

	for _, player in ipairs(Players:GetPlayers()) do
		if player ~= LocalPlayer then
			local entry = espObjects[player] or {}
			if entry.charCon then entry.charCon:Disconnect() end
			entry.charCon = player.CharacterAdded:Connect(function()
				task.wait(0.2)
				if Toggles.PlayerESP and Toggles.PlayerESP.Value then
					getOrCreateESP(player)
				end
			end)
		end
	end

	track("ESP_PlayerAdded", Players.PlayerAdded:Connect(function(player)
		player.CharacterAdded:Connect(function()
			task.wait(0.2)
			if Toggles.PlayerESP and Toggles.PlayerESP.Value then
				getOrCreateESP(player)
			end
		end)
	end))

	track("ESP_PlayerRemoving", Players.PlayerRemoving:Connect(function(player)
		removePlayerESP(player)
	end))

	updateAllESP()
end)

Toggles.OutlineESP:OnChanged(function()
	if not Toggles.OutlineESP.Value and not (Toggles.PlayerChams and Toggles.PlayerChams.Value) then
		for _, entry in pairs(espObjects) do
			if entry.highlight and entry.highlight.Enabled then
				entry.highlight.Enabled = false
			end
		end
	else
		updateAllESP()
	end
end)

Toggles.PlayerChams:OnChanged(function()
	if not Toggles.PlayerChams.Value and not (Toggles.OutlineESP and Toggles.OutlineESP.Value) then
		for _, entry in pairs(espObjects) do
			if entry.highlight and entry.highlight.Enabled then
				entry.highlight.Enabled = false
			end
		end
	else
		updateAllESP()
	end
end)

Toggles.PlayerTracers:OnChanged(function()
	if not Toggles.PlayerTracers.Value then
		for _, entry in pairs(espObjects) do
			if entry.tracer and entry.tracer.Visible then
				entry.tracer.Visible = false
			end
		end
	else
		updateAllESP()
	end
end)

Toggles.PlayerBoxes:OnChanged(function()
	if not Toggles.PlayerBoxes.Value then
		for _, entry in pairs(espObjects) do
			if entry.box and entry.box.Visible then
				entry.box.Visible = false
			end
		end
	else
		updateAllESP()
	end
end)

Toggles.PlayerHealthBar:OnChanged(function()
	if not Toggles.PlayerHealthBar.Value then
		for _, entry in pairs(espObjects) do
			if entry.healthBarOutline and entry.healthBarOutline.Visible then
				entry.healthBarOutline.Visible = false
			end
			if entry.healthBar and entry.healthBar.Visible then
				entry.healthBar.Visible = false
			end
		end
	else
		updateAllESP()
	end
end)

Toggles.ShowDistance:OnChanged(function()
	for _, entry in pairs(espObjects) do
		entry.lastDist = -1
	end
	updateAllESP()
end)

Options.OutlineESPColor:OnChanged(function()
	local color = Options.OutlineESPColor.Value
	for _, entry in pairs(espObjects) do
		if entry.highlight then
			entry.highlight.OutlineColor = color
		end
	end
end)

Options.PlayerChamsColor:OnChanged(function()
	local color = Options.PlayerChamsColor.Value
	for _, entry in pairs(espObjects) do
		if entry.highlight then
			entry.highlight.FillColor = color
		end
	end
end)

Options.PlayerTracersColor:OnChanged(function()
	local color = Options.PlayerTracersColor.Value
	for _, entry in pairs(espObjects) do
		if entry.tracer then
			entry.tracer.Color = color
		end
	end
end)

Options.PlayerBoxesColor:OnChanged(function()
	local color = Options.PlayerBoxesColor.Value
	for _, entry in pairs(espObjects) do
		if entry.box then
			entry.box.Color = color
		end
	end
end)

Options.PlayerESPColor:OnChanged(function()
	for _, entry in pairs(espObjects) do
		entry.lastDist = -1
	end
	updateAllESP()
end)

Options.ShowDistanceColor:OnChanged(function()
	for _, entry in pairs(espObjects) do
		entry.lastDist = -1
	end
	updateAllESP()
end)

local targetClockTime = nil
local lightingService = game:GetService("Lighting")

local function applyClockTime(newTime)
	targetClockTime = newTime
	disconnect("EnvironmentTime")
	if newTime == nil then
		return
	end
	pcall(function()
		lightingService.ClockTime = newTime
	end)
	track("EnvironmentTime", lightingService:GetPropertyChangedSignal("ClockTime"):Connect(function()
		if targetClockTime ~= nil and lightingService.ClockTime ~= targetClockTime then
			pcall(function()
				lightingService.ClockTime = targetClockTime
			end)
		end
	end))
end

Toggles.AlwaysDay:OnChanged(function()
	if Toggles.AlwaysDay.Value then
		Toggles.Midday:SetValue(false)
		Toggles.AlwaysNight:SetValue(false)
		applyClockTime(14)
		Library:Notify({ Title = "Always Day", Description = "Enabled", Time = 2 })
	else
		if not Toggles.Midday.Value and not Toggles.AlwaysNight.Value then
			applyClockTime(nil)
		end
	end
end)

Toggles.Midday:OnChanged(function()
	if Toggles.Midday.Value then
		Toggles.AlwaysDay:SetValue(false)
		Toggles.AlwaysNight:SetValue(false)
		applyClockTime(12)
		Library:Notify({ Title = "Midday", Description = "Enabled", Time = 2 })
	else
		if not Toggles.AlwaysDay.Value and not Toggles.AlwaysNight.Value then
			applyClockTime(nil)
		end
	end
end)

Toggles.AlwaysNight:OnChanged(function()
	if Toggles.AlwaysNight.Value then
		Toggles.AlwaysDay:SetValue(false)
		Toggles.Midday:SetValue(false)
		applyClockTime(0)
		Library:Notify({ Title = "Always Night", Description = "Enabled", Time = 2 })
	else
		if not Toggles.AlwaysDay.Value and not Toggles.Midday.Value then
			applyClockTime(nil)
		end
	end
end)

Toggles.InfiniteZoom:OnChanged(function()
	if Toggles.InfiniteZoom.Value then
		LocalPlayer.CameraMaxZoomDistance = 100000
		LocalPlayer.CameraMinZoomDistance = 0.5
		Library:Notify({ Title = "Infinite Zoom", Description = "Enabled", Time = 2 })
	else
		LocalPlayer.CameraMaxZoomDistance = 400
		LocalPlayer.CameraMinZoomDistance = 0.5
	end
end)

Options.ControlTheHours:OnChanged(function()
	if Toggles.AlwaysDay.Value or Toggles.Midday.Value or Toggles.AlwaysNight.Value then
		Toggles.AlwaysDay:SetValue(false)
		Toggles.Midday:SetValue(false)
		Toggles.AlwaysNight:SetValue(false)
	end
	applyClockTime(Options.ControlTheHours.Value)
end)
local touchFlingActive = false
local function touchFlingLoop()
	local movel = 0.1
	while touchFlingActive and Toggles.TouchFling.Value do
		RunService.Heartbeat:Wait()
		if not touchFlingActive then break end
		local c = LocalPlayer.Character
		local hrp = c and c:FindFirstChild("HumanoidRootPart")
		if hrp then
			local power = (Options.TouchFlingPower and Options.TouchFlingPower.Value) or 5000
			local vel = hrp.Velocity
			hrp.Velocity = vel * power + Vector3.new(0, power, 0)
			RunService.RenderStepped:Wait()
			if not touchFlingActive then break end
			hrp.Velocity = vel
			RunService.Stepped:Wait()
			if not touchFlingActive then break end
			hrp.Velocity = vel + Vector3.new(0, movel, 0)
			movel = -movel
		end
	end
end

Toggles.TouchFling:OnChanged(function()
	if updateTouchFlingVisibility then
		updateTouchFlingVisibility()
	end
	touchFlingActive = Toggles.TouchFling.Value
	if touchFlingActive then
		task.spawn(touchFlingLoop)
	end
end)

-- Fling Your Victim Script Logic
local helicopterAngle = 0
local function startHelicopter()
	disconnect("HelicopterLoop")
	local myHum = getHumanoid()
	if Toggles.HelicopterTroll.Value then
		track("HelicopterLoop", RunService.Heartbeat:Connect(function(dt)
			if not Toggles.HelicopterTroll.Value then return end
			local targetName = Options.HelicopterPlayerList and Options.HelicopterPlayerList.Value
			if not targetName or targetName == "" then return end

			local targetPlayer = Players:FindFirstChild(targetName)
			local targetChar = targetPlayer and targetPlayer.Character
			local targetRoot = targetChar and targetChar:FindFirstChild("HumanoidRootPart")
			local char = getCharacter()
			local myRoot = getRootPart()
			local hum = getHumanoid()

			if targetRoot and myRoot and isAlive() then
				for _, part in ipairs(noclipCoreParts) do
					if part and part.CanCollide then
						part.CanCollide = false
					end
				end

				local speed = 100
				local height = 1
				helicopterAngle = (helicopterAngle + (speed * 15) * dt) % 360

				if hum then
					hum.PlatformStand = true
				end

				local targetPos = targetRoot.Position + Vector3.new(0, height, 0)
				myRoot.CFrame = CFrame.new(targetPos) * CFrame.Angles(0, math.rad(helicopterAngle), 0)
				myRoot.Velocity = Vector3.zero
				myRoot.RotVelocity = Vector3.new(0, speed * 25, 0)
			end
		end))
	else
		if myHum then
			myHum.PlatformStand = false
		end
		local myRoot = getRootPart()
		if myRoot then
			myRoot.RotVelocity = Vector3.zero
		end
	end
end

Toggles.HelicopterTroll:OnChanged(function()
	if updateHelicopterVisibility then
		updateHelicopterVisibility()
	end
	startHelicopter()
	if Toggles.HelicopterTroll.Value then
		Library:Notify({ Title = "FLING YOUR VICTIM", Description = "Flinging: " .. tostring(Options.HelicopterPlayerList.Value), Time = 2 })
	else
		Library:Notify({ Title = "FLING YOUR VICTIM", Description = "Fling Disabled", Time = 2 })
	end
end)

Options.HelicopterPlayerList:OnChanged(function()
	if Toggles.HelicopterTroll.Value then
		startHelicopter()
	end
end)

-- Attach Script Logic
local function updateAttachPlayerList()
	local list = {}
	local kaList = {"All"}
	for _, player in ipairs(Players:GetPlayers()) do
		if player ~= LocalPlayer then
			table.insert(list, player.Name)
			table.insert(kaList, player.Name)
		end
	end
	pcall(function()
		Options.AttachPlayerList:SetValues(list)
		if #list > 0 then
			if not table.find(list, Options.AttachPlayerList.Value) then
				Options.AttachPlayerList:SetValue(list[1])
			end
		else
			Options.AttachPlayerList:SetValue("")
		end
	end)
	pcall(function()
		if Options.HelicopterPlayerList then
			Options.HelicopterPlayerList:SetValues(list)
			if #list > 0 then
				if not table.find(list, Options.HelicopterPlayerList.Value) then
					Options.HelicopterPlayerList:SetValue(list[1])
				end
			else
				Options.HelicopterPlayerList:SetValue("")
			end
		end
	end)
	pcall(function()
		if Options.KillAuraTarget then
			local current = Options.KillAuraTarget.Value
			Options.KillAuraTarget:SetValues(kaList)
			if table.find(kaList, current) then
				Options.KillAuraTarget:SetValue(current)
			else
				Options.KillAuraTarget:SetValue("All")
			end
		end
	end)
	pcall(function()
		if Options.CamlockTarget then
			local current = Options.CamlockTarget.Value
			Options.CamlockTarget:SetValues(kaList)
			if table.find(kaList, current) then
				Options.CamlockTarget:SetValue(current)
			else
				Options.CamlockTarget:SetValue("All")
			end
		end
	end)
	pcall(function()
		if Options.OutlineTarget then
			local current = Options.OutlineTarget.Value
			Options.OutlineTarget:SetValues(kaList)
			if table.find(kaList, current) then
				Options.OutlineTarget:SetValue(current)
			else
				Options.OutlineTarget:SetValue("All")
			end
		end
	end)
	pcall(function()
		if Options.ReachTarget then
			local current = Options.ReachTarget.Value
			Options.ReachTarget:SetValues(kaList)
			if table.find(kaList, current) then
				Options.ReachTarget:SetValue(current)
			else
				Options.ReachTarget:SetValue("All")
			end
		end
	end)
end

track("AttachPlayerAdded", Players.PlayerAdded:Connect(updateAttachPlayerList))
track("AttachPlayerRemoving", Players.PlayerRemoving:Connect(updateAttachPlayerList))
task.spawn(updateAttachPlayerList)

local function startAttach()
	disconnect("AttachLoop")
	if Toggles.AttachToggle.Value then
		track("AttachLoop", RunService.Heartbeat:Connect(function()
			if not Toggles.AttachToggle.Value then return end
			local targetName = Options.AttachPlayerList.Value
			if not targetName or targetName == "" then return end

			local targetPlayer = Players:FindFirstChild(targetName)
			local targetChar = targetPlayer and targetPlayer.Character
			local targetRoot = targetChar and targetChar:FindFirstChild("HumanoidRootPart")
			local char = getCharacter()
			local myRoot = getRootPart()

			if targetRoot and myRoot and isAlive() then
				for _, part in ipairs(noclipCoreParts) do
					if part and part.CanCollide then
						part.CanCollide = false
					end
				end
				if Toggles.FloatOverToggle.Value then
					myRoot.CFrame = targetRoot.CFrame * CFrame.new(0, 6, 0) -- Over head
				elseif Toggles.HideBeneathToggle.Value then
					myRoot.CFrame = targetRoot.CFrame * CFrame.new(0, -6, 0) -- Below feet
				else
					myRoot.CFrame = targetRoot.CFrame * CFrame.new(0, 0, 2.5) -- Behind player
				end
				myRoot.Velocity = Vector3.zero
			end
		end))
	end
end

Toggles.AttachToggle:OnChanged(startAttach)
Toggles.PlusKillPlayerToggle:OnChanged(function()
	if Toggles.PlusKillPlayerToggle.TextLabel then
		Toggles.PlusKillPlayerToggle.TextLabel.TextColor3 = Toggles.PlusKillPlayerToggle.Value and Color3.fromRGB(255, 100, 100) or Color3.fromRGB(255, 0, 0)
	end
	if Toggles.PlusKillPlayerToggle.Value then
		Toggles.KillAura:SetValue(true)
	else
		Toggles.KillAura:SetValue(false)
	end
end)
Options.AttachPlayerList:OnChanged(function()
	if Toggles.AttachToggle.Value then
		startAttach()
	end
end)
Toggles.HideBeneathToggle:OnChanged(function()
	if Toggles.AttachToggle.Value then
		startAttach()
	end
end)
Toggles.FloatOverToggle:OnChanged(function()
	if Toggles.AttachToggle.Value then
		startAttach()
	end
end)

-- Spectate Script Logic
local function updateSpectatePlayerList()
	local list = {}
	for _, player in ipairs(Players:GetPlayers()) do
		if player ~= LocalPlayer then
			table.insert(list, player.Name)
		end
	end
	pcall(function()
		Options.SpectatePlayerList:SetValues(list)
		if #list > 0 then
			if not table.find(list, Options.SpectatePlayerList.Value) then
				Options.SpectatePlayerList:SetValue(list[1])
			end
		else
			Options.SpectatePlayerList:SetValue("")
		end
	end)
end

track("SpectatePlayerAdded", Players.PlayerAdded:Connect(updateSpectatePlayerList))
track("SpectatePlayerRemoving", Players.PlayerRemoving:Connect(updateSpectatePlayerList))
task.spawn(updateSpectatePlayerList)

local function startSpectate()
	disconnect("SpectateLoop")
	if Toggles.SpectateToggle.Value then
		track("SpectateLoop", RunService.Heartbeat:Connect(function()
			if not Toggles.SpectateToggle.Value then return end
			local targetName = Options.SpectatePlayerList.Value
			local targetPlayer = targetName and Players:FindFirstChild(targetName)
			local targetHum = targetPlayer and targetPlayer.Character and targetPlayer.Character:FindFirstChildOfClass("Humanoid")
			local camera = workspace.CurrentCamera

			if targetHum then
				if camera.CameraSubject ~= targetHum then
					camera.CameraSubject = targetHum
				end
			else
				local localHum = getHumanoid()
				if localHum and camera.CameraSubject ~= localHum then
					camera.CameraSubject = localHum
				end
			end
		end))
	else
		local camera = workspace.CurrentCamera
		local localHum = getHumanoid()
		if localHum then
			camera.CameraSubject = localHum
		end
	end
end

Toggles.SpectateToggle:OnChanged(function()
	startSpectate()
	if Toggles.SpectateToggle.Value then
		Library:Notify({ Title = "SPECTATE", Description = "Spectating: " .. tostring(Options.SpectatePlayerList.Value), Time = 2 })
	else
		Library:Notify({ Title = "SPECTATE", Description = "Spectate Disabled", Time = 2 })
	end
end)

Options.SpectatePlayerList:OnChanged(function()
	if Toggles.SpectateToggle.Value then
		startSpectate()
	end
end)

-- Invisible Fly Script Logic
local invisibleFlyVars = {
	invisiblefly = false,
	playerClone = nil,
	wasInvisibleFlyEnabled = false,
	connection = nil,
	highlight = nil,
	originalTransparency = {},
	characterAddedConn = nil,
	lastClonePivot = nil
}

local function applyInvisFlyTranslucency(character)
	if not character then return end
	for _, desc in ipairs(character:GetDescendants()) do
		if desc:IsA("BasePart") or desc:IsA("Decal") or desc:IsA("Texture") then
			invisibleFlyVars.originalTransparency[desc] = desc.Transparency
			desc.Transparency = 0.5
		end
	end
end

local function restoreInvisFlyTranslucency()
	for obj, transp in pairs(invisibleFlyVars.originalTransparency) do
		if obj and obj.Parent then
			obj.Transparency = transp
		end
	end
	table.clear(invisibleFlyVars.originalTransparency)
end

local function onInvisibleFlyToggle(state)
	if updateFlightVisibility then
		updateFlightVisibility()
	end
	invisibleFlyVars.invisiblefly = state

	if state then
		invisibleFlyVars.wasInvisibleFlyEnabled = true
		task.spawn(function()
			repeat
				task.wait()
			until LocalPlayer.Character

			invisibleFlyVars.characterAddedConn = LocalPlayer.CharacterAdded:Connect(function(newChar)
				task.wait(0.1)
				applyInvisFlyTranslucency(newChar)
			end)

			applyInvisFlyTranslucency(LocalPlayer.Character)

			invisibleFlyVars.playerClone = LocalPlayer.Character:Clone()
			invisibleFlyVars.playerClone.Parent = workspace

			-- Create and apply highlight
			local hl = Instance.new("Highlight")
			hl.FillColor = Options.InvisibleFlyFillColor.Value
			hl.OutlineColor = Options.InvisibleFlyOutlineColor.Value
			hl.FillTransparency = 0.65
			hl.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
			hl.Adornee = invisibleFlyVars.playerClone
			hl.Enabled = true
			hl.Parent = workspace
			invisibleFlyVars.highlight = hl

			while invisibleFlyVars.invisiblefly do
				RunService.Heartbeat:Wait()

				if not (invisibleFlyVars.playerClone and invisibleFlyVars.playerClone:FindFirstChild("HumanoidRootPart")) then
					break
				end

				-- Update highlight colors in real-time
				if invisibleFlyVars.highlight then
					invisibleFlyVars.highlight.FillColor = Options.InvisibleFlyFillColor.Value
					invisibleFlyVars.highlight.OutlineColor = Options.InvisibleFlyOutlineColor.Value
				end

				local root = getRootPart()
				local hum = getHumanoid()

				if not (root and hum and invisibleFlyVars.playerClone) then
					return
				end

				workspace.CurrentCamera.CameraSubject = invisibleFlyVars.playerClone:FindFirstChild("Humanoid") or hum
				hum:ChangeState("Climbing")
				invisibleFlyVars.lastClonePivot = invisibleFlyVars.playerClone:GetPivot()
				LocalPlayer.Character:PivotTo(invisibleFlyVars.lastClonePivot + Vector3.new(0, 500, 0))
				root.Velocity = Vector3.zero

				local lookPosition = workspace.CurrentCamera.CFrame.Position + workspace.CurrentCamera.CFrame.LookVector * 9999

				invisibleFlyVars.playerClone.HumanoidRootPart.CFrame = CFrame.new(
					invisibleFlyVars.playerClone.HumanoidRootPart.Position,
					Vector3.new(lookPosition.X, invisibleFlyVars.playerClone.HumanoidRootPart.Position.Y, lookPosition.Z)
				)
				invisibleFlyVars.playerClone.HumanoidRootPart.Anchored = true

				invisibleFlyVars.playerClone.HumanoidRootPart.CFrame = CFrame.new(
					invisibleFlyVars.playerClone.HumanoidRootPart.Position + hum.MoveDirection / 10 * Options.InvisibleFlySpeedSlider.Value,
					Vector3.new(lookPosition.X, invisibleFlyVars.playerClone.HumanoidRootPart.Position.Y, lookPosition.Z)
				)

				if UserInputService:IsKeyDown(Enum.KeyCode.Space) then
					invisibleFlyVars.playerClone.HumanoidRootPart.CFrame = CFrame.new(
						invisibleFlyVars.playerClone.HumanoidRootPart.Position + Vector3.new(0, 0.2, 0),
						Vector3.new(lookPosition.X, invisibleFlyVars.playerClone.HumanoidRootPart.Position.Y, lookPosition.Z)
					)
				end

				if UserInputService:IsKeyDown(Enum.KeyCode.LeftShift) then
					invisibleFlyVars.playerClone.HumanoidRootPart.CFrame = CFrame.new(
						invisibleFlyVars.playerClone.HumanoidRootPart.Position - Vector3.new(0, 0.2, 0),
						Vector3.new(lookPosition.X, invisibleFlyVars.playerClone.HumanoidRootPart.Position.Y, lookPosition.Z)
					)
				end

				invisibleFlyVars.lastClonePivot = invisibleFlyVars.playerClone:GetPivot()
			end

			workspace.CurrentCamera.CameraSubject = getHumanoid()

			if invisibleFlyVars.characterAddedConn then
				invisibleFlyVars.characterAddedConn:Disconnect()
				invisibleFlyVars.characterAddedConn = nil
			end
			restoreInvisFlyTranslucency()

			if invisibleFlyVars.highlight then
				invisibleFlyVars.highlight:Destroy()
				invisibleFlyVars.highlight = nil
			end

			if invisibleFlyVars.playerClone then
				local finalPivot = invisibleFlyVars.lastClonePivot or invisibleFlyVars.playerClone:GetPivot()
				invisibleFlyVars.playerClone:Destroy()
				invisibleFlyVars.playerClone = nil
				if finalPivot then
					pcall(function() LocalPlayer.Character:PivotTo(finalPivot) end)
				end
			end
			invisibleFlyVars.lastClonePivot = nil
		end)
	else
		if invisibleFlyVars.wasInvisibleFlyEnabled then
			if invisibleFlyVars.characterAddedConn then
				invisibleFlyVars.characterAddedConn:Disconnect()
				invisibleFlyVars.characterAddedConn = nil
			end
			restoreInvisFlyTranslucency()

			if invisibleFlyVars.highlight then
				invisibleFlyVars.highlight:Destroy()
				invisibleFlyVars.highlight = nil
			end

			if invisibleFlyVars.playerClone then
				local finalPivot = invisibleFlyVars.lastClonePivot or invisibleFlyVars.playerClone:GetPivot()
				invisibleFlyVars.playerClone:Destroy()
				invisibleFlyVars.playerClone = nil
				if finalPivot then
					pcall(function() LocalPlayer.Character:PivotTo(finalPivot) end)
				end
			elseif invisibleFlyVars.lastClonePivot then
				pcall(function() LocalPlayer.Character:PivotTo(invisibleFlyVars.lastClonePivot) end)
			end
			invisibleFlyVars.wasInvisibleFlyEnabled = false
			invisibleFlyVars.lastClonePivot = nil
		end
	end
end

Toggles.InvisibleFlyToggle:OnChanged(onInvisibleFlyToggle)

local quickVanishTriggered = false

local function checkQuickVanish()
	if not Toggles.QuickVanish or not Toggles.QuickVanish.Value or not isAlive() then return end
	local hum = getHumanoid()
	if not hum or hum.Health <= 0 then return end

	local threshold = Options.QuickVanishThreshold and Options.QuickVanishThreshold.Value or 35

	if hum.Health > threshold then
		quickVanishTriggered = false
	elseif hum.Health <= threshold and not quickVanishTriggered then
		if not (Toggles.InvisibleFlyToggle and Toggles.InvisibleFlyToggle.Value) and not invisibleFlyVars.invisiblefly then
			quickVanishTriggered = true
			if Toggles.InvisibleFlyToggle then
				Toggles.InvisibleFlyToggle:SetValue(true)
			else
				onInvisibleFlyToggle(true)
			end
			Library:Notify({
				Title = "Quick Vanish",
				Description = string.format("Health low (%.0f HP)! Invis Fly activated.", hum.Health),
				Time = 3,
			})
		end
	end
end

Toggles.QuickVanish:OnChanged(function()
	disconnect("QuickVanish")
	quickVanishTriggered = false
	if Toggles.QuickVanish.Value then
		track("QuickVanish", RunService.Heartbeat:Connect(checkQuickVanish))
		Library:Notify({ Title = "Quick Vanish", Description = "Enabled", Time = 2 })
	else
		Library:Notify({ Title = "Quick Vanish", Description = "Disabled", Time = 2 })
	end
end)

local function updateTeleportPlayerList()
	local list = {}
	for _, player in ipairs(Players:GetPlayers()) do
		if player ~= LocalPlayer then
			table.insert(list, player.Name)
		end
	end
	pcall(function()
		Options.TeleportPlayerList:SetValues(list)
		if #list > 0 then
			if not table.find(list, Options.TeleportPlayerList.Value) then
				Options.TeleportPlayerList:SetValue(list[1])
			end
		else
			Options.TeleportPlayerList:SetValue("")
		end
	end)
end

track("TeleportPlayerAdded", Players.PlayerAdded:Connect(updateTeleportPlayerList))
track("TeleportPlayerRemoving", Players.PlayerRemoving:Connect(updateTeleportPlayerList))
task.spawn(updateTeleportPlayerList)

-- ==========================================
-- UI SETTINGS
-- ==========================================
local MenuGroup = Tabs["UI Settings"]:AddLeftGroupbox("Menu", "wrench")

MenuGroup:AddToggle("KeybindMenuOpen", {
	Default = Library.KeybindFrame.Visible,
	Text = "Open Keybind Menu",
	Callback = function(value)
		Library.KeybindFrame.Visible = value
	end,
})

MenuGroup:AddToggle("ShowCustomCursor", {
	Text = "Custom Cursor",
	Default = true,
	Callback = function(value)
		Library.ShowCustomCursor = value
	end,
})

MenuGroup:AddDropdown("NotificationSide", {
	Values = { "Left", "Right" },
	Default = "Right",
	Text = "Notification Side",
	Callback = function(value)
		Library:SetNotifySide(value)
	end,
})

MenuGroup:AddDropdown("DPIDropdown", {
	Values = { "50%", "75%", "100%", "125%", "150%", "175%", "200%" },
	Default = "100%",

	Text = "DPI Scale",

	Callback = function(Value)
		Value = Value:gsub("%%", "")
		local DPI = tonumber(Value)

		Library:SetDPIScale(DPI)
	end,
})

MenuGroup:AddSlider("UICornerSlider", {
	Text = "Corner Radius",
	Default = Library.CornerRadius,
	Min = 0,
	Max = 20,
	Rounding = 0,
	Compact = true,
	Callback = function(value)
		Window:SetCornerRadius(value)
	end
})

MenuGroup:AddLabel("Menu bind"):AddKeyPicker("MenuKeybind", {
	Default = "RightShift",
	NoUI = true,
	Text = "Menu keybind",
})

MenuGroup:AddButton("Unload", function()
	Library:Unload()
end)

Library.ToggleKeybind = Options.MenuKeybind

ThemeManager:SetLibrary(Library)
-- Set default accent color to red
ThemeManager:SetDefaultTheme({
	AccentColor = "ff0000" -- Red
})
SaveManager:SetLibrary(Library)
SaveManager:IgnoreThemeSettings()
SaveManager:SetIgnoreIndexes({ "MenuKeybind" })
ThemeManager:SetFolder("TSG")
SaveManager:SetFolder("TSG/TheSurvivalGame")

SaveManager:BuildConfigSection(Tabs["UI Settings"])
ThemeManager:ApplyToTab(Tabs["UI Settings"])
SaveManager:LoadAutoloadConfig()
if not (Toggles.Noclip and Toggles.Noclip.Value) then
	restoreCharacterCollisions(getCharacter())
end



Library:OnUnload(function()
	if Toggles.Reach and Toggles.Reach.Value then
		Toggles.Reach:SetValue(false)
	end
	if Toggles.ImmortalMode and Toggles.ImmortalMode.Value then
		Toggles.ImmortalMode:SetValue(false)
	end
	if Toggles.BypassShield and Toggles.BypassShield.Value then
		Toggles.BypassShield:SetValue(false)
	end
	if Toggles.TouchFling and Toggles.TouchFling.Value then
		Toggles.TouchFling:SetValue(false)
	end
	if Toggles.InfiniteBackpack and Toggles.InfiniteBackpack.Value then
		Toggles.InfiniteBackpack:SetValue(false)
	end

	if Toggles.NoWaterBlur and Toggles.NoWaterBlur.Value then
		Toggles.NoWaterBlur:SetValue(false)
	end
	if Toggles.LowTextures and Toggles.LowTextures.Value then
		Toggles.LowTextures:SetValue(false)
	end

	pcall(function()
		local lighting = game:GetService("Lighting")
		local blur = lighting:FindFirstChild("TSG_Smoothness_Blur")
		if blur then blur:Destroy() end
		local bloom = lighting:FindFirstChild("TSG_Smoothness_Bloom")
		if bloom then bloom:Destroy() end
		local cc = lighting:FindFirstChild("TSG_Smoothness_Color")
		if cc then cc:Destroy() end
	end)
	if Toggles.RemoveParticles and Toggles.RemoveParticles.Value then
		Toggles.RemoveParticles:SetValue(false)
	end
	if Toggles.KillHeavyPostEffects and Toggles.KillHeavyPostEffects.Value then
		Toggles.KillHeavyPostEffects:SetValue(false)
	end
	if Toggles.DisableRenderFog and Toggles.DisableRenderFog.Value then
		Toggles.DisableRenderFog:SetValue(false)
	end
	if Toggles.NoGrass and Toggles.NoGrass.Value then
		Toggles.NoGrass:SetValue(false)
	end

	if Toggles.TitanAura and Toggles.TitanAura.Value then
		Toggles.TitanAura:SetValue(false)
	end
	if Toggles.SamuraiAura and Toggles.SamuraiAura.Value then
		Toggles.SamuraiAura:SetValue(false)
	end
	if Toggles.JuggernautAura and Toggles.JuggernautAura.Value then
		Toggles.JuggernautAura:SetValue(false)
	end
	if Toggles.WalkOnWater and Toggles.WalkOnWater.Value then
		Toggles.WalkOnWater:SetValue(false)
	end
	if Toggles.AntiAFK and Toggles.AntiAFK.Value then
		Toggles.AntiAFK:SetValue(false)
	end
	if Toggles.AimbotLockOn and Toggles.AimbotLockOn.Value then
		Toggles.AimbotLockOn:SetValue(false)
	end

	if Toggles.AttachToggle and Toggles.AttachToggle.Value then
		Toggles.AttachToggle:SetValue(false)
	end
	if Toggles.PlusKillPlayerToggle and Toggles.PlusKillPlayerToggle.Value then
		Toggles.PlusKillPlayerToggle:SetValue(false)
	end

	if Toggles.HideBeneathToggle and Toggles.HideBeneathToggle.Value then
		Toggles.HideBeneathToggle:SetValue(false)
	end
	if Toggles.FloatOverToggle and Toggles.FloatOverToggle.Value then
		Toggles.FloatOverToggle:SetValue(false)
	end
	if Toggles.SpectateToggle and Toggles.SpectateToggle.Value then
		Toggles.SpectateToggle:SetValue(false)
	end
	if Toggles.TouchFling and Toggles.TouchFling.Value then
		Toggles.TouchFling:SetValue(false)
	end
	if Toggles.HelicopterTroll and Toggles.HelicopterTroll.Value then
		Toggles.HelicopterTroll:SetValue(false)
	end
	if Toggles.NoBearTrapDMG and Toggles.NoBearTrapDMG.Value then
		Toggles.NoBearTrapDMG:SetValue(false)
	end
	if Toggles.AutoHop and Toggles.AutoHop.Value then
		Toggles.AutoHop:SetValue(false)
	end
	if Toggles.SwordBot and Toggles.SwordBot.Value then
		Toggles.SwordBot:SetValue(false)
	end
	if Toggles.PlusSpeedBoost and Toggles.PlusSpeedBoost.Value then
		Toggles.PlusSpeedBoost:SetValue(false)
	end
	if Toggles.MountSpeedBoost and Toggles.MountSpeedBoost.Value then
		Toggles.MountSpeedBoost:SetValue(false)
	end
	if Toggles.SwimSlotBoost and Toggles.SwimSlotBoost.Value then
		Toggles.SwimSlotBoost:SetValue(false)
	end
	if Toggles.AutoShiftlock and Toggles.AutoShiftlock.Value then
		Toggles.AutoShiftlock:SetValue(false)
	end
	if Toggles.Camlock and Toggles.Camlock.Value then
		Toggles.Camlock:SetValue(false)
	end
	if Toggles.Outline and Toggles.Outline.Value then
		Toggles.Outline:SetValue(false)
	end
	if Toggles.CamlockIgnoreTeam and Toggles.CamlockIgnoreTeam.Value then
		Toggles.CamlockIgnoreTeam:SetValue(false)
	end
	if Toggles.SpearSword and Toggles.SpearSword.Value then
		Toggles.SpearSword:SetValue(false)
	end
	if Toggles.LookDownFloor and Toggles.LookDownFloor.Value then
		Toggles.LookDownFloor:SetValue(false)
	end
	if Toggles.InvisibleFlyToggle and Toggles.InvisibleFlyToggle.Value then
		Toggles.InvisibleFlyToggle:SetValue(false)
	end
	if Toggles.QuickVanish and Toggles.QuickVanish.Value then
		Toggles.QuickVanish:SetValue(false)
	end
	if Toggles.OreESPToggle and Toggles.OreESPToggle.Value then
		Toggles.OreESPToggle:SetValue(false)
	end

	if Toggles.FastPickup and Toggles.FastPickup.Value then
		Toggles.FastPickup:SetValue(false)
	end

	pcall(function()
		if fovCircle then fovCircle:Remove() end

		if autoShiftlockVars then
			if autoShiftlockVars.charAddedCon then autoShiftlockVars.charAddedCon:Disconnect() end
			if autoShiftlockVars.dragCon1 then autoShiftlockVars.dragCon1:Disconnect() end
			if autoShiftlockVars.dragCon2 then autoShiftlockVars.dragCon2:Disconnect() end
			if autoShiftlockVars.dragCon3 then autoShiftlockVars.dragCon3:Disconnect() end
			if autoShiftlockVars.activatedCon then autoShiftlockVars.activatedCon:Disconnect() end
			if autoShiftlockVars.renderCon then autoShiftlockVars.renderCon:Disconnect() end
			if autoShiftlockVars.screenGui then autoShiftlockVars.screenGui:Destroy() end
		end
	end)
	for name in pairs(Connections) do
		disconnect(name)
	end
	clearESP()
	pcall(function() clearOreESPHighlights() end)
	highlightTarget:Destroy()
	workspace.Gravity = 196.2
	LocalPlayer.CameraMaxZoomDistance = 400
	LocalPlayer.CameraMinZoomDistance = 0.5
	getgenv().TSG_OBSIDIAN_LOADED = nil
end)

Library:Notify({
	Title = "♠ URIEL",
	Description = "Script loaded successfully!",
	Time = 2,
})
