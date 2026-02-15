		local ServerStorage = game:GetService('ServerStorage')

local Services = ServerStorage:WaitForChild('Services')
local RankingService = require(Services:WaitForChild('RankingService'))

return function(context, player: Player, amount: number, institution: string)
	local succ = if institution then
		RankingService.AdjustInstitutionXP(player, institution, amount)
		else RankingService.AdjustXP(player, amount)
	
	return succ and `Successfully updated player's XP` or `Failed to update player's XP`
end