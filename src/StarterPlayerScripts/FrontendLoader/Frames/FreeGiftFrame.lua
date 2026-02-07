-- Services
local ReplicatedStorage = game:GetService('ReplicatedStorage')
local GroupService = game:GetService("GroupService")
local Players = game:GetService('Players')

-- Variables
local Gui = Players.LocalPlayer.PlayerGui:WaitForChild("MainGui")
local Frames = Gui.Frames

local GiftFrame = Frames.FreeGift

-- Dependencies
local DataService = require(ReplicatedStorage.Utilities.DataService)
local GlobalConfiguration = require(ReplicatedStorage.DataModules.GlobalConfiguration)
local RemoteBank = require(ReplicatedStorage.RemoteBank)
local NotificationComponent = require(ReplicatedStorage.Utilities.NotificationComponent)

local Confetti = require("../ConfettiHandler")

local Frame = {}

-- Initialization function for the script
function Frame:Initialize()
	GiftFrame.Container.ClaimButton.Activated:Connect(function()
		local success, response, color = RemoteBank.TryGroupJoin:InvokeServer()
		NotificationComponent.CreateNewNotification(response, color)
		
		if not success then
			if Players.LocalPlayer:IsInGroupAsync(GlobalConfiguration.GroupID) then
				return
			else 
				GroupService:PromptJoinAsync(GlobalConfiguration.GroupID)
			end
		else
			Confetti.SpawnConfetti(50)
		end
	end)
end

return Frame
