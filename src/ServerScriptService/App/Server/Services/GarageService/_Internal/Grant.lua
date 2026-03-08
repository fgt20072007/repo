--!strict

local Grant = {}

function Grant.Apply(player: Player, garageModel: Model, isRobux: boolean): boolean
	if garageModel.Parent == nil then
		return false
	end

	local paymentType = if isRobux == true then "Robux" else "Money"
	debug.profilebegin(`GarageService.Grant:{player.Name}:{garageModel:GetFullName()}:{paymentType}`)
	debug.profileend()

	return true
end

return table.freeze(Grant)