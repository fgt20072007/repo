local ReplicatedStorage = game:GetService('ReplicatedStorage')

local Format = require(ReplicatedStorage.Utilities.Format)
local GlobalConfiguration = require(ReplicatedStorage.DataModules.GlobalConfiguration)

while task.wait(1) do
	local currentTime = os.time()
	local timeSinceLastEvent = currentTime % GlobalConfiguration.GodlySpawnAmount
	local timeRemaining = GlobalConfiguration.GodlySpawnAmount - timeSinceLastEvent

	script.Parent.Text = "Godly spawns in: " .. Format.formatTime(timeRemaining)
end