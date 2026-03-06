--!strict
--!native
--!optimize 2

--// Services
local Players = game:GetService 'Players'
local RunService = game:GetService 'RunService'
local PhysicsService = game:GetService 'PhysicsService'
local ReplicatedStorage = game:GetService 'ReplicatedStorage'

--// Dependencies
local Util = require(script.Parent.Packages.Raw.Util)
local Units = require(script.Parent.Packages.Raw.Units)
local Vehicle = require(script.Vehicle) 

--// Constants
local buffer_readu16 = buffer.readu16
local buffer_readf32 = buffer.readf32
local buffer_readf64 = buffer.readf64

local buffer_writeu16 = buffer.writeu16
local buffer_writef32 = buffer.writef32
local buffer_writef64 = buffer.writef64

local table_create = table.create
local table_insert = table.insert
local table_remove = table.remove

local math_max = math.max
local math_lerp = math.lerp
local math_round = math.round

local Client = Players.LocalPlayer :: Player
local Replicator = ReplicatedStorage:WaitForChild 'Vehicle_Replicator' :: UnreliableRemoteEvent

local UI = script.UI
local UIStats = UI.Stats
local UISpeed = UIStats.Speed
local UIRPM = UIStats.RPM
local UIGear = UIStats.Gear

UI.Parent = Client:WaitForChild 'PlayerGui'

local WHEEL_ORDERS = {['RL'] = 1, ['RR'] = 2, ['FL'] = 3, ['FR'] = 4}

local MAX_HISTORY_SIZE = 10
local INTERPOLATION_DELAY = 0.1

local VehicleHistories: {
	[Player]: {
		Frame: number,
		State: {[string]: number},
		Root: BasePart,
		Wheels: Folder,
		HubAttachments: {Attachment},
		Snapshots: {{[string]: number}}}
} = {}

local VehicleFrame = 0
local VehicleBuffer = buffer.create(52)

local VehicleClass = Vehicle()
VehicleClass:StartInputs()

--// Structure
local Structure = {}

function Structure:Set(Chassis: Model)
	if not Chassis then
		if VehicleClass.Root then
			for _, Child in VehicleClass.Root:GetChildren() do
				if not Child:IsA 'Sound' then continue end

				Child.PlaybackSpeed = 0
				Child.Volume = 0
				Child:Stop()
			end
		end
		
		VehicleClass:SetChassis(nil)
		UI.Enabled = false
		
		return
	end
	
	local dataModule = Chassis:WaitForChild 'Data' :: any
	local Data = require(dataModule) :: any
	
	local PrimaryPart = Chassis:WaitForChild 'Primary'
	for _, Child in PrimaryPart:GetChildren() do
		if not Child:IsA 'Sound' then continue end
		
		Child.PlaybackSpeed = 0
		Child.Volume = 0
		Child:Play()
	end

	local Wheels = Chassis:WaitForChild 'Wheels'

	VehicleClass:SetSuspension(1, Data.RearStiffness, Data.RearDamping, Data.RearMinLength, Data.RearFreeLength, Data.RearMaxLength)
	VehicleClass:SetSuspension(2, Data.RearStiffness, Data.RearDamping, Data.RearMinLength, Data.RearFreeLength, Data.RearMaxLength)
	VehicleClass:SetSuspension(3, Data.FrontStiffness, Data.FrontDamping, Data.FrontMinLength, Data.FrontFreeLength, Data.FrontMaxLength)
	VehicleClass:SetSuspension(4, Data.FrontStiffness, Data.FrontDamping, Data.FrontMinLength, Data.FrontFreeLength, Data.FrontMaxLength)

	VehicleClass:SetAntiroll(1, Data.RearAntirollStiffness)
	VehicleClass:SetAntiroll(2, Data.RearAntirollStiffness)
	VehicleClass:SetAntiroll(3, Data.FrontAntirollStiffness)
	VehicleClass:SetAntiroll(4, Data.FrontAntirollStiffness)

	VehicleClass:SetSteering(Data)
	VehicleClass:SetChassis(Chassis)
	VehicleClass:SetSystems(Data)

	for _, Child in Wheels:GetChildren() :: {Model} do
		VehicleClass:SetWheel(WHEEL_ORDERS[Child.Name], Child)
	end

	VehicleClass:SetBrakes(Data)
	VehicleClass:SetEngine(Data)
	VehicleClass:SetDifferential(Data.DifferentialBias, Data.DifferentialPreload, Data.DifferentialMaxTorque, Data.TopSpeeds, Data.ShiftTime)

	UI.Enabled = true
