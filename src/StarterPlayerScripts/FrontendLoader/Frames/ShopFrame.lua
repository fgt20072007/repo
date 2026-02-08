-- Services
local ReplicatedStorage = game:GetService('ReplicatedStorage')
local CollectionService = game:GetService('CollectionService')

-- Variables
local ProductTag = "ProductPurchase"
local IsGamepassAttribute = "IsGamepass"
local ProductNameAttribute = "ProductName"

-- Dependencies
local DevProducts = require(ReplicatedStorage.DataModules.DevProducts)
local Gamepasses = require(ReplicatedStorage.DataModules.Gamepasses)
local RemoteBank = require(ReplicatedStorage.RemoteBank)

local SharedUtilities = require(ReplicatedStorage.Utilities.SharedUtilities)

local ShopFrame = {}

local function recursiveSearchByKey(t, lookingFor)
	for i, value in t do
		if tostring(i) == tostring(lookingFor) then
			return value
		end
		if typeof(value) == "table" then
			local nestedValue = recursiveSearchByKey(value, lookingFor)
			if nestedValue ~= nil then
				return nestedValue
			end
		end
	end
	return nil
end

local function resolveProductInfo(moduleTable, productKey)
	local info = recursiveSearchByKey(moduleTable, productKey)
	if info ~= nil then
		return info
	end

	local numericKey = tonumber(productKey)
	if numericKey then
		return recursiveSearchByKey(moduleTable, numericKey)
	end

	return nil
end

-- Initialization function for the script
function ShopFrame:Initialize()
	for _, v in CollectionService:GetTagged(ProductTag) do
		local productKey = v:GetAttribute(ProductNameAttribute)
		if productKey == nil then
			continue
		end

		local isGamepass = v:GetAttribute(IsGamepassAttribute) == true

		local moduleTable = if isGamepass then Gamepasses else DevProducts
		local productInfo = resolveProductInfo(moduleTable, productKey)
		if productInfo == nil then
			continue
		end

		local id = if typeof(productInfo) == "number" then productInfo else productInfo.Id
		id = tonumber(id)
		if not id then
			continue
		end

		local textLabel = v:FindFirstChild("PriceLabel")
		if textLabel and textLabel:IsA("TextLabel") then
			local price = SharedUtilities.getProductPrice(id, isGamepass and Enum.InfoType.GamePass or Enum.InfoType.Product)
			if typeof(price) == "number" then
				textLabel.Text = tostring(price) .. ""
			else
				textLabel.Text = tostring(price)
			end
		end

		if v:IsA("GuiButton") then
			v.Activated:Connect(function()
				RemoteBank.Purchase:InvokeServer(isGamepass, id)
			end)
		end
	end
end

return ShopFrame