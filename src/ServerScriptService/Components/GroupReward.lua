-- Services
local ReplicatedStorage = game:GetService('ReplicatedStorage')
local Players = game:GetService('Players')
local ServerStorage = game:GetService('ServerStorage')

-- Variables

-- Dependencies
local DataService = require(ReplicatedStorage.Utilities.DataService)
local ServerUtilities = require(ServerStorage.ServerUtilities)
local RemoteBank = require(ReplicatedStorage.RemoteBank)
local GlobalConfiguration = require(ReplicatedStorage.DataModules.GlobalConfiguration)

local ServerStorage = game:GetService('ServerStorage')
local ServerUtilities = require(ServerStorage.ServerUtilities)

local GroupReward = {}

-- Initialization function for the script
function GroupReward:Initialize()
	RemoteBank.TryGroupJoin.OnServerInvoke = function(plr: Player)
		if DataService.server:get(plr, "GroupReward") then
			return false, "You already claimed the group reward!"
		end
		
		if plr:IsInGroupAsync(GlobalConfiguration.GroupID) then
			ServerUtilities.ParseTableForRewards(plr, GlobalConfiguration.GroupRewards)
			DataService.server:set(plr, "GroupReward", true)
			return true, "Succesfully claimed group reward!", Color3.new(0.482353, 1, 0)
		else
			return false, "Please like the game and join the group to claim!", Color3.new(1, 0.109804, 0.109804)
		end
	end
end

return GroupReward
