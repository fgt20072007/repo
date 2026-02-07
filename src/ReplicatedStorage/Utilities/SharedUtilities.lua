local TableUtil = require("./TableUtil")
local marketplace = game:GetService("MarketplaceService")

return {
	getProductPrice = function(id, inforType, player)
		local success, informations = pcall(function()
			return marketplace:GetProductInfoAsync(id, inforType)
		end)
		if not success then
			return "NULL"
		else
			if inforType == Enum.InfoType.GamePass and player then
				if marketplace:UserOwnsGamePassAsync(player.UserId, id) then
					return "Owned"
				end
			end
			return informations.PriceInRobux
		end
	end,
	
	ownsGamepass = function(player, id)
		return marketplace:UserOwnsGamePassAsync(player.UserId, id)
	end,
	
	getLenghtOfT = function(t: {})
		local lenght = 0
		for _, v in t do
			lenght += 1
		end
		return lenght
	end,
	
	getToolsForBackpackAndEquipped = function(player)
		return TableUtil.Extend(player.Backpack:GetChildren(), (player.Character and player.Character:GetChildren() or {}))
	end
}