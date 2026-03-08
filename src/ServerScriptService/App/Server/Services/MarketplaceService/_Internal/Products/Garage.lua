--!strict

local Handler = {}

local function getGarageService(context: any)
	if type(context) ~= "table" then
		return nil
	end

	return context.GarageService
end

function Handler.ProcessReceipt(player: Player, _receiptInfo: any, context: any): boolean
	local garageService = getGarageService(context)
	if garageService == nil then
		return false
	end

	local garageModel = garageService:ConsumePending(player)
	if garageModel == nil then
		return false
	end

	return garageService:Activate(player, garageModel, true)
end

function Handler.OnPromptFinished(player: Player, wasPurchased: boolean, context: any)
	if wasPurchased == true then
		return
	end

	local garageService = getGarageService(context)
	if garageService == nil then
		return
	end

	garageService:ClearPending(player)
end

return table.freeze(Handler)