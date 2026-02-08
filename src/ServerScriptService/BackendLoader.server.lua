local ServerScriptService = game:GetService('ServerScriptService')
local ReplicatedStorage = game:GetService('ReplicatedStorage')
local RunService = game:GetService("RunService")
local LoaderFolder = ServerScriptService.Components

local DataService = require(ReplicatedStorage.Utilities.DataService)
local GlobalConfiguration = require(ReplicatedStorage.DataModules.GlobalConfiguration)
local ModelTween = require(ReplicatedStorage.Utilities.ModelTween)

local physicsService = game:GetService("PhysicsService")
do 
	local physicsService = game:GetService("PhysicsService")
	physicsService:RegisterCollisionGroup("Entities")
	physicsService:RegisterCollisionGroup("Effects")
	physicsService:RegisterCollisionGroup("Players")
	physicsService:RegisterCollisionGroup("FollowerUncollidable")

	physicsService:CollisionGroupSetCollidable("Effects", "Players", false)
	physicsService:CollisionGroupSetCollidable("Effects", "FollowerUncollidable", false)
	physicsService:CollisionGroupSetCollidable("Effects", "Effects", false)
	physicsService:CollisionGroupSetCollidable("Entities", "Default", false)

	for _, v in ReplicatedStorage.DataModules.Entities:GetDescendants() do
		if v:IsA("BasePart") then
			v.CollisionGroup = "Effects"
		end
	end

	local brainrotsFolder = ReplicatedStorage.DataModules:FindFirstChild("Brainrots")
	if brainrotsFolder then
		for _, v in brainrotsFolder:GetDescendants() do
			if v:IsA("BasePart") then
				v.CollisionGroup = "Effects"
			end
		end
	end

	for _, v in workspace.TemplateBase.Uncollidable:GetDescendants() do
		if v:IsA("BasePart") then
			v.CollisionGroup = "FollowerUncollidable"
		end
	end

	for _, v in ReplicatedStorage.DataModules.Bases:GetDescendants() do
		if v:IsA("BasePart") then
			v.CollisionGroup = "Effects"
		end
	end

	local Players = game:GetService('Players')
	Players.PlayerAdded:Connect(function(player)
		player.CharacterAdded:Connect(function(char)
			for _, v in char:GetDescendants() do
				if v:IsA("BasePart") then
					v.CollisionGroup = "Players"
				end
			end
		end)
	end)

end

local currentStoreIndex = GlobalConfiguration.CurrentDatastoreVersion
DataService.server:init({
	useMock = GlobalConfiguration.MockInStudio and RunService:IsStudio(),
	template = {
		rebirth = GlobalConfiguration.StarterRebirth,
		cash = GlobalConfiguration.StarterCash,

		bases = {
			1
		},
		index = {},
		stands = {},
		inventory = {},
		gears = {},
	},
	profileStoreIndex = "DatastoreVersion#" .. currentStoreIndex
})

local function LoadModule(Module: ModuleScript)
	local success, requiredOrError = pcall(function()
		return require(Module)
	end)
	if not success then
		return false, requiredOrError
	end

	if typeof(requiredOrError) == "table" and requiredOrError.Initialize then
		task.spawn(function()
			requiredOrError:Initialize()
		end)
	end
	return true, requiredOrError
end

for _, module in LoaderFolder:GetChildren() do
	local success, errormsg = LoadModule(module)
	if not success then
		warn(errormsg, debug.traceback())
	end
end