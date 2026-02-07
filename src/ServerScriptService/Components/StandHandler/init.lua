-- Services
local ReplicatedStorage = game:GetService('ReplicatedStorage')
local Players = game:GetService('Players')
local ServerStorage = game:GetService('ServerStorage')
local RunService = game:GetService('RunService')
local ServerScriptService = game:GetService('ServerScriptService')

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
local Entities = require(ReplicatedStorage.DataModules.Entities)
local DevProducts = require(ReplicatedStorage.DataModules.DevProducts)
local MarketplaceHandler = require(ServerScriptService.Components.MarketplaceHandler)
local Mutations = require(ReplicatedStorage.DataModules.Mutations)

-- Dependencies
local InventoryHandler = require("./InventoryHandler")
local PlotHandler = require("./PlotHandler")
local StarterPlayer = game:GetService("StarterPlayer")

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

local function EmitVFX(VFX)
	for _, v in VFX:GetDescendants() do
		if v:IsA("ParticleEmitter") then
			v:Emit(v:GetAttribute("EmitCount") or 12)
		end
	end
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

function StandController.GetStandData(self: Stand)
	local _, informations = pcall(function()
		return DataService.server:get(self.ownership, {"stands", self.standNumber})
	end)
	return informations
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
	if Informations.lastOnlineTime and Informations.entity then
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
	task.spawn(function()
		local block = false
		
		self.signal:Once(function()
			block = true
		end)
		
		while task.wait() do
			local standData = self:GetStandData() 
			if not standData.entity or block then break end
			
			DataService.server:update(self.ownership, {"stands", self.standNumber, "cash"}, function(old)
				local target = old + SharedFunctions.GetEarningsPerSecond(standData.entity.name, standData.entity.mutation,( standData.entity.upgradeLevel or 0), self.ownership, standData.entity.traits)
				self.cashSpring.Target = target
				return target
			end)
			task.wait(1)
		end
	end)
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
	
	self.janitor:Add(RunService.Heartbeat:Connect(function()
		if not self.entityModel then return end
		self.cashBillboard.CashLabel.Text = FormatCash(math.round(self.cashSpring.Position))
	end))
end

function StandController.ChangeState(self: Stand, State)
	self.model:SetAttribute("State", State)
end

function StandController.UpdateScale(self: Stand)
	local standData = self:GetStandData()
	if standData.entity then
		
		local PositionCFrame = CFrame.new()
		local StandCFrame = self.model:FindFirstChild("Stand"):GetPivot()
		local StandYSize = self.model:FindFirstChild("Stand"):GetExtentsSize().Y
		if GlobalConfiguration.UseLowerPivotMode then
			PositionCFrame = StandCFrame * CFrame.new(0, StandYSize / 2 + GlobalConfiguration.DistanceFromStand, 0) 
		else
			PositionCFrame = StandCFrame * CFrame.new(0, StandYSize / 2 + GlobalConfiguration.DistanceFromStand + self.entityModel:GetExtentsSize().Y / 2, 0)
		end
		
		self.entityModel:PivotTo(PositionCFrame * CFrame.Angles(0, math.rad(GlobalConfiguration.AnglesOfRotation), 0))
	end
end

function StandController.SpawnEntity(self: Stand, entityInformations)
	local NewEntity = SharedFunctions.CreateEntity(entityInformations.name, entityInformations.mutation, false, entityInformations.upgradeLevel, entityInformations.traits)
	
	local EntityBillboard = SharedFunctions.CreateBillboard(entityInformations.name, entityInformations.mutation, entityInformations.upgradeLevel, self.ownership, false, entityInformations.traits)
	self.entityBillboard = EntityBillboard
	EntityBillboard.Parent = SharedFunctions.FindRoot(NewEntity)
	
	StandController.CacheIndexObject(self.ownership, entityInformations)
	
	for _, v in pairs(NewEntity:GetChildren()) do
		if v:IsA("BasePart") then
			v.Anchored = true
		end
	end
	
	local UpgradeEffectThing = ReplicatedStorage.Assets.VFX.Upgrade:Clone()
	UpgradeEffectThing.Parent = SharedFunctions.FindRoot(NewEntity)
	self.vfx = UpgradeEffectThing
	
	local CashEffect = ReplicatedStorage.Assets.VFX.CashClaimed:Clone()
	CashEffect.Parent = SharedFunctions.FindRoot(NewEntity)
	self.cashVfx = CashEffect
	
	NewEntity.Parent = self.model
	self.entityModel = NewEntity
	
	RemoteBank.OfflineUpdated:FireClient(self.ownership)
	
	local animationToPlay = Entities[entityInformations.name].Animation
	if animationToPlay then
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
end

function StandController.PickupEntity(self: Stand, dontGive)
	local currentEntityData = self:GetStandData().entity
	if currentEntityData then
		
		self:UpdateBillboardVisiblity(false)
		self:ChangeState(StandStateEnum.Empty)
		self:ClaimGeneratedMoney()
		
		if not dontGive then
			InventoryHandler.CacheTool(self.ownership, "Entity", currentEntityData)
		end
		
		DataService.server:set(self.ownership, {"stands", self.standNumber, "entity"}, false)
		self.entityModel:Destroy()
		self.entityModel = nil
		
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
	local currentEntityData = self:GetStandData().entity
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
	if self.ownership.Character and not self.entityModel then
		local CurrentEquipped = self.ownership.Character:FindFirstChildOfClass("Tool")
		if CurrentEquipped then
			local Id = CurrentEquipped:GetAttribute("Id")
			if CurrentEquipped:HasTag("Entity") and Id then
				local EntityInformations = DataService.server:get(self.ownership, {"inventory", Id})
				if EntityInformations then
					DataService.server:update(self.ownership, {"inventory", Id}, function(oldInformations)
						DataService.server:set(self.ownership, {"stands", self.standNumber, "entity"}, oldInformations.informations)
						
						self:SpawnEntity(oldInformations.informations)
						
						CurrentEquipped:Destroy()
						
						RemoteBank.PlacedEntity:FireClient(self.ownership)
						
						
						return false
					end)
				end
			end
		end
	end
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
			
			if AddData or DataService.server:get(player, {"stands", StandNumber, "entity"}) and (not Entities[DataService.server:get(player, {"stands", StandNumber, "entity", "name"})] or not Mutations[DataService.server:get(player, {"stands", StandNumber, "entity", "mutation"})]) then
				DataService.server:set(player, {"stands", StandNumber}, {
					cash = 0,
				})
			end
			
			local self : Stand = setmetatable({
				model = Cloned,
				ownership = player,
				directory = StandNumber,
				standNumber = StandNumber,
				cashSpring = Spring.new(0, 1, 20),
				janitor = informations.janitor,
				signal = Signal.new()
			}, StandController)
			
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
			
			local Entity = self:GetStandData().entity
			if Entity then
				self:SpawnEntity(Entity)
			end
			
			self:ChangeState(Entity and StandStateEnum.Occupied or StandStateEnum.Empty)
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
