local Players = game:GetService("Players")

local ANSWER = "garama and madungdung" -- palabra correcta
local door = workspace:WaitForChild("BrainrotDoor")

local opened = false

-- estado inicial
door.Anchored = true
door.Transparency = 0
door.CanCollide = true

Players.PlayerAdded:Connect(function(player)
	player.Chatted:Connect(function(message)
		if opened then return end

		if string.lower(message) == ANSWER then
			opened = true

			-- hacerla atravesable sin desanclar
			door.Transparency = 1
			door.CanCollide = false

			-- esperar 5 segundos
			task.delay(5, function()
				door.Transparency = 0
				door.CanCollide = true
				opened = false
			end)
		end
	end)
end)
