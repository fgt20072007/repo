

local Tool = script.Parent
local Remote = Tool:WaitForChild("Activate")






local last = nil
local function CanSend(last)
	return tick() - last >= Tool:GetAttribute("SendRate")
end

Tool.Activated:Connect(function()
	if last and not CanSend(last) then return end
	last = tick()
	
	Remote:FireServer()
end)

