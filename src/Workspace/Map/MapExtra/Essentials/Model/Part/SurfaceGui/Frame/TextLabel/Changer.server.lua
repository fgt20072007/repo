local ReplicatedStorage = game:GetService('ReplicatedStorage')

local Format = require(ReplicatedStorage.Utilities.Format)
local GlobalConfiguration = require(ReplicatedStorage.DataModules.GlobalConfiguration)

while task.wait(1) do
	local currentTime = os.time()
	local timeSinceLastEvent = currentTime % GlobalConfiguration.MythicalSpawnAmount
	local timeRemaining = GlobalConfiguration.MythicalSpawnAmount - timeSinceLastEvent

	script.Parent.Text = "Mythic spawns in: " .. Format.formatTime(timeRemaining)
end