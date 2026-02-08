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
		Id = 0,
	},
	ProPack = {
		Rewards = {
			["Default"] = "Entity",
			[250000] = "Cash"
		},
		Id = 0,
	},
	SecretPack = {
		Rewards = {
			["Default"] = "Entity",
		},
		Id = 0,
	},
	InsanePack = {
		Rewards = {
			[1_000_000] = "Cash"
		},
		Id = 0,
	},
	MythicalUnit = {
		EntityName = "Test",
		Id = 0,
	},
	CosmicUnit = {
		EntityName = "Test",
		Id = 0,
	},
	SecretUnit = {
		EntityName = "Test",
		Id = 0,
	},

	Cash1 = {
		Id = 0,
		Amount = 100_000
	},
	Cash2 = {
		Id = 0,
		Amount = 1_000_000
	},
	Cash3 = {
		Id = 0,
		Amount = 100_000_000
	},
	Cash4 = {
		Id = 0,
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

	SpawnMythical = 0,
	SpawnSecret = 0
}
