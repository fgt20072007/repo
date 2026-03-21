--!strict

local CollectionService = game:GetService("CollectionService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")
local Workspace = game:GetService("Workspace")

local appServer = ServerScriptService:WaitForChild("App"):WaitForChild("Server")
local system = appServer:WaitForChild("System")

local sharedData = ReplicatedStorage:WaitForChild("App"):WaitForChild("Shared"):WaitForChild("Data")
local carsFolder = ReplicatedStorage:WaitForChild("Assets"):WaitForChild("Cars")
local liveVehiclesFolder = Workspace:WaitForChild("Vehicles")
local Gen = require(sharedData:WaitForChild("General"):WaitForChild("Gen"))

local BaseService = require(system:WaitForChild("BaseService"))
local Maid =
	require(ReplicatedStorage:WaitForChild("App"):WaitForChild("Shared"):WaitForChild("Util"):WaitForChild("Maid"))

local internal = script:WaitForChild("_Internal")
local SpawnRegistry = require(internal:WaitForChild("SpawnRegistry"))

type SpawnRecord = SpawnRegistry.Record

local defaultGarageKey = "Default"
local garageCarSpawnTag = "GarageCarSpawn"
local driveCarPromptTag = "DriveCar"
local vehicleSpawnLockedAttribute = "VehicleSpawnLocked"
local spawnUnlockTimeout = 1

local Service = BaseService.New("CarSpawnerService", { "PlayerProfileService", "GarageService" })
local garageSlotCacheByModel = setmetatable({}, { __mode = "k" }) :: { [Model]: { Attachment } }

local function resolveGarageSlotLimit(garageKey: string): number
	local garageDefinition = Gen.Garages.Slots[garageKey]
	if type(garageDefinition) == "table" and type(garageDefinition.Slots) == "number" then
		return garageDefinition.Slots
	end

	local defaultGarageDefinition = Gen.Garages.Slots[defaultGarageKey]
	if type(defaultGarageDefinition) == "table" and type(defaultGarageDefinition.Slots) == "number" then
		return defaultGarageDefinition.Slots
	end

	return 0
end

local function getSlotOrder(slotAttachment: Attachment): number
	local suffix = string.match(slotAttachment.Name, "^CarSlot_(%d+)$")
	if suffix ~= nil then
		local numericSuffix = tonumber(suffix)
		if numericSuffix ~= nil then
			return numericSuffix
		end
	end

	return 1
end

local function collectGarageSlots(garageModel: Model): { Attachment }
	local cachedSlots = garageSlotCacheByModel[garageModel]
	if cachedSlots ~= nil then
		return cachedSlots
	end

	local slots = {}

	for _, descendant in ipairs(garageModel:GetDescendants()) do
		if descendant:IsA("Attachment") and string.match(descendant.Name, "^CarSlot") ~= nil then
			table.insert(slots, descendant)
		end
	end

	table.sort(slots, function(leftSlot, rightSlot)
		local leftOrder = getSlotOrder(leftSlot)
		local rightOrder = getSlotOrder(rightSlot)
		if leftOrder ~= rightOrder then
			return leftOrder < rightOrder
		end

		return leftSlot:GetFullName() < rightSlot:GetFullName()
	end)

	garageSlotCacheByModel[garageModel] = slots
	return slots
end

local function resolveVehicleTemplateFromContainer(container: Instance): Model?
	local modelContainer = container:FindFirstChild("Model")
	if modelContainer ~= nil then
		if modelContainer:IsA("Model") then
			return modelContainer
		end

		local nestedModel = modelContainer:FindFirstChildWhichIsA("Model")
		if nestedModel ~= nil then
			return nestedModel
		end
	end

	if container:IsA("Model") then
		return container
	end

	local directModel = container:FindFirstChildWhichIsA("Model")
	if directModel ~= nil then
		return directModel
	end

	return nil
end

