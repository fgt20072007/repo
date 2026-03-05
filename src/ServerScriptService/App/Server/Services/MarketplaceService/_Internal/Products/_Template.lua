--!strict

local Handler = {}

function Handler.ProcessReceipt(player: Player, receiptInfo: any, context: any): boolean
	if player == nil or receiptInfo == nil or context == nil then
		return false
	end

	return false
end

return table.freeze(Handler)
