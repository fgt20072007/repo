local ReplicatedStorage = game:GetService('ReplicatedStorage')

local SpawnEntityRemote = ReplicatedStorage.Communication.Remotes.SpawnEntity
local GlobalConfiguration = require(ReplicatedStorage.DataModules.GlobalConfiguration)
local EntityData = require(ReplicatedStorage.DataModules.EntityData)

local Rarities = require(ReplicatedStorage.DataModules.Rarities)
local WeightedRNG = require(ReplicatedStorage.Utilities.WeightedRNG)

local LuckHandler = require("./LuckHandler")

local ConveyorServer = {}


local function GetSpawnables()
	local t = {}
	for entityName, v in EntityData do
		if v.Spawnable then
			t[entityName] = Rarities[v.Rarity].Percentage
		end
	end
	return t
end

function ConveyorServer.Initialize()
	local Spawnables = GetSpawnables()
	task.spawn(function()
		while task.wait(GlobalConfiguration.SpawnDelay) do
			local EntityName = WeightedRNG.get(Spawnables, LuckHandler.GetGlobalLuck())
			SpawnEntityRemote:FireAllClients(EntityName)
		end
	end)
end

return ConveyorServer