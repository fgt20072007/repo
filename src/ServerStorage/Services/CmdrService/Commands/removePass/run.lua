
local ServerStorage = game:GetService('ServerStorage')


local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Data = ReplicatedStorage.Data
local Gamepasses_Data = require(Data.Passes)

local Services = ServerStorage:WaitForChild('Services')
local MarketService = require(Services.MarketService)
local DataService = require(Services.DataService)



return function(context, player: Player, GamepassName: string)
	local OwnsPass = MarketService.OwnsPass(player, GamepassName)
	if not OwnsPass then return `This player doesn't own this gamepass` end
	
	local GamepassId = Gamepasses_Data[GamepassName]
	if not GamepassId then return `This gamepass doesn't exist` end
	
	local succ = MarketService._RemoveOwnership(player, GamepassId)
	return succ and `Successfully removed gamepass from player` or `Failed to remove gamepass from player`
end