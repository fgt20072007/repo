--!strict

return table.freeze({
	Driving = {
		MinSpeedThreshold = 5,
		TickRate = 1.0,

		XP = {
			PerDriveSecond = 1,
			PublishInterval = 30,
		},

		Money = {
			PerStud = 0.1,
			PublishInterval = 50,
		},
	},

	PlayTime = {
		Money = {
			PerInterval = 50,
			PublishInterval = 10,
		},
	},
})