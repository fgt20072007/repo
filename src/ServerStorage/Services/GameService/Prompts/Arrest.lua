local Players = game:GetService("Players")



local function PlayerIsCivilian(player: Player)
	if not player then return false end

	if player.Team.Name ~= "Civilian" then 
		return false 
	end

	return true
	end

return {

Init = function()

	Players.PlayerAdded:Connect(function(player: Player)
		if not player then return end

		player.CharacterAdded:Connect(function(character: Instance)
			if not character then return end
			if not PlayerIsCivilian(player) then return end

			player:SetAttribute("Detained", "Not Detained")
			
			
			local HumanoidRootPart = character:FindFirstChild("HumanoidRootPart")
			if HumanoidRootPart:FindFirstChild("ArrestPrompt") then return end

			local DetainPrompt = Instance.new("ProximityPrompt")
			DetainPrompt.Name = "DetainPrompt"
			DetainPrompt.ActionText = "Detain"
			DetainPrompt.ObjectText = "Cuffs"
			DetainPrompt.HoldDuration = 0.6
			DetainPrompt.MaxActivationDistance = 8
			DetainPrompt.Exclusivity =  Enum.ProximityPromptExclusivity.OnePerButton
			DetainPrompt.RequiresLineOfSight = false
			DetainPrompt.UIOffset = Vector2.new(0, -80)
			DetainPrompt:AddTag("DetainPrompt")
			DetainPrompt:AddTag("PlayerPrompt")
			DetainPrompt:AddTag("Highlight")
			DetainPrompt.Parent = HumanoidRootPart
			DetainPrompt.Enabled = false
			
			local ArrestPrompt = DetainPrompt:Clone()	
			ArrestPrompt.Name = "ArrestPrompt"
			ArrestPrompt.UIOffset = Vector2.zero
			ArrestPrompt.ActionText = "Arrest"
			ArrestPrompt.KeyboardKeyCode = Enum.KeyCode.F
			ArrestPrompt:RemoveTag("DetainPrompt")
			ArrestPrompt:RemoveTag("Highlight")
			ArrestPrompt:AddTag("ArrestPrompt")
			ArrestPrompt.Enabled = false
			ArrestPrompt.Parent = DetainPrompt.Parent
		end)
	end)		

end

}