end

function Structure:Replicate(Payload: {[number]: buffer})
	for userId, bufferData in Payload do
		local Player = Players:GetPlayerByUserId(userId)
		if not Player then continue end
		
		local Character = Player.Character
		if not Character then return end

		local Humanoid = Character:FindFirstChildOfClass 'Humanoid'
		if not Humanoid then return end

		local SeatPart = Humanoid.SeatPart
		if not SeatPart then return end

		local Chassis = SeatPart:FindFirstAncestorOfClass 'Model'
		if not Chassis then return end
		
		local PrimaryPart = Chassis.PrimaryPart
		if not PrimaryPart then return end
		
		local Wheels = Chassis:FindFirstChild 'Wheels' :: Folder
		if not Wheels then return end
		
		local Snapshot = {
			ServerTime = buffer_readf64(bufferData, 0),
			
			RPM = buffer_readu16(bufferData, 8),
			Throttle = buffer_readu16(bufferData, 10)/1_000,

			Steer_FL = buffer_readf32(bufferData, 12),
			Steer_FR = buffer_readf32(bufferData, 14),

			Rot_RL = buffer_readf32(bufferData, 20),
			Rot_RR = buffer_readf32(bufferData, 24),
			Rot_FL = buffer_readf32(bufferData, 28),
			Rot_FR = buffer_readf32(bufferData, 32),

			Len_RL = buffer_readf32(bufferData, 36),
			Len_RR = buffer_readf32(bufferData, 40),
			Len_FL = buffer_readf32(bufferData, 44),
			Len_FR = buffer_readf32(bufferData, 48),
		}
		
		if not VehicleHistories[Player] then
			local HubAttachments = {}
			for Name, Order in WHEEL_ORDERS do
				local Attachment = PrimaryPart:FindFirstChild(Name) :: Attachment
				if not Attachment then return end
				
				table_insert(HubAttachments, Attachment)
			end
			
			local State = {
				RPM = Snapshot.RPM,
				Throttle = Snapshot.Throttle,
				
				Steer_FL = Snapshot.Steer_FL,
				Steer_FR = Snapshot.Steer_FR,
				
				Rot_RL = Snapshot.Rot_RL,
				Rot_RR = Snapshot.Rot_RR,
				Rot_FL = Snapshot.Rot_FL,
				Rot_FR = Snapshot.Rot_FR,
				
				Len_RL = Snapshot.Len_RL,
				Len_RR = Snapshot.Len_RR,
				Len_FL = Snapshot.Len_FL,
				Len_FR = Snapshot.Len_FR,
			}
			
			for _, Child in PrimaryPart:GetChildren() do
				if Child:IsA 'Sound' then
					Child.PlaybackSpeed = 0
					Child.Volume = 0
					Child:Play()
				end
			end
			
			VehicleHistories[Player] = {
				Frame = VehicleFrame,
				State = State,
				Root = PrimaryPart,
				Wheels = Wheels,
				HubAttachments = HubAttachments,
				Snapshots = {Snapshot}
			}
			
			return
		end

		table_insert(VehicleHistories[Player].Snapshots, Snapshot)

		if #VehicleHistories[Player].Snapshots > MAX_HISTORY_SIZE then
			table_remove(VehicleHistories[Player].Snapshots, 1)
		end
	end
end

