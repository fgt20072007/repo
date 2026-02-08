-- Services
local ReplicatedStorage = game:GetService('ReplicatedStorage')
local Players = game:GetService('Players')
local ServerStorage = game:GetService('ServerStorage')
local RunService = game:GetService('RunService')
local ServerScriptService = game:GetService('ServerScriptService')
local CollectionService = game:GetService("CollectionService")

-- DataModules
local SignalBank = require(ServerStorage.SignalBank)
local RemoteBank = require(ReplicatedStorage.RemoteBank)
local GlobalConfiguration = require(ReplicatedStorage.DataModules.GlobalConfiguration)

-- Utilities
local DataService = require(ReplicatedStorage.Utilities.DataService)
local SharedFunctions = require(ReplicatedStorage.DataModules.SharedFunctions)
local Spring = require(ReplicatedStorage.Utilities.Spring)
local Janitor = require(ReplicatedStorage.Utilities.Janitor)
local Format = require(ReplicatedStorage.Utilities.Format)
local SharedUtilities = require(ReplicatedStorage.Utilities.SharedUtilities)
local Signal = require(ReplicatedStorage.Utilities.Signal)
local Entities = require(ReplicatedStorage.DataModules.EntityCatalog)
local LuckyBoxes = require(ReplicatedStorage.DataModules.LuckyBoxes)
local DevProducts = require(ReplicatedStorage.DataModules.DevProducts)
local MarketplaceHandler = require(ServerScriptService.Components.MarketplaceHandler)
local Mutations = require(ReplicatedStorage.DataModules.Mutations)

-- Dependencies
local InventoryHandler = require("./InventoryHandler")
local PlotHandler = require("./PlotHandler")

local FLOOR_SPAWN_NAME = "FloorSpawn"
local EXTRA = "Floor"

local StandController = {}
StandController.__index = StandController

export type Stand = typeof(setmetatable({} :: {
	model: Model,
	janitor: Janitor.Janitor,
	standNumber: number,	
	ownership: Player,
	entityModel: Model,
	cashBillboard: BillboardGui,
	cashSpring: Spring.Spring,
	entityBillboard: BillboardGui,
	signal: Signal.Signal,
	luckyblockModel: Model,
	rolling: boolean
}, StandController))

local StandsCache = {} :: {[Player]: {Stand}}

local StandStateEnum = {
	Empty = "Empty",
	Occupied = "Occupied",
	Luckyblock = "Luckyblock"
}

local LUCKYBLOCK_HATCH_BOUNCES = 3
local LUCKYBLOCK_HATCH_BOUNCE_TIME = 0.13
local LUCKYBLOCK_HATCH_BOUNCE_OVERLAP = 0.7
local LUCKYBLOCK_HATCH_BOUNCE_START_SCALE = 1.06
local LUCKYBLOCK_HATCH_BOUNCE_SCALE_STEP = 0.045
local LUCKYBLOCK_HATCH_BOUNCE_START_HEIGHT = 0.75
local LUCKYBLOCK_HATCH_BOUNCE_HEIGHT_STEP = 0.28
local LUCKYBLOCK_HATCH_TENSION_SCALE = 0.88
local LUCKYBLOCK_HATCH_TENSION_TIME = 0.1
local LUCKYBLOCK_HATCH_FINAL_POP_MULTIPLIER = 1.42
local LUCKYBLOCK_HATCH_FINAL_POP_TIME = 0.2
local LUCKYBLOCK_HATCH_FINAL_JUMP_HEIGHT = 2.6
local APPEAR_LUCKYBLOCK_VFX_NAME = "AppearLuckyBlock"
local APPEAR_LUCKYBLOCK_VFX_CLEANUP_TIME = 4
local APPEAR_LUCKYBLOCK_HATCH_BURSTS = 1
local APPEAR_LUCKYBLOCK_REVEAL_BURSTS = 3
local APPEAR_LUCKYBLOCK_BURST_DELAY = 0.07

local function getStandBillboardConnectionIndex(standNumber: number): string
	return "StandBillboardConnection_" .. tostring(standNumber)
end

local function getStandMoneyLoopIndex(standNumber: number): string
	return "StandMoneyLoop_" .. tostring(standNumber)
end

local function getStandSignalCleanupIndex(standNumber: number): string
	return "StandSignalCleanup_" .. tostring(standNumber)
end

local function isValidAnimationId(animationId)
	return typeof(animationId) == "string" and string.match(animationId, "^rbxassetid://%d+$") ~= nil
end

local function parseDegreesValue(value): number?
	if typeof(value) == "number" then
		return value
	end

	if typeof(value) == "string" then
		return tonumber(value)
	end

	return nil
end

