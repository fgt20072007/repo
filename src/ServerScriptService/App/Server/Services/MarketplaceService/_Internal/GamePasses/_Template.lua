--!strict

local Handler = {}

function Handler.ApplyOwnership(player: Player, context: any)
	if player == nil or context == nil then
		return
	end
end

return table.freeze(Handler)
