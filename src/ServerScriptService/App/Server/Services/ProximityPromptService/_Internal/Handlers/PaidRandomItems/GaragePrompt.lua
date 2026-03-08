--!strict

local MarketplaceService = game:GetService("MarketplaceService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local sharedData = ReplicatedStorage:WaitForChild("App"):WaitForChild("Shared"):WaitForChild("Data")
local Products = require(sharedData:WaitForChild("Market"):WaitForChild("Products"))

local GARAGE_PRODUCT_ID = Products.Garage

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

local GaragePrompt = {}

local function getGarageService(context: any)
	if type(context) ~= "table" then
		return nil
	end

	return context.GarageService
end

function GaragePrompt.OnTriggered(player: Player, prompt: ProximityPrompt, context: any)
	local garageService = getGarageService(context)
	if garageService == nil then
		return
	end

	local parent = prompt.Parent
	if parent == nil then
		return
	end

	local garageModel = findGarageModel(prompt)
	if garageModel == nil then
		return
	end

	local parentName = parent.Name

	if parentName == "Robux" then
		if garageService:HasPending(player) then
			return
		end
		if garageService:SetPending(player, garageModel) ~= true then
			return
		end
		MarketplaceService:PromptProductPurchase(player, GARAGE_PRODUCT_ID)
	elseif parentName == "Money" then
		garageService:Activate(player, garageModel, false)
	end
end

return table.freeze(GaragePrompt)