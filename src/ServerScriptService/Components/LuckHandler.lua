local ReplicatedStorage = game:GetService('ReplicatedStorage')
local LuckyData = require(ReplicatedStorage.DataModules.LuckyData)

local GlobalConfiguration = require(ReplicatedStorage.DataModules.GlobalConfiguration)

local LuckHandler = {}

function LuckHandler.GetGlobalLuck()
	local luck = 1
	for luckName, informations in LuckyData do
		local currentTime = os.time()
		if (game.Workspace:GetAttribute(luckName) or currentTime) - currentTime > 0 then
			luck *= informations.Multiplier
		end
	end
	return luck
end

function LuckHandler.GetLuckyblockLuck(Player: Player)
	local currentTime = os.time()
	local Luck2xTime = Player:GetAttribute(GlobalConfiguration.Luck2xAttribute) or currentTime
	local Luck10xTime = Player:GetAttribute(GlobalConfiguration.Luck10xAttribute) or currentTime
	local luck = 1
	if Luck2xTime - currentTime > 0 then luck *= 2 end
	if Luck10xTime - currentTime > 0 then luck *= 10 end
	return luck
end

return LuckHandler