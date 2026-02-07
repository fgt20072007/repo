local ReplicatedStorage = game:GetService("ReplicatedStorage")

local SpawnEntityRemote = ReplicatedStorage.Communication.Remotes.SpawnEntity
local EntityHandler = require("./EntityClientHandler")

local ConveyorPoints = workspace:WaitForChild("ConveyorPoints")
local StartPoint = ConveyorPoints:WaitForChild("Start")
local EndPoint = ConveyorPoints:WaitForChild("End")

local GlobalConfiguration = require(ReplicatedStorage.DataModules.GlobalConfiguration)

local ConveyorHandler = {}

function ConveyorHandler.Initialize()
	SpawnEntityRemote.OnClientEvent:Connect(function(EntityName: string)
		EntityHandler.SpawnEntity(
			EntityName,
			StartPoint.CFrame,
			EndPoint.CFrame,
			GlobalConfiguration.ConveyorWalkingTime
		)
	end)
end

return ConveyorHandler
