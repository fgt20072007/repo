--!strict

--[[
	Handler template for proximity prompt tags.

	Como funciona:
	Simplemente llama el nombre del archivo como el del tag y copia el template
	-> Funcionara siempre que se trigge por cualquier jugador
]]

local Prueba = {}

function Prueba.OnTriggered(_player: Player, _prompt: ProximityPrompt)
	print(_player, _prompt)
end

return table.freeze(Prueba)