local function resolveVehicleTemplate(vehicleName: string): Model?
	if vehicleName == "" then
		return nil
	end

	local storedVehicle = carsFolder:FindFirstChild(vehicleName)
	if storedVehicle == nil then
		storedVehicle = carsFolder:FindFirstChild(string.lower(vehicleName))
	end
	if storedVehicle ~= nil then
		local storedTemplate = resolveVehicleTemplateFromContainer(storedVehicle)
		if storedTemplate ~= nil then
			return storedTemplate
		end
	end

	return nil
end

local function ensurePrimaryPart(vehicleModel: Model): BasePart?
	local primaryPart = vehicleModel.PrimaryPart
	if primaryPart ~= nil then
		return primaryPart
	end

	local namedPrimary = vehicleModel:FindFirstChild("Primary")
	if namedPrimary ~= nil and namedPrimary:IsA("BasePart") then
		vehicleModel.PrimaryPart = namedPrimary
		return namedPrimary
	end

	local firstBasePart = vehicleModel:FindFirstChildWhichIsA("BasePart", true)
	if firstBasePart ~= nil then
		vehicleModel.PrimaryPart = firstBasePart
		return firstBasePart
	end

	return nil
end

local function isVehicleSpawnLocked(vehicleModel: Model): boolean
	return vehicleModel:GetAttribute(vehicleSpawnLockedAttribute) == true
end

local function stabilizeVehicleSpawn(vehicleModel: Model, targetCFrame: CFrame, shouldReleaseAfterSpawn: boolean)
	local primaryPart = ensurePrimaryPart(vehicleModel)
	if primaryPart == nil then
		return
	end

	vehicleModel:SetAttribute(vehicleSpawnLockedAttribute, true)
	primaryPart.Anchored = true
	vehicleModel:PivotTo(targetCFrame)

	task.defer(function()
		if primaryPart.Parent == nil then
			return
		end
		if vehicleModel.Parent ~= liveVehiclesFolder then
			return
		end

		primaryPart.AssemblyLinearVelocity = Vector3.zero
		primaryPart.AssemblyAngularVelocity = Vector3.zero
		vehicleModel:SetAttribute(vehicleSpawnLockedAttribute, false)
		if shouldReleaseAfterSpawn == true then
			primaryPart.Anchored = false
		end
	end)
end

local function destroyVehicle(vehicleModel: Model?)
	if vehicleModel == nil then
		return
	end
	if vehicleModel.Parent == nil then
		return
	end

	vehicleModel:Destroy()
end

local function collectOrderedVehicleNames(vehicles: { [any]: any }): { string }
	local orderedVehicleNames = {}
	local seenVehicleNames = {}

	for _, vehicleName in ipairs(vehicles) do
		if type(vehicleName) == "string" and vehicleName ~= "" and seenVehicleNames[vehicleName] ~= true then
			seenVehicleNames[vehicleName] = true
			table.insert(orderedVehicleNames, vehicleName)
		end
	end

	local keyedVehicleNames = {}
	for vehicleName in pairs(vehicles) do
		if type(vehicleName) == "string" and vehicleName ~= "" and seenVehicleNames[vehicleName] ~= true then
			table.insert(keyedVehicleNames, vehicleName)
		end
	end

	table.sort(keyedVehicleNames)

	for _, vehicleName in ipairs(keyedVehicleNames) do
		seenVehicleNames[vehicleName] = true
		table.insert(orderedVehicleNames, vehicleName)
	end

	return orderedVehicleNames
end

local function anchorVehiclePrimary(vehicleModel: Model, slotAttachment: Attachment)
	task.defer(function()
		if vehicleModel.Parent ~= liveVehiclesFolder then
			return
		end
		if slotAttachment.Parent == nil then
			return
		end

		local primaryPart = ensurePrimaryPart(vehicleModel)
		if primaryPart == nil then
			return
		end

		primaryPart.Anchored = true
		primaryPart.AssemblyLinearVelocity = Vector3.zero
		primaryPart.AssemblyAngularVelocity = Vector3.zero
		vehicleModel:PivotTo(slotAttachment.WorldCFrame)

		local seatsFolder = vehicleModel:FindFirstChild("Seats")
		if seatsFolder ~= nil then
			seatsFolder:Destroy()
		end
	end)
