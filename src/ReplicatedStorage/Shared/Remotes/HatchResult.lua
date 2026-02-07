local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")

local Red = require(Shared.Packages:WaitForChild("Red"))
local Guard = require(Shared.Packages:WaitForChild("Guard"))

return Red.Event("HatchResult", function(Result)
	return Guard.Map(Guard.String, Guard.Or(Guard.Integer, Guard.String))
end)
