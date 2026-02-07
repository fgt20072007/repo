-- Services
local ReplicatedStorage = game:GetService('ReplicatedStorage')
local Players = game:GetService('Players')
local TweenService = game:GetService('TweenService')

-- Variables

-- Dependencies
local DataService = require(ReplicatedStorage.Utilities.DataService)
local RemoteBank = require(ReplicatedStorage.RemoteBank)

local FOVEffect = {}

function FOVEffect.Start()
	TweenService:Create(workspace.CurrentCamera, TweenInfo.new(0.25, Enum.EasingStyle.Back), {FieldOfView = 50}):Play()
	task.delay(0.2, function()
		TweenService:Create(workspace.CurrentCamera, TweenInfo.new(0.25, Enum.EasingStyle.Back), {FieldOfView = 70}):Play()
	end)
end

-- Initialization function for the script
function FOVEffect:Initialize()
	RemoteBank.FOVEffect.OnClientEvent:Connect(FOVEffect.Start)
end

return FOVEffect
