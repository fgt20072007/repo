local function freezeWeapon(weapon)
	weapon.Animations.Combo = table.freeze(weapon.Animations.Combo)
	weapon.Animations = table.freeze(weapon.Animations)
	weapon.ComboDamage = table.freeze(weapon.ComboDamage)
	return table.freeze(weapon)
end

local defaultSword = freezeWeapon({
	Damage = 30,
	ComboDamage = { 30, 32, 35, 40 },
	AttackCooldown = 0.28,
	Animations = {
		Pickup = 0,
		Idle = 0,
		Parry = 0,
		Combo = { 0, 0, 0, 0 },
	},
})

return table.freeze({
	Default = defaultSword,
	Sword = defaultSword,
	PlayerSword = defaultSword,
})
