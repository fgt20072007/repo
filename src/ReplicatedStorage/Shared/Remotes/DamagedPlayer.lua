local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")

local Red = require(Shared.Packages:WaitForChild("Red"))
local Guard = require(Shared.Packages:WaitForChild("Guard"))

return Red.Event("DamagedPlayer", function(Character, Damage, Dead)
	return Guard.Instance(Character), Guard.Number(Damage), Guard.Boolean(Dead)
end)
