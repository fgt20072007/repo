local seat = script.Parent
local debounce = {}

-- 🔁 POSICIÓN A LA QUE SERÁ ENVIADO
local teleportCFrame = CFrame.new(-602.121, -87.411, 293.967) -- ⬅️ CAMBIA ESTO

seat.Touched:Connect(function(hit)
	local character = hit.Parent
	local humanoid = character:FindFirstChild("Humanoid")
	if not humanoid then return end

	local player = game.Players:GetPlayerFromCharacter(character)
	if not player then return end

	-- 🛑 Evitar que se active muchas veces
	if debounce[player] then return end
	debounce[player] = true

	local root = character:FindFirstChild("HumanoidRootPart")
	if root then
		root.CFrame = teleportCFrame
	end

	-- ⏱️ Cooldown
	task.delay(1, function()
		debounce[player] = nil
	end)
end)