local function getPreviewRotationDegrees(model: Model): number?
	local directValue = parseDegreesValue(model:GetAttribute("Prev"))
	if directValue then
		return directValue
	end

	local root = SharedFunctions.FindRoot(model)
	if root then
		local rootValue = parseDegreesValue(root:GetAttribute("Prev"))
		if rootValue then
			return rootValue
		end
	end

	local prevValueObject = model:FindFirstChild("Prev", true)
	if prevValueObject then
		if prevValueObject:IsA("NumberValue") or prevValueObject:IsA("IntValue") then
			return prevValueObject.Value
		end
		if prevValueObject:IsA("StringValue") then
			local objectValue = tonumber(prevValueObject.Value)
			if objectValue then
				return objectValue
			end
		end
	end

	for _, tagName in ipairs(CollectionService:GetTags(model)) do
		local tagValue = tagName:match("^Prev[:_%s]?([%-]?%d+%.?%d*)$")
		if tagValue then
			local parsed = tonumber(tagValue)
			if parsed then
				return parsed
			end
		end
	end

	if root then
		for _, tagName in ipairs(CollectionService:GetTags(root)) do
			local tagValue = tagName:match("^Prev[:_%s]?([%-]?%d+%.?%d*)$")
			if tagValue then
				local parsed = tonumber(tagValue)
				if parsed then
					return parsed
				end
			end
		end
	end

	return nil
end

local function EmitVFX(VFX)
	for _, v in VFX:GetDescendants() do
		if v:IsA("ParticleEmitter") then
			v:Emit(v:GetAttribute("EmitCount") or 12)
		end
	end
end

local function getAppearLuckyblockTemplate(): Instance?
	local vfxFolder = ReplicatedStorage.Assets:FindFirstChild("VFX")
	if not vfxFolder then
		return nil
	end

	return vfxFolder:FindFirstChild(APPEAR_LUCKYBLOCK_VFX_NAME)
		or vfxFolder:FindFirstChild("Upgrade")
		or vfxFolder:FindFirstChild("CashClaimed")
end

local function playAppearLuckyblockVFX(model: Model, bursts: number?)
	local effectTemplate = getAppearLuckyblockTemplate()
	if not effectTemplate then
		return
	end

	local totalBursts = math.max(1, math.floor(bursts or 1))
	for i = 0, totalBursts - 1 do
		task.delay(i * APPEAR_LUCKYBLOCK_BURST_DELAY, function()
			if not model.Parent then
				return
			end

			local root = SharedFunctions.FindRoot(model)
			if not root then
				return
			end

			local effectClone = effectTemplate:Clone()
			effectClone.Parent = root
			EmitVFX(effectClone)

			task.delay(APPEAR_LUCKYBLOCK_VFX_CLEANUP_TIME, function()
				if effectClone and effectClone.Parent then
					effectClone:Destroy()
				end
			end)
		end)
	end
end

local function playLuckyblockHatching(self: Stand)
	local luckyblockModel = self.entityModel
	if not luckyblockModel or not luckyblockModel.Parent then
		return
	end

	local baseScale = luckyblockModel:GetScale()
	if baseScale <= 0 then
		return
	end

	-- Simulator-style hatch: chained bounces, tension, reveal pop.
	for step = 1, LUCKYBLOCK_HATCH_BOUNCES do
		if self.entityModel ~= luckyblockModel or not luckyblockModel.Parent then
			return
		end

		local pulseTime = math.max(0.08, LUCKYBLOCK_HATCH_BOUNCE_TIME - ((step - 1) * 0.008))
		local pulseScale = baseScale * (LUCKYBLOCK_HATCH_BOUNCE_START_SCALE + ((step - 1) * LUCKYBLOCK_HATCH_BOUNCE_SCALE_STEP))
		local jumpHeight = LUCKYBLOCK_HATCH_BOUNCE_START_HEIGHT + ((step - 1) * LUCKYBLOCK_HATCH_BOUNCE_HEIGHT_STEP)

		RemoteBank.ScaleTween:FireClient(
			self.ownership,
			luckyblockModel,
			baseScale,
			pulseScale,
			true,
			pulseTime
		)

		RemoteBank.JumpEntity:FireClient(
			self.ownership,
			luckyblockModel,
			luckyblockModel:GetPivot(),
			CFrame.new(0, jumpHeight, 0)
		)

		playAppearLuckyblockVFX(luckyblockModel, APPEAR_LUCKYBLOCK_HATCH_BURSTS)
		task.wait(math.max(0.08, (pulseTime * 2) * LUCKYBLOCK_HATCH_BOUNCE_OVERLAP))
	end

	if self.entityModel ~= luckyblockModel or not luckyblockModel.Parent then
		return
	end

	RemoteBank.ScaleTween:FireClient(
		self.ownership,
		luckyblockModel,
		baseScale,
		baseScale * LUCKYBLOCK_HATCH_TENSION_SCALE,
		false,
		LUCKYBLOCK_HATCH_TENSION_TIME
	)
	task.wait(LUCKYBLOCK_HATCH_TENSION_TIME + 0.01)

	if self.entityModel ~= luckyblockModel or not luckyblockModel.Parent then
		return
	end

	RemoteBank.ScaleTween:FireClient(
		self.ownership,
		luckyblockModel,
		baseScale * LUCKYBLOCK_HATCH_TENSION_SCALE,
		baseScale * LUCKYBLOCK_HATCH_FINAL_POP_MULTIPLIER,
		false,
		LUCKYBLOCK_HATCH_FINAL_POP_TIME
	)
	RemoteBank.JumpEntity:FireClient(
		self.ownership,
		luckyblockModel,
		luckyblockModel:GetPivot(),
		CFrame.new(0, LUCKYBLOCK_HATCH_FINAL_JUMP_HEIGHT, 0)
	)
	playAppearLuckyblockVFX(luckyblockModel, APPEAR_LUCKYBLOCK_REVEAL_BURSTS)
	task.wait(LUCKYBLOCK_HATCH_FINAL_POP_TIME + 0.07)
