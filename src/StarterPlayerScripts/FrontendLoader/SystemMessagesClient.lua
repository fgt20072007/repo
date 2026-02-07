-- Services
local ReplicatedStorage = game:GetService('ReplicatedStorage')
local Players = game:GetService('Players')
local ChatService = game:GetService("TextChatService")

-- Variables

-- Dependencies
local DataService = require(ReplicatedStorage.Utilities.DataService)
local RemoteBank = require(ReplicatedStorage.RemoteBank)

local ChangeThistoWhatever = {}

-- Initialization function for the script
function ChangeThistoWhatever:Initialize()
	RemoteBank.SendSystemMessage.OnClientEvent:Connect(function(playername, productName, price)
		ChatService.TextChannels.RBXGeneral:DisplaySystemMessage(`[SYSTEM] {playername} has purchased {productName} for {price}`)
	end)
end

return ChangeThistoWhatever
