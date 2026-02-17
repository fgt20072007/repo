--!strict
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerStorage = game:GetService("ServerStorage")

local Packages = ReplicatedStorage.Packages
local Net = require(Packages.Net)
local RateLimit = require(Packages.ReplicaShared.RateLimit)

local Data = ReplicatedStorage.Data
local GeneralData = require(Data.General)

local Services = ServerStorage.Services
local DataService = require(Services.DataService)

local NotifyEvent = Net:RemoteEvent("Notification")

local ToolsPath = ServerStorage.ServerAssets.Tools

local DEFAULT_REWARD = 100
local BOX_NAME = "Box"

local GetRateLimit = RateLimit.New(3)
local DepositRateLimit = RateLimit.New(3)

local Manager = {}

local function IsFederal(player: Player): boolean
	local team = player.Team
	return team and team:HasTag("Federal") or false
end

local function GetBoxTemplate(): Tool?
	local found = ToolsPath:FindFirstChild(BOX_NAME)
	if found and found:IsA("Tool") then
		return found
	end
	return nil
end

local function ResolvePrompt(node: Instance?): ProximityPrompt?
	if not node then return nil end

	local attachment = node:FindFirstChild("Attachment")
	if not attachment then return nil end

	local named = attachment:FindFirstChild("Prompt")
	if named and named:IsA("ProximityPrompt") then
		return named
	end

	return attachment:FindFirstChildOfClass("ProximityPrompt") :: ProximityPrompt?
end

local function FindTool(container: Instance?): Tool?
	if not container then return nil end

	local found = container:FindFirstChild(BOX_NAME)
	if found and found:IsA("Tool") then
		return found
	end

	return nil
end

function Manager._HasBox(player: Player): boolean
	return FindTool(player.Character) ~= nil
		or FindTool(player:FindFirstChildOfClass("Backpack")) ~= nil
		or FindTool(player:FindFirstChildOfClass("StarterGear")) ~= nil
end

function Manager._GetEquippedBox(player: Player): Tool?
	local character = player.Character
	if not character then return nil end

	local equipped = character:FindFirstChildOfClass("Tool") :: Tool?
	if equipped and equipped.Name == BOX_NAME then
		return equipped
	end

	return nil
end

function Manager._DestroyAllBoxes(player: Player)
	local backpack = player:FindFirstChildOfClass("Backpack")
	local starterGear = player:FindFirstChildOfClass("StarterGear")
	local character = player.Character

	local containers = {character, backpack, starterGear}
	for _, container in containers do
		if not container then continue end
		for _, child in container:GetChildren() do
			if not child:IsA("Tool") then continue end
			if child.Name ~= BOX_NAME then continue end
			child:Destroy()
		end
	end
end

function Manager._OnGetTriggered(player: Player)
	if not GetRateLimit:CheckRate(player) then return end

	if IsFederal(player) then
		Manager._DestroyAllBoxes(player)
		NotifyEvent:FireClient(player, "BoxDelivery/FedBlocked")
		return
	end

	local backpack = player:FindFirstChildOfClass("Backpack")
	if not backpack then return end

	local boxTemplate = GetBoxTemplate()
	if not boxTemplate then return end

	if Manager._HasBox(player) then
		NotifyEvent:FireClient(player, "BoxDelivery/AlreadyCarrying")
		return
	end

	local clone = boxTemplate:Clone()
	clone.Parent = backpack

	NotifyEvent:FireClient(player, "BoxDelivery/PickedUp")
end

function Manager._OnDepositTriggered(player: Player)
	if not DepositRateLimit:CheckRate(player) then return end

	if IsFederal(player) then
		Manager._DestroyAllBoxes(player)
		NotifyEvent:FireClient(player, "BoxDelivery/FedBlocked")
		return
	end

	local equipped = Manager._GetEquippedBox(player)
	if not equipped then
		NotifyEvent:FireClient(player, "BoxDelivery/MustEquip")
		return
	end

	equipped:Destroy()
	Manager._DestroyAllBoxes(player)

	local rewardValue = (GeneralData :: any).BoxDeliveryReward
	local reward = DEFAULT_REWARD
	if typeof(rewardValue) == "number" then
		reward = rewardValue
	end
	reward = math.max(0, math.floor(reward))

	if reward > 0 then
		DataService.AdjustBalance(player, reward)
	end

	NotifyEvent:FireClient(player, "BoxDelivery/Delivered", {
		cash = reward,
	})
end

function Manager._BindCharacter(player: Player, character: Model)
	local humanoid = character:FindFirstChildOfClass("Humanoid") :: Humanoid?
	if not humanoid then
		humanoid = character:WaitForChild("Humanoid", 5) :: Humanoid?
	end
	if not humanoid then return end

	humanoid.Died:Connect(function()
		Manager._DestroyAllBoxes(player)
	end)
end

function Manager._BindPlayer(player: Player)
	player.CharacterAdded:Connect(function(character: Model)
		Manager._BindCharacter(player, character)
	end)

	if player.Character then
		task.defer(Manager._BindCharacter, player, player.Character)
	end
end

function Manager.Init()
	if not GetBoxTemplate() then return end

	local boxes = workspace:WaitForChild("Boxes", 15)
	if not boxes then return end

	local getPrompt = ResolvePrompt(boxes:WaitForChild("Get"))
	local depositPrompt = ResolvePrompt(boxes:WaitForChild("Deposit"))
	if not getPrompt or not depositPrompt then return end

	getPrompt.Triggered:Connect(Manager._OnGetTriggered)
	depositPrompt.Triggered:Connect(Manager._OnDepositTriggered)

	Players.PlayerAdded:Connect(Manager._BindPlayer)
	for _, player in Players:GetPlayers() do
		task.defer(Manager._BindPlayer, player)
	end
end

return table.freeze(Manager)
