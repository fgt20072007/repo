local DataModules = script.Parent.Parent
local EntitiesFolder = DataModules:FindFirstChild("Entities")

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
	["Test"] = {
		Rarity = "Common",
		MoneyPerSecond = 250,
		Animation = "rbxassetid://",
		DisplayName = "Test",
		Model = resolveModel("Models", "Test"),
	},
}