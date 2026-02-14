local server = script.Parent

local function getEntryModules(container: Instance): { ModuleScript }
	local modules = {}

	for _, child in container:GetChildren() do
		if child:IsA("ModuleScript") then
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

local function initializeModule(moduleScript: ModuleScript)
	local ok, loadedOrError = pcall(require, moduleScript)
	if not ok then
		if string.find(tostring(loadedOrError), "did not return exactly one value", 1, true) then
			return
		end

		error(loadedOrError)
	end

	local loaded = loadedOrError

	if type(loaded) == "function" then
		loaded()
		return
	end

	if type(loaded) ~= "table" then
		return
	end

	local init = loaded.Init or loaded.init
	if type(init) == "function" then
		init(loaded)
	end

	local start = loaded.Start or loaded.start
	if type(start) == "function" then
		task.spawn(start, loaded)
	end
end

local function initializeCollection(container: Instance)
	for _, moduleScript in getEntryModules(container) do
		initializeModule(moduleScript)
	end
end

initializeCollection(server:WaitForChild("System"))
initializeCollection(server:WaitForChild("Services"))
