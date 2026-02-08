-- Replace all of the following ids with yours.
-- Rewards support both formats:
-- Legacy format:
--	{
--		["Default"] = "Entity",
--		[50000] = "Cash",
--	}
-- New readable format:
--	{
--		Luckybox = "Common",
--		Cash = 50000,
--		PermanentGear = "Bat",
--	}
-- PermanentGear must match a key in ReplicatedStorage/DataModules/Gears/init.lua.
-- Luckybox must match a Lucky Box entity name.

return {
	StarterPack = {
		Rewards = {
			Luckybox = "Common",
			Cash = 50_000,
			PermanentGear = "Bat",
		},
		Id = 3528614789,
	},
	ProPack = {
		Rewards = {
			["Default"] = "Entity",
			[250000] = "Cash"
		},
		Id = 3531448529,
	},
	SecretPack = {
		Rewards = {
			["Default"] = "Entity",
		},
		Id = 3531448571,
	},
	InsanePack = {
		Rewards = {
			[1_000_000] = "Cash"
		},
		Id = 3531448969,
	},
	MythicalUnit = {
		EntityName = "Test",
		Id = 3531448669,
	},
	CosmicUnit = {
		EntityName = "Test",
		Id = 3531448752,
	},
	SecretUnit = {
		EntityName = "Test",
		Id = 3531448859,
	},

	Cash1 = {
		Id = 3531449088,
		Amount = 100_000
	},
	Cash2 = {
		Id = 3531449131,
		Amount = 1_000_000
	},
	Cash3 = {
		Id = 3531449169,
		Amount = 100_000_000
	},
	Cash4 = {
		Id = 3531449024,
		Amount = 1_000_000_000
	},

	Stealables = {
		Common = 3531447675,
		Uncommon = 3531447756,
		Rare = 3531447801,
		Epic = 3531447846,
		Legendary = 3531447898,
		Mythical = 3531447959,
		Secret = 3531448001,
		Godly = 3531448071
	},

	SpawnMythical = 3531449310,
	SpawnSecret = 3531449213
}
