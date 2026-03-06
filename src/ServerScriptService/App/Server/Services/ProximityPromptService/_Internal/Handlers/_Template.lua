--!strict

--[[
	Handler template for proximity prompt tags.

	Copy this file, rename it to match a tag from TagRegistry, and implement OnTriggered.
	The file name MUST match the tag key exactly (e.g. "ShopPrompt (ModuleScript)" for tag "ShopPrompt").
]]

local _Template = {}

function _Template.OnTriggered(_player: Player, _prompt: ProximityPrompt)
	-- Code Here
end

return table.freeze(_Template)
