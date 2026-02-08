-- Services
local ReplicatedStorage = game:GetService('ReplicatedStorage')
local ServerScriptService = game:GetService('ServerScriptService')

-- Variables

-- Dependencies
local DataService = require(ReplicatedStorage.Utilities.DataService)
local InventoryHandler = require(ServerScriptService.Components.InventoryHandler)
local Gears = require(ReplicatedStorage.DataModules.Gears)

local ServerOnlyUtilities = {}

local RewardTypeAliases = {
	entity = "Entity",
	luckybox = "Luckybox",
	luckyblock = "Luckybox",
	cash = "Cash",
	cashamount = "Cash",
	gear = "Gear",
	permanentgear = "Gear",
}

local list = {
	Entity = function(plr, a1)
		if typeof(a1) ~= "string" then
			warn("The entity reward is invalid: " .. tostring(a1))
			return
		end

		InventoryHandler.CacheTool(plr, "Entity", {
			name = a1,
			mutation = "Normal"
		})
	end,
	Luckyblock = function(plr, a1)
		if typeof(a1) ~= "string" then
			warn("The luckybox reward is invalid: " .. tostring(a1))
			return
		end

		InventoryHandler.CacheTool(plr, "Luckybox", {
			name = a1,
			mutation = "Normal"
		})
	end,
	Luckybox = function(plr, a1)
		if typeof(a1) ~= "string" then
			warn("The luckybox reward is invalid: " .. tostring(a1))
			return
		end

		InventoryHandler.CacheTool(plr, "Luckybox", {
			name = a1,
			mutation = "Normal"
		})
	end,
	Cash = function(plr, a1)
		local amount = tonumber(a1)
		if not amount then
			warn("The cash reward is invalid: " .. tostring(a1))
			return
		end

		DataService.server:update(plr, "cash", function(old)
			return old + amount
		end)
	end,
	Gear = function(plr, a1)
		if typeof(a1) ~= "string" or not Gears[a1] then
			warn("The gear reward is invalid: " .. tostring(a1))
			return
		end

		local gears = DataService.server:get(plr, "gears") or {}
		if table.find(gears, a1) then
			return
		end

		DataService.server:arrayInsert(plr, "gears", a1)
		InventoryHandler.AddToolsAndClear(plr)
	end,
}

local function normalizeRewardType(rewardType)
	if typeof(rewardType) ~= "string" then
		return nil
	end

	return RewardTypeAliases[string.lower(rewardType)] or rewardType
end

local function parseReward(player: Player, rewardType, rewardValue)
	local normalizedRewardType = normalizeRewardType(rewardType)
	if not normalizedRewardType then
		warn("The reward type you used is not correct: " .. tostring(rewardType))
		return
	end

	local parser = list[normalizedRewardType]
	if not parser then
		warn("The reward type you used is not correct: " .. tostring(rewardType))
		return
	end

	parser(player, rewardValue)
end

function ServerOnlyUtilities.ParseTableForRewards(player: Player, t: {})
	local usedReadableKeys = {}

	for rewardKey, rewardValue in t do
		if typeof(rewardKey) ~= "string" then
			continue
		end

		local normalizedRewardType = RewardTypeAliases[string.lower(rewardKey)]
		if normalizedRewardType then
			parseReward(player, normalizedRewardType, rewardValue)
			usedReadableKeys[rewardKey] = true
		end
	end

	for rewardKey, rewardType in t do
		if usedReadableKeys[rewardKey] then
			continue
		end

		parseReward(player, rewardType, rewardKey)
	end
end

return ServerOnlyUtilities