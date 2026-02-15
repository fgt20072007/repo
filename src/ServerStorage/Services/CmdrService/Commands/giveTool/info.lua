return {
	Name = 'giveTool',
	Description = `Gives a tool to a selected player. ⚠️ Bypasses any checks`,
	Group = 'DefaultAdmin',
	Args = {
		{
			Type = 'player',
			Name = 'Target',
			Description = ''
		},
		{
			Type = 'tool',
			Name = 'Tool',
			Description = ''
		}
	}
}