end

local function resolveVehicleModelFromPrompt(prompt: ProximityPrompt): Model?
	local currentInstance = prompt.Parent
	local resolvedVehicleModel = nil :: Model?

	while currentInstance ~= nil do
		if currentInstance:IsA("Model") then
			local hasVehicleStructure = currentInstance:FindFirstChild("Body") ~= nil
				or currentInstance:FindFirstChild("Primary") ~= nil
				or currentInstance:FindFirstChild("Seats") ~= nil
			if hasVehicleStructure == true then
				resolvedVehicleModel = currentInstance
			end
		end

		currentInstance = currentInstance.Parent
	end

	return resolvedVehicleModel
end

local function resolveDriveSeat(vehicleModel: Model): VehicleSeat?
	local directDriveSeat = vehicleModel:FindFirstChild("DriveSeat", true)
	if directDriveSeat ~= nil and directDriveSeat:IsA("VehicleSeat") then
		return directDriveSeat
	end

	local seatsFolder = vehicleModel:FindFirstChild("Seats")
	if seatsFolder ~= nil then
		local namedDriveSeat = seatsFolder:FindFirstChild("Drive")
		if namedDriveSeat ~= nil and namedDriveSeat:IsA("VehicleSeat") then
			return namedDriveSeat
		end

		local folderDriveSeat = seatsFolder:FindFirstChildWhichIsA("VehicleSeat")
		if folderDriveSeat ~= nil then
			return folderDriveSeat
		end
	end

	return vehicleModel:FindFirstChildWhichIsA("VehicleSeat", true)
end

local function resolveCharacterHumanoid(player: Player): Humanoid?
	local character = player.Character
	if character == nil then
		return nil
	end

	local humanoid = character:FindFirstChildOfClass("Humanoid")
	if humanoid ~= nil then
		return humanoid
	end

	return nil
end

local function disableDriveCarPrompts(vehicleModel: Model)
	for _, descendant in ipairs(vehicleModel:GetDescendants()) do
		if descendant:IsA("ProximityPrompt") and CollectionService:HasTag(descendant, driveCarPromptTag) then
			descendant.Enabled = false
		end
	end
end

function Service:_GetOrCreateSpawnRecord(player: Player): SpawnRecord
	local record = self._spawnRegistry:Get(player)
	if record ~= nil then
		return record
	end

	local nextRecord: SpawnRecord = {
		DisplayVehicles = {},
		ActiveDriveVehicle = nil,
	}

	self._spawnRegistry:Set(player, nextRecord)
	return nextRecord
end

function Service:_BindPlayer(player: Player)
	if self._playerMaids[player] ~= nil then
		return
	end

	local playerMaid = Maid.New()
	self._playerMaids[player] = playerMaid

	playerMaid:Add(player.CharacterRemoving:Connect(function()
		self:_ClearDriveVehicle(player)
	end))
end

function Service:_UnbindPlayer(player: Player)
	local playerMaid = self._playerMaids[player]
	if playerMaid == nil then
		return
	end

	self._playerMaids[player] = nil
	playerMaid:Cleanup()
end

function Service:_ClearActiveDriveVehicleMaid(player: Player)
	local driveVehicleMaid = self._activeDriveVehicleMaids[player]
	if driveVehicleMaid == nil then
		return
	end

	self._activeDriveVehicleMaids[player] = nil
	driveVehicleMaid:Cleanup()
end

