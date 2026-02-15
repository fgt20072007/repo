return {
	Name = 'giveXP',
	Description = `Increases or decreases a player's XP by a set amount`,
	Group = 'DefaultAdmin',
	Args = {
		{
			Type = 'player',
			Name = 'Target',
			Description = ''
		},
		{
			Type = 'integer',
			Name = 'Amount',
			Description = ''
		},
		{
			Type = 'institution',
			Optional = true,
			Name = 'Institution',
			Description = ''
		},
	}
}