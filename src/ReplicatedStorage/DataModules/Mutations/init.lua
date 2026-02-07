-- When adding a new mutation make sure to use the following setup

--[[
	MutationName = {
		Percentage - Number and is the probability to find that mutation
		Gradient - The gradient of the rarity
		Multiplier - Number and is the multiplier of the mutation
		ShowLabel - Boolean and is if the mutation label will show
	}
]]

return {
	Normal = {
		Percentage = 200,
		Gradient = script.NormalGradient,
		Multiplier = 1,
		ShowLabel = false
	},
	Gold = {
		Percentage = 50,
		Gradient = script.GoldGradient,
		Effect = script.GoldEffect,
		Multiplier = 1.5,
		ShowLabel = true
	},
	Diamond = {
		Percentage = 25,
		Gradient = script.DiamondGradient,
		Effect = script.DiamondEffect,
		Multiplier = 2,
		ShowLabel = true
	},
}