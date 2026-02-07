-- Services
local ReplicatedStorage = game:GetService('ReplicatedStorage')
local Players = game:GetService('Players')

local MessagingService = game:GetService("MessagingService")

-- Variables

-- Dependencies
local DataService = require(ReplicatedStorage.Utilities.DataService)
local RemoteBank = require(ReplicatedStorage.RemoteBank)

local SharedUtilities = require(ReplicatedStorage.Utilities.SharedUtilities)

local SystemMessageHandler = {}

-- Initialization function for the script
function SystemMessageHandler:Initialize()
	MessagingService:SubscribeAsync("globalMessages", function(data)
		local data = data.Data
		local playerPurchasingName = data.player
		local productId = data.id
		
		local price, name = SharedUtilities.getProductPrice(productId, Enum.InfoType.Product)
		RemoteBank.SendSystemMessage:FireAllClients(playerPurchasingName, name, price)
	end)
end

return SystemMessageHandler
