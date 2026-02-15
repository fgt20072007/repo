--!strict
local ServerStorage = game:GetService 'ServerStorage'
local ReplicatedStorage = game:GetService 'ReplicatedStorage'

local Services = ServerStorage:WaitForChild("Services")

local Products = require(ReplicatedStorage.Data.Products)
local DataService = require(Services:WaitForChild('DataService'))

return function(_, player: Player, index: number): boolean
	local data = Products.Cash[index]
	if not index then return false end
	
	return DataService.AdjustBalance(player, data.Reward)
end