end

function StandController.CacheIndexObject(player, informations)
	local indexInformations = DataService.server:get(player, "index")
	if not indexInformations[informations.mutation] then
		DataService.server:set(player, {"index", informations.mutation}, {})
	end

	if not table.find(indexInformations[informations.mutation], informations.name) then
		DataService.server:arrayInsert(player, {"index", informations.mutation}, informations.name)
	end
end

local function FormatCash(amount: number)
	return "$" .. Format.abbreviateCash(amount)
end

local function isValidEntityStandData(entityData)
	if typeof(entityData) ~= "table" then
		return false
	end

	local entityName = entityData.name
	local mutationName = entityData.mutation
	if typeof(entityName) ~= "string" or not Entities[entityName] then
		return false
	end

	if typeof(mutationName) ~= "string" or not Mutations[mutationName] then
		return false
	end

	return true
end

local function isValidLuckyBoxStandData(luckyBoxData)
	if not isValidEntityStandData(luckyBoxData) then
		return false
	end

	return LuckyBoxes.IsLuckyBox(luckyBoxData.name)
end

local function normalizeStandData(player: Player, standNumber: number, standData: any)
	if typeof(standData) ~= "table" then
		standData = {
			cash = 0,
			entity = false,
			luckybox = false,
		}
		DataService.server:set(player, {"stands", standNumber}, standData)
		return standData
	end

	local didChange = false
	local currentEntity = standData.entity
	local currentLuckybox = standData.luckybox

	if typeof(currentEntity) == "table" and (typeof(currentEntity.mutation) ~= "string" or not Mutations[currentEntity.mutation]) and Mutations.Normal then
		currentEntity.mutation = "Normal"
		didChange = true
	end

	if typeof(currentLuckybox) == "table" and (typeof(currentLuckybox.mutation) ~= "string" or not Mutations[currentLuckybox.mutation]) and Mutations.Normal then
		currentLuckybox.mutation = "Normal"
		didChange = true
	end

	if typeof(currentEntity) == "table" and LuckyBoxes.IsLuckyBox(currentEntity.name) then
		currentLuckybox = currentEntity
		currentEntity = false
		didChange = true
	end

	if currentEntity and not isValidEntityStandData(currentEntity) then
		currentEntity = false
		didChange = true
	end

	if currentLuckybox and not isValidLuckyBoxStandData(currentLuckybox) then
		currentLuckybox = false
		didChange = true
	end

	if currentEntity == nil then
		currentEntity = false
		didChange = true
	end

	if currentLuckybox == nil then
		currentLuckybox = false
		didChange = true
	end

	if currentEntity and currentLuckybox then
		currentLuckybox = false
		didChange = true
	end

	local currentCash = standData.cash
	if typeof(currentCash) ~= "number" then
		currentCash = 0
		didChange = true
	end

	if currentLuckybox and currentCash ~= 0 then
		currentCash = 0
		didChange = true
	end

	if currentLuckybox and standData.lastOnlineTime ~= nil then
		standData.lastOnlineTime = nil
		didChange = true
	end

	standData.entity = currentEntity
	standData.luckybox = currentLuckybox
	standData.cash = currentCash

	if didChange then
		DataService.server:set(player, {"stands", standNumber}, standData)
	end

	return standData
end

function StandController.GetStandData(self: Stand)
	local success, informations = pcall(function()
		return DataService.server:get(self.ownership, {"stands", self.standNumber})
	end)
	if not success then
		return nil
	end

	return normalizeStandData(self.ownership, self.standNumber, informations)
