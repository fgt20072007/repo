--!strict
--!native
--!optimize 2

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")

local appServer = ServerScriptService:WaitForChild("App"):WaitForChild("Server")
local appShared = ReplicatedStorage:WaitForChild("App"):WaitForChild("Shared")

local RunLoop = require(appServer:WaitForChild("System"):WaitForChild("RunLoop"))
local Maid = require(appShared:WaitForChild("Util"):WaitForChild("Maid"))
local Net = require(appShared:WaitForChild("Net")) :: any
local drivingRewardsConfig = require(appShared:WaitForChild("Data"):WaitForChild("Driving"):WaitForChild("Rewards"))

local fuelAmountAttribute = "FuelAmount"
local fuelCapacityAttribute = "FuelCapacity"
local fuelPercentAttribute = "FuelPercent"
local fuelConsumptionPerStudAttribute = "FuelConsumptionPerStud"

local minSpeedThreshold: number = drivingRewardsConfig.Driving.MinSpeedThreshold
local fuelPublishInterval = 0.2

type FuelSpec = {
	capacity: number,
	consumptionPerStud: number,
}

type DriverFuelState = {
	player: Player,
	chassis: Model,
	primaryPart: BasePart,
	lastPosition: Vector3,
	publishTimer: number,
	hasPendingPublish: boolean,
}

local stateByPlayer: { [Player]: DriverFuelState } = {}
local stateByChassis: { [Model]: DriverFuelState } = {}
local statesPendingRemoval: { DriverFuelState } = {}

local isInitialized = false
local runtimeMaid = nil :: any

local function clampFuelAmount(fuelAmount: number, fuelCapacity: number): number
	return math.clamp(fuelAmount, 0, fuelCapacity)
end

local function resolveFuelSpec(chassis: Model): FuelSpec
	local dataModule = chassis:FindFirstChild("Data")
	if dataModule == nil or dataModule:IsA("ModuleScript") ~= true then
		return {
			capacity = 0,
			consumptionPerStud = 0,
		}
	end

	local vehicleData = require(dataModule)
	local fuelData = if type(vehicleData) == "table" then vehicleData.Fuel else nil
	if type(fuelData) ~= "table" then
		return {
			capacity = 0,
			consumptionPerStud = 0,
		}
	end

	local fuelCapacity = if type(fuelData.Capacity) == "number" and fuelData.Capacity > 0 then fuelData.Capacity else 0
	local consumptionPerStud =
		if type(fuelData.ConsumptionPerStud) == "number" and fuelData.ConsumptionPerStud >= 0
		then fuelData.ConsumptionPerStud
		else 0

	return {
		capacity = fuelCapacity,
		consumptionPerStud = consumptionPerStud,
	}
end

local function applyFuelAttributes(
	chassis: Model,
	fuelAmount: number,
	fuelCapacity: number,
	consumptionPerStud: number
): number
	local clampedFuelAmount = clampFuelAmount(fuelAmount, fuelCapacity)
	local fuelPercent = if fuelCapacity > 0 then clampedFuelAmount / fuelCapacity else 0

	chassis:SetAttribute(fuelAmountAttribute, clampedFuelAmount)
	chassis:SetAttribute(fuelCapacityAttribute, fuelCapacity)
	chassis:SetAttribute(fuelPercentAttribute, fuelPercent)
	chassis:SetAttribute(fuelConsumptionPerStudAttribute, consumptionPerStud)

	return clampedFuelAmount
end

local function publishFuelState(player: Player, chassis: Model)
	local fuelAmount = chassis:GetAttribute(fuelAmountAttribute)
	local fuelCapacity = chassis:GetAttribute(fuelCapacityAttribute)
	local fuelPercent = chassis:GetAttribute(fuelPercentAttribute)

	if type(fuelAmount) ~= "number" or type(fuelCapacity) ~= "number" or type(fuelPercent) ~= "number" then
		Net.VehicleFuelChanged.Fire(player, 0, 0, 0)
		return
	end

	Net.VehicleFuelChanged.Fire(player, fuelAmount, fuelCapacity, fuelPercent)
end

local function publishNoActiveVehicle(player: Player)
	Net.VehicleFuelChanged.Fire(player, 0, 0, 0)
end

local function detachFuelState(driverFuelState: DriverFuelState)
	stateByPlayer[driverFuelState.player] = nil
	stateByChassis[driverFuelState.chassis] = nil
end

