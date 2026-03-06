--!strict
--!native
--!optimize 2

--// Services
local Players = game:GetService 'Players'
local RunService = game:GetService 'RunService'
local ReplicatedStorage = game:GetService 'ReplicatedStorage'
local CollectionService = game:GetService 'CollectionService'

--// Folders


--// Dependencies
local VehicleSystem = require(script.VehicleSystem) 

--// Constants
local Client = Players.LocalPlayer :: Player
local Replicator = ReplicatedStorage:WaitForChild 'Vehicle_Replicator' :: UnreliableRemoteEvent

--// System
CollectionService:GetInstanceAddedSignal(`VehicleStepper_{Client.UserId}`):Connect(function(Chassis)
	VehicleSystem:Set(Chassis)
end)

CollectionService:GetInstanceRemovedSignal(`VehicleStepper_{Client.UserId}`):Connect(function()
	VehicleSystem:Set(nil)
end)

Replicator.OnClientEvent:Connect(function(Snapshot)
	VehicleSystem:Replicate(Snapshot)
end)

RunService.PostSimulation:Connect(function(dt)
	VehicleSystem:Step(dt)
end)