end

function StandController.CalculateOfflineForTime(self: Stand, timeAmount)
	local Informations = self:GetStandData()
	if Informations and Informations.entity then
		return timeAmount * 0.4 * SharedFunctions.GetEarningsPerSecond(Informations.entity.name, Informations.entity.mutation, Informations.entity.upgradeLevel, self.ownership, Informations.entity.traits)
	end
	return 0
end

function StandController.GetOfflineEarnings(self: Stand)
	local Informations = self:GetStandData()
	if Informations and Informations.lastOnlineTime and Informations.entity then
		local TimeDifference = os.time() - Informations.lastOnlineTime
		local Clamped = math.min(TimeDifference, GlobalConfiguration.OfflineTime)
		return self:CalculateOfflineForTime(Clamped)
	end
end

function StandController.GetAllOfflineEarnings(player)
	local currentEarnings = 0

	if StandsCache[player] then
		for _, v in StandsCache[player] do
			currentEarnings += v:CalculateOfflineForTime(GlobalConfiguration.OfflineTime)
		end
	end

	return currentEarnings
end

function StandController.UpgradeCommunication(self: Stand)
	RemoteBank.UpgradeStand:FireClient(self.ownership, self.standNumber)
end

function StandController.StartMoneyGenerationCycle(self: Stand)
	local loopIndex = getStandMoneyLoopIndex(self.standNumber)
	self.janitor:Remove(loopIndex)
	self.janitor:Add(task.spawn(function()
		while true do
			local standData = self:GetStandData()
			if not standData or not standData.entity or not self.entityModel then
				break
			end

			DataService.server:update(self.ownership, {"stands", self.standNumber, "cash"}, function(old)
				local currentAmount = if typeof(old) == "number" then old else 0
				local target = currentAmount + SharedFunctions.GetEarningsPerSecond(
					standData.entity.name,
					standData.entity.mutation,
					(standData.entity.upgradeLevel or 0),
					self.ownership,
					standData.entity.traits
				)
				self.cashSpring.Target = target
				return target
			end, true)

			task.wait(1)
		end
	end), true, loopIndex)
end

function StandController.ClaimGeneratedMoney(self: Stand)
	local Informations = self:GetStandData()
	if Informations and Informations.entity then
		local OfflineEarnings = self:GetOfflineEarnings()
		if Informations.cash == 0 then return end

		self.cashSpring.Target = 0; self.cashSpring.Position = 0;
		DataService.server:update(self.ownership, {"cash"}, function(cashold)
			local amountToGive = Informations.cash + (OfflineEarnings or 0)
			RemoteBank.CashNotification:FireClient(self.ownership, amountToGive)
			return cashold + amountToGive
		end)

		RemoteBank.JumpEntity:FireClient(self.ownership, self.entityModel, self.entityModel:GetPivot(), CFrame.new(0, 5, 0))
		if self.cashVfx then
			EmitVFX(self.cashVfx)
		end

		self.cashBillboard.OfflineRewards.Visible = false

		DataService.server:set(self.ownership, {"stands", self.standNumber, "lastOnlineTime"}, nil, true)
		DataService.server:set(self.ownership, {"stands", self.standNumber, "cash"}, 0)
	end
end

function StandController.UpdateBillboardVisiblity(self: Stand, boolean: boolean)
	self.cashBillboard.Enabled = boolean
end

function StandController.UpdateBillboard(self: Stand)
	local OfflineEarnings = self:GetOfflineEarnings()
	local OfflineLabel = self.cashBillboard.OfflineRewards

	OfflineLabel.Visible = OfflineEarnings and true or false
	OfflineLabel.Text = "Offline: " .. FormatCash(OfflineEarnings or 0)

	local connectionIndex = getStandBillboardConnectionIndex(self.standNumber)
	self.janitor:Remove(connectionIndex)

	local lastRenderedText
	local elapsed = 0
	self.janitor:Add(RunService.Heartbeat:Connect(function(deltaTime)
		if not self.entityModel then
			return
		end

		elapsed += deltaTime
		if elapsed < 0.2 then
			return
		end
		elapsed = 0

		local updatedText = FormatCash(math.round(self.cashSpring.Position))
		if updatedText == lastRenderedText then
			return
		end

		lastRenderedText = updatedText
		self.cashBillboard.CashLabel.Text = updatedText
	end), "Disconnect", connectionIndex)
end

function StandController.ChangeState(self: Stand, State)
	self.model:SetAttribute("State", State)
end

