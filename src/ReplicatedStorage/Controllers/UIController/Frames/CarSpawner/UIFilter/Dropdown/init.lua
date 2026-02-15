local Signal = require(script.Signal)

local module = {}

local function ClearDropdown(DropdownData)
	--> Remove Dropdown options
	DropdownData.Visible = false
	DropdownData.ScrollingFrame.Visible = false
	
	for _, OptionFrame in DropdownData.ScrollingFrame:GetChildren() do
		if OptionFrame:GetAttribute("Option") then OptionFrame:Destroy() end
	end
end

local function UpdateDropdown(DropdownData)
	DropdownData.Frame.Holder.TextButton.TextLabel.Text = DropdownData.CurrentDropdownOption
end

local function ToggleDropdown(DropdownData)
	DropdownData.Visible = not DropdownData.Visible
	DropdownData.ScrollingFrame.Visible = DropdownData.Visible
	
	if DropdownData.Visible then
		local OptionsTemplate:TextButton = DropdownData.ScrollingFrame:FindFirstChild("Template")
		--> Create Dropdown options
		for _, Option in DropdownData.Options do
			local OptionButton = OptionsTemplate:Clone()
			OptionButton.TextLabel.Text = Option
			OptionButton.Visible = true
			OptionButton:SetAttribute("Option", true)
			OptionButton.Parent = DropdownData.ScrollingFrame
			
			--TODO: El garbage collector se encargaría de limpiar esta conexión?
			OptionButton.MouseButton1Click:Connect(function()
				DropdownData.CurrentDropdownOption = Option
				
				ClearDropdown(DropdownData)
				UpdateDropdown(DropdownData)
				DropdownData.TriggerEvent:Fire(Option)
			end)
		end
	else
		ClearDropdown(DropdownData)
	end
end 

function module:Clear(DropdownData)
	ClearDropdown(DropdownData)
end

function module:Setup(Frame:Frame, Options:{string})
	local Holder:Frame = Frame:FindFirstChild("Holder")
	local ScrollingFrame:ScrollingFrame = Frame:FindFirstChild("Dropdown")
	local TriggerButton:TextButton = Holder:FindFirstChild("TextButton")
	
	local DropdownData = {
		CurrentDropdownOption = Options and Options[1] or "N/A",
		Visible = false,
		Frame = Frame,
		ScrollingFrame = ScrollingFrame,
		Options = Options,
		
		TriggerEvent = Signal.New()
	}
	
	UpdateDropdown(DropdownData)
	
	DropdownData.Connections = {
		TriggerButton.MouseButton1Click:Connect(function()
			ToggleDropdown(DropdownData)
		end)
	}
	
	
	return DropdownData
end



return module
