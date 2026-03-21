--!strict

local Activation = {}

function Activation.TryActivate(
	profileService: {
		SpendMoney: (self: any, player: Player, amount: number) -> (boolean, number?),
	},
	player: Player,
	garageModel: Model,
	garageCost: number,
	isRobux: boolean
): boolean
	if garageModel.Parent == nil then
		return false
	end

	if isRobux == true then
		return true
	end

	return profileService:SpendMoney(player, garageCost)
end

return table.freeze(Activation)