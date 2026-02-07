local ReplicatedStorage = game:GetService('ReplicatedStorage')

local Function = ReplicatedStorage.Communication.Functions.PurchaseBetterHint
local MarketplaceHandler = require("./MarketplaceHandler")
local ProductIds = require(ReplicatedStorage.DataModules.ProductIds)

local IndexServer = {}

function IndexServer.Initialize()
	Function.OnServerInvoke = function(player, entityName)
		MarketplaceHandler.Purchase(player, false, ProductIds.BetterHintId, entityName)
	end
end

return IndexServer