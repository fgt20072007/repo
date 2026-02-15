--!strict
export type XPItem = {ProductId: number, Reward: number}

local XPList: { XPItem } = {
	{ ProductId = 3526260391, Reward = 10 },
	{ ProductId = 3526257423, Reward = 20 },
	{ ProductId = 3526257424, Reward = 50 },
	{ ProductId = 3526257421, Reward = 100 },
	{ ProductId = 3526257420, Reward = 250 },
	{ ProductId = 3526257419, Reward = 350 },
	{ ProductId = 3526257422, Reward = 1000 },
	{ ProductId = 3526257417, Reward = 2500 },
}


table.sort(XPList :: any, function(a: any, b: any)
	return a.Reward < b.Reward 
end)

local T, M = 1e3, 1e6 

return {
	XP = XPList,
	Cash = {
		{ProductId = 3488585236, Reward = 7.5 * T}, -- Cash Pack 1
		{ProductId = 3488585384, Reward = 25 * T}, -- Cash Pack 2
		{ProductId = 3488585584, Reward = 70 * T}, -- Cash Pack 3
		{ProductId = 3488585743, Reward = 200 * T}, -- Cash Pack 4
		{ProductId = 3488585897, Reward = 400 * T}, -- Cash Pack 5
		{ProductId = 3488586031, Reward = 750 * T}, -- Cash Pack 6
		{ProductId = 3488586179, Reward = 1.25 * M}, -- Cash Pack 7
		
	}
} 