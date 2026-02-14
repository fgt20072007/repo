local function freezeWeapon(weapon)
	weapon.Animations.Combo = table.freeze(weapon.Animations.Combo)
	weapon.Animations = table.freeze(weapon.Animations)
	weapon.ComboDamage = table.freeze(weapon.ComboDamage)
	return table.freeze(weapon)
end

local defaultKnife = freezeWeapon({
	Damage = 22,
	ComboDamage = { 22, 24, 26, 30 },
	AttackCooldown = 0.24,
	Animations = {
		Pickup = 116938529882322,
		Idle = 96733597991076,
		Parry = 106948730224787,
		Combo = {
			115154793976699,
			87680755904862,
			120597419176592,
			122271507203637,
		},
	},
})

return table.freeze({
	Default = defaultKnife,
	Knife = defaultKnife,
	PlayerKnife = defaultKnife,
})