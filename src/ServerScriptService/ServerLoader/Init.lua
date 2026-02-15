local ServerStorage = game:GetService('ServerStorage')

return {
	Init = function()
		for _, module in pairs(ServerStorage.Services:GetChildren()) do
			if not module:IsA("ModuleScript") then continue end
			if not module:HasTag("Start") then continue end

			local success, result = pcall(require, module)

			if success then
				if not result.Init then continue end
				
				local success, result = pcall(result.Init)
				if success then continue end
				
				print('Failed to init module:', module.Name, '-', result)
			else
				warn("Failed to require module:", module.Name, "-", result)
			end
		end
	end,
}