local uis = game:GetService("UserInputService")

local button = script.Parent

local dragging
local dragInput
local dragStart
local startPos

local function update(input)
	local actualX = input.Position.X - button.Parent.AbsolutePosition.X
	local actualY = input.Position.Y - button.Parent.AbsolutePosition.Y
	button.Position = UDim2.new(0,actualX,0,actualY)
end

button.InputBegan:Connect(function(input)
	if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
		dragging = true
		dragStart = input.Position
		startPos = button.Position
		
		input.Changed:Connect(function()
			if input.UserInputState == Enum.UserInputState.End then
				dragging = false
			end
		end)
	end
end)

button.InputChanged:Connect(function(input)
	if input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch then
		dragInput = input
	end
end)

uis.InputChanged:Connect(function(input)
	if input == dragInput and dragging then
		update(input)
	end
end)

button.InputEnded:Connect(function()
	button.Position = UDim2.new(0.5,0,0.5,0)
end)