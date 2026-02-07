-- Services
local ReplicatedStorage = game:GetService('ReplicatedStorage')
local Players = game:GetService('Players')
local TweenService = game:GetService('TweenService')

-- Variables

-- Dependencies
local DataService = require(ReplicatedStorage.Utilities.DataService)
local RemoteBank = require(ReplicatedStorage.RemoteBank)


local ScaleTweenModels = {}

-- Initialization function for the script
function ScaleTweenModels:Initialize()
	RemoteBank.ScaleTween.OnClientEvent:Connect(function(model, startingScale, endScale, goback: boolean, TimeInformation: number)
		local NumberValue = Instance.new("NumberValue")
		NumberValue.Value = startingScale
		local Tween = TweenService:Create(NumberValue, TweenInfo.new(TimeInformation, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut), {Value = endScale})
		
		local Connection
		Connection = NumberValue:GetPropertyChangedSignal("Value"):Connect(function()
			model:ScaleTo(NumberValue.Value)
		end)
		
		Tween:Play()
		
		if goback then
			task.delay(TimeInformation, function()
				TweenService:Create(NumberValue, TweenInfo.new(TimeInformation, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut), {Value = startingScale}):Play()
				task.delay(TimeInformation, function()
					Connection:Disconnect()
					NumberValue:Destroy()
				end)
			end)
		else
			task.delay(TimeInformation, function()
				Connection:Disconnect()
				NumberValue:Destroy()
			end)
		end
	end)
	
	RemoteBank.ScalePart.OnClientEvent:Connect(function(part, startingSize, endSize)
		print(part)
		part.Size = startingSize
		TweenService:Create(part, TweenInfo.new(1.3, Enum.EasingStyle.Sine), {Size = endSize}):Play()
	end)
end

return ScaleTweenModels
