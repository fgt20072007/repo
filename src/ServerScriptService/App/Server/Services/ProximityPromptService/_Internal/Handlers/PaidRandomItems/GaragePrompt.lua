--!strict

local MarketplaceService = game:GetService("MarketplaceService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local sharedData = ReplicatedStorage:WaitForChild("App"):WaitForChild("Shared"):WaitForChild("Data")
local Gen = require(sharedData:WaitForChild("General"):WaitForChild("Gen"))
local Products = require(sharedData:WaitForChild("Market"):WaitForChild("Products"))

local garageCost = Gen.Container.Cost
local garageProductId = Products.Container
local robuxIcon = utf8.char(0xE002)

local function findGarageModel(prompt: ProximityPrompt): Model?
	local current: Instance? = prompt.Parent
	while current ~= nil do
		if current:IsA("Model") and current.Name == "Garage" then
			return current :: Model
		end
		current = (current :: Instance).Parent
	end
	return nil
end

local function resolvePaymentType(prompt: ProximityPrompt): string?
	local current: Instance? = prompt.Parent
	return current.Name
end

local GaragePrompt = {}
local moneyActionText = nil :: string?
local robuxActionText = nil :: string?
local robuxActionTextResolved = false

local function formatIntegerWithCommas(value: number): string
	local roundedValue = math.round(value)
	local digits = tostring(math.abs(roundedValue))
	local digitCount = string.len(digits)

	if digitCount <= 3 then
		if roundedValue < 0 then
			return "-" .. digits
		end

		return digits
	end

	local segments = table.create(math.ceil(digitCount / 3))
	local firstSegmentLength = ((digitCount - 1) % 3) + 1

	table.insert(segments, string.sub(digits, 1, firstSegmentLength))

	local index = firstSegmentLength + 1
	while index <= digitCount do
		table.insert(segments, string.sub(digits, index, index + 2))
		index += 3
	end

	local formattedValue = table.concat(segments, ",")
	if roundedValue < 0 then
		return "-" .. formattedValue
	end

	return formattedValue
end

local function getMoneyActionText(): string
	if moneyActionText == nil then
		moneyActionText = `Buy for ${formatIntegerWithCommas(garageCost)}`
	end

	return moneyActionText
end

local function getRobuxActionText(): string?
	if robuxActionTextResolved == true then
		return robuxActionText
	end

	robuxActionTextResolved = true

	local ok, productInfo =
		pcall(MarketplaceService.GetProductInfo, MarketplaceService, garageProductId, Enum.InfoType.Product)
	if ok ~= true or type(productInfo) ~= "table" then
		return nil
	end

	local isForSale = productInfo.IsForSale
	local priceInRobux = productInfo.PriceInRobux

	if isForSale ~= true or type(priceInRobux) ~= "number" then
		return nil
	end

	robuxActionText = `{robuxIcon} {priceInRobux}`
	return robuxActionText
end

local function getGarageService(context: any)
	if type(context) ~= "table" then
		return nil
	end

	return context.GarageService
end

function GaragePrompt.OnLoad(prompt: ProximityPrompt, _context: any)
	local paymentType = resolvePaymentType(prompt)
	if paymentType == "Money" then
		prompt.ActionText = getMoneyActionText()
		return
	end

	if paymentType == "Robux" then
		prompt.ActionText = getRobuxActionText() or ""
	end
end

function GaragePrompt.OnTriggered(player: Player, prompt: ProximityPrompt, context: any)
	local garageService = getGarageService(context)
	if garageService == nil then
		return
	end

	local garageModel = findGarageModel(prompt)
	if garageModel == nil then
		return
	end

	local paymentType = resolvePaymentType(prompt)
	if paymentType == "Robux" then
		garageService:ClearPending(player)
		if garageService:SetPending(player, garageModel) ~= true then
			return
		end

		local didOpenPurchasePrompt =
			pcall(MarketplaceService.PromptProductPurchase, MarketplaceService, player, garageProductId)
		if didOpenPurchasePrompt ~= true then
			garageService:ClearPending(player)
		end
	elseif paymentType == "Money" then
		garageService:Activate(player, garageModel, false)
	end
end

return table.freeze(GaragePrompt)