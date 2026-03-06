--!strict

return table.freeze({
	Driving = {
		MinSpeedThreshold = 5,
		TickRate = 1.0,

		XP = {
			PerDriveSecond = 1,
			PublishInterval = 4,
		},

		Money = {
			PerStud = 0.1,
			PublishInterval = 1,
		},
	},

	PlayTime = {
		Money = {
			PerInterval = 50,
			PublishInterval = 10,
		},
	},
})