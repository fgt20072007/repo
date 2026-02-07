-- Services
local ReplicatedStorage = game:GetService('ReplicatedStorage')
local Players = game:GetService('Players')
local MessagingService = game:GetService("MessagingService")

-- Variables

-- Dependencies
local DataService = require(ReplicatedStorage.Utilities.DataService)
local RemoteBank = require(ReplicatedStorage.RemoteBank)

local GlobalMessagesHandler = {}

function GlobalMessagesHandler.SendGlobalMessage(message)
	MessagingService:PublishAsync("GlobalMessage", message)
end

-- Initialization function for the script
function GlobalMessagesHandler:Initialize()
	MessagingService:SubscribeAsync("GlobalMessage", function(data)
		RemoteBank.SendNotification:FireAllClients("ADMIN: " .. data.Data)
	end)
end

return GlobalMessagesHandler
