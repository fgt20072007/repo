local uis = game:GetService("UserInputService")
local OnMobile = Instance.new("BoolValue")

if uis.KeyboardEnabled == false and uis.TouchEnabled == true then
	OnMobile.Value = true
elseif uis.KeyboardEnabled == true then
	OnMobile.Value = false
end

OnMobile.Name = "OnMobile"
OnMobile.Parent = script.Parent
script.Parent = OnMobile

uis.LastInputTypeChanged:Connect(function(inputtype, chat)
	if not chat then
		if inputtype == Enum.UserInputType.Touch then
			OnMobile.Value = true
			--print(inputtype)
		elseif inputtype == Enum.UserInputType.MouseButton2 then
			OnMobile.Value = false
			--print(inputtype)
		elseif inputtype == Enum.UserInputType.Keyboard then
			OnMobile.Value = false
		end
	end
end)