-- These arguments are guaranteed to exist and be correctly typed.
local ServerScriptService = game:GetService('ServerScriptService')
local ReplicatedStorage = game:GetService('ReplicatedStorage')

local GlobalMessagesHandler = require(ServerScriptService.Components.GlobalMessagesHandler)

return function (context, message)
	GlobalMessagesHandler.SendGlobalMessage(message)
end