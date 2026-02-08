local ReplicatedStorage = game:GetService('ReplicatedStorage')
local RunService = game:GetService('RunService')
local DataService = require(ReplicatedStorage.Utilities.DataService)
local Format = require(ReplicatedStorage.Utilities.Format)

local Players = game:GetService('Players')

local Entities = require("./EntityCatalog")
local Rarities = require("./Rarities")
local Mutations = require("./Mutations")
local EconomyCalculations = require("./EconomyCalculations")
local LuckyBoxes = require(ReplicatedStorage.DataModules.LuckyBoxes)

local WeightedRNG = require(ReplicatedStorage.Utilities.WeightedRNG)
local RemoteBank = require(ReplicatedStorage.RemoteBank)
local GlobalConfiguration = require(ReplicatedStorage.DataModules.GlobalConfiguration)

local SharedFunctions = {}

local function getColorFromGradient(gradient: UIGradient?): Color3?
	if not gradient then
		return nil
	end

	local keypoints = gradient.Color.Keypoints
	if #keypoints == 0 then
		return nil
	end

	-- Use the center keypoint as a representative label color.
	return keypoints[math.ceil(#keypoints / 2)].Value
end

local function replaceLabelGradient(label: TextLabel, gradient: UIGradient?)
	for _, child in ipairs(label:GetChildren()) do
		if child:IsA("UIGradient") then
			child:Destroy()
		end
	end

	if gradient then
		local clonedGradient = gradient:Clone()
		clonedGradient.Parent = label
	end
end

local function isValidAnimationId(animationId)
	return typeof(animationId) == "string" and string.match(animationId, "^rbxassetid://%d+$") ~= nil
end

local function resolveEntityVariantModel(entityInfo, preferredMutation)
	if not entityInfo or not entityInfo.Model then
		return nil
	end

	local modelContainer = entityInfo.Model
	local candidates = {}

	if preferredMutation then
		table.insert(candidates, preferredMutation)
	end
	if preferredMutation ~= "Normal" then
		table.insert(candidates, "Normal")
	end
	table.insert(candidates, "Gold")
	table.insert(candidates, "Diamond")

	-- Brainrots can store the model directly instead of using mutation variants.
	-- If this model also contains variant models, prefer variant logic below.
	if modelContainer:IsA("Model") then
		local containsVariants = false
		for _, mutationName in candidates do
			local possibleVariant = modelContainer:FindFirstChild(mutationName)
			if possibleVariant and possibleVariant:IsA("Model") then
				containsVariants = true
				break
			end
		end

		if not containsVariants then
			return modelContainer, preferredMutation or "Normal"
		end
	end

	for _, mutationName in candidates do
		local variantModel = modelContainer:FindFirstChild(mutationName)
		if variantModel and variantModel:IsA("Model") then
			return variantModel, mutationName
		end
	end

	for _, child in modelContainer:GetChildren() do
		if child:IsA("Model") then
			return child, child.Name
		end
	end

	return nil
end

function SharedFunctions.FindRoot(Model)
	return Model.PrimaryPart or Model:FindFirstChild("HumanoidRootPart")
end

function SharedFunctions.GetEntityBillboardPart(model: Model)
	if not model then
		return nil
	end

	local head = model:FindFirstChild("Head")
	if head and head:IsA("BasePart") then
		return head
	end

	return SharedFunctions.FindRoot(model)
end

function SharedFunctions.GetEntitiesOfRarity(RarityName: string)
	local t = {}
	for entityName, entityData in Entities do
		if entityData.Rarity == RarityName then
			table.insert(t, entityName)
		end
	end
	return t
end


function SharedFunctions.GetRebirthMultiplier(Player: Player)
	local rebirths = DataService.server:get(Player, "rebirth")
	return rebirths and rebirths * GlobalConfiguration.RebirthIncrements + 1 or 1
end

function SharedFunctions.GetRebirthGoal(Player)
	local rebirths = DataService.server:get(Player, "rebirth")
	return rebirths and (rebirths + 1) * GlobalConfiguration.SpeedBetweenRebirths or GlobalConfiguration.SpeedBetweenRebirths
end

function SharedFunctions.GetUpgradeCost(EntityName, UpgradeLevel)
	return EconomyCalculations.calculateUpgradePrice(Entities[EntityName].MoneyPerSecond, UpgradeLevel)
end

function SharedFunctions.GetEarningsPerSecond(EntityName: string, Mutation: string, UpgradeLevel: number, Player: Player, traits)
	local moneyPerSecond = EconomyCalculations.calculateEarnings(Entities[EntityName].MoneyPerSecond * (Mutations[Mutation] and Mutations[Mutation].Multiplier or 1), UpgradeLevel or 0) 

	if Player then
		local indexMulti = SharedFunctions.GetIndexMultipliers(Player)
		local rebirthMultiplier = SharedFunctions.GetRebirthMultiplier(Player) - 1
		moneyPerSecond *= rebirthMultiplier + indexMulti + 1

		local gamepassMultiplier = Player:GetAttribute("MoneyPerSecondMultiplier")
		if typeof(gamepassMultiplier) == "number" and gamepassMultiplier > 0 then
			moneyPerSecond *= gamepassMultiplier
		end
	end
	return moneyPerSecond
end

function SharedFunctions.GetEntityValue(EntityName: string, Mutation: string, UpgradeLevel: number)
	return SharedFunctions.GetEarningsPerSecond(EntityName, Mutation, UpgradeLevel) * 2
end

function SharedFunctions.GetValueFromId(id: string, Player: Player)
	local inventoryInfo = if RunService:IsClient() then DataService.client:get({"inventory", id}) else DataService.server:get(Player, {"inventory", id})
	if inventoryInfo then
		inventoryInfo = inventoryInfo.informations
		return SharedFunctions.GetEntityValue(inventoryInfo.name, inventoryInfo.mutation, inventoryInfo.upgradeLevel), inventoryInfo.name, inventoryInfo.mutation
	end
end


function SharedFunctions.CreateHiddenEntity(entityName, spawnCFrame, aliveTime, player)
	local entityInformations = Entities[entityName]
	if entityInformations and entityInformations.Model then
		local variantModel = select(1, resolveEntityVariantModel(entityInformations, "Normal"))
		if not variantModel then
			return nil
		end
		local Clone = variantModel:Clone()

		local animationToPlay = Entities[entityName].Animation
		if isValidAnimationId(animationToPlay) then
			local animationInstance = Instance.new("Animation")
			animationInstance.AnimationId = animationToPlay
			local humanoid = Clone:FindFirstChildWhichIsA("Humanoid") or Clone:FindFirstChildOfClass("AnimationController")
			if humanoid then
				local animator = humanoid:FindFirstChildOfClass("Animator")
				if animator then
					animator:LoadAnimation(animationInstance):Play()
				end
			end

			task.delay(aliveTime, function()
				animationInstance:Destroy()
			end)
		end

		if spawnCFrame then
			Clone:PivotTo(spawnCFrame * CFrame.new(0, Clone:GetExtentsSize().Y / 2, 0))
		end

		local newhighlight = script.HideHighlight:Clone()
		newhighlight.Parent = Clone

		Clone.Parent = workspace

		for _, v in pairs(Clone:GetChildren()) do
			if v:IsA("BasePart") then
				v.Anchored = true
			end
		end

		RemoteBank.ScaleTween:FireClient(player, Clone, Clone:GetScale() / 2, Clone:GetScale(), false, aliveTime + 0.05)

		task.delay(aliveTime or 0.1, function()
			Clone:Destroy()
		end)

		return Clone
	end
end

function SharedFunctions.GetEntityVariantModel(entityName, mutation)
	local entityInfo = Entities[entityName]
	local variantModel, resolvedMutation = resolveEntityVariantModel(entityInfo, mutation)
	return variantModel, resolvedMutation
end

function SharedFunctions.CreateBillboard(EntityName: string, Mutation: string, UpgradeLevel: number, Player, dontShowCash, Traits)
	local EntityInformations = if typeof(EntityName) == "string" then Entities[EntityName] else EntityName
	local newBillboard = script.EntityBillboardTemplate:Clone()
	local RarityLabel, MutationLabel, CashLabel, NameLabel = newBillboard.RarityLabel, newBillboard.MutationLabel, newBillboard.CashLabel, newBillboard.NameLabel
	local isLuckyBox = if typeof(EntityName) == "string" then LuckyBoxes.IsLuckyBox(EntityName) else false
	local rarityName = if typeof(EntityInformations.Rarity) == "string" then EntityInformations.Rarity else "Common"
	local mutationName = if typeof(Mutation) == "string" and Mutations[Mutation] then Mutation else "Normal"
	if mutationName == rarityName then
		mutationName = "Normal"
	end

	NameLabel.Text = EntityInformations.DisplayName
	NameLabel.Visible = not isLuckyBox
	RarityLabel.Text = rarityName

	MutationLabel.Visible = true
	MutationLabel.Text = mutationName
	local mutationInfo = Mutations[mutationName]
	replaceLabelGradient(MutationLabel, if mutationInfo then mutationInfo.Gradient else nil)

	local mutationColor = getColorFromGradient(if mutationInfo then mutationInfo.Gradient else nil)
	if mutationColor then
		MutationLabel.TextColor3 = mutationColor
	end

	local raritiesInfo = Rarities[rarityName]
	if raritiesInfo then
		replaceLabelGradient(RarityLabel, raritiesInfo.Gradient)

		local rarityColor = getColorFromGradient(raritiesInfo.Gradient)
		if rarityColor then
			RarityLabel.TextColor3 = rarityColor
		end
	end

	CashLabel.Visible = false
	CashLabel.Text = ""
	if not dontShowCash then
		CashLabel.Text = "$" .. Format.abbreviateCash(SharedFunctions.GetEarningsPerSecond(EntityName, Mutation, UpgradeLevel, Player, Traits)) .. "/s"
		CashLabel.Visible = true
	end

	return newBillboard
end

function SharedFunctions.GetRandomMutation()
	local t = {}
	for i, v in Mutations do
		if v.Percentage then
			t[i] = v.Percentage
		end
	end

	local random = WeightedRNG.get(t, _G.GlobalLuck or 1)
	if random then
		return random
	end
end


function SharedFunctions.GetRandomEntity(percentages)
	local random = WeightedRNG.get(percentages, _G.GlobalLuck or 1)
	if random then
		local Entities = SharedFunctions.GetEntitiesOfRarity(random)
		if #Entities == 0 then
			return nil
		end
		return Entities[math.random(1, #Entities)]
	end
end

function SharedFunctions.CreateEntity(entityName, mutation, createBillboard, UpgradeLevel: number, Traits)
	if not entityName then return end
	local variantModel, resolvedMutation = SharedFunctions.GetEntityVariantModel(entityName, mutation)
	if not variantModel then
		return nil
	end

	local model: Model = variantModel:Clone()
	local humanoid = model:FindFirstChildOfClass("Humanoid")
	if humanoid then
		humanoid.EvaluateStateMachine = false
		humanoid.AutoRotate = false
		humanoid.DisplayDistanceType = Enum.HumanoidDisplayDistanceType.None
	end
	local root = SharedFunctions.FindRoot(model)
	if not root then
		return nil
	end

	local mutationForEffects = mutation or resolvedMutation
	if mutationForEffects then
		local informations = Mutations[mutationForEffects]
		if informations then
			local EffectContainer = informations.Effect
			if EffectContainer then
				for _, v in EffectContainer:GetChildren() do
					local clone = v:Clone()
					clone.Parent = root
				end
			end
		end
	end

	if createBillboard then
		local billboard = SharedFunctions.CreateBillboard(entityName, mutation, UpgradeLevel, nil, nil, Traits)
		local billboardParent = SharedFunctions.GetEntityBillboardPart(model) or root
		billboard.Parent = billboardParent
	end

	return model
end

function SharedFunctions.GetIndexMultipliers(player)
	local totalMulti = 0
	for mutation, informations in Mutations do
		local List = DataService.server:get(player, {"index", mutation})
		if List and #List >= GlobalConfiguration.EntitiesForMulti then
			totalMulti += GlobalConfiguration.IndexMultiplier
		end
	end
	return totalMulti
end

return SharedFunctions
