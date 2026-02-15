return {
	Name = 'setSpeed',
	Description = `Updates the player walkspeed if they have a character`,
	Group = 'DefaultAdmin',
	Args = {
		{
			Type = 'player',
			Name = 'Target',
			Description = ''
		},
		{
			Type = 'integer',
			Name = 'Speed',
			Description = ''
		}
	}
}