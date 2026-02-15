return {
	Name = 'removePass',
	Description = `|⚠️ WARNING| Removes a Gamepass from a Player. Gamepass needs to be in the database`,
	Group = 'DefaultAdmin',
	Args = {
		{
			Type = 'player',
			Name = 'Target',
			Description = ''
		},
		{
			Type = 'gamepass',
			Name = 'Gamepass Name',
			Description = ''
		},
	}
}