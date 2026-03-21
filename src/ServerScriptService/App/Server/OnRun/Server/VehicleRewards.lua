--!strict
--!native
--!optimize 2

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")

local appServer = ServerScriptService:WaitForChild("App"):WaitForChild("Server")
local appShared = ReplicatedStorage:WaitForChild("App"):WaitForChild("Shared")
local servicesFolder = appServer:WaitForChild("Services")

local PlayerProfileService = require(servicesFolder:WaitForChild("PlayerProfileService"))
local RunLoop = require(appServer:WaitForChild("System"):WaitForChild("RunLoop"))
local Maid = require(appShared:WaitForChild("Util"):WaitForChild("Maid"))
local Net = require(appShared:WaitForChild("Net")) :: any
local Config = require(appShared:WaitForChild("Data"):WaitForChild("Driving"):WaitForChild("Rewards"))

local TICK_RATE: number = Config.Driving.TickRate
local MIN_SPEED_THRESHOLD: number = Config.Driving.MinSpeedThreshold

local XP_PER_DRIVE_SECOND: number = Config.Driving.XP.PerDriveSecond
local XP_PUBLISH_INTERVAL: number = Config.Driving.XP.PublishInterval

local MONEY_PER_STUD: number = Config.Driving.Money.PerStud
local MONEY_PUBLISH_INTERVAL: number = Config.Driving.Money.PublishInterval

type DriverState = {
	Player: Player,
	Chassis: Model,
	Primary: BasePart,
	AccumTime: number,
	AccumStuds: number,
	FlushTimer: number,
	LastPosition: Vector3,
	XPPublishTimer: number,
	XPPending: number,
	MoneyPublishTimer: number,
	MoneyPending: number,
}

local activeByPlayer: { [Player]: DriverState } = {}
local activeByChassis: { [Model]: DriverState } = {}
local pendingRemoval: { DriverState } = {}

local initialized = false
local runtimeMaid = nil :: any

local function isProfileServiceReady(): boolean
	return PlayerProfileService._isStarted == true
end

local function roundMoney(value: number): number
	return math.floor(value * 100) / 100
end

local function commitDriveStats(player: Player, driveSeconds: number, studsDriven: number): boolean
	local updated = PlayerProfileService:UpdateStats(player, function(stats)
		stats.DriveSeconds += driveSeconds
		stats.StudsDriven += studsDriven
		return stats
	end)

	return updated == true
end

local function commitDrivingMoney(player: Player, studsDriven: number): number
	local moneyDelta = studsDriven * MONEY_PER_STUD
	if moneyDelta <= 0 then
		return 0
	end

	local updated = PlayerProfileService:UpdateEconomy(player, function(economy)
		economy.Money += moneyDelta
		return economy
	end)

	if updated ~= true then
		return 0
	end

	return moneyDelta
end

local function commitDrivingXP(player: Player, driveSeconds: number): number
	local xpDelta = driveSeconds * XP_PER_DRIVE_SECOND
	if xpDelta <= 0 then
		return 0
	end

	local updated = PlayerProfileService:UpdateProfile(player, function(profile)
		profile.XP += xpDelta
		return profile
	end)

	if updated ~= true then
		return 0
	end

	return xpDelta
end

local function flushDriver(state: DriverState)
	local driveSeconds = state.AccumTime
	local studsDriven = state.AccumStuds
	if driveSeconds <= 0 and studsDriven <= 0 then
		return
	end
	if isProfileServiceReady() ~= true then
		return
	end
	if commitDriveStats(state.Player, driveSeconds, studsDriven) ~= true then
		return
	end

	state.AccumTime = 0
	state.AccumStuds = 0

	state.MoneyPending += commitDrivingMoney(state.Player, studsDriven)
	state.XPPending += commitDrivingXP(state.Player, driveSeconds)
end

local function detachState(state: DriverState)
	activeByPlayer[state.Player] = nil
	activeByChassis[state.Chassis] = nil
end

