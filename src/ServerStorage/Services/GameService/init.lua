 local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")

local Util = ReplicatedStorage:WaitForChild("Util")
local Utility = require(Util.Utility)

local GameService = {}

function GameService.Init()
	for _, module in script:GetChildren() do
		if not module:IsA("ModuleScript") then continue end
		local result = Utility:Require(module)
		if not result then continue end
		
		result.Init()
	end
end

return GameService	