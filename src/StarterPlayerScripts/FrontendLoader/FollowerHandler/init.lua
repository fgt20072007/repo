-- Services
local ReplicatedStorage = game:GetService('ReplicatedStorage')
local Players = game:GetService('Players')

-- Variables

-- Dependencies
local DataService = require(ReplicatedStorage.Utilities.DataService)
local Bases = require(ReplicatedStorage.DataModules.Bases)
local Zone = require(ReplicatedStorage.Utilities.Zone)
local Class = require("@self/FollowerClass")

local RemoteBank = require(ReplicatedStorage.RemoteBank)

local FollowerHandler = {}
local DEFENDER_SPAWN_Y_OFFSET = 4

local function prepareDefenderModel(model: Model)
	for _, descendant in model:GetDescendants() do
		if descendant:IsA("BasePart") then
			descendant.Anchored = false
		end
	end
end

local function setBaseHitboxCollision(baseModel: Model, canCollide: boolean)
	local hitbox = baseModel:FindFirstChild("Hitbox")
	if hitbox and hitbox:IsA("BasePart") then
		hitbox.CanCollide = canCollide
	end
end

-- Initialization function for the script
function FollowerHandler:Initialize()
	local BasesOwned = DataService.client:get("bases")
	local Cache = {}

	for _, v in workspace.Map.Bases:GetChildren() do
		local BaseNumber = tonumber(v.Name)
		local SpawnPosition = v.NPCSpawn.CFrame

		local Informations = Bases[BaseNumber]

		local OwnsBase = table.find(BasesOwned, BaseNumber)
		local PurchaseZone = v:FindFirstChild("PurchaseZone")

		local connection

		if PurchaseZone and not OwnsBase then
			local NewZone = Zone.new(PurchaseZone)
			connection = NewZone.localPlayerEntered:Connect(function()
				RemoteBank.TryPurchaseBase:InvokeServer(BaseNumber)
			end)
		end

		if OwnsBase then
			v:FindFirstChild("Button"):Destroy()
			v:FindFirstChild("Lasers"):Destroy()
			setBaseHitboxCollision(v, false)
		else
			setBaseHitboxCollision(v, true)
		end

		Cache[BaseNumber] = function()
			v:FindFirstChild("Button"):Destroy()
			v:FindFirstChild("Lasers"):Destroy()
			setBaseHitboxCollision(v, false)
			if connection then
				connection:Disconnect()
			end
		end
		if Informations and Informations.BaseDefender then
			local NewModel = Informations.BaseDefender:Clone()
			NewModel.Parent = workspace
			prepareDefenderModel(NewModel)

			local DefenderSpawnPosition = SpawnPosition + Vector3.new(0, DEFENDER_SPAWN_Y_OFFSET, 0)
			NewModel:PivotTo(DefenderSpawnPosition)

			Class(DefenderSpawnPosition, NewModel, BaseNumber, v:FindFirstChild("Zone"), Informations.Speed, Informations.IdleAnimation, Informations.WalkingAnimation, Informations.Orientation)
		end
	end

	DataService.client:getArrayInsertedSignal("bases"):Connect(function(index, value)
		if Cache[value] then
			Cache[value]()
		end
	end)
end

return FollowerHandler
