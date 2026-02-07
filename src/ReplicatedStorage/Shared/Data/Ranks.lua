export type Rank = {
	name: string,
	displayName: string,
	Price: number,
	Boosts: { Skulls: number, Coins: number, Shards: number },
	imageId: string,
}

local Ranks = {
	{
		name = "Rank1",
		displayName = "Beginner",
		Price = 10,
		Boosts = { Skulls = 1.1, Coins = 1.1, Shards = 1.0 },
		imageId = "rbxassetid://128923604845695",
	},

	{
		name = "Rank2",
		displayName = "Novice",
		Price = 10,
		Boosts = { Skulls = 1.15, Coins = 1.15, Shards = 1.05 },
		imageId = "rbxassetid://115539541791150",
	},

	{
		name = "Rank3",
		displayName = "Apprentice",
		Price = 10,
		Boosts = { Skulls = 1.2, Coins = 1.2, Shards = 1.1 },
		imageId = "rbxassetid://136109933357577",
	},

	{
		name = "Rank4",
		displayName = "Skilled",
		Price = 10,
		Boosts = { Skulls = 1.3, Coins = 1.3, Shards = 1.15 },
		imageId = "rbxassetid://131922474180157",
	},

	{
		name = "Rank5",
		displayName = "Expert",
		Price = 10,
		Boosts = { Skulls = 1.4, Coins = 1.4, Shards = 1.2 },
		imageId = "rbxassetid://0",
	},

	{
		name = "Rank6",
		displayName = "Master",
		Price = 10,
		Boosts = { Skulls = 1.5, Coins = 1.5, Shards = 1.3 },
		imageId = "rbxassetid://0",
	},

	{
		name = "Rank7",
		displayName = "Champion",
		Price = 10,
		Boosts = { Skulls = 1.65, Coins = 1.65, Shards = 1.4 },
		imageId = "rbxassetid://0",
	},

	{
		name = "Rank8",
		displayName = "Legend",
		Price = 10,
		Boosts = { Skulls = 1.8, Coins = 1.8, Shards = 1.5 },
		imageId = "rbxassetid://0",
	},
} :: { Rank }

local cache = {}

cache.Raw = Ranks
cache.Sorted = {} :: { [string]: Rank }

for _, rank in Ranks do
	cache.Sorted[rank.name] = rank
end

return cache
