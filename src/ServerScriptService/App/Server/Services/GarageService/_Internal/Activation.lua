--!strict

local Activation = {}

function Activation.TryActivate(
	profileService: any,
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

	local wasCharged = false
	local ok = profileService:UpdateValue(player, "Economy", function(economy)
		if type(economy) ~= "table" then
			return economy
		end

		local money = economy.Money
		if type(money) ~= "number" then
			return economy
		end
		if money < garageCost then
			return economy
		end

		economy.Money = money - garageCost
		wasCharged = true

		return economy
	end)

	return ok == true and wasCharged == true
end

return table.freeze(Activation)