function StandController.DestroyCurrentModel(self: Stand)
	self.janitor:Remove(getStandBillboardConnectionIndex(self.standNumber))
	self.janitor:Remove(getStandMoneyLoopIndex(self.standNumber))

	if self.entityModel then
		self.entityModel:Destroy()
		self.entityModel = nil
	end

	self.entityBillboard = nil
	self.vfx = nil
	self.cashVfx = nil
end

function StandController.UpdateScale(self: Stand)
	if self.entityModel then
		local PositionCFrame = CFrame.new()
		local StandCFrame = self.model:FindFirstChild("Stand"):GetPivot()
		local StandYSize = self.model:FindFirstChild("Stand"):GetExtentsSize().Y
		if GlobalConfiguration.UseLowerPivotMode then
			PositionCFrame = StandCFrame * CFrame.new(0, StandYSize / 2 + GlobalConfiguration.DistanceFromStand, 0) 
		else
			PositionCFrame = StandCFrame * CFrame.new(0, StandYSize / 2 + GlobalConfiguration.DistanceFromStand + self.entityModel:GetExtentsSize().Y / 2, 0)
		end

		local orientationDegrees = getPreviewRotationDegrees(self.entityModel) or GlobalConfiguration.AnglesOfRotation
		self.entityModel:PivotTo(PositionCFrame * CFrame.Angles(0, math.rad(orientationDegrees), 0))
	end
end

function StandController.SpawnEntity(self: Stand, entityInformations)
	self:DestroyCurrentModel()

	local NewEntity = SharedFunctions.CreateEntity(entityInformations.name, entityInformations.mutation, false, entityInformations.upgradeLevel, entityInformations.traits)
	if not NewEntity then
		return false
	end

	local entityRoot = SharedFunctions.FindRoot(NewEntity)
	if not entityRoot then
		return false
	end

	local EntityBillboard = SharedFunctions.CreateBillboard(entityInformations.name, entityInformations.mutation, entityInformations.upgradeLevel, self.ownership, false, entityInformations.traits)
	self.entityBillboard = EntityBillboard
	EntityBillboard.Parent = entityRoot

	StandController.CacheIndexObject(self.ownership, entityInformations)

	for _, v in pairs(NewEntity:GetChildren()) do
		if v:IsA("BasePart") then
			v.Anchored = true
		end
	end

	local UpgradeEffectThing = ReplicatedStorage.Assets.VFX.Upgrade:Clone()
	UpgradeEffectThing.Parent = entityRoot
	self.vfx = UpgradeEffectThing

	local CashEffect = ReplicatedStorage.Assets.VFX.CashClaimed:Clone()
	CashEffect.Parent = entityRoot
	self.cashVfx = CashEffect

	NewEntity.Parent = self.model
	self.entityModel = NewEntity

	RemoteBank.OfflineUpdated:FireClient(self.ownership)

	local animationToPlay = Entities[entityInformations.name].Animation
	if isValidAnimationId(animationToPlay) then
		local animationInstance = Instance.new("Animation")
		animationInstance.AnimationId = animationToPlay
		local humanoid = NewEntity:FindFirstChildWhichIsA("Humanoid") or NewEntity:FindFirstChildOfClass("AnimationController")
		if humanoid then
			local animator = humanoid:FindFirstChildOfClass("Animator")
			if animator then
				animator:LoadAnimation(animationInstance):Play()
			end
		end
	end

	RemoteBank.ScaleTween:FireClient(self.ownership, NewEntity, 0.001, NewEntity:GetScale(), false, 0.2)

	-- Placing setups
	self:UpdateBillboardVisiblity(true)
	self:UpdateBillboard()
	self:StartMoneyGenerationCycle()
	self:ChangeState(StandStateEnum.Occupied)
	self:UpdateScale()
	self:UpgradeCommunication()
	return true
end

function StandController.SpawnLuckybox(self: Stand, luckyboxInformations)
	self:DestroyCurrentModel()

	local NewLuckybox = SharedFunctions.CreateEntity(luckyboxInformations.name, luckyboxInformations.mutation, false, luckyboxInformations.upgradeLevel, luckyboxInformations.traits)
	if not NewLuckybox then
		return false
	end

	local luckyboxRoot = SharedFunctions.FindRoot(NewLuckybox)
	if not luckyboxRoot then
		return false
	end

	local luckyboxBillboard = SharedFunctions.CreateBillboard(luckyboxInformations.name, luckyboxInformations.mutation, luckyboxInformations.upgradeLevel, self.ownership, true, luckyboxInformations.traits)
	self.entityBillboard = luckyboxBillboard
	luckyboxBillboard.Parent = luckyboxRoot

	for _, v in pairs(NewLuckybox:GetChildren()) do
		if v:IsA("BasePart") then
			v.Anchored = true
		end
	end

	NewLuckybox.Parent = self.model
	self.entityModel = NewLuckybox

	RemoteBank.ScaleTween:FireClient(self.ownership, NewLuckybox, 0.001, NewLuckybox:GetScale(), false, 0.2)

	self:UpdateBillboardVisiblity(false)
	self.cashBillboard.OfflineRewards.Visible = false
	self:ChangeState(StandStateEnum.Luckyblock)
	self:UpdateScale()
	self:UpgradeCommunication()
	return true
