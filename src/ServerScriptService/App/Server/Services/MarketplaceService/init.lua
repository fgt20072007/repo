--!strict

local MarketplaceService = game:GetService("MarketplaceService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")

local appServer = ServerScriptService:WaitForChild("App"):WaitForChild("Server")
local system = appServer:WaitForChild("System")

local sharedData = ReplicatedStorage:WaitForChild("App"):WaitForChild("Shared"):WaitForChild("Data")
local marketData = sharedData:WaitForChild("Market")
local products = require(marketData:WaitForChild("Products"))
local gamePasses = require(marketData:WaitForChild("GamePasses"))

local BaseService = require(system:WaitForChild("BaseService"))

local internal = script:WaitForChild("_Internal")
local HandlerResolver = require(internal:WaitForChild("HandlerResolver"))

local SERVICE_NAME = "MarketplaceService"

local Service = BaseService.New(SERVICE_NAME, { "PlayerProfileService", "GarageService" })

local gamePassHandlersFolder = internal:WaitForChild("GamePasses")
local productHandlersFolder = internal:WaitForChild("Products")

local gamePassKeyById, gamePassHandlersById = HandlerResolver.BuildHandlers(gamePasses, gamePassHandlersFolder)
local productKeyById, productHandlersById = HandlerResolver.BuildHandlers(products, productHandlersFolder)

local function getUserIdFromReceipt(receiptInfo: any): number?
	local playerId = receiptInfo.PlayerId
	if type(playerId) ~= "number" then
		return nil
	end

	return playerId
end

local function getPlayerFromReceipt(receiptInfo: any): Player?
	local userId = getUserIdFromReceipt(receiptInfo)
	if userId == nil then
		return nil
	end

	return Players:GetPlayerByUserId(userId)
end

function Service:_BuildContext()
	return {
		ProfileService = self._profileService,
		GarageService = self._GarageService,
	}
end

function Service:_ApplyGamePass(player: Player, gamePassId: number)
	local handler = gamePassHandlersById[gamePassId]
	if handler == nil then
		return
	end

	if type(handler.ApplyOwnership) ~= "function" then
		error(`GamePass handler "{gamePassKeyById[gamePassId]}" must expose ApplyOwnership(player, context)`)
	end

	handler.ApplyOwnership(player, self:_BuildContext())
end

function Service:_ApplyOwnedGamePasses(player: Player)
	for gamePassId, _ in pairs(gamePassKeyById) do
		local ok, owns = pcall(MarketplaceService.UserOwnsGamePassAsync, MarketplaceService, player.UserId, gamePassId)
		if ok == true and owns == true then
			self:_ApplyGamePass(player, gamePassId)
		end
	end
end

function Service:_OnGamePassPurchaseFinished(player: Player, gamePassId: number, wasPurchased: boolean)
	if wasPurchased ~= true then
		return
	end

	self:_ApplyGamePass(player, gamePassId)
end

function Service:_ProcessReceipt(receiptInfo: any)
	local productId = receiptInfo.ProductId
	if type(productId) ~= "number" then
		return Enum.ProductPurchaseDecision.NotProcessedYet
	end

	local handler = productHandlersById[productId]
	if handler == nil then
		return Enum.ProductPurchaseDecision.NotProcessedYet
	end

	if type(handler.ProcessReceipt) ~= "function" then
		error(`Product handler "{productKeyById[productId]}" must expose ProcessReceipt(player, receiptInfo, context)`)
	end

	local player = getPlayerFromReceipt(receiptInfo)
	if player == nil then
		return Enum.ProductPurchaseDecision.NotProcessedYet
	end

	local ok, processed = pcall(handler.ProcessReceipt, player, receiptInfo, self:_BuildContext())
	if ok ~= true then
		return Enum.ProductPurchaseDecision.NotProcessedYet
	end

	if processed == true then
		return Enum.ProductPurchaseDecision.PurchaseGranted
	end

	return Enum.ProductPurchaseDecision.NotProcessedYet
end

function Service:_OnProductPurchaseFinished(userId: number, productId: number, wasPurchased: boolean)
	local handler = productHandlersById[productId]
	if handler == nil then
		return
	end

	if type(handler.OnPromptFinished) ~= "function" then
		return
	end

	local player = Players:GetPlayerByUserId(userId)
	if player == nil then
		return
	end

	handler.OnPromptFinished(player, wasPurchased, self:_BuildContext())
end

function Service:Init(registry)
	self._profileService = registry:Get("PlayerProfileService")
	self._GarageService = registry:Get("GarageService")
end

function Service:Start(_registry)
	MarketplaceService.ProcessReceipt = function(receiptInfo)
		return self:_ProcessReceipt(receiptInfo)
	end

	self.Maid:Add(MarketplaceService.PromptProductPurchaseFinished:Connect(function(userId, productId, wasPurchased)
		self:_OnProductPurchaseFinished(userId, productId, wasPurchased)
	end))

	self.Maid:Add(MarketplaceService.PromptGamePassPurchaseFinished:Connect(function(player, gamePassId, wasPurchased)
		self:_OnGamePassPurchaseFinished(player, gamePassId, wasPurchased)
	end))

	self.Maid:Add(Players.PlayerAdded:Connect(function(player)
		task.spawn(function()
			self:_ApplyOwnedGamePasses(player)
		end)
	end))

	for _, player in ipairs(Players:GetPlayers()) do
		task.spawn(function()
			self:_ApplyOwnedGamePasses(player)
		end)
	end
end

return Service
