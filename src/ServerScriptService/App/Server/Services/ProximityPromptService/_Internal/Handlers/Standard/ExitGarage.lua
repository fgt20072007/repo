--!strict

local Garage = {}

local function getGarageService(context: any)
	if type(context) ~= "table" then
		return nil
	end

	return context.GarageService
end

function Garage.OnTriggered(player: Player, prompt: ProximityPrompt, context: any)
	local _ = prompt

	local garageService = getGarageService(context)
	if garageService == nil then
		return
	end

	garageService:ExitGarageForPlayer(player)
end

return table.freeze(Garage)