end

function StandController.PickupEntity(self: Stand, dontGive)
	local standData = self:GetStandData()
	if not standData then
		return
	end

	local currentEntityData = standData.entity
	if currentEntityData then

		self:UpdateBillboardVisiblity(false)
		self:ChangeState(StandStateEnum.Empty)
		self:ClaimGeneratedMoney()

		if not dontGive then
			InventoryHandler.CacheTool(self.ownership, "Entity", currentEntityData)
		end

		DataService.server:set(self.ownership, {"stands", self.standNumber, "entity"}, false)
		DataService.server:set(self.ownership, {"stands", self.standNumber, "luckybox"}, false)
		self:DestroyCurrentModel()

		self.signal:Fire()
		RemoteBank.OfflineUpdated:FireClient(self.ownership)

		self:UpgradeCommunication()

		if self.ownership.Character then
			local CurrentEquipped = self.ownership.Character:FindFirstChildOfClass("Tool")
			if CurrentEquipped then
				self:PlaceEntity()
			end
		end
	end
end

function StandController.UpgradeEntity(self: Stand)
	local standData = self:GetStandData()
	if not standData then
		return
	end

	local currentEntityData = standData.entity
	if currentEntityData then
		local currentCash = DataService.server:get(self.ownership, "cash")
		local UpgradePrice = SharedFunctions.GetUpgradeCost(currentEntityData.name, (currentEntityData.upgradeLevel or 0) + 1)

		if currentCash >= UpgradePrice then
			DataService.server:update(self.ownership, "cash", function(old)
				return old - UpgradePrice
			end)

			DataService.server:update(self.ownership, {"stands", self.standNumber, "entity", "upgradeLevel"}, function(old)
				return (old or 0) + 1
			end)

			self:UpgradeCommunication()
			self:UpdateScale()

			RemoteBank.OfflineUpdated:FireClient(self.ownership)

			if self.vfx then
				EmitVFX(self.vfx)
			end

			RemoteBank.SendNotification:FireClient(self.ownership, "Upgraded " .. currentEntityData.name .. " to level " .. (currentEntityData.upgradeLevel or 0) + 1, Color3.new(0.682353, 1, 0))

			self.entityBillboard.CashLabel.Text = Format.abbreviateCash(SharedFunctions.GetEarningsPerSecond(currentEntityData.name, currentEntityData.mutation, currentEntityData.upgradeLevel or 0, self.ownership, currentEntityData.traits)) .. "$/s"
		end
	end
end


function StandController.PlaceEntity(self: Stand)
	if not self.ownership.Character or self.entityModel then
		return
	end

	local CurrentEquipped = self.ownership.Character:FindFirstChildOfClass("Tool")
	if not CurrentEquipped then
		return
	end

	local Id = CurrentEquipped:GetAttribute("Id")
	if not Id then
		return
	end

	if not CurrentEquipped:HasTag("Entity") and not CurrentEquipped:HasTag("Luckybox") and not CurrentEquipped:HasTag("Luckyblock") then
		return
	end

	DataService.server:update(self.ownership, {"inventory", Id}, function(oldInformations)
		if typeof(oldInformations) ~= "table" or typeof(oldInformations.informations) ~= "table" then
			return oldInformations
		end

		local informations = oldInformations.informations
		local shouldPlaceLuckyBox = oldInformations.tag == "Luckybox"
			or oldInformations.tag == "Luckyblock"
			or LuckyBoxes.IsLuckyBox(informations.name)

		local hasSpawned = false
		if shouldPlaceLuckyBox then
			DataService.server:set(self.ownership, {"stands", self.standNumber, "entity"}, false)
			DataService.server:set(self.ownership, {"stands", self.standNumber, "luckybox"}, informations)
			DataService.server:set(self.ownership, {"stands", self.standNumber, "cash"}, 0)
			DataService.server:set(self.ownership, {"stands", self.standNumber, "lastOnlineTime"}, nil, true)

			hasSpawned = self:SpawnLuckybox(informations)
		else
			DataService.server:set(self.ownership, {"stands", self.standNumber, "luckybox"}, false)
			DataService.server:set(self.ownership, {"stands", self.standNumber, "entity"}, informations)

			hasSpawned = self:SpawnEntity(informations)
		end

		if not hasSpawned then
			if shouldPlaceLuckyBox then
				DataService.server:set(self.ownership, {"stands", self.standNumber, "luckybox"}, false)
			else
				DataService.server:set(self.ownership, {"stands", self.standNumber, "entity"}, false)
			end
			self:ChangeState(StandStateEnum.Empty)
			return oldInformations
		end

		CurrentEquipped:Destroy()
		RemoteBank.PlacedEntity:FireClient(self.ownership)

		return false
	end)
