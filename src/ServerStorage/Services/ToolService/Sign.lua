local ServerStorage = game:GetService("ServerStorage")

local SignService = require(ServerStorage.Services.SignService)

return {
	Init = function()
		SignService.Init()
	end,
}