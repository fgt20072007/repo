local ReplicatedStorage = game:GetService("ReplicatedStorage")

local WeightedRNG = require(ReplicatedStorage.Utilities.WeightedRNG)
local Entities = require(ReplicatedStorage.DataModules.Entities)
local Brainrots = require(ReplicatedStorage.DataModules.Brainrots)
local EntityCatalog = require(ReplicatedStorage.DataModules.EntityCatalog)

local LuckyBoxes = {
	Boxes = {
		["Common"] = {
			Brainrots = {
				["Trulimero Trulicina"] = 50,
				["FluriFlura"] = 50,
			},
		},
		["Rare"] = {
			Brainrots = {
				["Brr Brr Patapim"] = 100,
			},
		},
		["Epic"] = {
			Brainrots = {
				["FluriFlura"] = 100,
			},
		},
		["Mythical"] = {
			Brainrots = {
				["Trulimero Trulicina"] = 80,
				["FluriFlura"] = 20,
			},
		},

		["Legendary"] = {
			Brainrots = {
				["Trulimero Trulicina"] = 80,
				["FluriFlura"] = 20,
			},
		},

		["Secret"] = {
			Brainrots = {
				["Trulimero Trulicina"] = 80,
				["FluriFlura"] = 20,
			},
		},

		["SixSeven"] = {
			Brainrots = {
				["Trulimero Trulicina"] = 80,
				["FluriFlura"] = 20,
			},
		},

		["Strawberry"] = {
			Brainrots = {
				["Trulimero Trulicina"] = 80,
				["FluriFlura"] = 20,
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

local function getBaseLuckyBoxWeights(baseLuckyBoxes)
	if baseLuckyBoxes == false then
		return {}
	end

	if typeof(baseLuckyBoxes) ~= "table" then
		return nil
	end

	local weights = {}
	for key, value in baseLuckyBoxes do
		local luckyBoxName
		local weight

		if typeof(key) == "number" then
			luckyBoxName = value
			weight = 1
		else
			luckyBoxName = key
			weight = value
		end

		if typeof(luckyBoxName) == "string" and LuckyBoxes.IsLuckyBox(luckyBoxName) then
			if typeof(weight) == "number" then
				if weight > 0 then
					weights[luckyBoxName] = weight
				end
			else
				weights[luckyBoxName] = 1
			end
		end
	end

	return weights
end

function LuckyBoxes.IsLuckyBox(entityName: string)
	if typeof(entityName) ~= "string" then
		return false
	end

	return LuckyBoxes.Boxes[entityName] ~= nil and Entities[entityName] ~= nil
end

function LuckyBoxes.GetRandomLuckyBoxForBase(baseLuckyBoxes)
	local configuredBaseWeights = getBaseLuckyBoxWeights(baseLuckyBoxes)
	if not configuredBaseWeights or not next(configuredBaseWeights) then
		return nil
	end

	return getWeightedResult(configuredBaseWeights)
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
	for brainrotName, weight in luckyBoxData.Brainrots do
		local hasBrainrotDefinition = Brainrots[brainrotName] or EntityCatalog[brainrotName]
		if hasBrainrotDefinition and not LuckyBoxes.IsLuckyBox(brainrotName) then
			rewards[brainrotName] = weight
		end
	end

	return getWeightedResult(rewards)
end

return LuckyBoxes