end

function StandController.OpenLuckyblock(self: Stand)
	if self.rolling then
		return
	end
	self.rolling = true

	local function finishOpening()
		self.rolling = false
	end

	local standData = self:GetStandData()
	if not standData or not standData.luckybox then
		finishOpening()
		return
	end

	local luckyboxData = standData.luckybox
	local rolledBrainrot = LuckyBoxes.GetRandomBrainrot(luckyboxData.name)
	if not rolledBrainrot or not Entities[rolledBrainrot] then
		RemoteBank.SendNotification:FireClient(self.ownership, "This mystery box has no valid rewards.", Color3.new(1, 0.180392, 0.180392))
		finishOpening()
		return
	end

	local rewardMutation = SharedFunctions.GetRandomMutation() or "Normal"
	local rewardData = {
		name = rolledBrainrot,
		mutation = rewardMutation,
		traits = {},
	}

	playLuckyblockHatching(self)

	DataService.server:set(self.ownership, {"stands", self.standNumber, "luckybox"}, false)
	DataService.server:set(self.ownership, {"stands", self.standNumber, "entity"}, rewardData)
	DataService.server:set(self.ownership, {"stands", self.standNumber, "cash"}, 0)

	if not self:SpawnEntity(rewardData) then
		DataService.server:set(self.ownership, {"stands", self.standNumber, "entity"}, false)
		self:ChangeState(StandStateEnum.Empty)
		finishOpening()
		return
	end

	playAppearLuckyblockVFX(self.entityModel, APPEAR_LUCKYBLOCK_REVEAL_BURSTS)

	local displayName = Entities[rolledBrainrot].DisplayName or rolledBrainrot
	RemoteBank.LuckyblockOpened:FireClient(self.ownership, self.standNumber, rewardData)
	RemoteBank.SendNotification:FireClient(self.ownership, "You opened a mystery box and got " .. displayName .. "!", Color3.new(0.682353, 1, 0))
	finishOpening()
end

function StandController.CreateNewStand(player: Player, informations: {}, AddData: boolean)
	local StandNumber = #StandsCache[player] + 1
	local Floor = math.floor((StandNumber - 1) / GlobalConfiguration.StandsPerFloor)
	local FloorName = EXTRA .. Floor

	if Floor >= GlobalConfiguration.MaxFloors then warn("Max floors was reached, cant spawn any more stands.") return end

	local AdjustedNumber = StandNumber - Floor * GlobalConfiguration.StandsPerFloor

	local FloorFolder: Folder = informations.plot.Floors:FindFirstChild(FloorName)
	if FloorFolder then

		local DecorationsModel = FloorFolder:FindFirstChildOfClass("Model")
		if not DecorationsModel then
			local NewDecorations = ReplicatedStorage.Assets.PlotFloors:FindFirstChild(FloorName)
			if NewDecorations then 
				local Clonable = NewDecorations:Clone()
				Clonable:PivotTo(FloorFolder:FindFirstChild(FLOOR_SPAWN_NAME):GetPivot())
				informations.janitor:Add(Clonable)
				Clonable.Parent = FloorFolder
			else
				warn("No new decorations could be found for floor number " .. Floor)
			end
		end

		local StandsContainer = FloorFolder:FindFirstChild("Stands")
		if not StandsContainer then
			StandsContainer = Instance.new("Folder")
			StandsContainer.Name = "Stands"
			informations.janitor:Add(StandsContainer)
			StandsContainer.Parent = FloorFolder
		end

		local StandsFolder = FloorFolder:FindFirstChild("StandSpawns")
		assert(StandsFolder, "Did you forget to put a StandSpawns folder inside of the floor?")

		local StandSpawn = StandsFolder:FindFirstChild(AdjustedNumber)
		if StandSpawn then
			local Cloned = ReplicatedStorage.Assets.PlotAssets:FindFirstChild(GlobalConfiguration.StandTemplateName):Clone()
			Cloned:PivotTo(StandSpawn.CFrame)
			informations.janitor:Add(Cloned)
			Cloned.Name = AdjustedNumber
			Cloned.Parent = StandsContainer

			if AddData or typeof(DataService.server:get(player, {"stands", StandNumber})) ~= "table" then
				DataService.server:set(player, {"stands", StandNumber}, {
					cash = 0,
					entity = false,
					luckybox = false,
				})
			end

			local self : Stand = setmetatable({
				model = Cloned,
				ownership = player,
				directory = StandNumber,
				standNumber = StandNumber,
				cashSpring = Spring.new(0, 1, 20),
				janitor = informations.janitor,
				signal = Signal.new(),
				rolling = false
			}, StandController)

			informations.janitor:Add(function()
				self.signal:Fire()
				self.signal:Destroy()
			end, true, getStandSignalCleanupIndex(StandNumber))

			local Touchpart = Cloned:FindFirstChild("TouchPart", true)
			if Touchpart then
				SharedUtilities.attachToTouchEvents(Touchpart, function(plr)
					if plr == self.ownership then
						self:ClaimGeneratedMoney()
					end
				end, 1)
			end

			local NewCashBillboard = script.CashBillboard:Clone()
			NewCashBillboard.Parent = Cloned:FindFirstChild("TouchPart", true)

			self.cashBillboard = NewCashBillboard
			NewCashBillboard.Enabled = false

			local standData = self:GetStandData()
			if standData and standData.entity then
				self:SpawnEntity(standData.entity)
			elseif standData and standData.luckybox then
				self:SpawnLuckybox(standData.luckybox)
			else
				self:ChangeState(StandStateEnum.Empty)
			end

			RemoteBank.StandAdded:FireAllClients(player, Cloned, StandNumber)

			StandsCache[player][StandNumber] = self

			return self
		else
			warn("No stand spawn could be found")
		end
	else
		warn("No floor folder of x amount could be found")
	end
