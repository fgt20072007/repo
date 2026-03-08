--!strict

local Garage = {}

function Garage.OnTriggered(_player: Player, _prompt: ProximityPrompt)
	print(_player, _prompt)
end

return table.freeze(Garage)