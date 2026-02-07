

return {
	[1] = {
		BaseName = "Sammy's Base", -- Name of the base
		BasePrice = 0, -- Price of the base
		LuckAmount = 1, -- Amount of luck (only for display reasons)
		Percentages = {
			Common = 100,
		}, -- Percentages of rarities being found
		Speed = 25, -- Speed of the chaser
		BaseDefender = script.Template, -- Model of the chaser
		RobuxPurchasables = { -- Purchasable list of purchasable entities with robux
			[1] = {
				PurchaseId = 3531449456,
				EntityName = "Default"
			}
		},
		
		WalkingAnimation = 85016681705983, -- Walking animation for the follower
		IdleAnimation = 135339478276860, -- Idle animation for the follower (Replace these to what you want)
	},
}