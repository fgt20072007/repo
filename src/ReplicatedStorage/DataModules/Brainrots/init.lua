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

local function resolveModel(modelName: string)
	if ModelsFolder:WaitForChild(modelName) then
		return ModelsFolder:WaitForChild(modelName)
	end

	return nil
end

return {
	["Trulimero Trulicina"] = {
		Rarity = "Common",
		MoneyPerSecond = 20,
		Animation = "rbxassetid://73603575720334",
		DisplayName = "Trulimero Trulicina",
		Model = resolveModel("Trulimero Trulicina"),
	},

	["FluriFlura"] = {
		Rarity = "Common",
		MoneyPerSecond = 30,
		Animation = "rbxassetid://137210644909122",
		DisplayName = "FluriFlura",
		Model = resolveModel("FluriFlura"),
	},

	["Brr Brr Patapim"] = {
		Rarity = "Rare",
		MoneyPerSecond = 70,
		Animation = "rbxassetid://130955114090339",
		DisplayName = "Brr Brr Patapim",
		Model = resolveModel("BrrBrrPatapim"),
	},
}