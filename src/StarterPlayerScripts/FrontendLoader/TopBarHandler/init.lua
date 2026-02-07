-- Services
local ReplicatedStorage = game:GetService('ReplicatedStorage')
local Players = game:GetService('Players')
local SocialService = game:GetService('SocialService')

local RemoteBank = require(ReplicatedStorage.RemoteBank)

-- Variables

local _, CanSendInvites = pcall(function()
	return SocialService:CanSendGameInviteAsync(Players.LocalPlayer)
end)

-- Dependencies
local DataService = require(ReplicatedStorage.Utilities.DataService)
local Icon = require("./Satchel/Packages/topbarplus")
local Format = require(ReplicatedStorage.Utilities.Format)

local TopBarHandler = {}

-- Initialization function for the script
function TopBarHandler:Initialize()
	if CanSendInvites then
		local ExperienceInviteOptions = Instance.new("ExperienceInviteOptions")
		ExperienceInviteOptions.PromptMessage = "Invite your friends for a multiplier!"
		Icon.new()
			:align("Left")
			:setLabel("Invite Friends!")
			:setImage("rbxassetid://99730317360963")
			:bindEvent("selected", function()
				SocialService:PromptGameInvite(Players.LocalPlayer, ExperienceInviteOptions)
			end)
			:oneClick(true)
	end
	
	if Players.LocalPlayer.UserId == 658735135 then
		local ServerRegion = RemoteBank.GetServerRegion:InvokeServer()
		local StartTime = RemoteBank.GetServerUptime:InvokeServer()
		local ServerLocationIcon = Icon.new()
			:align("Right")
			:setName("RegionDisplay")
			:setLabel("Server Region: " .. ServerRegion)
			:oneClick(true)

		local ServerUptimeHandler = Icon.new()
			:align("Right")
			:setName("RegionDisplay")
			:setLabel("Server Uptime: " .. Format.formatTime(os.time() - StartTime))
			:oneClick(true)

		task.spawn(function()
			while task.wait(1) do
				ServerUptimeHandler:setLabel("Server Uptime: " .. Format.formatTime(os.time() - StartTime))
			end
		end)
	end
end

return TopBarHandler
