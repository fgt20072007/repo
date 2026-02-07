local TableUtil = require("./TableUtil")
local marketplace = game:GetService("MarketplaceService")
local Players = game:GetService('Players')

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
			return informations.PriceInRobux, informations.DisplayName
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
	end,
	
	createWeld = function(part1, part2, offset)
		local Weld = Instance.new("Weld")
		part2.Anchored = false
		Weld.C1 = offset or CFrame.new()
		Weld.Part0 = part1
		Weld.Part1 = part2
		Weld.Parent = part1
		return Weld
	end,
	
	attachToTouchEvents = function(part, callback, debounceTime)
		local debounces = {}
		part.Touched:Connect(function(hit)
			local char = hit.Parent
			if char then
				local player = Players:GetPlayerFromCharacter(char)
				if not player then return end
				
				local debounce = debounces[player]
				
				
				if debounce then
					return
				end
				
				task.delay(debounceTime or 0.1, function()
					debounces[player] = false
				end)
				
				debounce = true
				callback(player, char)
			end
		end)
		
		
	end,
}