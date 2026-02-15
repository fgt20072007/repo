local AnimationConfig = {
	Animations = {
		Movement = {
			Default = {
				Idle = "rbxassetid://140646818888686",
				Walk = "rbxassetid://76547664653044",
				Sprint = "rbxassetid://97895234554642",
				Jump = "rbxassetid://92331581117205",
				Fall = "rbxassetid://101055306675860",
			},
			Rod = {
				Idle = "rbxassetid://128099365238864",
				Walk = "rbxassetid://140644796826473",
				Sprint = "rbxassetid://78223436870090",
				Jump = "rbxassetid://117179144945514",
				Fall = "rbxassetid://74198809002659",
			},
			Shared = {
				IdleBreak = "rbxassetid://121248387383716",
			},
		},
		Combat = {
			Knife = {},
			Swords = {},
		},
	},
	TransitionFadeTime = 0.15,
	ResetFadeTime = 0.1,

	MoveThreshold = 0.08,
	MoveThresholdStart = 0.2,
	MoveThresholdStop = 0.05,
	DefaultWalkSpeed = 10,
	DefaultSprintSpeed = 18,
	UpdateRate = 1 / 20,

	KeepAnimateDisabled = true,
	
	BasePriority = Enum.AnimationPriority.Movement,
	OverlayPriority = Enum.AnimationPriority.Action,
	
	IdleBreakInterval = 8,
	
	NonLoopedStates = {
		Movement = {
			Default = {
				Jump = true,
				Fall = true,
			},
			Rod = {
				Jump = true,
				Fall = true,
			},
			Shared = {
				IdleBreak = true,
			},
		},
		Combat = {
			Knife = {},
			Swords = {},
		},
	},
}

return table.freeze(AnimationConfig)
