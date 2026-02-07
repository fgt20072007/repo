local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")

local Red = require(Shared.Packages:WaitForChild("Red"))
local Guard = require(Shared.Packages:WaitForChild("Guard"))

return Red.Event("CollectDroppables", function(Droppables, Character)
	return Guard.List(Guard.Instance(Droppables)), Guard.Instance(Character)
end)
