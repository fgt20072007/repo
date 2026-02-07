export type Dna = {
	name: string,
	displayName: string,
	Price: number,
	StorageSpace: number,
	ImageId: string,
}

local dna = {
	{
		name = "dna1",
		displayName = "dna1",
		Price = 10,
		StorageSpace = 100,
		ImageId = "rbxassetid://109768805116922",
	},
	{
		name = "dna2",
		displayName = "dna2",
		Price = 10,
		StorageSpace = 110,
		ImageId = "rbxassetid://109768805116922",
	},
	{
		name = "dna3",
		displayName = "dna3",
		Price = 10,
		StorageSpace = 120,
		ImageId = "rbxassetid://109768805116922",
	},
	{
		name = "dna4",
		displayName = "dna4",
		Price = 10,
		StorageSpace = 130,
		ImageId = "rbxassetid://109768805116922",
	},
	{
		name = "dna5",
		displayName = "dna5",
		Price = 10,
		StorageSpace = 140,
		ImageId = "rbxassetid://109768805116922",
	},
	{
		name = "dna6",
		displayName = "dna6",
		Price = 10,
		StorageSpace = 150,
		ImageId = "rbxassetid://109768805116922",
	},
	{
		name = "dna7",
		displayName = "dna7",
		Price = 10,
		StorageSpace = 160,
		ImageId = "rbxassetid://109768805116922",
	},
	{
		name = "dna8",
		displayName = "dna8",
		Price = 10,
		StorageSpace = 170,
		ImageId = "rbxassetid://109768805116922",
	},
	{
		name = "dna9",
		displayName = "dna9",
		Price = 10,
		StorageSpace = 180,
		ImageId = "rbxassetid://109768805116922",
	},
	{
		name = "dna10",
		displayName = "dna10",
		Price = 10,
		StorageSpace = 190,
		ImageId = "rbxassetid://109768805116922",
	},
	{
		name = "dna11",
		displayName = "dna11",
		Price = 10,
		StorageSpace = 200,
		ImageId = "rbxassetid://109768805116922",
	},
	{
		name = "dna12",
		displayName = "dna12",
		Price = 10,
		StorageSpace = 210,
		ImageId = "rbxassetid://109768805116922",
	},
	{
		name = "dna13",
		displayName = "dna13",
		Price = 10,
		StorageSpace = 220,
		ImageId = "rbxassetid://109768805116922",
	},
} :: { Dna }

local cache = {}
cache.Raw = dna
cache.Sorted = {}

for _, dnaData in dna do
	cache.Sorted[dnaData.name] = dnaData
end

return cache
