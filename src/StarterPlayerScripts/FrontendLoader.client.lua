repeat
	task.wait(1)
until game:IsLoaded()


local ReplicatedStorage = game:GetService('ReplicatedStorage')
local LoaderFolder = ReplicatedStorage.Controllers

local DataService = require(ReplicatedStorage.Utilities.DataService)
DataService.client:init()

local function LoadModule(Module: ModuleScript)
	if not Module:IsA("ModuleScript") then return end
	local Required = require(Module)
	if Required["Initialize"] then
		Required:Initialize()
	end
	return Required
end

for _, module in LoaderFolder:GetChildren() do
	local success, errormsg = pcall(LoadModule, module)
	if not success then warn(errormsg) end
end