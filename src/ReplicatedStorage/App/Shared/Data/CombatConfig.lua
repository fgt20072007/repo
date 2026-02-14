local CombatConfig = {
	ComboResetTime = 1,
	AttackRatePerSecond = 18,
	ParryRatePerSecond = 8,
	ParryDuration = 0.35,
	ParryCooldown = 0.9,
	ParryDamageMultiplier = 0.5,
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