local StarterPlayer = game:GetService('StarterPlayer')
local BasicWalkSpeed = StarterPlayer.CharacterWalkSpeed

return function(tool: Tool, informations)
	local Boost = informations.Boost
	
	local previousHumanoid 
	
	tool.Equipped:Connect(function()
		local char = tool.Parent
		if char then
			local Humanoid = char:FindFirstChild("Humanoid")
			if Humanoid then
				previousHumanoid = Humanoid
				Humanoid.WalkSpeed = BasicWalkSpeed + Boost
			end
		end
	end)
	
	tool.Unequipped:Connect(function()
		if previousHumanoid then
			previousHumanoid.WalkSpeed = BasicWalkSpeed
		end
	end)
end