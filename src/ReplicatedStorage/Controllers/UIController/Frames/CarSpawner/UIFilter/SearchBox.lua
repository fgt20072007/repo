local Signal = require(script.Parent.Dropdown.Signal)

local module = {}

function module:Clear(SearchData)
	SearchData.TextBox.Text = ""
end

function module:Setup(Frame: Frame, _Options)
	local Holder = Frame:FindFirstChild("Holder")
	local TextBox = Holder and Holder:FindFirstChild("TextBox")

	local SearchData = {
		CurrentDropdownOption = "",
		Frame = Frame,
		TextBox = TextBox,
		TriggerEvent = Signal.New(),
		Connections = {}
	}

	if TextBox then
		table.insert(SearchData.Connections, TextBox:GetPropertyChangedSignal("Text"):Connect(function()
			SearchData.CurrentDropdownOption = TextBox.Text
			SearchData.TriggerEvent:Fire(TextBox.Text)
		end))
	end

	return SearchData
end

return module