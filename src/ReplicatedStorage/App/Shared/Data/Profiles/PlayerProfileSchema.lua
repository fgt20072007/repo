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
		CurrentGarage = "Default",
		Vehicles = {
			["bmw"] = {},
		},  
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
		Dev = "Dev2",
	}),
	UseMock = true,
	ReplicaToken = "PlayerProfile",
	Fields = table.freeze(fields),
})