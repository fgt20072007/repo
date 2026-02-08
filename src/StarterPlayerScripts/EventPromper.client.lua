local SocialService = game:GetService('SocialService')
local Players = game:GetService('Players')

local playerGui = Players.LocalPlayer:WaitForChild("PlayerGui")
local mainGui = playerGui:WaitForChild("MainGui")
local rightContainer = mainGui:WaitForChild("Right")
local Button = rightContainer:FindFirstChild("EventButton")
if not Button or not Button:IsA("GuiButton") then
	return
end

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
