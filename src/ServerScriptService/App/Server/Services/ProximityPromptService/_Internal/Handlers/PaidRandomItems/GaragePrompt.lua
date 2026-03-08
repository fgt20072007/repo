--!strict

local GaragePrompt = {}

function GaragePrompt.OnTriggered(_player: Player, _prompt: ProximityPrompt)
	if _player == nil or _prompt == nil then
		return
	end
	
	warn("aca tambien jala")
end

return table.freeze(GaragePrompt)
