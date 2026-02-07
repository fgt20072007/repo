local HttpService = game:GetService("HttpService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local ServerScriptService = game:GetService("ServerScriptService")

local Shared = ReplicatedStorage.Shared

local Server = require(ServerScriptService.Server)
local Zone = require(Shared.Packages.Zone)

local KOTHContainer = workspace:FindFirstChild("Code") and workspace.Code:FindFirstChild("KOTH")

local function SetOwnership(Area, King: Player?, noOne: boolean)
	local billboard = Area:FindFirstChild("BillboardGui")
	if not billboard then return end

	local icon = billboard:FindFirstChild("Icon")
	if not icon then return end

	if noOne or not King then
		icon.Image = ""
		icon.Visible = true
		return
	end

	local success, thumbnail = pcall(function()
		return Players:GetUserThumbnailAsync(King.UserId, Enum.ThumbnailType.HeadShot, Enum.ThumbnailSize.Size420x420)
	end)

	icon.Image = success and thumbnail or ""
	icon.Visible = true
end

local KOTHService = {}

function KOTHService._Init(self: KOTHService)
	if not KOTHContainer then return end

	local area = KOTHContainer:FindFirstChild("Area")
	if not area then return end

	local kothZone = Zone.new(area)
	local id = HttpService:GenerateGUID(false)
	local Immutable = Server.GetImmutable()

	self.Hills = {}
	self.Hills[id] = {
		Model = KOTHContainer,
		PlayersInArea = {},
		PlayersInAreaSet = {},
		RewardAccumulator = 0,
	}

	local function GetNextKing(hill)
		for player in hill.PlayersInAreaSet do
			return player
		end
		return nil
	end

	local function SetKing(hill, player: Player?)
		hill.King = player
		SetOwnership(hill.Model.Area, player, player == nil)
	end

	kothZone.playerEntered:Connect(function(player)
		local hill = self.Hills[id]
		if hill.PlayersInAreaSet[player] then return end

		hill.PlayersInAreaSet[player] = true
		table.insert(hill.PlayersInArea, player)

		if not hill.King then
			SetKing(hill, player)
		end
	end)

	kothZone.playerExited:Connect(function(player)
		local hill = self.Hills[id]
		if not hill.PlayersInAreaSet[player] then return end

		hill.PlayersInAreaSet[player] = nil

		local index = table.find(hill.PlayersInArea, player)
		if index then table.remove(hill.PlayersInArea, index) end

		if hill.King ~= player then return end
		SetKing(hill, GetNextKing(hill))
	end)

	RunService.Heartbeat:Connect(function(deltaTime)
		local hill = self.Hills[id]
		local king = hill.King
		if not king then
			hill.RewardAccumulator = 0
			return
		end

		if king.Parent ~= Players then
			hill.PlayersInAreaSet[king] = nil
			local index = table.find(hill.PlayersInArea, king)
			if index then table.remove(hill.PlayersInArea, index) end
			SetKing(hill, GetNextKing(hill))
			hill.RewardAccumulator = 0
			return
		end

		hill.RewardAccumulator += deltaTime
		if hill.RewardAccumulator < Immutable.KOTH_REWARD_COOLDOWN then return end

		local ticks = math.floor(hill.RewardAccumulator / Immutable.KOTH_REWARD_COOLDOWN)
		hill.RewardAccumulator -= ticks * Immutable.KOTH_REWARD_COOLDOWN
		if ticks <= 0 then return end

		Server.Services.DataService:Increment(king, "Shards", Immutable.KOTH_REWARD_AMOUNT * ticks)
		Server.Services.DataService:Increment(king, "KOTHTime", ticks)
	end)
end

type KOTHService = typeof(KOTHService) & {
	Hills: { [string]: { Model: Model, King: Player?, PlayersInArea: { Player }, PlayersInAreaSet: { [Player]: boolean }, RewardAccumulator: number } },
}

return KOTHService