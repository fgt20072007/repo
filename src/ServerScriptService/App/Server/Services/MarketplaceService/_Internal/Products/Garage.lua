--!strict

local ServerScriptService = game:GetService("ServerScriptService")

local appServer = ServerScriptService:WaitForChild("App"):WaitForChild("Server")
local servicesFolder = appServer:WaitForChild("Services")
local GarageService = require(servicesFolder:WaitForChild("Functions"):WaitForChild("GarageService"))

local Handler = {}

function Handler.ProcessReceipt(player: Player, _receiptInfo: any, _context: any): boolean
	if player == nil then
		return false
	end

	local garageModel = GarageService.ConsumePending(player)
	if garageModel == nil then
		return false
	end

	GarageService.Activate(player, garageModel, true)
	return true
end

return table.freeze(Handler)