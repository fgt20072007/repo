local UserInputService = game:GetService("UserInputService")

local Buttons = script.Parent:WaitForChild("Buttons")
local HornButton = Buttons:WaitForChild("Horn") :: GuiButton

local Car = script.Parent.Car.Value

local COOLDOWN = 0.15
local lastCheck: number

local ToggleHornRE = Car:WaitForChild("ToggleHorn") :: RemoteEvent

local function GetPcHornLabel(): TextLabel?
	local gauge = script.Parent:FindFirstChild("Gauge")
	if not gauge then return nil end

	local els = gauge:FindFirstChild("ELS")
	if not els then return nil end

	local frame = els:FindFirstChild("Frame")
	if not frame then return nil end

	local horn = frame:FindFirstChild("Horn")
	if not horn then return nil end

	local label = horn:FindFirstChild("TextLabel")
	if label and label:IsA("TextLabel") then
		return label
	end

	return nil
end


local function ToggleHornButton(state)
	local label = GetPcHornLabel()
	if not label then return end
	label.TextColor3 = state and Color3.fromRGB(255, 158, 1) or Color3.fromRGB(200, 200, 200)
end

UserInputService.InputBegan:Connect(function(input: InputObject, gPE: boolean)
	if gPE then return end
	if input.KeyCode == Enum.KeyCode.H or input.KeyCode == Enum.KeyCode.F then
		ToggleHornRE:FireServer(true)
		ToggleHornButton(true)
	end
end)

UserInputService.InputEnded:Connect(function(input: InputObject, gPE: boolean)
	if gPE then return end
	if input.KeyCode == Enum.KeyCode.H or input.KeyCode == Enum.KeyCode.F then
		ToggleHornRE:FireServer(false)
		ToggleHornButton(false)
	end
end)

HornButton.MouseButton1Down:Connect(function()
	local now = tick()
	if lastCheck and now - lastCheck < COOLDOWN then
		return
	end
	lastCheck = now

	ToggleHornRE:FireServer(true)
end)

HornButton.MouseButton1Up:Connect(function()
	ToggleHornRE:FireServer(false)
end)

do
	local gauge = script.Parent:FindFirstChild("Gauge")
	local els = gauge and gauge:FindFirstChild("ELS")
	local frame = els and els:FindFirstChild("Frame")
	local hornButton = frame and frame:FindFirstChild("Horn")

	if hornButton and hornButton:IsA("GuiButton") then
		hornButton.MouseButton1Down:Connect(function()
			ToggleHornRE:FireServer(true)
			ToggleHornButton(true)
		end)

		hornButton.MouseButton1Click:Connect(function()
			ToggleHornButton(false)
			ToggleHornRE:FireServer(false)
		end)

		hornButton.MouseLeave:Connect(function()
			ToggleHornButton(false)
			ToggleHornRE:FireServer(false)
		end)
	end
end



