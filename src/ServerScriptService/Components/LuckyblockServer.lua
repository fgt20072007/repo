local ReplicatedStorage = game:GetService('ReplicatedStorage')
local Players = game:GetService('Players')

local LuckyBlocksData = require(ReplicatedStorage.DataModules.LuckyBlocksData)

local WeightedRNG = require(ReplicatedStorage.Utilities.WeightedRNG)
local LuckHandler = require("./LuckHandler")

local LuckyBlockHandler = {}
local Debounces = {}
local Lucks = {}

function LuckyBlockHandler.GetCurrentLuck(player)
	return LuckHandler.GetLuckyblockLuck(player) 
end

function LuckyBlockHandler.OpenLuckyblock(player, luckyblockName: string)
	local data = LuckyBlocksData[luckyblockName]
	if data then
		if Debounces[player][luckyblockName] then return end
		local RandomEntity = WeightedRNG.get(data.Findables, 
			LuckyBlockHandler.GetCurrentLuck(player)
		)
		
		if RandomEntity then
			Debounces[player][luckyblockName] = true
			task.delay(data.DelayBetweenRolls, function()
				Debounces[player][luckyblockName] = false
			end)
			return RandomEntity
		end
	end
end

function LuckyBlockHandler.Initialize()
	Players.PlayerAdded:Connect(function(player)
		Debounces[player] = {}
	end)
	
	ReplicatedStorage.Communication.Functions.OpenLuckyblock.OnServerInvoke = function(...)
		return LuckyBlockHandler.OpenLuckyblock(...)
	end
end

return LuckyBlockHandler