local function stopFuelState(driverFuelState: DriverFuelState)
	detachFuelState(driverFuelState)
	publishNoActiveVehicle(driverFuelState.player)
end

local function resolveFuelState(player: Player?, chassis: Model?): DriverFuelState?
	if chassis ~= nil then
		local chassisFuelState = stateByChassis[chassis]
		if chassisFuelState ~= nil then
			return chassisFuelState
		end
	end

	if player ~= nil then
		return stateByPlayer[player]
	end

	return nil
end

local function consumeFuel(chassis: Model, fuelToConsume: number): number
	local fuelAmount = chassis:GetAttribute(fuelAmountAttribute)
	local fuelCapacity = chassis:GetAttribute(fuelCapacityAttribute)
	local consumptionPerStud = chassis:GetAttribute(fuelConsumptionPerStudAttribute)

	if type(fuelAmount) ~= "number" or type(fuelCapacity) ~= "number" or type(consumptionPerStud) ~= "number" then
		return 0
	end

	return applyFuelAttributes(chassis, fuelAmount - fuelToConsume, fuelCapacity, consumptionPerStud)
end

local function flushFuelUpdates(driverFuelState: DriverFuelState, forcePublish: boolean)
	if forcePublish ~= true and driverFuelState.hasPendingPublish ~= true then
		return
	end

	driverFuelState.publishTimer = 0
	driverFuelState.hasPendingPublish = false
	publishFuelState(driverFuelState.player, driverFuelState.chassis)
end

local function onHeartbeat(deltaTime: number)
	for player, driverFuelState in stateByPlayer do
		if player.Parent ~= Players
			or driverFuelState.chassis.Parent == nil
			or driverFuelState.primaryPart:IsDescendantOf(workspace) ~= true
		then
			table.insert(statesPendingRemoval, driverFuelState)
			continue
		end

		local currentPosition = driverFuelState.primaryPart.Position
		local displacement = (currentPosition - driverFuelState.lastPosition).Magnitude
		driverFuelState.lastPosition = currentPosition

		if driverFuelState.primaryPart.AssemblyLinearVelocity.Magnitude >= minSpeedThreshold and displacement > 0 then
			local fuelAmount = driverFuelState.chassis:GetAttribute(fuelAmountAttribute)
			local consumptionPerStud = driverFuelState.chassis:GetAttribute(fuelConsumptionPerStudAttribute)

			if type(fuelAmount) == "number" and type(consumptionPerStud) == "number" then
				local fuelToConsume = displacement * consumptionPerStud
				if fuelAmount > 0 and fuelToConsume > 0 then
					local nextFuelAmount = consumeFuel(driverFuelState.chassis, fuelToConsume)
					if nextFuelAmount ~= fuelAmount then
						driverFuelState.hasPendingPublish = true
					end
				end
			end
		end

		driverFuelState.publishTimer += deltaTime
		if driverFuelState.publishTimer >= fuelPublishInterval then
			flushFuelUpdates(driverFuelState, false)
		end
	end

	for _, driverFuelState in statesPendingRemoval do
		if stateByPlayer[driverFuelState.player] == driverFuelState then
			stopFuelState(driverFuelState)
		end
	end
	table.clear(statesPendingRemoval)
end

local VehicleFuel = {}

function VehicleFuel:Init()
	if isInitialized == true then
		return
	end

	isInitialized = true
	runtimeMaid = Maid.New()

	runtimeMaid:Add(Players.PlayerRemoving:Connect(function(player: Player)
		local driverFuelState = stateByPlayer[player]
		if driverFuelState == nil then
			return
		end

		stopFuelState(driverFuelState)
	end))

	local unbind = RunLoop.Get():Bind("Heartbeat", "VehicleFuel", onHeartbeat)
	runtimeMaid:Add(unbind)
end

function VehicleFuel:PrepareChassis(chassis: Model)
	if isInitialized ~= true then
		self:Init()
	end

	local fuelSpec = resolveFuelSpec(chassis)
	local existingFuelAmount = chassis:GetAttribute(fuelAmountAttribute)
	local startingFuelAmount = fuelSpec.capacity

	if type(existingFuelAmount) == "number" then
		startingFuelAmount = existingFuelAmount
	end

	applyFuelAttributes(chassis, startingFuelAmount, fuelSpec.capacity, fuelSpec.consumptionPerStud)
end

