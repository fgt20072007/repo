return {
	Name = 'giveCash',
	Description = `Increases or decreases a player's cash by a set amount`,
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
		}
	}
}