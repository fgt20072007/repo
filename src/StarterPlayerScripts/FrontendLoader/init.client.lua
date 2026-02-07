local ReplicatedStorage = game:GetService('ReplicatedStorage')
local SoundService = game:GetService('SoundService')
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
	if SoundService:FindFirstChild(soundName) then
		SoundService:FindFirstChild(soundName):Play()
	end
end)

local function LoadModule(Module: ModuleScript)
	if Module:HasTag("Ignore") then return end
	if not Module:IsA("ModuleScript") then return end
	local Required = require(Module)
	if Required["Initialize"] then
		print(Module)
		task.spawn(function()
			Required:Initialize()
		end)
	end
	return Required
end

for _, module in LoaderFolder:GetChildren() do
	LoadModule(module)
end

ReplicaClient.RequestData()