local function publishPendingRewards(state: DriverState, force: boolean)
	if force == true or (state.XPPublishTimer >= XP_PUBLISH_INTERVAL and state.XPPending > 0) then
		if state.XPPending > 0 then
			Net.DrivingXPReward.Fire(state.Player, math.floor(state.XPPending))
			state.XPPending = 0
		end
		state.XPPublishTimer = 0
	end

	if force == true or (state.MoneyPublishTimer >= MONEY_PUBLISH_INTERVAL and state.MoneyPending > 0) then
		if state.MoneyPending > 0 then
			Net.DrivingMoneyReward.Fire(state.Player, roundMoney(state.MoneyPending))
			state.MoneyPending = 0
		end
		state.MoneyPublishTimer = 0
	end
end

local function stopState(state: DriverState)
	detachState(state)
	flushDriver(state)
	publishPendingRewards(state, true)
end

local function resolveState(player: Player?, chassis: Model?): DriverState?
	if chassis ~= nil then
		local state = activeByChassis[chassis]
		if state ~= nil then
			return state
		end
	end

	if player ~= nil then
		return activeByPlayer[player]
	end

	return nil
end

local function onHeartbeat(dt: number)
	for player, state in activeByPlayer do
		if player.Parent ~= Players or state.Chassis.Parent == nil or state.Primary:IsDescendantOf(workspace) ~= true then
			table.insert(pendingRemoval, state)
			continue
		end

		local currentPosition = state.Primary.Position
		local displacement = (currentPosition - state.LastPosition).Magnitude
		state.LastPosition = currentPosition

		if state.Primary.AssemblyLinearVelocity.Magnitude >= MIN_SPEED_THRESHOLD then
			state.AccumTime += dt
			state.AccumStuds += displacement
		end

		state.FlushTimer += dt
		if state.FlushTimer >= TICK_RATE then
			state.FlushTimer %= TICK_RATE
			flushDriver(state)
		end

		state.XPPublishTimer += dt
		if state.XPPublishTimer >= XP_PUBLISH_INTERVAL then
			publishPendingRewards(state, false)
		end

		state.MoneyPublishTimer += dt
		if state.MoneyPublishTimer >= MONEY_PUBLISH_INTERVAL then
			publishPendingRewards(state, false)
		end
	end

	for _, state in pendingRemoval do
		if activeByPlayer[state.Player] == state then
			stopState(state)
		end
	end
	table.clear(pendingRemoval)
end

local VehicleRewards = {}

function VehicleRewards:Init()
	if initialized == true then
		return
	end

	initialized = true
	runtimeMaid = Maid.New()

	runtimeMaid:Add(Players.PlayerRemoving:Connect(function(player: Player)
		local state = activeByPlayer[player]
		if state == nil then
			return
		end

		stopState(state)
	end))

	local unbind = RunLoop.Get():Bind("Heartbeat", "VehicleRewards", onHeartbeat)
	runtimeMaid:Add(unbind)
end

function VehicleRewards:StartDriving(player: Player, chassis: Model)
	if initialized ~= true then
		self:Init()
	end

	local primary = chassis.PrimaryPart
	if primary == nil then
		return
	end

	local playerState = activeByPlayer[player]
	if playerState ~= nil and playerState.Chassis ~= chassis then
		stopState(playerState)
	end

	local chassisState = activeByChassis[chassis]
	if chassisState ~= nil and chassisState.Player ~= player then
		stopState(chassisState)
	end

	local existingState = activeByPlayer[player]
	if existingState ~= nil and existingState.Chassis == chassis then
		existingState.Primary = primary
		existingState.LastPosition = primary.Position
		return
	end

	local state: DriverState = {
		Player = player,
		Chassis = chassis,
		Primary = primary,
		AccumTime = 0,
		AccumStuds = 0,
		FlushTimer = 0,
		LastPosition = primary.Position,
		XPPublishTimer = 0,
		XPPending = 0,
		MoneyPublishTimer = 0,
		MoneyPending = 0,
	}

	activeByPlayer[player] = state
	activeByChassis[chassis] = state
end

function VehicleRewards:StopDriving(player: Player?, chassis: Model?)
	local state = resolveState(player, chassis)
	if state == nil then
		return
	end
	if player ~= nil and state.Player ~= player then
		return
	end
	if chassis ~= nil and state.Chassis ~= chassis then
		return
	end

	stopState(state)
end

return table.freeze(VehicleRewards)