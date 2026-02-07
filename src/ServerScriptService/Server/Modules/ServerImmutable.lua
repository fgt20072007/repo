local RunService = game:GetService("RunService")

local Immutable = {
	DATA_KEY = RunService:IsStudio() and "STUDIO_KEY_0001.81" or "GAME_KEY_01",

	PRODUCT_PUBLISHING_TOPIC = "PRODUCT",

	KOTH_REWARD_COOLDOWN = 1,
	KOTH_REWARD_AMOUNT = 1,
}

return table.freeze(Immutable)