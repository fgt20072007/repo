-- Services
local ReplicatedStorage = game:GetService('ReplicatedStorage')
local ServerScriptService = game:GetService('ServerScriptService')
local Players = game:GetService('Players')

-- Variables

-- Dependencies
local DataService = require(ReplicatedStorage.Utilities.DataService)
local InventoryHandler = require(ServerScriptService.Components.InventoryHandler)

local ServerOnlyUtilities = {}

local list = {
	Entity = function(plr, a1)
		InventoryHandler.CacheTool(plr, "Entity", {
			name = a1,
			mutation = "Normal"
		})
	end,
	Luckyblock = function(plr, a1)
		InventoryHandler.CacheTool(plr, "Luckybox", {
			name = a1,
			mutation = "Normal"
		})
	end,
	Luckybox = function(plr, a1)
		InventoryHandler.CacheTool(plr, "Luckybox", {
			name = a1,
			mutation = "Normal"
		})
	end,
	Cash = function(plr, a1)
		DataService.server:update(plr, "cash", function(old)
			return old + a1
		end)
	end,
}

function ServerOnlyUtilities.ParseTableForRewards(player: Player, t: {})
	for a1, Type in t do
		if list[Type] then
			list[Type](player, a1)
		else
			warn("The reward type you used is not correct: " .. Type)
		end
	end
end

return ServerOnlyUtilities