return {
	Name = "givecash";
	Aliases = {"gc"};
	Description = "Gives cash to player.";
	Group = "Admin";
	Args = {
		{
			Type = "player";
			Name = "player";
			Description = "The player to give to";
		},
		{
			Type = "number";
			Name = "cashAmount";
			Description = "The amount of cash";
		},
	};
}