function VehicleFuel:GetFuelState(chassis: Model): (number, number, number)
	self:PrepareChassis(chassis)

	local fuelAmount = chassis:GetAttribute(fuelAmountAttribute)
	local fuelCapacity = chassis:GetAttribute(fuelCapacityAttribute)
	local fuelPercent = chassis:GetAttribute(fuelPercentAttribute)

	return if type(fuelAmount) == "number" then fuelAmount else 0,
	if type(fuelCapacity) == "number" then fuelCapacity else 0,
	if type(fuelPercent) == "number" then fuelPercent else 0
end

function VehicleFuel:RefuelByPercent(chassis: Model, percentDelta: number): number
	self:PrepareChassis(chassis)

	local fuelAmount = chassis:GetAttribute(fuelAmountAttribute)
	local fuelCapacity = chassis:GetAttribute(fuelCapacityAttribute)
	local consumptionPerStud = chassis:GetAttribute(fuelConsumptionPerStudAttribute)

	if type(fuelAmount) ~= "number" or type(fuelCapacity) ~= "number" or type(consumptionPerStud) ~= "number" then
		return 0
	end

	local nextFuelAmount =
		applyFuelAttributes(chassis, fuelAmount + fuelCapacity * (percentDelta / 100), fuelCapacity, consumptionPerStud)

	local driverFuelState = stateByChassis[chassis]
	if driverFuelState ~= nil then
		flushFuelUpdates(driverFuelState, true)
	end

	return nextFuelAmount
end

function VehicleFuel:RefuelToPercent(chassis: Model, targetPercent: number): number
	self:PrepareChassis(chassis)

	local fuelCapacity = chassis:GetAttribute(fuelCapacityAttribute)
	local consumptionPerStud = chassis:GetAttribute(fuelConsumptionPerStudAttribute)

	if type(fuelCapacity) ~= "number" or type(consumptionPerStud) ~= "number" then
		return 0
	end

	local nextFuelAmount =
		applyFuelAttributes(chassis, fuelCapacity * (targetPercent / 100), fuelCapacity, consumptionPerStud)

	local driverFuelState = stateByChassis[chassis]
	if driverFuelState ~= nil then
		flushFuelUpdates(driverFuelState, true)
	end

	return nextFuelAmount
end

function VehicleFuel:RefuelActiveVehicleByPercent(player: Player, percentDelta: number): number
	local driverFuelState = stateByPlayer[player]
	if driverFuelState == nil then
		return 0
	end

	return self:RefuelByPercent(driverFuelState.chassis, percentDelta)
end

function VehicleFuel:RefuelActiveVehicleToPercent(player: Player, targetPercent: number): number
	local driverFuelState = stateByPlayer[player]
	if driverFuelState == nil then
		return 0
	end

	return self:RefuelToPercent(driverFuelState.chassis, targetPercent)
end

function VehicleFuel:StartDriving(player: Player, chassis: Model)
	if isInitialized ~= true then
		self:Init()
	end

	local primaryPart = chassis.PrimaryPart
	if primaryPart == nil then
		return
	end

	self:PrepareChassis(chassis)

	local playerFuelState = stateByPlayer[player]
	if playerFuelState ~= nil and playerFuelState.chassis ~= chassis then
		stopFuelState(playerFuelState)
	end

	local chassisFuelState = stateByChassis[chassis]
	if chassisFuelState ~= nil and chassisFuelState.player ~= player then
		stopFuelState(chassisFuelState)
	end

	local existingFuelState = stateByPlayer[player]
	if existingFuelState ~= nil and existingFuelState.chassis == chassis then
		existingFuelState.primaryPart = primaryPart
		existingFuelState.lastPosition = primaryPart.Position
		flushFuelUpdates(existingFuelState, true)
		return
	end

	local nextFuelState: DriverFuelState = {
		player = player,
		chassis = chassis,
		primaryPart = primaryPart,
		lastPosition = primaryPart.Position,
		publishTimer = 0,
		hasPendingPublish = false,
	}

	stateByPlayer[player] = nextFuelState
	stateByChassis[chassis] = nextFuelState
	flushFuelUpdates(nextFuelState, true)
end

function VehicleFuel:StopDriving(player: Player?, chassis: Model?)
	local driverFuelState = resolveFuelState(player, chassis)
	if driverFuelState == nil then
		return
	end
	if player ~= nil and driverFuelState.player ~= player then
		return
	end
	if chassis ~= nil and driverFuelState.chassis ~= chassis then
		return
	end

	stopFuelState(driverFuelState)
end

return table.freeze(VehicleFuel)