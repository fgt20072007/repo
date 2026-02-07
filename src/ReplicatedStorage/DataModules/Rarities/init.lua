--[[
	[RarityName]: {
		Percentage: number, -- the percentage of that rarity being spawned
		Gradient: UIGradient -- the gradient of the rarity for uis
	}
]]

return {
	["Common"] = {
		Percentage = 45,
		Gradient = script.CommonGradient,
		Weight = 1
	},

	["Uncommon"] = {
		Percentage = 18,
		Gradient = script.UncommonGradient,
		Weight = 1.5
	},

	["Rare"] = {
		Percentage = 16,
		Gradient = script.RareGradient,
		Weight = 2
	},

	["Epic"] = {
		Percentage = 10,
		Gradient = script.EpicGradient,
		Weight = 3
	},

	["Legendary"] = {
		Percentage = 6,
		Gradient = script.LegendaryGradient,
		Weight = 4
	},

	["Mythic"] = {
		Percentage = 3,
		Gradient = script.MythicGradient,
		Weight = 5
	},

	["Secret"] = {
		Percentage = 2,
		Gradient = script.SecretGradient,
		Weight = 6
	},
}
