--!strict

local server = script.Parent

local function getEntryModules(container: Instance, includeModuleScripts: boolean): { ModuleScript }
	local modules = {}

	for _, child in container:GetChildren() do
		if includeModuleScripts == true and child:IsA("ModuleScript") then
			table.insert(modules, child)
		elseif child:IsA("Folder") then
			local initModule = child:FindFirstChild("init")
			if initModule and initModule:IsA("ModuleScript") then
				table.insert(modules, initModule)
			end
		end
	end

	table.sort(modules, function(a, b)
		return a:GetFullName() < b:GetFullName()
	end)

	return modules
end

local function safeRequire(moduleScript: ModuleScript)
	local ok, loadedOrError = pcall(require, moduleScript)
	if not ok then
		error(`Failed to require {moduleScript:GetFullName()}\n{loadedOrError}`)
	end
	return loadedOrError
end

local systemFolder = server:WaitForChild("System")
local servicesFolder = server:WaitForChild("Services")

local serviceRegistry = safeRequire(systemFolder:WaitForChild("ServiceRegistry"))
local registry = serviceRegistry.New()

for _, moduleScript in getEntryModules(servicesFolder, true) do
	local service = safeRequire(moduleScript)
	if type(service) ~= "table" then
		error(`Service module must return table: {moduleScript:GetFullName()}`)
	end
	registry:Register(service)
end

registry:InitAll()
registry:StartAll()