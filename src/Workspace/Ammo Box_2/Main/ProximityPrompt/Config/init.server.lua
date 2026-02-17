--!strict
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerStorage = game:GetService("ServerStorage")

local Packages = ReplicatedStorage:WaitForChild("Packages")
local Net = require(Packages:WaitForChild("Net"))
local RateLimit = require(Packages:WaitForChild("ReplicaShared"):WaitForChild("RateLimit"))

local Data = ReplicatedStorage:WaitForChild("Data")
local GeneralData = require(Data:WaitForChild("General"))

local DataService = require(ServerStorage:WaitForChild("Services"):WaitForChild("DataService"))
local ToolsPath = ServerStorage:WaitForChild("ServerAssets"):WaitForChild("Tools")

local NotifyEvent = Net:RemoteEvent("Notification")
local Prompt = script.Parent :: ProximityPrompt
local PromptOwner = Prompt.Parent

local Engine = ReplicatedStorage:FindFirstChild("ACS_MICTLAN") or ReplicatedStorage:FindFirstChild("ACS_Engine")

local Events = Engine:FindFirstChild("Events")

local RefilEvent = Events:FindFirstChild("Refil")

local RefilRemote = RefilEvent :: RemoteEvent

-- Settings
local Universal = true
local BulletType = "Universal"
local Infinite = true
local Stored = script:WaitForChild("Stored") :: IntValue
local DEFAULT_PRICE = 750
local FEDERAL_TAG = "Federal"

local PurchaseRateLimit = RateLimit.New(3)

local function GetPrice(): number
	local configuredPrice = (GeneralData :: any).AmmoBoxPrice
	if typeof(configuredPrice) ~= "number" then
		return DEFAULT_PRICE
	end

	return math.max(0, math.floor(configuredPrice))
end

local function IsFederalPlayer(player: Player): boolean
	local team = player.Team
	return team ~= nil and team:HasTag(FEDERAL_TAG)
end

local function IsGunTool(tool: Tool): (boolean, {[any]: any}?)
	local settingsModule = tool:FindFirstChild("ACS_Settings")
		or tool:FindFirstChild("GunSettings")
	if not (settingsModule and settingsModule:IsA("ModuleScript")) then
		return false, nil
	end

	local success, settings = pcall(require, settingsModule)
	if not success or typeof(settings) ~= "table" then
		return false, nil
	end

	if settings.Type ~= "Gun" then
		return false, nil
	end

	return true, settings
end

local function IsAllowedBullet(settings: {[any]: any}?): boolean
	if Universal then
		return true
	end

	return settings ~= nil and settings.BulletType == BulletType
end

local function ReplaceWithFullAmmoClone(player: Player, tool: Tool): Tool?
	local template = ToolsPath:FindFirstChild(tool.Name)
	if not (template and template:IsA("Tool")) then
		return nil
	end

	local parent = tool.Parent
	if not parent then
		return nil
	end

	local character = player.Character
	local humanoid = character and character:FindFirstChildOfClass("Humanoid")
	local backpack = player:FindFirstChildOfClass("Backpack")
	local wasEquipped = character ~= nil and parent == character

	if wasEquipped and humanoid then
		humanoid:UnequipTools()
	end

	local targetParent = if wasEquipped and backpack then backpack else parent
	local clone = template:Clone()
	clone.Name = tool.Name

	-- Detach first so runtime does not alter the new tool identity/order unexpectedly.
	tool.Parent = nil
	clone.Parent = targetParent
	tool:Destroy()

	if wasEquipped and humanoid and clone.Parent == backpack then
		task.defer(function()
			if clone.Parent == backpack then
				humanoid:EquipTool(clone)
			end
		end)
	end

	return clone
end

local function RefillGunIfAllowed(player: Player, tool: Tool): boolean
	local isGun, settings = IsGunTool(tool)
	if not isGun then return false end
	if not Infinite and Stored.Value <= 0 then return false end

	if not IsAllowedBullet(settings) then return false end

	local replaced = ReplaceWithFullAmmoClone(player, tool)
	if replaced then
		-- Legacy ACS hook (if any listener exists on the client build).
		RefilRemote:FireClient(player, replaced, Infinite, Stored)
		return true
	end

	-- Fallback for tools that do not exist in ServerAssets.Tools.
	RefilRemote:FireClient(player, tool, Infinite, Stored)
	return true
end

local function RefillAllPlayerGuns(player: Player): number
	local filled = 0

	local backpack = player:FindFirstChildOfClass("Backpack")
	if backpack then
		for _, child in backpack:GetChildren() do
			if not child:IsA("Tool") then continue end
			if RefillGunIfAllowed(player, child) then
				filled += 1
			end
		end
	end

	local character = player.Character
	if character then
		for _, child in character:GetChildren() do
			if not child:IsA("Tool") then continue end
			if RefillGunIfAllowed(player, child) then
				filled += 1
			end
		end
	end

	local starterGear = player:FindFirstChildOfClass("StarterGear")
	if starterGear then
		for _, child in starterGear:GetChildren() do
			if not child:IsA("Tool") then continue end
			if RefillGunIfAllowed(player, child) then
				filled += 1
			end
		end
	end

	return filled
end



-- Detect when prompt is triggered
local function OnPromptTriggered(player: Player)
	if not PurchaseRateLimit:CheckRate(player) then return end

	local character = player.Character
	local humanoid = character and character:FindFirstChildOfClass("Humanoid")
	if not humanoid or humanoid.Health <= 0 then return end

	local price = IsFederalPlayer(player) and 0 or GetPrice()
	if price > 0 then
		local balance = DataService.GetBalance(player) or 0
		if balance < price then
			NotifyEvent:FireClient(player, "AmmoBox/NotEnoughCash", {
				needed = price - balance,
			})
			return
		end

		local paid = DataService.AdjustBalance(player, -price)
		if not paid then
			NotifyEvent:FireClient(player, "AmmoBox/NotEnoughCash", {
				needed = math.max(1, price - (DataService.GetBalance(player) or 0)),
			})
			return
		end
	end

	local filledCount = RefillAllPlayerGuns(player)
	if filledCount <= 0 then
		if price > 0 then
			DataService.AdjustBalance(player, price)
		end
		NotifyEvent:FireClient(player, "AmmoBox/NoWeapons")
		return
	end

	local refillSound = PromptOwner:FindFirstChild("RefilSound")
	if refillSound and refillSound:IsA("Sound") then
		refillSound:Play()
	end

	NotifyEvent:FireClient(player, "AmmoBox/Purchased")
end

-- Connect prompt events to handling functions
Prompt.Triggered:Connect(OnPromptTriggered)
