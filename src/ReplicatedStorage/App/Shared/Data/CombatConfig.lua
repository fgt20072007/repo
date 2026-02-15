local CombatConfig = {
	ComboResetTime = 1,
	AttackRatePerSecond = 18,
	ParryRatePerSecond = 8,
	ParryDuration = 0.35,
	ParryCooldown = 0.9,
	ParryDamageMultiplier = 0.5,
	Client = {
		ComboContinueWindow = {
			Default = 0.26,
			Min = 0.18,
			Max = 0.4,
			Multiplier = 1.35,
		},
		SprintLockAttribute = "CombatSprintLocked",
		AttackWalkSpeed = 10,
	},
	ParryInput = {
		Keyboard = Enum.KeyCode.F,
		Gamepad = Enum.KeyCode.ButtonL2,
	},
	Hitbox = {
		Size = Vector3.new(4.5, 4, 5.5),
		Offset = CFrame.new(0, 0, -3),
		Lifetime = 0.08,
		Samples = 3,
	},
}

return table.freeze(CombatConfig)