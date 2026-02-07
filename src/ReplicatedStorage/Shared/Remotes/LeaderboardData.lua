local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")

local Red = require(Shared.Packages:WaitForChild("Red"))
local Guard = require(Shared.Packages:WaitForChild("Guard"))

return Red.Event("LeaderboardData", function(LeaderboardName, Data)
	return Guard.String(LeaderboardName), Guard.Any(Data)
end)