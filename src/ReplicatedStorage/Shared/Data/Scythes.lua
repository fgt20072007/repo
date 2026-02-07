export type Scythe = {
	name: string,
	displayName: string,
	price: number,
	type: string,
	skullPerClick: number,
}

local Scythes = {

	{
		name = "noob_scythe",
		displayName = "Noob Scythe",
		price = 250,
		type = "Default",
		skullPerClick = 100,
	},
	{
		name = "blue_noob_scythe",
		displayName = "Blue Noob Scythe",
		price = 300,
		type = "Noob",
		skullPerClick = 2,
	},
	{
		name = "green_noob_scythe",
		displayName = "Green Noob Scythe",
		price = 300,
		type = "Noob",
		skullPerClick = 4,
	},
	{
		name = "pink_noob_scythe",
		displayName = "Pink Noob Scythe",
		price = 300,
		type = "Noob",
		skullPerClick = 8,
	},

	{
		name = "purple_noob_scythe",
		displayName = "Purple Noob Scythe",
		price = 300,
		type = "Noob",
		skullPerClick = 16,
	},

	{
		name = "red_noob_scythe",
		displayName = "Red Noob Scythe",
		price = 300,
		type = "Noob",
		skullPerClick = 32,
	},

	{
		name = "beginner_blue_scythe",
		displayName = "Beginner Blue Scythe",
		price = 0,
		type = "Beginner",
		skullPerClick = 64,
	},
	{
		name = "beginner_green_scythe",
		displayName = "Beginner Green Scythe",
		price = 0,
		type = "Beginner",
		skullPerClick = 128,
	},
	{
		name = "beginner_pink_scythe",
		displayName = "Beginner Pink Scythe",
		price = 0,
		type = "Beginner",
		skullPerClick = 256,
	},
	{
		name = "beginner_purple_scythe",
		displayName = "Beginner Purple Scythe",
		price = 0,
		type = "Beginner",
		skullPerClick = 502,
	},
	{
		name = "beginner_red_scythe",
		displayName = "Beginner Red Scythe",
		price = 0,
		type = "Beginner",
		skullPerClick = 1004,
	},
	{
		name = "beginner_white_scythe",
		displayName = "Beginner White Scythe",
		price = 0,
		type = "Beginner",
		skullPerClick = 2008,
	},
	{
		name = "charged_blue_scythe",
		displayName = "Charged Blue Scythe",
		price = 750,
		type = "Charged",
		skullPerClick = 4016,
	},
	{
		name = "charged_green_scythe",
		displayName = "Charged Green Scythe",
		price = 750,
		type = "Charged",
		skullPerClick = 8032,
	},
	{
		name = "charged_pink_scythe",
		displayName = "Charged Pink Scythe",
		price = 800,
		type = "Charged",
		skullPerClick = 16064,
	},
	{
		name = "charged_purple_scythe",
		displayName = "Charged Purple Scythe",
		price = 850,
		type = "Charged",
		skullPerClick = 16064,
	},
	{
		name = "charged_red_scythe",
		displayName = "Charged Red Scythe",
		price = 900,
		type = "Charged",
		skullPerClick = 16064,
	},
	{
		name = "charged_white_scythe",
		displayName = "Charged White Scythe",
		price = 950,
		type = "Charged",
		skullPerClick = 16064,
	},

	{
		name = "pro_blue_scythe",
		displayName = "Pro Blue Scythe",
		price = 1500,
		type = "Pro",
		skullPerClick = 16064,
	},
	{
		name = "pro_green_scythe",
		displayName = "Pro Green Scythe",
		price = 1500,
		type = "Pro",
		skullPerClick = 16064,
	},
	{
		name = "pro_pink_scythe",
		displayName = "Pro Pink Scythe",
		price = 1600,
		type = "Pro",
		skullPerClick = 16064,
	},
	{
		name = "pro_red_scythe",
		displayName = "Pro Red Scythe",
		price = 1700,
		type = "Pro",
		skullPerClick = 16064,
	},
	{
		name = "pro_violet_scythe",
		displayName = "Pro Violet Scythe",
		price = 1800,
		type = "Pro",
		skullPerClick = 16064,
	},
	{
		name = "pro_white_scythe",
		displayName = "Pro White Scythe",
		price = 1900,
		type = "Pro",
		skullPerClick = 16064,
	},
	{
		name = "eternal_blue_scythe",
		displayName = "Eternal Blue Scythe",
		price = 5000,
		type = "Eternal",
		skullPerClick = 16064,
	},
	{
		name = "eternal_green_scythe",
		displayName = "Eternal Green Scythe",
		price = 5000,
		type = "Eternal",
		skullPerClick = 16064,
	},
	{
		name = "eternal_pink_scythe",
		displayName = "Eternal Pink Scythe",
		price = 5200,
		type = "Eternal",
		skullPerClick = 16064,
	},
	{
		name = "eternal_red_scythe",
		displayName = "Eternal Red Scythe",
		price = 5400,
		type = "Eternal",
		skullPerClick = 16064,
	},
	{
		name = "eternal_violet_scythe",
		displayName = "Eternal Violet Scythe",
		price = 5600,
		type = "Eternal",
		skullPerClick = 16064,
	},
	{
		name = "eternal_white_scythe",
		displayName = "Eternal White Scythe",
		price = 5800,
		type = "Eternal",
		skullPerClick = 16064,
	},
}

local cache = {}
cache.Raw = {}
cache.Sorted = {}

for _, scythe in Scythes do
	cache.Sorted[scythe.name] = scythe
	table.insert(cache.Raw, scythe)
end

return cache :: { Raw: { Scythe }, Sorted: { [string]: { { Scythe } } } }