end

function StandController.OnPlotInitialized(player: Player, informations)
	DataService.server:waitForData(player)
	if StandsCache[player] then return end
	StandsCache[player] = {}

	informations.janitor:Add(function()
		StandsCache[player] = nil
	end)

	local LenghtOfStands = #DataService.server:get(player, "stands")

	for i = 1, math.max(GlobalConfiguration.StarterStands, LenghtOfStands) do
		local hasData = DataService.server:get(player, {"stands", i})
		StandController.CreateNewStand(player, informations, if hasData then false else true)
	end
end

-- Initialization function for the script
function StandController:Initialize()
	for player, informations in PlotHandler.GetLoadedPlots() do
		StandController.OnPlotInitialized(player, informations)
	end

	SignalBank.PlotInitialized:Connect(StandController.OnPlotInitialized)

	RemoteBank.GetOfflineAmount.OnServerInvoke = function(player)
		return StandController.GetAllOfflineEarnings(player) or 0
	end

	RemoteBank.PlaceStand.OnServerInvoke = function(playerCalling, standNumber)
		local container = StandsCache[playerCalling]
		if not container then return end

		local stand = container[standNumber]
		if stand then
			stand:PlaceEntity()
		end
	end

	RemoteBank.PickupStand.OnServerInvoke = function(playerCalling, standNumber)
		local container = StandsCache[playerCalling]
		if not container then return end

		local stand = container[standNumber]
		if stand then
			stand:PickupEntity()
		end
	end

	RemoteBank.UpgradeStand.OnServerEvent:Connect(function(playerCalling, standNumber)
		local container = StandsCache[playerCalling]
		if not container then return end

		local stand = container[standNumber]
		if stand then
			stand:UpgradeEntity()
		end
	end)

	RemoteBank.OpenStand.OnServerInvoke = function(playerCalling, standNumber)
		local container = StandsCache[playerCalling]
		if not container then return end

		local stand = container[standNumber]
		if stand then
			stand:OpenLuckyblock()
		end
	end

	RemoteBank.StealStand.OnServerInvoke = function(playerCalling, otherPlayer, standNumber)
		if otherPlayer and standNumber then
			if playerCalling == otherPlayer then return end
			local container = StandsCache[otherPlayer]
			if not container then return end

			local stand = container[tonumber(standNumber)]
			if stand then
				local data = stand:GetStandData()
				if data.entity then
					local rarity = Entities[data.entity.name].Rarity
					local pass = DevProducts.Stealables[rarity]
					if pass then
						MarketplaceHandler.Purchase(playerCalling, false, pass, table.clone(data.entity), standNumber, otherPlayer)
					end
				end
			end
		end
	end

	RemoteBank.GetStands.OnServerInvoke = function(playerCalling)
		local t = {}
		for player, stands in StandsCache do
			t[player.Name] = {}
			for standNumber, informations in stands do
				t[player.Name][standNumber] = informations.model
			end
		end
		return t
	end

	SignalBank.ClearEntityOnStand:Connect(function(otherplayer, standNumber)
		local container = StandsCache[otherplayer]
		if not container then return end

		local stand = container[standNumber]
		if stand then
			stand:PickupEntity(true)
		end
	end)
end

return StandController
