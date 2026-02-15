local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Util = ReplicatedStorage:WaitForChild('Util')
local Utility = require(Util.Utility)

local ToolService = {}

function ToolService.Init()
	
	for _, module in ipairs(script:GetChildren()) do
		if not module:IsA("ModuleScript") then continue end
		
		local safeRequire = Utility:Require(module)
		if not (safeRequire and safeRequire.Init) then continue end

		local succ, res = pcall(safeRequire.Init)
		if succ then continue end
		
		print('Failed to load tool:', module.Name, '-', res)
	end
	
end

return ToolService