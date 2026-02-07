local tool = script.Parent
local event = tool:WaitForChild("UseEvent")

event.OnServerEvent:Connect(function(player, action)
	local character = player.Character
	if not character then return end

	local root = character:FindFirstChild("HumanoidRootPart")
	if not root then return end

	if action == "Anchor" then
		root.Anchored = true
	elseif action == "Unanchor" then
		root.Anchored = false
	end
end)
