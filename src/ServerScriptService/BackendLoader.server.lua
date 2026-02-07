local ServerScriptService = game:GetService('ServerScriptService')
local ReplicatedStorage = game:GetService('ReplicatedStorage')
local RunService = game:GetService("RunService")
local LoaderFolder = ServerScriptService.Components

local DataService = require(ReplicatedStorage.Utilities.DataService)
local currentStoreIndex = "0.0.1"
DataService.server:init({
	useMock = RunService:IsStudio(),
	template = {
		index = {},
		betterHintsOwned = {}
	},
	profileStoreIndex = "DatastoreVersion#" .. currentStoreIndex
})

local function LoadModule(Module: ModuleScript)
	local Required = require(Module)
	if Required["Initialize"] then
		Required:Initialize()
	end
	return Required
end

for _, module in LoaderFolder:GetChildren() do
	local success, errormsg = LoadModule(module)
	if not success then warn(errormsg, debug.traceback()) end
end