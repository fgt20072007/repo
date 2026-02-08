local ReplicatedStorage = game:GetService("ReplicatedStorage")

local WeightedRNG = require(ReplicatedStorage.Utilities.WeightedRNG)
local Entities = require(ReplicatedStorage.DataModules.Entities)
local Brainrots = require(ReplicatedStorage.DataModules.Brainrots)
local EntityCatalog = require(ReplicatedStorage.DataModules.EntityCatalog)

local LuckyBoxes = {
	UseConfiguredBaseSpawns = true,
	Boxes = {
		["Default"] = {
			SpawnWeight = 100,
			Brainrots = {
				["Trulimero Trulicina"] = 100
			},
		},
	}
}

local function sanitizeWeights(rawWeights: {[string]: number})
	local sanitized = {}
	for name, weight in rawWeights do
		if typeof(name) == "string" and typeof(weight) == "number" and weight > 0 then
			sanitized[name] = weight
		end
	end
	return sanitized
end

local function getWeightedResult(weights: {[string]: number})
	local sanitizedWeights = sanitizeWeights(weights)
	if not next(sanitizedWeights) then
		return nil
	end
	return WeightedRNG.get(sanitizedWeights, _G.GlobalLuck or 1)
end

function LuckyBoxes.IsLuckyBox(entityName: string)
	if typeof(entityName) ~= "string" then
		return false
	end

	return LuckyBoxes.Boxes[entityName] ~= nil and Entities[entityName] ~= nil
end

function LuckyBoxes.GetRandomLuckyBoxForBase()
	if not LuckyBoxes.UseConfiguredBaseSpawns then
		return nil
	end

	local weights = {}
	for luckyBoxName, luckyBoxData in LuckyBoxes.Boxes do
		if typeof(luckyBoxData) == "table" and Entities[luckyBoxName] then
			weights[luckyBoxName] = luckyBoxData.SpawnWeight
		end
	end

	return getWeightedResult(weights)
end

function LuckyBoxes.GetRandomBrainrot(luckyBoxName: string)
	if typeof(luckyBoxName) ~= "string" then
		return nil
	end

	local luckyBoxData = LuckyBoxes.Boxes[luckyBoxName]
	if typeof(luckyBoxData) ~= "table" or typeof(luckyBoxData.Brainrots) ~= "table" then
		return nil
	end

	local rewards = {}
	for brainrotName, spawnWeight in luckyBoxData.Brainrots do
		local hasBrainrotDefinition = Brainrots[brainrotName] or EntityCatalog[brainrotName]
		if hasBrainrotDefinition and not LuckyBoxes.IsLuckyBox(brainrotName) then
			rewards[brainrotName] = spawnWeight
		end
	end

	return getWeightedResult(rewards)
end

return LuckyBoxes