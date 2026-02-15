local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Packages = ReplicatedStorage:WaitForChild("Packages")
local Controllers = ReplicatedStorage:WaitForChild("Controllers")

local function load()
	local list = Controllers:GetChildren()
	
	for _, module in list do
		if not (module:IsA("ModuleScript") and module:HasTag('Start')) then continue end

		local success, result = pcall(require, module)
		if success then
			if not result.Init then continue end
			
			local success, result = pcall(result.Init)
			if success then continue end
			
			warn('Failed to init module:', module.Name, '-', result)
		else
			warn("Failed to require module:", module.Name, "-", result)
		end
	end


	local satchel = Packages:WaitForChild("Satchel")
	if satchel then
		local success, result = pcall(require, satchel)

		if not success then
			warn("Failed to require module:", result)
		end
	end
end

return {
	Init = load,
}