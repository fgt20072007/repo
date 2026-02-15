local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Packages = ReplicatedStorage:WaitForChild("Packages")
local Debug = require(Packages:WaitForChild("Debug"))

local Utility = {}

function Utility:Require(module: ModuleScript)
	local success, result = pcall(function()
		return require(module)
	end)
	
	if success then
		return result
	else
		Debug:Breakpoint(script.Name, result, false)
		return false
	end
	
end

return Utility