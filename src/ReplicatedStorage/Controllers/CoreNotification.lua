local StarterGui = game:GetService("StarterGui")
local ReplicatedStorage = game:GetService('ReplicatedStorage')

local EntityData = require(ReplicatedStorage.DataModules.EntityData)

local CoreNotificationHandler = {}

function CoreNotificationHandler.SendNotification(EntityName, Success)
	local TitleText = if Success then "Succesfully found " .. EntityName else "Already found " .. EntityName
	local DescriptionText = if Success then "You have just found a new entity!" else "You already found this entity"
	local ImageData = EntityData[EntityName].Image
	StarterGui:SetCore("SendNotification",{
		Title = TitleText, 
		Text = DescriptionText, 
		Icon = ImageData,
		Duration = 1
	})
end

function CoreNotificationHandler.Initialize()
	ReplicatedStorage.Communication.Functions.SendCoreNotification.OnClientInvoke = CoreNotificationHandler.SendNotification
end

return CoreNotificationHandler