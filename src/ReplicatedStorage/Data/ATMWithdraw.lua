--!strict

export type WithdrawEntry = {
	ProductId: number,
	Money: number,
}

local K = 1_000
local M = 1_000_000

local Data: {[number]: WithdrawEntry} = {
	[1] = { ProductId = 3488585236, Money = 7.5 * K },
	[2] = { ProductId = 3488585384, Money = 25 * K },
	[3] = { ProductId = 3488585584, Money = 70 * K },
	[4] = { ProductId = 3488585743, Money = 200 * K },
	[5] = { ProductId = 3488585897, Money = 400 * K },
	[6] = { ProductId = 3488586031, Money = 750 * K },
	[7] = { ProductId = 3488586179, Money = 1.25 * M },
}

return Data