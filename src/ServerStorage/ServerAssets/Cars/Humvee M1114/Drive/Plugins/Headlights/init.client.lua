local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService("UserInputService")

local Car = script.Parent.Car.Value :: ObjectValue

local ToggleHeadlightsRE = Car:WaitForChild("ToggleHeadlights") :: RemoteEvent

local COOLDOWN = 0.15
local lastCheck: number

UserInputService.InputBegan:Connect(function(input: InputObject, gPE: boolean)
		if gPE then return end
		
		
		local now = tick()
		if lastCheck and now - lastCheck < COOLDOWN then return end
		lastCheck = now

	if input.KeyCode == Enum.KeyCode.L or input.KeyCode == Enum.KeyCode.ButtonL1 then
		ToggleHeadlightsRE:FireServer() 
	end
end)



