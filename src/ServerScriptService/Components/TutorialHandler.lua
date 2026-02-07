-- Services
local ReplicatedStorage = game:GetService('ReplicatedStorage')
local Players = game:GetService('Players')
local AnalyticsService = game:GetService("AnalyticsService")

-- Variables

-- Dependencies
local DataService = require(ReplicatedStorage.Utilities.DataService)
local RemoteBank = require(ReplicatedStorage.RemoteBank)

local TutorialServer = {}

-- Initialization function for the script
function TutorialServer:Initialize()
	Players.PlayerAdded:Connect(function(player)
		AnalyticsService:LogOnboardingFunnelStepEvent(player, 1, "Player Joined")
	end)
	
	RemoteBank.CompletedTutorial.OnServerInvoke = function(player)
		DataService.server:set(player, "tutorial", true)
		AnalyticsService:LogOnboardingFunnelStepEvent(player, 2, "Tutorial Completed")
	end
end

return TutorialServer
