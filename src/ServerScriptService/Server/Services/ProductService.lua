type receiptInfo = {
	PurchaseId: number,
	PlayerId: number,
	ProductId: number,
	PlaceIdWherePurchased: number,
	CurrencySpent: number,
	ProductPurchaseChannel: Enum.ProductPurchaseChannel,
}

local MarketplaceService = game:GetService("MarketplaceService")
local MessagingService = game:GetService("MessagingService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")
local Players = game:GetService("Players")

local Shared = ReplicatedStorage.Shared

local Networker = require(Shared.Packages.networker)
local RewardFunctions = require(ServerScriptService.Server.Modules.ProductFunctions)
local Server = require(ServerScriptService.Server)

local ProductService = {}

function ProductService._Init(self: ProductService)
	self.Networker = Networker.server.new("ProductService", self, {
		self.PurchaseProduct,
	})

	local function ProcessReciept(receiptInfo: receiptInfo)
		local playerWhoPurchased = Players:GetPlayerByUserId(receiptInfo.PlayerId)
		if not playerWhoPurchased or playerWhoPurchased.Parent ~= Players then
			return Enum.ProductPurchaseDecision.NotProcessedYet
		end

		if not RewardFunctions[receiptInfo.ProductId] then
			return Enum.ProductPurchaseDecision.NotProcessedYet
		end

		RewardFunctions[receiptInfo.ProductId](playerWhoPurchased)

		local robuxSpent = receiptInfo.CurrencySpent or 0
		if robuxSpent > 0 then
			Server.Services.DataService:Increment(playerWhoPurchased, "RobuxSpent", robuxSpent)
		end

		return Enum.ProductPurchaseDecision.PurchaseGranted
	end

	local success, err = pcall(function()
		return MessagingService:SubscribeAsync(Server.GetImmutable().PRODUCT_PUBLISHING_TOPIC, function(data)
			print(data)
		end)
	end)

	if not success then
		warn(err)
	end

	MarketplaceService.ProcessReceipt = ProcessReciept
end

function ProductService.PurchaseProduct(self: ProductService, Player: Player, Id: number)
	MarketplaceService:PromptProductPurchase(Player, Id)
end

export type ProductService = typeof(ProductService) & {
	Networker: Networker.Server,
}

return ProductService
