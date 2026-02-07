local part = script.Parent
local debounce = {}

part.Touched:Connect(function(hit)
	local character = hit.Parent
	local humanoid = character:FindFirstChild("Humanoid")
	local player = game.Players:GetPlayerFromCharacter(character)

	if humanoid and player and not debounce[player] then
		debounce[player] = true
		humanoid.Health = 0

		task.delay(1, function()
			debounce[player] = nil
		end)
	end
end)
