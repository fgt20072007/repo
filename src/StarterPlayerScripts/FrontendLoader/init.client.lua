local ReplicatedStorage = game:GetService('ReplicatedStorage')
local SoundService = game:GetService('SoundService')
local RunService = game:GetService('RunService')
local LoaderFolder = script

local DataService = require(ReplicatedStorage.Utilities.DataService)
local NotificationComponent = require(ReplicatedStorage.Utilities.NotificationComponent)
NotificationComponent:Initialize()
DataService.client:init()

local Fireworks = require(ReplicatedStorage.Utilities.Fireworks)
local RemoteBank = require(ReplicatedStorage.RemoteBank)
local ModelTween = require(ReplicatedStorage.Utilities.ModelTween)
local ReplicaClient = require(ReplicatedStorage.Utilities.ReplicaClient)

RemoteBank.PlaySound.OnClientEvent:Connect(function(soundName)
	if RunService:IsStudio() then
		return
	end

	local sound = SoundService:FindFirstChild(soundName)
	if sound then
		sound:Play()
	end
end)

local function LoadModule(Module: ModuleScript)
	if Module:HasTag("Ignore") then return end
	if not Module:IsA("ModuleScript") then return end

	local success, requiredOrError = pcall(function()
		return require(Module)
	end)
	if not success then
		return nil
	end

	if typeof(requiredOrError) == "table" and requiredOrError.Initialize then
		task.spawn(function()
			requiredOrError:Initialize()
		end)
	end
	return requiredOrError
end

for _, module in LoaderFolder:GetChildren() do
	LoadModule(module)
end

ReplicaClient.RequestData()