--!strict

local CollectionService = game:GetService("CollectionService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local ServerScriptService = game:GetService("ServerScriptService")
local Workspace = game:GetService("Workspace")

local appServer = ServerScriptService:WaitForChild("App"):WaitForChild("Server")
local system = appServer:WaitForChild("System")

local sharedData = ReplicatedStorage:WaitForChild("App"):WaitForChild("Shared"):WaitForChild("Data")
local garagesFolder = ReplicatedStorage:WaitForChild("Assets"):WaitForChild("Garages")
local Gen = require(sharedData:WaitForChild("General"):WaitForChild("Gen"))

local BaseService = require(system:WaitForChild("BaseService"))
local Maid =
	require(ReplicatedStorage:WaitForChild("App"):WaitForChild("Shared"):WaitForChild("Util"):WaitForChild("Maid"))
local Signal =
	require(ReplicatedStorage:WaitForChild("App"):WaitForChild("Shared"):WaitForChild("Util"):WaitForChild("Signal"))

local internal = script:WaitForChild("_Internal")
local ActiveRegistry = require(internal:WaitForChild("ActiveRegistry"))
local PendingRegistry = require(internal:WaitForChild("PendingRegistry"))
local SlotAllocator = require(internal:WaitForChild("SlotAllocator"))

type ActiveRecord = ActiveRegistry.Record

local defaultGarageKey = "Default"
local plotSpacing = 200
local garageTeleporterPollInterval = 0.25
local garageTeleporterCooldown = 1

local Service = BaseService.New("GarageService", { "PlayerProfileService" })
Service.GarageLoaded = Signal.New()
Service.GarageDestroyed = Signal.New()

local getWorldCFrame: (instance: Instance) -> CFrame?

local function isValidGarageModel(garageModel: Model): boolean
	return garageModel.Parent ~= nil
end

local function getTemplateAnchor(instance: Instance): Instance?
	local origin = instance:FindFirstChild("Origin", true)
	if origin ~= nil and getWorldCFrame(origin) ~= nil then
		return origin
	end

	local plot = instance:FindFirstChild("Plot", true)
	if plot ~= nil and getWorldCFrame(plot) ~= nil then
		return plot
	end

	local spawnAttachment = instance:FindFirstChild("SpawnPlayer", true)
	if spawnAttachment ~= nil and getWorldCFrame(spawnAttachment) ~= nil then
		return spawnAttachment
	end

	local firstBasePart = instance:FindFirstChildWhichIsA("BasePart", true)
	if firstBasePart ~= nil then
		return firstBasePart
	end

	return nil
end

getWorldCFrame = function(instance: Instance): CFrame?
	if instance:IsA("Attachment") then
		return instance.WorldCFrame
	end
	if instance:IsA("BasePart") then
		return instance.CFrame
	end
	if instance:IsA("Model") then
		local ok, pivot = pcall(instance.GetPivot, instance)
		if ok == true then
			return pivot
		end
	end

	return nil
end

local function getSpawnAttachment(instance: Instance): Attachment?
	local spawnAttachment = instance:FindFirstChild("SpawnPlayer", true)
	if spawnAttachment ~= nil and spawnAttachment:IsA("Attachment") then
		return spawnAttachment
	end

	return nil
end

local function getCurrentGarageKey(profileService: any, player: Player): string
	local currentGarage = profileService:GetCurrentGarage(player)
	if type(currentGarage) ~= "string" or currentGarage == "" then
		return defaultGarageKey
	end

	return currentGarage
end

local function resolveTaggedAttachment(tagName: string): Attachment?
	for _, taggedInstance in CollectionService:GetTagged(tagName) do
		if taggedInstance:IsA("Attachment") then
			return taggedInstance
		end
	end

	return nil
end

local function resolveCharacterRoot(character: Model): BasePart?
	local humanoidRootPart = character:FindFirstChild("HumanoidRootPart")
	if humanoidRootPart ~= nil and humanoidRootPart:IsA("BasePart") then
		return humanoidRootPart
	end

	local rootPart = character:WaitForChild("HumanoidRootPart", 5)
	if rootPart ~= nil and rootPart:IsA("BasePart") then
		return rootPart
	end

	return nil
end

local function resolveGarageTeleporterPlayer(hitPart: BasePart): Player?
	local character = hitPart:FindFirstAncestorOfClass("Model")
	if character == nil then
		return nil
	end

	return Players:GetPlayerFromCharacter(character)
end

function Service:_GetOrCreateCreatedGaragesFolder(): Folder
	local existingFolder = Workspace:FindFirstChild("CreatedGarages")
	if existingFolder ~= nil and existingFolder:IsA("Folder") then
		return existingFolder
	end

	local folder = Instance.new("Folder")
	folder.Name = "CreatedGarages"
	folder.Parent = Workspace

	return folder
end

function Service:_ResolvePlotTemplate(garageKey: string): Instance?
	local template = self._plotTemplatesByGarageKey[garageKey]
	if template ~= nil then
		return template
	end

	return self._plotTemplatesByGarageKey[defaultGarageKey]
end

function Service:_BuildPlotTemplatesByGarageKey(): { [string]: Instance }
	local templatesByGarageKey = {}

	for _, garageEntry in ipairs(garagesFolder:GetChildren()) do
		local plotTemplate = garageEntry:FindFirstChild("PlotTemplate")
		if plotTemplate ~= nil then
			templatesByGarageKey[garageEntry.Name] = plotTemplate
		end
	end

	return templatesByGarageKey
end

function Service:_CreateGarageModel(player: Player, template: Instance): Model?
	local clonedTemplate = template:Clone()
	local garageModel: Model

	if clonedTemplate:IsA("Model") then
		garageModel = clonedTemplate
	else
		garageModel = Instance.new("Model")
		clonedTemplate.Parent = garageModel
	end

	garageModel.Name = `{player.UserId}_Garage`

	return garageModel
end

function Service:_PositionGarageModel(garageModel: Model, slotIndex: number): boolean
	local anchor = getTemplateAnchor(garageModel)
	if anchor == nil then
		return false
	end

	local anchorCFrame = getWorldCFrame(anchor)
	if anchorCFrame == nil then
		return false
	end

	local garagePivot = garageModel:GetPivot()
	local offset = CFrame.new((slotIndex - 1) * plotSpacing, 0, 0)
	local nextAnchorCFrame = anchorCFrame * offset
	local delta = nextAnchorCFrame * anchorCFrame:Inverse()

	garageModel:PivotTo(delta * garagePivot)
	return true
end

function Service:_DestroyGarageRecord(player: Player)
	local record = self._activeRegistry:Clear(player)
	if record == nil then
		self._slotAllocator:Release(player)
		return
	end

	self._slotAllocator:Release(player)
	self.GarageDestroyed:Fire(player, record.GarageModel, record.GarageKey)

	if record.GarageModel.Parent ~= nil then
		record.GarageModel:Destroy()
	end
end

function Service:_TeleportCharacterToGarage(player: Player, garageModel: Model)
	local spawnAttachment = getSpawnAttachment(garageModel)
	if spawnAttachment == nil then
		return
	end

	local character = player.Character
	if character == nil then
		return
	end

	if resolveCharacterRoot(character) == nil then
		return
	end

	local spawnCFrame = spawnAttachment.WorldCFrame
	pcall(player.RequestStreamAroundAsync, player, spawnCFrame.Position)

	if player.Parent ~= Players then
		return
	end
	if character.Parent == nil then
		return
	end

	character:PivotTo(spawnCFrame)
end

function Service:_TeleportPlayerToActiveGarage(player: Player)
	local record = self._activeRegistry:Get(player)
	if record == nil then
		return
	end
	if record.GarageModel.Parent == nil then
		return
	end

	self:_TeleportCharacterToGarage(player, record.GarageModel)
end

function Service:_TeleportCharacterToWorldPoint(player: Player, targetInstance: Instance): boolean
	local targetCFrame = getWorldCFrame(targetInstance)
	if targetCFrame == nil then
		return false
	end

	local character = player.Character
	if character == nil then
		return false
	end
	if resolveCharacterRoot(character) == nil then
		return false
	end

	pcall(player.RequestStreamAroundAsync, player, targetCFrame.Position)

	if player.Parent ~= Players then
		return false
	end
	if character.Parent == nil then
		return false
	end

	character:PivotTo(targetCFrame)
	return true
end

function Service:_BindPlayer(player: Player)
	if self._playerMaids[player] ~= nil then
		return
	end

	local playerMaid = Maid.New()
	self._playerMaids[player] = playerMaid

	playerMaid:Add(player.CharacterAdded:Connect(function()
		task.spawn(function()
			if self._profileService:IsLoaded(player) ~= true then
				return
			end

			self:LoadGarageForPlayer(player)
		end)
	end))
end

function Service:_UnbindPlayer(player: Player)
	local playerMaid = self._playerMaids[player]
	if playerMaid ~= nil then
		self._playerMaids[player] = nil
		playerMaid:Cleanup()
	end
end

function Service:_HandleProfileLoaded(player: Player)
	task.spawn(self.LoadGarageForPlayer, self, player)
end

function Service:_RefreshExitGarageAttachment()
	self._exitGarageAttachment = resolveTaggedAttachment("ExitGarage")
end

function Service:_ResolveGarageTeleportersFolder(): Instance?
	local zonesFolder = Workspace:FindFirstChild("Zones")
	if zonesFolder == nil then
		return nil
	end

	return zonesFolder:FindFirstChild("GaragesTeleporters")
end

function Service:_RebuildGarageTeleporterParts()
	table.clear(self._garageTeleporterParts)

	if self._garageTeleportersFolder == nil then
		return
	end

	for _, descendant in ipairs(self._garageTeleportersFolder:GetDescendants()) do
		if descendant:IsA("BasePart") then
			descendant.CanCollide = false
			descendant.CanTouch = false
			descendant.CanQuery = true
			table.insert(self._garageTeleporterParts, descendant)
		end
	end
end

function Service:_RefreshGarageTeleportersFolder()
	local nextFolder = self:_ResolveGarageTeleportersFolder()
	if self._garageTeleportersFolder == nextFolder then
		return
	end

	self._garageTeleportersMaid:Cleanup()
	self._garageTeleportersFolder = nextFolder
	self:_RebuildGarageTeleporterParts()

	if self._garageTeleportersFolder == nil then
		return
	end

	self._garageTeleportersMaid:Add(self._garageTeleportersFolder.DescendantAdded:Connect(function(descendant: Instance)
		if descendant:IsA("BasePart") then
			self:_RebuildGarageTeleporterParts()
		end
	end))

	self._garageTeleportersMaid:Add(self._garageTeleportersFolder.DescendantRemoving:Connect(function(descendant: Instance)
		if descendant:IsA("BasePart") then
			self:_RebuildGarageTeleporterParts()
		end
	end))
end

function Service:_QueueGarageLoadFromTeleporter(player: Player)
	if player.Parent ~= Players then
		return
	end

	local now = os.clock()
	local nextAllowedAt = self._garageTeleporterCooldownByPlayer[player]
	if nextAllowedAt ~= nil and nextAllowedAt > now then
		return
	end

	self._garageTeleporterCooldownByPlayer[player] = now + garageTeleporterCooldown

	task.spawn(function()
		self:LoadGarageForPlayer(player)
	end)
end

function Service:_PollGarageTeleporters()
	self:_RefreshGarageTeleportersFolder()

	if self._garageTeleportersFolder == nil or #self._garageTeleporterParts == 0 then
		return
	end

	for _, teleporterPart in ipairs(self._garageTeleporterParts) do
		if teleporterPart.Parent == nil then
			continue
		end

		local overlappingParts = Workspace:GetPartBoundsInBox(
			teleporterPart.CFrame,
			teleporterPart.Size,
			self._garageTeleporterOverlapParams
		)

		for _, hitPart in ipairs(overlappingParts) do
			local player = resolveGarageTeleporterPlayer(hitPart)
			if player ~= nil then
				self:_QueueGarageLoadFromTeleporter(player)
			end
		end
	end
end

function Service:Init(registry)
	self._profileService = registry:Get("PlayerProfileService")
	self._createdGaragesFolder = self:_GetOrCreateCreatedGaragesFolder()
	self._plotTemplatesByGarageKey = self:_BuildPlotTemplatesByGarageKey()
	self._activeRegistry = ActiveRegistry.New()
	self._pendingRegistry = PendingRegistry.New()
	self._slotAllocator = SlotAllocator.New()
	self._playerMaids = {}
	self._spawningPlayers = {}
	self._garageTeleportersFolder = nil
	self._garageTeleportersMaid = Maid.New()
	self._garageTeleporterParts = {}
	self._garageTeleporterCooldownByPlayer = {}
	self._garageTeleporterOverlapParams = OverlapParams.new()
end

function Service:Start(_registry)
	self:_RefreshExitGarageAttachment()
	self:_RefreshGarageTeleportersFolder()

	self.Maid:Add(self._profileService.ProfileLoaded:Connect(function(player: Player)
		self:_HandleProfileLoaded(player)
	end))

	self.Maid:Add(self._profileService.ProfileReleased:Connect(function(player: Player)
		self:_DestroyGarageRecord(player)
	end))

	self.Maid:Add(Players.PlayerAdded:Connect(function(player: Player)
		self:_BindPlayer(player)

		if self._profileService:IsLoaded(player) == true then
			self:_HandleProfileLoaded(player)
		end
	end))

	self.Maid:Add(Players.PlayerRemoving:Connect(function(player: Player)
		self._spawningPlayers[player] = nil
		self._pendingRegistry:Clear(player)
		self._garageTeleporterCooldownByPlayer[player] = nil
		self:_UnbindPlayer(player)
		self:_DestroyGarageRecord(player)
	end))

	self.Maid:Add(CollectionService:GetInstanceAddedSignal("ExitGarage"):Connect(function()
		self:_RefreshExitGarageAttachment()
	end))

	self.Maid:Add(CollectionService:GetInstanceRemovedSignal("ExitGarage"):Connect(function()
		self:_RefreshExitGarageAttachment()
	end))

	do
		local accumulatedDelta = 0
		self.Maid:Add(RunService.Heartbeat:Connect(function(deltaTime: number)
			accumulatedDelta += deltaTime
			if accumulatedDelta < garageTeleporterPollInterval then
				return
			end

			accumulatedDelta = 0
			self:_PollGarageTeleporters()
		end))
	end

	for _, player in ipairs(Players:GetPlayers()) do
		self:_BindPlayer(player)

		if self._profileService:IsLoaded(player) == true then
			self:_HandleProfileLoaded(player)
		end
	end

	self.Maid:Add(function()
		for player in pairs(self._playerMaids) do
			self:_UnbindPlayer(player)
		end

		for _, player in ipairs(Players:GetPlayers()) do
			self:_DestroyGarageRecord(player)
		end

		self._spawningPlayers = {}
		self._garageTeleportersFolder = nil
		self._garageTeleportersMaid:Cleanup()
		table.clear(self._garageTeleporterParts)
		table.clear(self._garageTeleporterCooldownByPlayer)
		self._activeRegistry:Destroy()
		self._pendingRegistry:Destroy()
		self._slotAllocator:Destroy()
	end)
end

function Service:GetActiveGarage(player: Player): Model?
	local record = self._activeRegistry:Get(player)
	if record == nil then
		return nil
	end
	if record.GarageModel.Parent == nil then
		return nil
	end

	return record.GarageModel
end

function Service:LoadGarageForPlayer(player: Player): Model?
	if player.Parent ~= Players then
		return nil
	end
	if self._profileService:IsLoaded(player) ~= true then
		return nil
	end

	if self._spawningPlayers[player] == true then
		return self:GetActiveGarage(player)
	end

	self._spawningPlayers[player] = true

	local garageKey = getCurrentGarageKey(self._profileService, player)
	local activeRecord = self._activeRegistry:Get(player)
	if activeRecord ~= nil and activeRecord.GarageModel.Parent ~= nil and activeRecord.GarageKey == garageKey then
		self._spawningPlayers[player] = nil
		self.GarageLoaded:Fire(player, activeRecord.GarageModel, activeRecord.GarageKey)
		self:_TeleportPlayerToActiveGarage(player)
		return activeRecord.GarageModel
	end

	self:_DestroyGarageRecord(player)

	local plotTemplate = self:_ResolvePlotTemplate(garageKey)
	if plotTemplate == nil then
		self._spawningPlayers[player] = nil
		return nil
	end

	local slotIndex = self._slotAllocator:Acquire(player)
	local garageModel = self:_CreateGarageModel(player, plotTemplate)
	if garageModel == nil then
		self._slotAllocator:Release(player)
		self._spawningPlayers[player] = nil
		return nil
	end

	if self:_PositionGarageModel(garageModel, slotIndex) ~= true then
		garageModel:Destroy()
		self._slotAllocator:Release(player)
		self._spawningPlayers[player] = nil
		return nil
	end

	local resolvedGarageKey = garageKey
	if self._plotTemplatesByGarageKey[garageKey] == nil then
		resolvedGarageKey = defaultGarageKey
	end

	local record: ActiveRecord = {
		GarageModel = garageModel,
		GarageKey = resolvedGarageKey,
		SlotIndex = slotIndex,
	}

	garageModel:SetAttribute("OwnerUserId", player.UserId)
	garageModel:SetAttribute("GarageKey", resolvedGarageKey)
	garageModel:SetAttribute("GarageSlotIndex", slotIndex)
	garageModel.Parent = self._createdGaragesFolder

	self._activeRegistry:Set(player, record)
	self._spawningPlayers[player] = nil
	self.GarageLoaded:Fire(player, garageModel, resolvedGarageKey)

	self:_TeleportPlayerToActiveGarage(player)
	return garageModel
end

function Service:SpawnGarageForPlayer(player: Player): Model?
	return self:LoadGarageForPlayer(player)
end

function Service:DestroyGarageForPlayer(player: Player)
	self._pendingRegistry:Clear(player)
	self._spawningPlayers[player] = nil
	self:_DestroyGarageRecord(player)
end

function Service:ExitGarageForPlayer(player: Player, exitPoint: Instance?): boolean
	local resolvedExitPoint = exitPoint
	if typeof(resolvedExitPoint) ~= "Instance" then
		resolvedExitPoint = self._exitGarageAttachment
	end
	if typeof(resolvedExitPoint) ~= "Instance" then
		return false
	end

	local didTeleport = self:_TeleportCharacterToWorldPoint(player, resolvedExitPoint)
	self:DestroyGarageForPlayer(player)

	return didTeleport
end

function Service:HasPending(player: Player): boolean
	return self._pendingRegistry:Has(player)
end

function Service:SetPending(player: Player, garageModel: Model): boolean
	if isValidGarageModel(garageModel) ~= true then
		return false
	end

	self._pendingRegistry:Set(player, garageModel)
	return true
end

function Service:ConsumePending(player: Player): Model?
	return self._pendingRegistry:Consume(player)
end

function Service:ClearPending(player: Player)
	self._pendingRegistry:Clear(player)
end

function Service:Activate(player: Player, garageModel: Model, isRobux: boolean): boolean
	if isValidGarageModel(garageModel) ~= true then
		return false
	end

	if isRobux == true then
		return true
	end

	return self._profileService:SpendMoney(player, Gen.Garage.Cost)
end

return Service
