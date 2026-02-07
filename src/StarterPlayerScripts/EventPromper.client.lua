local SocialService = game:GetService('SocialService')
local Players = game:GetService('Players')

local Button = Players.LocalPlayer.PlayerGui:WaitForChild("MainGui").Right.EventButton

local ReplicatedStorage = game:GetService('ReplicatedStorage')
local GlobalConfiguration = require(ReplicatedStorage.DataModules.GlobalConfiguration)


local eventId = GlobalConfiguration.EventId

if SocialService:GetEventRsvpStatusAsync(eventId) == Enum.RsvpStatus.Going then Button.Visible = false return end 

Button.Activated:Connect(function()
	SocialService:PromptRsvpToEventAsync(eventId)
end)