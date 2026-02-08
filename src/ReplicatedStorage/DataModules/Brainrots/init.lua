local DataModules = script.Parent.Parent
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local DataModules = ReplicatedStorage:WaitForChild("DataModules")
local Brainrots = DataModules:WaitForChild("Brainrots")
local ModelsFolder = Brainrots:WaitForChild("Models")

--[[


Common
Mythical
Secret
Godly


]]

local function resolveModel(modelName: string, fallbackName: string?)
	local model = script:FindFirstChild(modelName)
	if model then
		return model
	end

	if fallbackName then
		model = script:FindFirstChild(fallbackName)
		if model then
			return model
		end
	end

	if EntitiesFolder then
		model = EntitiesFolder:FindFirstChild(modelName)
		if model then
			return model
		end

		if fallbackName then
			return EntitiesFolder:FindFirstChild(fallbackName)
		end
	end

	return nil
end

return {
	["Trulimero Trulicina"] = {
		Rarity = "Common",
		MoneyPerSecond = 250,
		Animation = "rbxassetid://73603575720334",
		DisplayName = "Trulimero Trulicina",
		Model = resolveModel("Models", "Trulimero Trulicina"),
	},

	["FluriFlura"] = {
		Rarity = "Common",
		MoneyPerSecond = 250,
		Animation = "rbxassetid://137210644909122",
		DisplayName = "FluriFlura",
		Model = resolveModel("Models", "FluriFlura"),
	},
}