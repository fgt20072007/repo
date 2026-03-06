--!strict

-- FIELD MOCK
local fields = {
	-- Progress
	Profile = {
		XP = 0,
	},

	-- Economy
	Economy = {
		Money = 0,
	},

	-- Stats
	Stats = {
		StudsDriven = 0,
		DriveSeconds = 0,
		CarsSold = 0,
		Kills = 0,
	},

	-- Garage
	Garage = {
		BaseSlots = 3,
		PremiumSlots = 0,      -- +X por gamepass
		Vehicles = {},         -- lista de autos
		ActiveVehicleId = nil, -- auto actualmente spawneado/equipado
	},

	-- Trade
	Trade = {
		TradesCompleted = 0,
		CarsTraded = 0,
	},
}

return table.freeze({
	StoreNames = table.freeze({
		Live = "Live",
		Dev = "Dev",
	}),
	UseMock = true,
	ReplicaToken = "PlayerProfile",
	Fields = table.freeze(fields),
})