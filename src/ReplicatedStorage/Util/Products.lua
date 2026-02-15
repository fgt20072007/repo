--!strict
local MarketplaceService = game:GetService 'MarketplaceService'

export type ProductInfo = {[string]: any}

local CachedData: {[Enum.InfoType]: {[number]: ProductInfo}} = {}

local function GetProductInfo(id: number, infoType: Enum.InfoType): ProductInfo?
	if not (id and infoType) then return nil end

	local category = CachedData[infoType]
	if category and category[id] then return category[id] end

	local succ, res = pcall(function()
		return MarketplaceService:GetProductInfoAsync(id, infoType)
	end)
	
	if succ	then
		if CachedData[infoType] then
			CachedData[infoType][id] = res
		else
			CachedData[infoType] = {[id] = res}
		end
	end
	
	return succ and res or nil
end

return table.freeze { GetProductInfo = GetProductInfo }