--!strict

-- [PassKey] = Game Pass Id
local GamePasses: { [string]: number } = {
	-- VIP = 1234567890, -- Requiere handler: MarketplaceService/_Internal/GamePasses/VIP.lua
}

return table.freeze(GamePasses)
