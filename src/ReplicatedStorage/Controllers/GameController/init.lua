local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Util = ReplicatedStorage:WaitForChild("Util")
local Utility = require(Util.Utility)

local GameController = {}

function GameController.Init()
	
	for _, module in pairs(script:GetChildren()) do
		if not module:IsA("ModuleScript") then continue end
		
		local result = Utility:Require(module)
		if not result then continue end
		
		result.Init()
	end

end

return GameController