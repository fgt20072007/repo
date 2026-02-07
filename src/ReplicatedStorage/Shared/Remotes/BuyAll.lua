local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")

local Red = require(Shared.Packages:WaitForChild("Red"))
local Guard = require(Shared.Packages:WaitForChild("Guard"))

return Red.Event("BuyAll", function(Category)
	return Guard.String(Category)
end)