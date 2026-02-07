-- Services
local ReplicatedStorage = game:GetService('ReplicatedStorage')
local Players = game:GetService('Players')
local TweenService = game:GetService('TweenService')

-- Variables
local ConfettiUI = Players.LocalPlayer.PlayerGui:WaitForChild("ConfettiUI")

-- Dependencies
local DataService = require(ReplicatedStorage.Utilities.DataService)
local RemoteBank = require(ReplicatedStorage.RemoteBank)

local ConfettiHandler = {}

function ConfettiHandler.SpawnConfetti(Amount)
	for i = 1, Amount do
		local Conffettis = script:GetChildren() 
		local Randomized = Conffettis[math.random(1, #Conffettis)]
		local Clone = Randomized:Clone()
		
		local RandomizedX = math.random(0, 1000) / 1000
		local RandomOrientation = math.random(340, 780)
		
		Clone.Position = UDim2.new(RandomizedX, 0, -0.2, 0)
		
		Clone.Parent = ConfettiUI
		
		local Tween = TweenService:Create(Clone, TweenInfo.new(1, Enum.EasingStyle.Sine), {Rotation = RandomOrientation, Position = UDim2.fromScale(RandomizedX, 1.1)}); Tween:Play()
		Tween.Completed:Connect(function()
			Clone:Destroy()
		end)
		
		task.wait(math.random(1, 3) / 100)
	end
end

-- Initialization function for the script
function ConfettiHandler:Initialize()
	RemoteBank.Confetti.OnClientEvent:Connect(ConfettiHandler.SpawnConfetti)
end

return ConfettiHandler
