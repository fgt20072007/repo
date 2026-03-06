--!strict
--!native
--!optimize 2

--// Services
local Players = game:GetService("Players")
local PhysicsService = game:GetService("PhysicsService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

--// Dependencies
local appServer = script.Parent.Parent
local RunLoop = require(appServer.System.RunLoop)
local VehicleSystem = require(script.VehicleSystem)
local DrivingRewardSystem = require(script.DrivingRewardSystem)

--// Constants
local Replicator = Instance.new("UnreliableRemoteEvent")
Replicator.Name = "Vehicle_Replicator"
Replicator.Parent = ReplicatedStorage

local buffer_readf64 = buffer.readf64

local math_abs = math.abs

local vector3_dot = Vector3.zero.Dot

local SNAPSHOT_HZ = 1 / 20
local STREAMING_RADIUS = 2_048 ^ 2

--// System
PhysicsService:RegisterCollisionGroup("Vehicles")
PhysicsService:RegisterCollisionGroup("Character_Vehicles")

PhysicsService:CollisionGroupSetCollidable("Vehicles", "Vehicles", false)
PhysicsService:CollisionGroupSetCollidable("Vehicles", "Character_Vehicles", false)

local VehicleStates: { [number]: { Timestamp: number, Buffer: buffer } } = {}
Players.PlayerAdded:Connect(function(Player)
	Player.CharacterAdded:Connect(function(Character)
		for _, Descendant in Character:GetDescendants() do
			if Descendant:IsA("BasePart") then
				Descendant.CollisionGroup = "Character_Vehicles"
			end
		end
	end)
end)

Replicator.OnServerEvent:Connect(function(Player, VehicleBuffer: buffer)
	local LastState = VehicleStates[Player.UserId]

	local ServerTime = workspace:GetServerTimeNow()
	local ClientTime = buffer_readf64(VehicleBuffer, 0)
	if math_abs(ServerTime - ClientTime) > 1.0 then
		return
	end
	if LastState and ClientTime < LastState.Timestamp then
		return
	end

	if not LastState then
		LastState = {} :: any
		VehicleStates[Player.UserId] = LastState
	end

	LastState.Timestamp = ClientTime
	LastState.Buffer = VehicleBuffer
end)

--// Vehicle Replication (via RunLoop)
local loop = RunLoop.Get()
local acumTime = 0

loop:Bind("PostSimulation", "VehicleReplication", function(dt: number)
	acumTime += dt

	if acumTime < SNAPSHOT_HZ then
		return
	end
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
			if not Player.Character then
				continue
			end

			local LocalSnapshot = {}
			for userId, VehicleBuffer in Payload do
				if Player.UserId == userId then
					continue
				end

				local otherPlayer = Players:GetPlayerByUserId(userId)
				if not otherPlayer then
					continue
				end
				if not otherPlayer.Character then
					continue
				end

				local diff = Player.Character:GetPivot().Position - otherPlayer.Character:GetPivot().Position
				if vector3_dot(diff, diff) > STREAMING_RADIUS then
					continue
				end

				LocalSnapshot[userId] = VehicleBuffer
			end

			if next(LocalSnapshot) then
				Replicator:FireClient(Player, LocalSnapshot)
			end
		end
	end
end)

--// Build Vehicles
for _, Vehicle in workspace.Vehicles:GetChildren() do
	VehicleSystem:Build(Vehicle :: any)
end

--// Start Systems
DrivingRewardSystem:Start()