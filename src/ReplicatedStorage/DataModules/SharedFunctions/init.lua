local ReplicatedStorage = game:GetService('ReplicatedStorage')
local RunService = game:GetService('RunService')
local DataService = require(ReplicatedStorage.Utilities.DataService)
local Format = require(ReplicatedStorage.Utilities.Format)

local Players = game:GetService('Players')

local Entities = require("./Entities")
local Rarities = require("./Rarities")
local Mutations = require("./Mutations")
local EconomyCalculations = require("./EconomyCalculations")

local WeightedRNG = require(ReplicatedStorage.Utilities.WeightedRNG)
local RemoteBank = require(ReplicatedStorage.RemoteBank)
local GlobalConfiguration = require(ReplicatedStorage.DataModules.GlobalConfiguration)

local SharedFunctions = {}

function SharedFunctions.FindRoot(Model)
	return Model.PrimaryPart or Model:FindFirstChild("HumanoidRootPart")
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
		print(inventoryInfo)
		return SharedFunctions.GetEntityValue(inventoryInfo.name, inventoryInfo.mutation, inventoryInfo.upgradeLevel), inventoryInfo.name, inventoryInfo.mutation
	end
end


function SharedFunctions.CreateHiddenEntity(entityName, spawnCFrame, aliveTime, player)
	local entityInformations = Entities[entityName]
	if entityInformations and entityInformations.Model then
		local Clone = entityInformations.Model["Normal"]:Clone()
		
		local animationToPlay = Entities[entityName].Animation
		if animationToPlay then
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

function SharedFunctions.CreateBillboard(EntityName: string, Mutation: string, UpgradeLevel: number, Player, dontShowCash, Traits)
	local EntityInformations = if typeof(EntityName) == "string" then Entities[EntityName] else EntityName
	local newBillboard = script.EntityBillboardTemplate:Clone()
	local RarityLabel, CashLabel, NameLabel = newBillboard.RarityLabel, newBillboard.CashLabel, newBillboard.NameLabel
	NameLabel.Text = EntityInformations.DisplayName
	RarityLabel.Text = EntityInformations.Rarity
	
	if Mutation then
		local infos = Mutations[Mutation]
		if infos and infos.ShowLabel then
			newBillboard.MutationLabel.Visible = true
			newBillboard.MutationLabel.Text = Mutation
			local newGradient = infos.Gradient:Clone()
			newGradient.Parent = newBillboard.MutationLabel
		end
	end

	local raritiesInfo = Rarities[EntityInformations.Rarity]
	if raritiesInfo then
		local clonedGradient = raritiesInfo.Gradient:Clone()
		clonedGradient.Parent = RarityLabel
	end
	
	CashLabel.Visible = false
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
	local model: Model = Entities[entityName].Model:FindFirstChild(mutation):Clone()
	local humanoid = model:FindFirstChildOfClass("Humanoid")
	if humanoid then
		humanoid.EvaluateStateMachine = false
		humanoid.AutoRotate = false
		humanoid.DisplayDistanceType = Enum.HumanoidDisplayDistanceType.None
	end
	local root = SharedFunctions.FindRoot(model)
	
	if mutation then
		local informations = Mutations[mutation]
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
		billboard.Parent = root
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
