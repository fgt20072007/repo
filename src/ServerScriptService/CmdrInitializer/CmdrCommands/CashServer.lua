-- These arguments are guaranteed to exist and be correctly typed.
local ServerScriptService = game:GetService('ServerScriptService')
local ReplicatedStorage = game:GetService('ReplicatedStorage')

local DataService = require(ReplicatedStorage.Utilities.DataService)

return function (context, player, amount)
	DataService.server:update(player, "cash", function(old)
		return old + amount
	end)
end