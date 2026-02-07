local part = script.Parent
local clickDetector = part:WaitForChild("ClickDetector")

-- 📍 Posición destino
local targetCFrame = CFrame.new(-455.851, -91.296, 291.293)

-- ⏱️ cooldown por jugador
local cooldown = {}
local COOLDOWN_TIME = 1.5 -- segundos

clickDetector.MouseClick:Connect(function(player)
	-- Anti-spam
	if cooldown[player] then return end
	cooldown[player] = true

	local character = player.Character
	if not character then
		cooldown[player] = nil
		return
	end

	local humanoid = character:FindFirstChildOfClass("Humanoid")
	local root = character:FindFirstChild("HumanoidRootPart")

	if humanoid and root and humanoid.Health > 0 then
		-- Evita bugs de sentarse / físicas raras
		humanoid.Sit = false
		humanoid:ChangeState(Enum.HumanoidStateType.Physics)

		-- Teleport seguro
		character:PivotTo(targetCFrame)
	end

	-- Quitar cooldown
	task.delay(COOLDOWN_TIME, function()
		cooldown[player] = nil
	end)
end)
