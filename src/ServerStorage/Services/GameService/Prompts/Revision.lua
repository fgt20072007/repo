local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")

local Packages = ReplicatedStorage.Packages
local Observers = require(Packages.Observers)


local function PlayerIsCivilian(player: Player)
	if not player then return false end

	if player.Team:HasTag("Federal") then
		return false
	end

	if player.Team.Name ~= "Civilian" then 
		return false 
	end

	return true
end

return {

	Init = function()
		Observers.observeCharacter(function(player: Player, character: Model)
			if not player or not character then return end
			if not PlayerIsCivilian(player) then 

				return
			end

			local currentRevision = player:GetAttribute("Revision")
			if currentRevision ~= "Wanted" and currentRevision ~= "Hostile" then
				player:SetAttribute("Revision", "Not Approved")
			end
			local HumanoidRootPart = character:FindFirstChild("HumanoidRootPart")
			if HumanoidRootPart:FindFirstChild("ApprovePrompt") then return end

			local approvePrompt = Instance.new("ProximityPrompt")
			approvePrompt.Name = "ApprovePrompt"
			approvePrompt.ActionText = "Stamp"
			approvePrompt.ObjectText = "Approve"
			approvePrompt.HoldDuration = 0.4
			approvePrompt.MaxActivationDistance = 8
			approvePrompt.RequiresLineOfSight = false
			approvePrompt.KeyboardKeyCode = Enum.KeyCode.R
			approvePrompt.GamepadKeyCode = Enum.KeyCode.ButtonA
			approvePrompt.Exclusivity = Enum.ProximityPromptExclusivity.OnePerButton
			approvePrompt:AddTag("StampPrompt")
			approvePrompt:AddTag("PlayerPrompt")
			approvePrompt:AddTag("Highlight")
			approvePrompt.Parent = HumanoidRootPart
			approvePrompt.Enabled = false

			local secondaryPrompt = Instance.new("ProximityPrompt")
			secondaryPrompt.Name = "SecondaryPrompt"
			secondaryPrompt.ActionText = "Stamp"
			secondaryPrompt.ObjectText = "Secondary revision"
			secondaryPrompt.HoldDuration = 0.4
			secondaryPrompt.KeyboardKeyCode = Enum.KeyCode.F
			secondaryPrompt.GamepadKeyCode = Enum.KeyCode.ButtonY
			secondaryPrompt.MaxActivationDistance = 8
			secondaryPrompt.RequiresLineOfSight = false
			secondaryPrompt.Exclusivity = Enum.ProximityPromptExclusivity.OnePerButton
			secondaryPrompt.UIOffset = Vector2.new(0, -80)
			secondaryPrompt:AddTag("StampPrompt")
			secondaryPrompt:AddTag("PlayerPrompt")
			secondaryPrompt:AddTag("Highlight")
			secondaryPrompt.Parent = HumanoidRootPart
			secondaryPrompt.Enabled = false
		end)
	end

}