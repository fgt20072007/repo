-- Services
local ReplicatedStorage = game:GetService('ReplicatedStorage')
local Players = game:GetService('Players')

-- Variables

-- Dependencies
local DataService = require(ReplicatedStorage.Utilities.DataService)
local GlobalConfiguration = require(ReplicatedStorage.DataModules.GlobalConfiguration)
local SharedFunctions = require(ReplicatedStorage.DataModules.SharedFunctions)
local RemoteBank = require(ReplicatedStorage.RemoteBank)

local RebirthsHandler = {}

-- Initialization function for the script
function RebirthsHandler:Initialize()
	RemoteBank.Rebirth.OnServerInvoke = function(player)
		local currentSpeedLevel = DataService.server:get(player, "speed")
		local currentRebirth = DataService.server:get(player, "rebirth")
		if currentSpeedLevel >= SharedFunctions.GetRebirthGoal(player) then
			DataService.server:set(player, "speed", GlobalConfiguration.StarterWalkspeed)
			DataService.server:set(player, "rebirth", currentRebirth + 1)
			
			if GlobalConfiguration.RebirthCash then
				DataService.server:set(player, "cash", 0)
			end
			
			return true, "Succesfully rebirthed"
		else
			return false, "You don't have enough speed to rebirth!"
		end
	end
end

return RebirthsHandler
