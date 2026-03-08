--!strict

local MarketplaceService = game:GetService("MarketplaceService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")

local appServer = ServerScriptService:WaitForChild("App"):WaitForChild("Server")
local servicesFolder = appServer:WaitForChild("Services")
local GarageService = require(servicesFolder:WaitForChild("Functions"):WaitForChild("GarageService"))

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

function GaragePrompt.OnTriggered(player: Player, prompt: ProximityPrompt)
	if player == nil or prompt == nil then
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
		GarageService.SetPending(player, garageModel)
		MarketplaceService:PromptProductPurchase(player, GARAGE_PRODUCT_ID)
	elseif parentName == "Money" then
		GarageService.Activate(player, garageModel, false)
	end
end

return table.freeze(GaragePrompt)