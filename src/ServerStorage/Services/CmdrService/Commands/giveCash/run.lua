local ServerStorage = game:GetService('ServerStorage')

local Services = ServerStorage:WaitForChild('Services')
local DataService = require(Services:WaitForChild('DataService'))



return function(context, player: Player, amount: number)
	local playerCash = DataService.GetBalance(player)
	if not playerCash then
		return `Player's data isn't ready yet`
	end
	
	if amount < 0 and playerCash + amount < 0 then
		return 'Input amount would result in a negative balance'
	end
	
	local succ = DataService.AdjustBalance(player, amount)
	return succ and `Successfully updated player's balance` or `Failed to update player's balance`
end