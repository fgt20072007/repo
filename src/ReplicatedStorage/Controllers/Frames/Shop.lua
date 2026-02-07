local Players = game:GetService('Players')
local ReplicatedStorage = game:GetService('ReplicatedStorage')
local marketplace = game:GetService("MarketplaceService")

local Player = Players.LocalPlayer
local MainGui = Player.PlayerGui:WaitForChild("MainGui")

local ShopFrame = MainGui:FindFirstChild("Frames").Shop

local ToolsData = require(ReplicatedStorage.DataModules.ToolsData)
local ProductIds = require(ReplicatedStorage.DataModules.ProductIds)

local GlobalConfiguration = require(ReplicatedStorage.DataModules.GlobalConfiguration)
local SharedUtilities = require(ReplicatedStorage.Utilities.SharedUtilities)

local purchaseFunction = ReplicatedStorage.Communication.Functions.PromptPurchase

local Shop = {}

function Shop.Initialize()
	for _, v: GuiButton in pairs(ShopFrame:GetDescendants()) do
		if v:IsA("GuiButton") then
			local TextLabel = v:FindFirstChild("PriceLabel", true)
			local buttonPurchaseId, isProduct = nil, false
			if v:HasTag(GlobalConfiguration.ProductButtonTag) then
				isProduct = true
				buttonPurchaseId = ProductIds[v:GetAttribute(GlobalConfiguration.ProductButtonAttribute)]
			elseif v:HasTag(GlobalConfiguration.ToolButtonTag) then
				buttonPurchaseId = ToolsData[v:GetAttribute(GlobalConfiguration.ToolButtonAttribute)].GamepassId
			end
			
			local function updateTextLabel()
				task.spawn(function()
					TextLabel.Text = SharedUtilities.getProductPrice(buttonPurchaseId, isProduct and Enum.InfoType.Product or Enum.InfoType.GamePass, Player) .. " "
				end)
			end
			
			if TextLabel then
				updateTextLabel()
			end

			v.Activated:Connect(function()
				purchaseFunction:InvokeServer(not isProduct, buttonPurchaseId)
			end)
			
			if not isProduct then
				marketplace.PromptGamePassPurchaseFinished:Connect(function(player, gamepassId, wasPurchased)
					if wasPurchased and Player == player and gamepassId == buttonPurchaseId then
						if TextLabel then
							updateTextLabel()
						end
					end
				end)
			end
		end
	end
end

return Shop