function Service:_TrackActiveDriveVehicle(player: Player, vehicleModel: Model)
	self:_ClearActiveDriveVehicleMaid(player)

	local driveVehicleMaid = Maid.New()
	self._activeDriveVehicleMaids[player] = driveVehicleMaid

	driveVehicleMaid:Add(vehicleModel.Destroying:Connect(function()
		if self._activeDriveVehicleMaids[player] == driveVehicleMaid then
			self._activeDriveVehicleMaids[player] = nil
		end

		local record = self._spawnRegistry:Get(player)
		if record == nil then
			return
		end
		if record.ActiveDriveVehicle ~= vehicleModel then
			return
		end

		record.ActiveDriveVehicle = nil
	end))
end

function Service:_ClearDisplayVehicles(player: Player)
	local record = self._spawnRegistry:Get(player)
	if record == nil then
		return
	end

	for _, displayVehicle in ipairs(record.DisplayVehicles) do
		destroyVehicle(displayVehicle)
	end

	record.DisplayVehicles = {}
end

function Service:_ClearDriveVehicle(player: Player)
	self:_ClearActiveDriveVehicleMaid(player)

	local record = self._spawnRegistry:Get(player)
	if record == nil then
		return
	end

	destroyVehicle(record.ActiveDriveVehicle)
	record.ActiveDriveVehicle = nil
end

function Service:_DestroySpawnRecord(player: Player)
	self:_ClearActiveDriveVehicleMaid(player)

	local record = self._spawnRegistry:Clear(player)
	if record == nil then
		return
	end

	for _, displayVehicle in ipairs(record.DisplayVehicles) do
		destroyVehicle(displayVehicle)
	end

	destroyVehicle(record.ActiveDriveVehicle)
end

function Service:_SpawnVehicleIntoSlot(
	player: Player,
	vehicleName: string,
	slotAttachment: Attachment,
	spawnIndex: number
): Model?
	local vehicleTemplate = resolveVehicleTemplate(vehicleName)
	if vehicleTemplate == nil then
		return nil
	end

	local vehicleModel = vehicleTemplate:Clone()
	vehicleModel.Name = vehicleName
	vehicleModel:SetAttribute("VehicleName", vehicleName)
	vehicleModel:SetAttribute("OwnerUserId", player.UserId)
	vehicleModel:SetAttribute("GarageCarIndex", spawnIndex)
	vehicleModel:SetAttribute("IsGarageDisplayVehicle", true)

	stabilizeVehicleSpawn(vehicleModel, slotAttachment.WorldCFrame, false)
	vehicleModel.Parent = liveVehiclesFolder
	anchorVehiclePrimary(vehicleModel, slotAttachment)

	return vehicleModel
end

function Service:_ResolveGarageCarSpawn(player: Player): Attachment?
	local activeGarage = self._garageService:GetActiveGarage(player)
	local activeGarageSpawn = nil :: Attachment?
	local fallbackSpawn = nil :: Attachment?

	local function selectEarlierAttachment(currentBest: Attachment?, candidate: Attachment): Attachment
		if currentBest == nil then
			return candidate
		end
		if candidate:GetFullName() < currentBest:GetFullName() then
			return candidate
		end

		return currentBest
	end

	for _, taggedInstance in CollectionService:GetTagged(garageCarSpawnTag) do
		if taggedInstance:IsA("Attachment") and taggedInstance:IsDescendantOf(Workspace) then
			if activeGarage ~= nil and taggedInstance:IsDescendantOf(activeGarage) then
				activeGarageSpawn = selectEarlierAttachment(activeGarageSpawn, taggedInstance)
			else
				fallbackSpawn = selectEarlierAttachment(fallbackSpawn, taggedInstance)
			end
		end
	end

	if activeGarageSpawn ~= nil then
		return activeGarageSpawn
	end

	return fallbackSpawn
end

