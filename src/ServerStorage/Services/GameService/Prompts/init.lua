local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")

local Util = ReplicatedStorage:WaitForChild("Util")
local Utility = require(Util.Utility)

return {
	Init = function()
		for _,v in pairs(script:GetChildren()) do
			if not v:IsA("ModuleScript") then continue end
			
			local result = Utility:Require(v)
			if not result then continue end
			
			result.Init()
		end		
	end,
}