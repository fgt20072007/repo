--!strict
--!native
--!optimize 2

--// Services
local Players = game:GetService 'Players'
local RunService = game:GetService 'RunService'
local PhysicsService = game:GetService 'PhysicsService'
local ReplicatedStorage = game:GetService 'ReplicatedStorage'

--// Dependencies
local VehicleSystem = require(script.VehicleSystem)

--// Constants
local Replicator = Instance.new 'UnreliableRemoteEvent'
Replicator.Name = 'Vehicle_Replicator'
Replicator.Parent = ReplicatedStorage

local VEHICLE_COLLISION_GROUP = 'Vehicle_Collision'
local VEHICLE_DYNAMIC_GROUP = 'Vehicle_Dynamic'
local VEHICLE_SEAT_GROUP = 'Vehicle_Seat'
local CHARACTER_VEHICLE_GROUP = 'Character_Vehicles'

local buffer_readf64 = buffer.readf64
local buffer_readf32 = buffer.readf32

local math_abs = math.abs

local vector3_dot = Vector3.zero.Dot

local SNAPSHOT_HZ = 1/20
local STREAMING_RADIUS = 2_048^2
local VehiclesFolder = workspace:WaitForChild('Vehicles')

--// System
PhysicsService:RegisterCollisionGroup(VEHICLE_COLLISION_GROUP)
PhysicsService:RegisterCollisionGroup(VEHICLE_DYNAMIC_GROUP)
PhysicsService:RegisterCollisionGroup(VEHICLE_SEAT_GROUP)
PhysicsService:RegisterCollisionGroup(CHARACTER_VEHICLE_GROUP)

PhysicsService:CollisionGroupSetCollidable(VEHICLE_COLLISION_GROUP, VEHICLE_COLLISION_GROUP, true)
PhysicsService:CollisionGroupSetCollidable(VEHICLE_COLLISION_GROUP, VEHICLE_DYNAMIC_GROUP, false)
PhysicsService:CollisionGroupSetCollidable(VEHICLE_COLLISION_GROUP, VEHICLE_SEAT_GROUP, false)
PhysicsService:CollisionGroupSetCollidable(VEHICLE_COLLISION_GROUP, CHARACTER_VEHICLE_GROUP, false)

PhysicsService:CollisionGroupSetCollidable(VEHICLE_DYNAMIC_GROUP, VEHICLE_DYNAMIC_GROUP, false)
PhysicsService:CollisionGroupSetCollidable(VEHICLE_DYNAMIC_GROUP, VEHICLE_SEAT_GROUP, false)
PhysicsService:CollisionGroupSetCollidable(VEHICLE_DYNAMIC_GROUP, CHARACTER_VEHICLE_GROUP, false)

PhysicsService:CollisionGroupSetCollidable(VEHICLE_SEAT_GROUP, VEHICLE_SEAT_GROUP, false)

local VehicleStates: {[number]: {Timestamp: number, Buffer: buffer}} = {}
Players.PlayerAdded:Connect(function(Player)
	Player.CharacterAdded:Connect(function(Character)
		for _, Descendant in Character:GetDescendants() do
			if Descendant:IsA 'BasePart' then
				Descendant.CollisionGroup = CHARACTER_VEHICLE_GROUP
			end
		end
	end)
end)

Replicator.OnServerEvent:Connect(function(Player, VehicleBuffer: buffer)
	local LastState = VehicleStates[Player.UserId]

	local ServerTime = workspace:GetServerTimeNow()
	local ClientTime = buffer_readf64(VehicleBuffer, 0)
	if math_abs(ServerTime - ClientTime) > 1.0 then return end
	if LastState and ClientTime < LastState.Timestamp then return end

	if not LastState then
		LastState = {} :: any
		VehicleStates[Player.UserId] = LastState
	end

	LastState.Timestamp = ClientTime
	LastState.Buffer = VehicleBuffer

	local hasActiveSuspensionState = buffer_readf32(VehicleBuffer, 36) > 0
		or buffer_readf32(VehicleBuffer, 40) > 0
		or buffer_readf32(VehicleBuffer, 44) > 0
		or buffer_readf32(VehicleBuffer, 48) > 0
	if hasActiveSuspensionState then
		VehicleSystem:MarkClientSimulationTick(Player.UserId, ClientTime)
	end
end)

local acumTime = 0
RunService.PostSimulation:Connect(function(dt)
	acumTime += dt

	if acumTime < SNAPSHOT_HZ then return end
	acumTime %= SNAPSHOT_HZ

	local ServerTime = workspace:GetServerTimeNow()

	local Payload = {}
	for userId, State in VehicleStates do
		if ServerTime - State.Timestamp > 0.5 then
			VehicleStates[userId] = nil
			continue
		end

		Payload[userId] = State.Buffer
	end

	if next(Payload) then
		for _, Player in Players:GetPlayers() do
			if not Player.Character then continue end

			local LocalSnapshot = {}
			for userId, VehicleBuffer in Payload do
				if Player.UserId == userId then continue end

				local otherPlayer = Players:GetPlayerByUserId(userId)
				if not otherPlayer then continue end
				if not otherPlayer.Character then continue end

				local diff = Player.Character:GetPivot().Position - otherPlayer.Character:GetPivot().Position
				if vector3_dot(diff, diff) > STREAMING_RADIUS then continue end

				LocalSnapshot[userId] = VehicleBuffer
			end

			if next(LocalSnapshot) then
				Replicator:FireClient(Player, LocalSnapshot)
			end
		end
	end
end)

VehicleSystem:Init()

local function registerVehicle(vehicle: Instance)
	if not vehicle:IsA('Model') then
		return
	end

	VehicleSystem:Build(vehicle)
end

for _, Vehicle in VehiclesFolder:GetChildren() do
	registerVehicle(Vehicle)
end

VehiclesFolder.ChildAdded:Connect(registerVehicle)
