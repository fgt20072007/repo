--> Services
local UserInputService = game:GetService("UserInputService")


--> Misc
local Buttons = script.Parent:WaitForChild("Buttons")
local SirenButton = Buttons:WaitForChild("Siren") :: GuiButton
local ELS_Frame = Buttons:WaitForChild("ELS")
local PC_ELS_Frame = script.Parent:WaitForChild("Gauge"):WaitForChild("ELS")

local Car = script.Parent.Car.Value
local ToggleSirenRE = Car.ToggleSiren
local SirenTypes = require(ToggleSirenRE.SirenTypes)

local COOLDOWN = 0.15
local SirenKeyboardButton = Enum.KeyCode.X
local SirenSoundKeyboardButton = Enum.KeyCode.C

local SirenControllerButton = Enum.KeyCode.ButtonY
local SirenSoundControllerButton = Enum.KeyCode.DPadRight


local last = tick()
local function ToggleSirenLight(SirenType:string)
	local now = tick()
	if now - last < COOLDOWN then return end
	last = now
	
	ToggleSirenRE:FireServer("Siren", SirenType)
end


local function ToggleSirenSound(SirenType:string)
	local now = tick()
	if now - last < COOLDOWN then return end
	last = now

	ToggleSirenRE:FireServer("SirenSound", SirenType)
end

local function UpdateButtons(NextSirenType)
	local CurrentSiren = NextSirenType or Car:GetAttribute("SirenSound")
	CurrentSiren = CurrentSiren ~= "OFF" and CurrentSiren or nil
	
	local function Update(Frame)
		for _, Button in Frame:GetChildren() do
			if not table.find(SirenTypes, Button.Name) then continue end
			if not (Button:IsA("TextButton") and Button.Name ~= "CloseButton") then continue end
			local TextColor = CurrentSiren == Button.Name and Color3.fromRGB(255, 158, 1) or Color3.fromRGB(200, 200, 200)
			Button.TextLabel.TextColor3  = TextColor
			Button.UIStroke.Color = TextColor
		end
	end
	
	Update(ELS_Frame.Frame)
	Update(PC_ELS_Frame.Frame)
end
UpdateButtons()

--> Cycle through all siren types and turn off

local function CompareSirenLights()
	local CurrentSiren = Car:GetAttribute("Siren")
	return CurrentSiren == SirenTypes[3] and "OFF" or SirenTypes[3]
end

local function CycleSirenLights()
	local Siren = CompareSirenLights()
	ToggleSirenLight(Siren)
	return Siren
end

local function UpdateSirenLightButton(CurrentSiren)
	local function Update(Frame)
		local TextColor = CurrentSiren ~= "OFF" and Color3.fromRGB(255, 158, 1) or Color3.fromRGB(200, 200, 200)
		Frame.Emergency.TextLabel.TextColor3 = TextColor
		Frame.Emergency.UIStroke.Color = TextColor
		
	end
	
	Update(ELS_Frame.Frame)
	Update(PC_ELS_Frame.Frame)
end
UpdateSirenLightButton(Car:GetAttribute("Siren") ~= SirenTypes[3] and "OFF" or SirenTypes[3])

local function CycleSirenSound()
	local CurrentSiren = Car:GetAttribute("SirenSound")
	local CurrentSirenIndex = table.find(SirenTypes, CurrentSiren)

	if not CurrentSiren then
		CurrentSirenIndex = 0
	end

	if not CurrentSirenIndex then return end
	CurrentSirenIndex = (CurrentSirenIndex % (#SirenTypes + 1)) + 1


	local Siren = SirenTypes[CurrentSirenIndex] or "OFF"
	
	ToggleSirenSound(Siren)
	return Siren
end

UserInputService.InputBegan:Connect(function(input: InputObject, gPE: boolean)
	if gPE then return end
	if input.KeyCode == SirenKeyboardButton or input.KeyCode == SirenControllerButton then
		local NextSirenLightType = CycleSirenLights()
		UpdateSirenLightButton(NextSirenLightType)
	elseif input.KeyCode == SirenSoundKeyboardButton or input.KeyCode == SirenSoundControllerButton then
		local NextSirenSound = CycleSirenSound()
		UpdateButtons(NextSirenSound)
	end
end)

local function MakeELS_ButtonsFunctionality(ELS_Frame)
	for _, Button in ELS_Frame:GetChildren() do
		if not (Button:IsA("TextButton") and Button.Name ~= "CloseButton" and Button.Name ~= "Horn") then continue end

		Button.MouseButton1Click:Connect(function()
			if table.find(SirenTypes, Button.Name) then
				ToggleSirenSound(Button.Name)
				local NextSirenType = Car:GetAttribute("SirenSound") == Button.Name and "OFF" or Button.Name
				UpdateButtons(NextSirenType)
			else
				local NextSirenLightType = CycleSirenLights()
				UpdateSirenLightButton(NextSirenLightType)
			end
		end)
	end

end
MakeELS_ButtonsFunctionality(ELS_Frame.Frame)
MakeELS_ButtonsFunctionality(PC_ELS_Frame.Frame)



--> Open/Close ELS Frame
SirenButton.MouseButton1Click:Connect(function()
	ELS_Frame.Visible = not ELS_Frame.Visible
end)

ELS_Frame.Frame.CloseButton.MouseButton1Click:Connect(function()
	ELS_Frame.Visible = false
end)