local ReplicatedStorage = game:GetService('ReplicatedStorage')

local Format = require(ReplicatedStorage.Utilities.Format)
local GlobalConfiguration = require(ReplicatedStorage.DataModules.GlobalConfiguration)

while task.wait(1) do
	local currentTime = os.time()
	local timeSinceLastEvent = currentTime % GlobalConfiguration.SecretSpawnAmount
	local timeRemaining = GlobalConfiguration.SecretSpawnAmount - timeSinceLastEvent

	script.Parent.Text = "Secret spawns in: " .. Format.formatTime(timeRemaining)
end