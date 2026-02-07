-- Services
local ReplicatedStorage = game:GetService('ReplicatedStorage')
local Players = game:GetService('Players')
local CollectionService = game:GetService('CollectionService')

-- Variables
local Gui = Players.LocalPlayer.PlayerGui:WaitForChild("MainGui")
local Frames = Gui.Frames
local ShopFrame = Frames.ShopFrame

local ProductTag = "ProductPurchase"
local IsGamepassAttribute = "IsGamepass"
local ProductNameAttribute = "ProductName"

-- Dependencies
local DataService = require(ReplicatedStorage.Utilities.DataService)

local DevProducts = require(ReplicatedStorage.DataModules.DevProducts)
local Gamepasses = require(ReplicatedStorage.DataModules.Gamepasses)
local RemoteBank = require(ReplicatedStorage.RemoteBank)

local SharedUtilities = require(ReplicatedStorage.Utilities.SharedUtilities)

local ShopFrame = {}

-- Initialization function for the script
function ShopFrame:Initialize()
	for _, v in CollectionService:GetTagged(ProductTag) do
		local ProductId = v:GetAttribute(ProductNameAttribute)
		local IsGamepass = v:GetAttribute(IsGamepassAttribute)
		
		local Module = if IsGamepass then Gamepasses else DevProducts
		local function RecursiveSearch(t, lookingFor)
			for i, v in t do
				if tostring(i) == tostring(lookingFor) then
					return v
				elseif typeof(v) == "table" then
					local result = RecursiveSearch(v, lookingFor)
					if result then
						return result
					end
				end
			end
		end
		
		local ProductInfo = RecursiveSearch(Module, ProductId)
		
		if ProductInfo then
			local Id = typeof(ProductInfo) == "number" and ProductInfo or ProductInfo.Id
			if Id then
				local TextLabel = v:FindFirstChild("PriceLabel")
				if TextLabel then
					TextLabel.Text = SharedUtilities.getProductPrice(Id, IsGamepass and Enum.InfoType.GamePass or Enum.InfoType.Product) .. ""
				else
					--warn("Text label could not be found for " .. v.Name .. ", did you forget to name it PriceLabel?")
				end
				if v:IsA("GuiButton") then
					v.Activated:Connect(function()
						RemoteBank.Purchase:InvokeServer(IsGamepass, Id)
					end)
				end
			else
				warn("Product Id not found for: " .. ProductNameAttribute)
			end
		else
			warn("Product informations not found for: " .. ProductNameAttribute)
		end
	end
end

return ShopFrame
