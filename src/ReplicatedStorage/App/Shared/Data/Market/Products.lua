--!strict

-- [ProductKey] = Developer Product Id
local Products: { [string]: number } = {
	Garage = 123,
}

return table.freeze(Products)
