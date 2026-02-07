local ServerScriptService = game:GetService("ServerScriptService")
local Server = require(ServerScriptService.Server)

return {
	[3494471762] = function(Player)
		Server.Services.DataService:Increment(Player, "JumpPoints", 100_000)
	end,

	[3494472868] = function(Player)
		Server.Services.DataService:Increment(Player, "JumpPoints", 1_000_000)
	end,

	[3494473429] = function(Player)
		Server.Services.DataService:Set(Player, "DoubleJumpStage", 10_000_000)
	end,

	[3494475058] = function(Player)
		Server.Services.DataService:Set(Player, "DoubleJumpStage", 2)
	end,

	[3494475421] = function(Player)
		Server.Services.DataService:Set(Player, "DoubleJumpStage", 3)
	end,

	[3494475731] = function(Player)
		Server.Services.DataService:Set(Player, "DoubleJumpStage", 4)
	end,

	[3494476518] = function(Player)
		Server.Services.DataService:Set(Player, "DoubleJumpStage", 5)
	end,

	[3494477145] = function(Player)
		Server.Services.DataService:Set(Player, "DoubleJumpStage", 6)
	end,

	[3494477610] = function(Player)
		Server.Services.DataService:Set(Player, "DoubleJumpStage", 7)
	end,

	[3494478068] = function(Player)
		Server.Services.DataService:Set(Player, "DoubleJumpStage", 8)
	end,

	[3495136340] = function(Player)
		local DataService = Server.Services.DataService
		local prof = DataService:GetProfile(Player)
		DataService:Increment(Player, "Wins", prof.Data.Wins)
	end,
}
