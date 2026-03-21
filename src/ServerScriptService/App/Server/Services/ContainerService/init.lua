--!strict

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")

local appServer = ServerScriptService:WaitForChild("App"):WaitForChild("Server")
local system = appServer:WaitForChild("System")

local sharedData = ReplicatedStorage:WaitForChild("App"):WaitForChild("Shared"):WaitForChild("Data")
local Gen = require(sharedData:WaitForChild("General"):WaitForChild("Gen"))

local BaseService = require(system:WaitForChild("BaseService"))

local internal = script:WaitForChild("_Internal")
local Activation = require(internal:WaitForChild("Activation"))
local Grant = require(internal:WaitForChild("Grant"))
local PendingRegistry = require(internal:WaitForChild("PendingRegistry"))

local garageCost = Gen.Container.Cost

local Service = BaseService.New("ContainerService", { "PlayerProfileService" })

local function isValidGarageModel(garageModel: Model): boolean
	return garageModel.Parent ~= nil
end

function Service:Init(registry)
	self._profileService = registry:Get("PlayerProfileService")
	self._pendingRegistry = PendingRegistry.New()
end

function Service:Start(_registry)
	self.Maid:Add(Players.PlayerRemoving:Connect(function(player: Player)
		self._pendingRegistry:Clear(player)
	end))

	self.Maid:Add(function()
		self._pendingRegistry:Destroy()
	end)
end

function Service:HasPending(player: Player): boolean
	return self._pendingRegistry:Has(player)
end

function Service:SetPending(player: Player, garageModel: Model): boolean
	if isValidGarageModel(garageModel) ~= true then
		return false
	end

	self._pendingRegistry:Set(player, garageModel)
	return true
end

function Service:ConsumePending(player: Player): Model?
	return self._pendingRegistry:Consume(player)
end

function Service:ClearPending(player: Player)
	self._pendingRegistry:Clear(player)
end

function Service:Activate(player: Player, garageModel: Model, isRobux: boolean): boolean
	if isValidGarageModel(garageModel) ~= true then
		return false
	end

	local paymentConfirmed = Activation.TryActivate(self._profileService, player, garageModel, garageCost, isRobux)
	if paymentConfirmed ~= true then
		return false
	end

	return Grant.Apply(player, garageModel, isRobux)
end

return Service