function Structure:Step(dt)
	VehicleClass:Step(dt)
	VehicleFrame += 1

	if VehicleClass.Root then
		Util.updateEngineSounds(VehicleClass.Root:GetChildren() :: {Sound}, VehicleClass.Engine.RPM, VehicleClass.Engine.Throttle)
		
		UISpeed.Text = `{math_round(VehicleClass.Root.AssemblyLinearVelocity.Magnitude/Units.KMH_Studs)} km/h`
		UIRPM.Text = `{math_round(VehicleClass.Engine.RPM)}`
		UIGear.Text = `{VehicleClass.Gear}`
	end
	
	local renderTime = workspace:GetServerTimeNow() - INTERPOLATION_DELAY
	for Player, History in VehicleHistories do
		if #History.Snapshots < 2 then continue end
		
		local prevSnapshot = nil
		local lastSnapshot = nil
		
		for _, Snapshot in History.Snapshots do
			if Snapshot.ServerTime > renderTime then
				lastSnapshot = Snapshot
				break
			end
			
			prevSnapshot = Snapshot
		end
		
		if prevSnapshot and lastSnapshot and prevSnapshot ~= lastSnapshot then
			local frac = (renderTime - prevSnapshot.ServerTime)/(lastSnapshot.ServerTime - prevSnapshot.ServerTime)
			
			local State = History.State
			State.RPM = math_lerp(prevSnapshot.RPM, lastSnapshot.RPM, frac)
			State.Throttle = math_lerp(prevSnapshot.Throttle, lastSnapshot.Throttle, frac)
			
			State.Steer_FL = math_lerp(prevSnapshot.Steer_FL, lastSnapshot.Steer_FL, frac)
			State.Steer_FR = math_lerp(prevSnapshot.Steer_FR, lastSnapshot.Steer_FR, frac)
			
			State.Rot_RL = Util.lerpAngle(prevSnapshot.Rot_RL, lastSnapshot.Rot_RL, frac)
			State.Rot_RR = Util.lerpAngle(prevSnapshot.Rot_RR, lastSnapshot.Rot_RR, frac)
			State.Rot_FL = Util.lerpAngle(prevSnapshot.Rot_FL, lastSnapshot.Rot_FL, frac)
			State.Rot_FR = Util.lerpAngle(prevSnapshot.Rot_FR, lastSnapshot.Rot_FR, frac)
			
			State.Len_RL = math_lerp(prevSnapshot.Len_RL, lastSnapshot.Len_RL, frac)
			State.Len_RR = math_lerp(prevSnapshot.Len_RR, lastSnapshot.Len_RR, frac)
			State.Len_FL = math_lerp(prevSnapshot.Len_FL, lastSnapshot.Len_FL, frac)
			State.Len_FR = math_lerp(prevSnapshot.Len_FR, lastSnapshot.Len_FR, frac)

			History.Frame = VehicleFrame
			
			for i, HubAttachment in History.HubAttachments do
				local Wheel = History.Wheels:FindFirstChild(HubAttachment.Name) :: Model
				if not Wheel then continue end
				if not Wheel.PrimaryPart then continue end
				
				local HubMotor = Wheel.PrimaryPart:FindFirstChildOfClass 'Motor6D'
				if not HubMotor then continue end
				if not HubMotor.Part0 then continue end
				if not HubMotor.Part1 then continue end
				
				local WheelName = Wheel.Name
				
				local Steer = State['Steer_'..WheelName] or 0
				local Rotation = State['Rot_'..WheelName]
				local Length = State['Len_'..WheelName]
				
				Util.updateHubMotor(HubMotor, HubAttachment.CFrame, i%2 == 1, Rotation, Steer, Length)
			end
			
			Util.updateEngineSounds(History.Root:GetChildren() :: {Sound}, State.RPM, State.Throttle)
		end
	end
	
	for Player, History in VehicleHistories do
		if #History.Snapshots < 2 then continue end
		if History.Frame == VehicleFrame then continue end
		
		if History.Root then
			for _, Child in History.Root:GetChildren() do
				if not Child:IsA 'Sound' then continue end

				Child.PlaybackSpeed = 0
				Child.Volume = 0
				Child:Stop()
			end
		end
		
		VehicleHistories[Player] = nil
	end

	buffer_writef64(VehicleBuffer, 0, workspace:GetServerTimeNow())
	
	buffer_writeu16(VehicleBuffer, 8, math_max(0, VehicleClass.Engine.RPM))
	buffer_writeu16(VehicleBuffer, 10, math_round(math_max(0, VehicleClass.Engine.Throttle)*1_000))

	buffer_writef32(VehicleBuffer, 12, VehicleClass.Wheels[3].Steer)
	buffer_writef32(VehicleBuffer, 16, VehicleClass.Wheels[4].Steer)

	buffer_writef32(VehicleBuffer, 20, Util.wrapAngle(VehicleClass.Wheels[1].Rotation))
	buffer_writef32(VehicleBuffer, 24, Util.wrapAngle(VehicleClass.Wheels[2].Rotation))
	buffer_writef32(VehicleBuffer, 28, Util.wrapAngle(VehicleClass.Wheels[3].Rotation))
	buffer_writef32(VehicleBuffer, 32, Util.wrapAngle(VehicleClass.Wheels[4].Rotation))

	buffer_writef32(VehicleBuffer, 36, VehicleClass.Wheels[1].Length)
	buffer_writef32(VehicleBuffer, 40, VehicleClass.Wheels[2].Length)
	buffer_writef32(VehicleBuffer, 44, VehicleClass.Wheels[3].Length)
	buffer_writef32(VehicleBuffer, 48, VehicleClass.Wheels[4].Length)

	Replicator:FireServer(VehicleBuffer)
end

return Structure