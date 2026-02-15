--!strict
local ServerStorage = game:GetService 'ServerStorage'
local ReplicatedStorage = game:GetService 'ReplicatedStorage'

local Products = require(ReplicatedStorage.Data.Products)
local RankingService = require(ServerStorage.Services.RankingService)

return function(_, player: Player, index: number): boolean
	local data = Products.XP[index]
	if not index then return false end
	
	return RankingService._GrantPurchase(player, data.Reward)
end