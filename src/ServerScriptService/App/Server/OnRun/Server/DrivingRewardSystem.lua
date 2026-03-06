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

--// Constants
local TICK_RATE: number = Config.TickRate
local MONEY_PER_STUD: number = Config.MoneyPerStud
local XP_PER_DRIVE_SECOND: number = Config.XPPerDriveSecond
local MIN_SPEED_THRESHOLD: number = Config.MinSpeedThreshold

--// Types
type DriverState = {
	Chassis: Model,
	Primary: BasePart,
	AccumTime: number,
	AccumStuds: number,
	FlushTimer: number,
	LastPosition: Vector3,
}

--// State
local activeDrivers: { [Player]: DriverState } = {}

--// Private
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
		else
			moneyDelta = 0
		end
	end

	local xpDelta: number = driveSeconds * XP_PER_DRIVE_SECOND
	if xpDelta > 0 then
		local profile = PlayerProfileService:GetValue(player, "Profile")
		if profile then
			profile.XP += xpDelta
			PlayerProfileService:SetValue(player, "Profile", profile)
		else
			xpDelta = 0
		end
	end

	if moneyDelta > 0 or xpDelta > 0 then
		Net.DrivingReward.Fire(player, moneyDelta, xpDelta)
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
	}
end

local function stopTracking(player: Player)
	local state = activeDrivers[player]
	if not state then
		return
	end

	activeDrivers[player] = nil
	flushDriver(player, state)
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

--// Public
local DrivingRewardSystem = {}

function DrivingRewardSystem:Start()
	local loop = RunLoop.Get()

	local pendingRemoval: { Player } = {}

	loop:Bind("Heartbeat", "DrivingReward", function(dt: number)
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
		end

		for _, player in pendingRemoval do
			stopTracking(player)
		end
		table.clear(pendingRemoval)
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

	Players.PlayerRemoving:Connect(function(player: Player)
		stopTracking(player)
	end)
end

return DrivingRewardSystem