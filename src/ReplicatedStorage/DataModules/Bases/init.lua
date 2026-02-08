

return {
	[1] = {
		BaseName = "Strawberry Elephant's Base", -- Name of the base
		BasePrice = 0, -- Price of the base
		LuckAmount = 1, -- Amount of luck (only for display reasons)
		Percentages = {
			Common = 100,
		}, -- Percentages of rarities being found
		Speed = 25, -- Speed of the chaser
		BaseDefender = script:WaitForChild("Template"), -- Model of the chaser
		Orientation = 270,
		RobuxPurchasables = { -- Purchasable list of purchasable entities with robux
			[1] = {
				PurchaseId = 3531449456,
				EntityName = "Default"
			}
		},
		
		WalkingAnimation = 85016681705983, -- Walking animation for the follower
		IdleAnimation = 135339478276860, -- Idle animation for the follower (Replace these to what you want)
	},
	[2] = {
		BaseName = "SixSeven67's Base", -- Name of the base
		BasePrice = 0, -- Price of the base
		LuckAmount = 1, -- Amount of luck (only for display reasons)
		Percentages = {
			Common = 100,
		}, -- Percentages of rarities being found
		Speed = 35, -- Speed of the chaser
		BaseDefender = script:WaitForChild("SixSeven"), -- Model of the chaser
		Orientation = 360,
		RobuxPurchasables = { -- Purchasable list of purchasable entities with robux
			[1] = {
				PurchaseId = 3531449456,
				EntityName = "Default"
			}
		},

		WalkingAnimation = 92505401336649, -- Walking animation for the follower
		IdleAnimation = 135370039956825, -- Idle animation for the follower (Replace these to what you want)
	},
}