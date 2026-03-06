--!strict
--!native
--!optimize 2

--// Services
local Players = game:GetService("Players")
local ServerScriptService = game:GetService("ServerScriptService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

--// Dependencies
local appServer = ServerScriptService:WaitForChild("App"):WaitForChild("Server")
local appShared = ReplicatedStorage:WaitForChild("App"):WaitForChild("Shared")
local servicesFolder = appServer:WaitForChild("Services")
local PlayerProfileService = require(
	servicesFolder:WaitForChild("PlayerProfileService")
) :: any

local RunLoop = require(appServer:WaitForChild("System"):WaitForChild("RunLoop"))
local Net = require(appShared.Net) :: any
local Config = require(appShared.Data.Driving.Rewards)

--// Constants — Driving
local TICK_RATE: number = Config.Driving.TickRate
local MIN_SPEED_THRESHOLD: number = Config.Driving.MinSpeedThreshold

local XP_PER_DRIVE_SECOND: number = Config.Driving.XP.PerDriveSecond
local XP_PUBLISH_INTERVAL: number = Config.Driving.XP.PublishInterval

local MONEY_PER_STUD: number = Config.Driving.Money.PerStud
local MONEY_PUBLISH_INTERVAL: number = Config.Driving.Money.PublishInterval

--// Constants — PlayTime
local PLAYTIME_MONEY_PER_INTERVAL: number = Config.PlayTime.Money.PerInterval
local PLAYTIME_PUBLISH_INTERVAL: number = Config.PlayTime.Money.PublishInterval

--// Types
type DriverState = {
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

type PlayTimeState = {
	Timer: number,
}

--// State
local activeDrivers: { [Player]: DriverState } = {}
local activePlayers: { [Player]: PlayTimeState } = {}

--// Private — Driving
local function flushDriver(player: Player, state: DriverState)
	local driveSeconds = state.AccumTime
	local studsDriven = state.AccumStuds

	state.AccumTime = 0
	state.AccumStuds = 0
	state.FlushTimer = 0

	if driveSeconds <= 0 and studsDriven <= 0 then
		return
	end

	local stats = PlayerProfileService:GetValue(player, "Stats")
	if stats == nil then
		return
	end

	stats.DriveSeconds += driveSeconds
	stats.StudsDriven += studsDriven
	PlayerProfileService:SetValue(player, "Stats", stats)

	local moneyDelta: number = studsDriven * MONEY_PER_STUD
	if moneyDelta > 0 then
		local economy = PlayerProfileService:GetValue(player, "Economy")
		if economy then
			economy.Money += moneyDelta
			PlayerProfileService:SetValue(player, "Economy", economy)
			state.MoneyPending += moneyDelta
		end
	end

	local xpDelta: number = driveSeconds * XP_PER_DRIVE_SECOND
	if xpDelta > 0 then
		local profile = PlayerProfileService:GetValue(player, "Profile")
		if profile then
			profile.XP += xpDelta
			PlayerProfileService:SetValue(player, "Profile", profile)
			state.XPPending += xpDelta
		end
	end
end

local function startTracking(player: Player, chassis: Model)
	if activeDrivers[player] then
		return
	end

	local primary = chassis.PrimaryPart
	if not primary then
		return
	end

	activeDrivers[player] = {
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
end

local function stopTracking(player: Player)
	local state = activeDrivers[player]
	if not state then
		return
	end

	activeDrivers[player] = nil
	flushDriver(player, state)

	if state.XPPending > 0 then
		Net.DrivingXPReward.Fire(player, math.floor(state.XPPending))
	end

	if state.MoneyPending > 0 then
		Net.DrivingMoneyReward.Fire(player, math.floor(state.MoneyPending * 100) / 100)
	end
end

local function bindSeat(seat: VehicleSeat, chassis: Model)
	seat:GetPropertyChangedSignal("Occupant"):Connect(function()
		local occupant = seat.Occupant
		if occupant then
			local player = Players:GetPlayerFromCharacter(occupant.Parent :: Model)
			if player then
				startTracking(player, chassis)
			end
		else
			for trackedPlayer, state in activeDrivers do
				if state.Chassis == chassis then
					stopTracking(trackedPlayer)
					break
				end
			end
		end
	end)
end

--// Private — PlayTime
local function startPlayTimeTracking(player: Player)
	activePlayers[player] = { Timer = 0 }
end

local function stopPlayTimeTracking(player: Player)
	activePlayers[player] = nil
end

--// Public
local DrivingRewardSystem = {}

function DrivingRewardSystem:Start()
	local loop = RunLoop.Get()

	local pendingRemoval: { Player } = {}

	loop:Bind("Heartbeat", "DrivingReward", function(dt: number)
		--// Driving rewards
		for player, state in activeDrivers do
			if not player.Parent or not state.Primary:IsDescendantOf(workspace) then
				table.insert(pendingRemoval, player)
				continue
			end

			local currentPosition = state.Primary.Position
			local displacement = (currentPosition - state.LastPosition).Magnitude
			state.LastPosition = currentPosition

			local speed = state.Primary.AssemblyLinearVelocity.Magnitude
			if speed >= MIN_SPEED_THRESHOLD then
				state.AccumTime += dt
				state.AccumStuds += displacement
			end

			state.FlushTimer += dt
			if state.FlushTimer >= TICK_RATE then
				flushDriver(player, state)
			end

			state.XPPublishTimer += dt
			if state.XPPublishTimer >= XP_PUBLISH_INTERVAL and state.XPPending > 0 then
				Net.DrivingXPReward.Fire(player, math.floor(state.XPPending))
				state.XPPending = 0
				state.XPPublishTimer = 0
			end

			state.MoneyPublishTimer += dt
			if state.MoneyPublishTimer >= MONEY_PUBLISH_INTERVAL and state.MoneyPending > 0 then
				Net.DrivingMoneyReward.Fire(player, math.floor(state.MoneyPending * 100) / 100)
				state.MoneyPending = 0
				state.MoneyPublishTimer = 0
			end
		end

		for _, player in pendingRemoval do
			stopTracking(player)
		end
		table.clear(pendingRemoval)

		--// PlayTime rewards
		for player, state in activePlayers do
			if not player.Parent then
				continue
			end

			state.Timer += dt
			if state.Timer >= PLAYTIME_PUBLISH_INTERVAL then
				state.Timer = 0

				local economy = PlayerProfileService:GetValue(player, "Economy")
				if economy then
					economy.Money += PLAYTIME_MONEY_PER_INTERVAL
					PlayerProfileService:SetValue(player, "Economy", economy)
					Net.PlayTimeMoneyReward.Fire(player, PLAYTIME_MONEY_PER_INTERVAL)
				end
			end
		end
	end)

	local vehicles = workspace:FindFirstChild("Vehicles")
	if not vehicles then
		return
	end

	for _, chassis in vehicles:GetChildren() do
		local seats = chassis:FindFirstChild("Seats")
		if not seats then
			continue
		end

		local drive = seats:FindFirstChildOfClass("VehicleSeat")
		if drive then
			bindSeat(drive, chassis)
		end
	end

	for _, player in Players:GetPlayers() do
		startPlayTimeTracking(player)
	end

	Players.PlayerAdded:Connect(function(player: Player)
		startPlayTimeTracking(player)
	end)

	Players.PlayerRemoving:Connect(function(player: Player)
		stopTracking(player)
		stopPlayTimeTracking(player)
	end)
end

return DrivingRewardSystem
