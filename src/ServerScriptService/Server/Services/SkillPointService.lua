local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Shared = ReplicatedStorage.Shared

local Server = require(game:GetService("ServerScriptService").Server)
local SkillPointRemote = require(Shared.Remotes.AddSkillPoint):Server()

local SkillPointService = {}

function SkillPointService._Init()
	SkillPointRemote:On(function(Player, Category, Amount)
		local Profile = Server.Services.DataService:GetProfile(Player).Data
		if not Profile then
			return
		end

		if Profile.SkillPoints < Amount then
			return
		end

		if not Profile.AllocatedPoints[Category] then
			return
		end

		Server.Services.DataService:Decrement(Player, "SkillPoints", Amount)
		Profile.AllocatedPoints[Category] += Amount
	end)
end

return SkillPointService