function Service:LoadCarsForPlayer(player: Player, garageModel: Model?): { Model }
	if player.Parent ~= Players then
		return {}
	end
	if self._profileService:IsLoaded(player) ~= true then
		return {}
	end

	local resolvedGarageModel = garageModel
	if resolvedGarageModel == nil then
		resolvedGarageModel = self._garageService:GetActiveGarage(player)
	end
	if resolvedGarageModel == nil or resolvedGarageModel.Parent == nil then
		self:_DestroySpawnRecord(player)
		return {}
	end

	self:_ClearDriveVehicle(player)
	self:_ClearDisplayVehicles(player)

	local vehicleState = self._profileService:GetGarageVehicles(player)
	if type(vehicleState) ~= "table" then
		return {}
	end

	local orderedVehicleNames = collectOrderedVehicleNames(vehicleState)
	if #orderedVehicleNames == 0 then
		return {}
	end

	local currentGarageKey = self._profileService:GetCurrentGarage(player)
	local garageKey = if type(currentGarageKey) == "string" and currentGarageKey ~= ""
		then currentGarageKey
		else defaultGarageKey
	local garageSlotLimit = resolveGarageSlotLimit(garageKey)
	local garageSlots = collectGarageSlots(resolvedGarageModel)
	if garageSlotLimit <= 0 or #garageSlots == 0 then
		return {}
	end

	local spawnedVehicles = {}
	local spawnCount = math.min(#orderedVehicleNames, garageSlotLimit, #garageSlots)

	for spawnIndex = 1, spawnCount do
		local vehicleName = orderedVehicleNames[spawnIndex]
		local slotAttachment = garageSlots[spawnIndex]
		local spawnedVehicle = self:_SpawnVehicleIntoSlot(player, vehicleName, slotAttachment, spawnIndex)
		if spawnedVehicle ~= nil then
			table.insert(spawnedVehicles, spawnedVehicle)
		end
	end

	if #spawnedVehicles == 0 then
		self._spawnRegistry:Clear(player)
		return {}
	end

	local record = self:_GetOrCreateSpawnRecord(player)
	record.DisplayVehicles = spawnedVehicles
	return spawnedVehicles
end

function Service:ClearCarsForPlayer(player: Player)
	self:_DestroySpawnRecord(player)
end

function Service:GetSpawnedCars(player: Player): { Model }
	local record = self._spawnRegistry:Get(player)
	if record == nil then
		return {}
	end

	local spawnedVehicles = table.create(#record.DisplayVehicles)
	for index, spawnedVehicle in ipairs(record.DisplayVehicles) do
		spawnedVehicles[index] = spawnedVehicle
	end

	return spawnedVehicles
end

function Service:SpawnDriveableCarFromPrompt(player: Player, prompt: ProximityPrompt): Model?
	if player.Parent ~= Players then
		return nil
	end

	local vehicleModel = resolveVehicleModelFromPrompt(prompt)
	if vehicleModel == nil then
		return nil
	end

	local vehicleName = vehicleModel.Name
	local vehicleTemplate = resolveVehicleTemplate(vehicleName)
	if vehicleTemplate == nil then
		return nil
	end

	local spawnAttachment = self:_ResolveGarageCarSpawn(player)
	if spawnAttachment == nil or spawnAttachment.Parent == nil then
		return nil
	end

	pcall(player.RequestStreamAroundAsync, player, spawnAttachment.WorldPosition)

	self:_ClearDriveVehicle(player)

	local driveableVehicle = vehicleTemplate:Clone()
	driveableVehicle.Name = tostring(player.UserId)
	driveableVehicle:SetAttribute("VehicleName", vehicleName)
	driveableVehicle:SetAttribute("OwnerUserId", player.UserId)
	driveableVehicle:SetAttribute("IsGarageDisplayVehicle", false)
	disableDriveCarPrompts(driveableVehicle)
	stabilizeVehicleSpawn(driveableVehicle, spawnAttachment.WorldCFrame, true)
	driveableVehicle.Parent = liveVehiclesFolder

	local primaryPart = ensurePrimaryPart(driveableVehicle)
	if primaryPart ~= nil then
		primaryPart.AssemblyLinearVelocity = Vector3.zero
		primaryPart.AssemblyAngularVelocity = Vector3.zero
	end

	local record = self:_GetOrCreateSpawnRecord(player)
	record.ActiveDriveVehicle = driveableVehicle
	self:_TrackActiveDriveVehicle(player, driveableVehicle)

	return driveableVehicle
end

function Service:SeatPlayerInDriveSeat(player: Player, vehicleModel: Model): boolean
	if player.Parent ~= Players then
		return false
	end

	local humanoid = resolveCharacterHumanoid(player)
	if humanoid == nil then
		return false
	end

	local driveSeat = resolveDriveSeat(vehicleModel)
	if driveSeat == nil or driveSeat.Parent == nil then
		return false
	end

	driveSeat:Sit(humanoid)
	return true
end

function Service:WaitForVehicleSpawnUnlock(vehicleModel: Model, timeoutSeconds: number?): boolean
	if vehicleModel.Parent == nil then
		return false
	end
	if isVehicleSpawnLocked(vehicleModel) ~= true then
		return true
	end

	local runningThread = coroutine.running()
	if runningThread == nil then
		return false
	end

	local didResume = false
	local connection: RBXScriptConnection?

	local function resumeWaiting(isUnlocked: boolean)
		if didResume == true then
			return
		end

		didResume = true
		if connection ~= nil then
			connection:Disconnect()
			connection = nil
		end

		task.spawn(runningThread, isUnlocked)
	end

	connection = vehicleModel:GetAttributeChangedSignal(vehicleSpawnLockedAttribute):Connect(function()
		if vehicleModel.Parent == nil then
			resumeWaiting(false)
			return
		end
		if isVehicleSpawnLocked(vehicleModel) ~= true then
			resumeWaiting(true)
		end
	end)

	task.delay(timeoutSeconds or spawnUnlockTimeout, function()
		if vehicleModel.Parent == nil then
			resumeWaiting(false)
			return
		end

		resumeWaiting(isVehicleSpawnLocked(vehicleModel) ~= true)
	end)

	return coroutine.yield()
end

function Service:Init(registry)
	self._profileService = registry:Get("PlayerProfileService")
	self._garageService = registry:Get("GarageService")
	self._spawnRegistry = SpawnRegistry.New()
	self._playerMaids = {}
	self._activeDriveVehicleMaids = {}
end

function Service:Start(_registry)
	self.Maid:Add(self._garageService.GarageLoaded:Connect(function(player: Player, garageModel: Model)
		task.spawn(function()
			self:LoadCarsForPlayer(player, garageModel)
		end)
	end))

	self.Maid:Add(self._garageService.GarageDestroyed:Connect(function(player: Player)
		self:_ClearDisplayVehicles(player)
	end))

	self.Maid:Add(self._profileService.ProfileReleased:Connect(function(player: Player)
		self:ClearCarsForPlayer(player)
		self:_UnbindPlayer(player)
	end))

	self.Maid:Add(Players.PlayerAdded:Connect(function(player: Player)
		self:_BindPlayer(player)
	end))

	self.Maid:Add(Players.PlayerRemoving:Connect(function(player: Player)
		self:ClearCarsForPlayer(player)
		self:_UnbindPlayer(player)
	end))

	for _, player in ipairs(Players:GetPlayers()) do
		self:_BindPlayer(player)

		local garageModel = self._garageService:GetActiveGarage(player)
		if garageModel ~= nil then
			task.spawn(function()
				self:LoadCarsForPlayer(player, garageModel)
			end)
		end
	end

	self.Maid:Add(function()
		for player in pairs(self._playerMaids) do
			self:_UnbindPlayer(player)
		end

		for _, player in ipairs(Players:GetPlayers()) do
			self:ClearCarsForPlayer(player)
		end

		table.clear(self._activeDriveVehicleMaids)
		self._spawnRegistry:Destroy()
	end)
end

return Service
