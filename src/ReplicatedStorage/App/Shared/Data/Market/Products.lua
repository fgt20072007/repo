--!strict

-- [ProductKey] = Developer Product Id
local Products: { [string]: number } = {
	-- CoinsSmall = 1234567890, -- Requiere handler: MarketplaceService/_Internal/Products/CoinsSmall.lua
}

return table.freeze(Products)
