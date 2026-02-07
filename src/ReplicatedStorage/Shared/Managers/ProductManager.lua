local ReplicatedStorage = game:GetService("ReplicatedStorage")
local MarketplaceService = game:GetService("MarketplaceService")

local Shared = ReplicatedStorage:WaitForChild("Shared")

local ProductsData = require(Shared.Data.Products)

local cache = {}

local ProductManager = {}

function ProductManager.GetProductInfoAsync(ProductName: string)
	assert(typeof(ProductName) == "string")

	if cache[ProductName] then
		return cache[ProductName]
	end

	local productData = ProductManager.GetProductData(ProductName)

	if productData then
		local productInfo

		local success, err = pcall(function()
			productInfo = MarketplaceService:GetProductInfoAsync(
				productData.Id,
				if productData.Type == "Gamepass" then Enum.InfoType.GamePass else Enum.InfoType.Product
			)
		end)

		if success then
			cache[ProductName] = productInfo
			return cache[ProductName]
		else
			warn(err)
		end
	else
		warn(`[ERROR]: Could not find data for {ProductName}`)
	end
end

function ProductManager.GetProductData(ProductName: string): ProductsData.Product
	return ProductsData[ProductName]
end

return ProductManager
