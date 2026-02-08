local SocialService = game:GetService('SocialService')
local Players = game:GetService('Players')

local Button = Players.LocalPlayer.PlayerGui:WaitForChild("MainGui").Right.EventButton

local ReplicatedStorage = game:GetService('ReplicatedStorage')
local GlobalConfiguration = require(ReplicatedStorage.DataModules.GlobalConfiguration)


local eventId = tonumber(GlobalConfiguration.EventId)
if not eventId or eventId <= 0 then
	Button.Visible = false
	return
end

local statusSuccess, rsvpStatus = pcall(function()
	return SocialService:GetEventRsvpStatusAsync(eventId)
end)
if statusSuccess and rsvpStatus == Enum.RsvpStatus.Going then
	Button.Visible = false
	return
end

Button.Activated:Connect(function()
	pcall(function()
		SocialService:PromptRsvpToEventAsync(eventId)
	end)
end)