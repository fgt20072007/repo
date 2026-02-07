local GlobalAnimations = {
	Pets = {
		Follow = {
			PerRow = 4,
			BackOffset = 6,
			RowSpacing = 3,
			ArcSpread = math.rad(120),
			HeightOffset = 2,
			DelayPerPet = 0.1,
			PositionResponsiveness = 10,
			ModelScale = 1,
		},
		Float = {
			Amplitude = 0.7,
			Frequency = 2,
		},
		Sway = {
			PitchAmplitude = math.rad(6),
			RollAmplitude = math.rad(5),
			Frequency = 2,
		},
	},
}

return GlobalAnimations