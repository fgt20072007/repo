
local Tool = script.Parent
local Remote = Tool:WaitForChild("Activate")
local Character = nil


local last = nil
local function CanReceive(last)
	return tick() - last >= Tool:GetAttribute("SendRate")
end



Tool.Activated:Connect(function()
	Character = Tool.Parent
end)

Tool.Deactivated:Connect(function()
	Character = nil
end)

Remote.OnServerEvent:Connect(function(player)
	if not Character then return end
	
	local ToolsPlayer = game.Players:GetPlayerFromCharacter(Character)
	if ToolsPlayer ~= player then return end
	
	if last and not CanReceive(last) then return end
	last = tick()
	
	
	print("Receive")
	Tool:SetAttribute("Activated", not Tool:GetAttribute("Activated"))
end)