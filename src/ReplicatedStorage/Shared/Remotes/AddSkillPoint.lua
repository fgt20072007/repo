local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")

local Red = require(Shared.Packages:WaitForChild("Red"))
local Guard = require(Shared.Packages:WaitForChild("Guard"))

return Red.Event("AddSkillPoint", function(Category, Amount)
	return Guard.String(Category), Guard.Integer(Amount)
end)
