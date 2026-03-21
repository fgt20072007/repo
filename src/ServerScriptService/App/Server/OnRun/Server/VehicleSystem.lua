--!strict
--!native
--!optimize 2

--// Services
local Players = game:GetService 'Players'
local ReplicatedStorage = game:GetService 'ReplicatedStorage'
local ServerScriptService = game:GetService 'ServerScriptService'

--// Dependencies
local VehicleFuel = require(script.Parent.VehicleFuel)
local DrivingRewards = require(script.Parent.VehicleRewards)
local RunLoop = require(ServerScriptService:WaitForChild('App'):WaitForChild('Server'):WaitForChild('System'):WaitForChild('RunLoop'))
local Maid = require(ReplicatedStorage:WaitForChild('App'):WaitForChild('Shared'):WaitForChild('Util'):WaitForChild('Maid'))

--// Constants
local string_lower = string.lower
local string_sub = string.sub

local vector3_zero = Vector3.zero

local cframe_offset1 = CFrame.Angles(0, -math.pi, 0)

local VEHICLE_COLLISION_GROUP = 'Vehicle_Collision'
local VEHICLE_DYNAMIC_GROUP = 'Vehicle_Dynamic'
local VEHICLE_SEAT_GROUP = 'Vehicle_Seat'
local NETWORK_OWNERSHIP_REFRESH_INTERVAL = 0.5
local VEHICLE_SPAWN_LOCKED_ATTRIBUTE = "VehicleSpawnLocked"

type VehicleRuntime = {
	Chassis: Model,
	Primary: BasePart,
	Wheels: Folder,
	Data: any,
	Drive: VehicleSeat,
	Maid: any,
	Ownership: Player?,
	DriverTag: string?,
	AwaitingDriverSimulation: boolean,
	DriverAssignedAt: number,
}

local builtVehicles: { [Model]: VehicleRuntime } = {}
local activeRuntimeByDriverUserId: { [number]: VehicleRuntime } = {}
local lastClientSimulationTickByUserId: { [number]: number } = {}
local initialized = false
local ownershipRefreshTimer = 0

local function IsDisplayVehicle(Chassis: Model): boolean
	return Chassis:GetAttribute("IsGarageDisplayVehicle") == true
end

local function SetNetworkOwnerSafe(Primary: BasePart, owner: Player?)
	pcall(Primary.SetNetworkOwner, Primary, owner)
end

local function ResolvePrimaryPart(Chassis: Model): BasePart?
	local Primary = Chassis.PrimaryPart
	if Primary then
		return Primary
	end

	local NamedPrimary = Chassis:FindFirstChild('Primary')
	if NamedPrimary and NamedPrimary:IsA('BasePart') then
		Chassis.PrimaryPart = NamedPrimary
		return NamedPrimary
	end

	local FirstBasePart = Chassis:FindFirstChildWhichIsA('BasePart', true)
	if FirstBasePart then
		Chassis.PrimaryPart = FirstBasePart
		return FirstBasePart
	end

	return nil
end

local function CloneModelTemplate(Template: Instance): Model?
	if Template:IsA('Model') then
		local ModelClone = Template:Clone()
		if not ModelClone.PrimaryPart then
			local Primary = ModelClone:FindFirstChild('Primary')
			if Primary and Primary:IsA('BasePart') then
				ModelClone.PrimaryPart = Primary
			else
				local FirstBasePart = ModelClone:FindFirstChildWhichIsA('BasePart', true)
				if FirstBasePart then
					ModelClone.PrimaryPart = FirstBasePart
				end
			end
		end

		return ModelClone
	end

	local WrappedModel = Instance.new('Model')
	WrappedModel.Name = Template.Name

	for _, Child in Template:GetChildren() do
		Child:Clone().Parent = WrappedModel
	end

	local Primary = WrappedModel:FindFirstChild('Primary')
	if Primary and Primary:IsA('BasePart') then
		WrappedModel.PrimaryPart = Primary
	else
		local FirstBasePart = WrappedModel:FindFirstChildWhichIsA('BasePart', true)
		if FirstBasePart then
			WrappedModel.PrimaryPart = FirstBasePart
		end
	end

	if not WrappedModel.PrimaryPart then
		WrappedModel:Destroy()
		return nil
	end

	return WrappedModel
end

local function ResolveWheelTemplate(Chassis: Model): Model?
	local Assets = ReplicatedStorage:FindFirstChild 'Assets'
	if not Assets then return nil end

	local Cars = Assets:FindFirstChild 'Cars'
	if not Cars then return nil end

	local VehicleName = Chassis:GetAttribute("VehicleName")
	local AssetKey = if type(VehicleName) == "string" and VehicleName ~= "" then VehicleName else Chassis.Name
	local VehicleAssets = Cars:FindFirstChild(AssetKey) or Cars:FindFirstChild(string_lower(AssetKey))
	if not VehicleAssets then return nil end

	local Wheels = VehicleAssets:FindFirstChild 'Wheels'
	if not Wheels then return nil end

	local Wheel = Wheels:FindFirstChild 'Wheel'
	if not Wheel then return nil end

	return CloneModelTemplate(Wheel)
end

local function SetWheelCollisionEnabled(Wheels: Folder, enabled: boolean)
	for _, Wheel in Wheels:GetChildren() do
		for _, Descendant in Wheel:GetDescendants() do
			if Descendant:IsA 'BasePart' then
				Descendant.CanCollide = enabled
			end
		end
	end
end

local function RemoveDriverTag(Chassis: Model, tagName: string?)
	if tagName == nil then
		return
	end
	if table.find(Chassis:GetTags(), tagName) == nil then
		return
	end

	Chassis:RemoveTag(tagName)
end

local function IsDriverSimulationReady(runtime: VehicleRuntime): boolean
	local owner = runtime.Ownership
	if owner == nil then
		return false
	end

	local lastSimulationTick = lastClientSimulationTickByUserId[owner.UserId]
	if lastSimulationTick == nil then
		return false
	end

	return lastSimulationTick >= runtime.DriverAssignedAt
end

local function RefreshDriverWheelCollision(runtime: VehicleRuntime)
	if runtime.AwaitingDriverSimulation ~= true then
		return
	end
	if IsDriverSimulationReady(runtime) ~= true then
		return
	end

	SetWheelCollisionEnabled(runtime.Wheels, false)
	runtime.AwaitingDriverSimulation = false
end

--// Structure
local Structure = {}

local function SetNeutralVehicleState(runtime: VehicleRuntime)
	SetNetworkOwnerSafe(runtime.Primary, nil)
	runtime.Primary.AssemblyLinearVelocity = vector3_zero
	runtime.Primary.AssemblyAngularVelocity = vector3_zero
end

local function ReleaseDriver(runtime: VehicleRuntime)
	local previousOwner = runtime.Ownership
	if previousOwner == nil then
		return
	end

	runtime.Drive:SetAttribute('Driven', nil)
	RemoveDriverTag(runtime.Chassis, runtime.DriverTag)
	runtime.DriverTag = nil

	for _, Wheel in runtime.Wheels:GetChildren() :: {any} do
		Structure:SetSuspension(runtime.Chassis, runtime.Data, Wheel.Name)
	end
	SetWheelCollisionEnabled(runtime.Wheels, true)
	runtime.AwaitingDriverSimulation = false
	runtime.DriverAssignedAt = 0
	if activeRuntimeByDriverUserId[previousOwner.UserId] == runtime then
		activeRuntimeByDriverUserId[previousOwner.UserId] = nil
	end

	DrivingRewards:StopDriving(previousOwner, runtime.Chassis)
	VehicleFuel:StopDriving(previousOwner, runtime.Chassis)

	SetNetworkOwnerSafe(runtime.Primary, nil)
	runtime.Ownership = nil
end

local function AssignDriver(runtime: VehicleRuntime, Player: Player)
	if runtime.Ownership == Player then
		return
	end

	ReleaseDriver(runtime)

	runtime.Drive:SetAttribute('Driven', true)

	runtime.DriverTag = `VehicleStepper_{Player.UserId}`
	runtime.Chassis:AddTag(runtime.DriverTag)

	DrivingRewards:StartDriving(Player, runtime.Chassis)
	VehicleFuel:StartDriving(Player, runtime.Chassis)

	SetNetworkOwnerSafe(runtime.Primary, Player)
	runtime.Ownership = Player
	activeRuntimeByDriverUserId[Player.UserId] = runtime
	runtime.DriverAssignedAt = workspace:GetServerTimeNow()
	runtime.AwaitingDriverSimulation = true
	RefreshDriverWheelCollision(runtime)
end

local function DestroyRuntime(runtime: VehicleRuntime)
	if builtVehicles[runtime.Chassis] ~= runtime then
		return
	end

	builtVehicles[runtime.Chassis] = nil
	ReleaseDriver(runtime)
	runtime.Maid:Cleanup()
end

local function SyncSeatOccupant(runtime: VehicleRuntime)
	local Occupant = runtime.Drive.Occupant
	if not Occupant then
		ReleaseDriver(runtime)
		return
	end

	local Player = Players:GetPlayerFromCharacter(Occupant.Parent :: Model)
	if not Player then
		ReleaseDriver(runtime)
		return
	end

	AssignDriver(runtime, Player)
end

local function RefreshVehicleOwnership(dt: number)
	ownershipRefreshTimer += dt
	if ownershipRefreshTimer < NETWORK_OWNERSHIP_REFRESH_INTERVAL then
		return
	end
	ownershipRefreshTimer %= NETWORK_OWNERSHIP_REFRESH_INTERVAL

	for _, runtime in builtVehicles do
		if runtime.Chassis:IsDescendantOf(workspace) ~= true or runtime.Primary:IsDescendantOf(workspace) ~= true then
			ReleaseDriver(runtime)
			continue
		end

		if runtime.Primary.Anchored then
			ReleaseDriver(runtime)
			runtime.Primary.AssemblyLinearVelocity = vector3_zero
			runtime.Primary.AssemblyAngularVelocity = vector3_zero
			continue
		end

		if runtime.Ownership then
			SetNetworkOwnerSafe(runtime.Primary, runtime.Ownership)
			RefreshDriverWheelCollision(runtime)
		else
			SetNeutralVehicleState(runtime)
		end
	end
end

function Structure:Init()
	if initialized == true then
		return
	end

	initialized = true
	DrivingRewards:Init()
	RunLoop.Get():Bind('Heartbeat', 'VehicleOwnership', RefreshVehicleOwnership)
end

function Structure:MarkClientSimulationTick(userId: number, clientTime: number)
	lastClientSimulationTickByUserId[userId] = clientTime

	local runtime = activeRuntimeByDriverUserId[userId]
	if runtime == nil then
		return
	end

	RefreshDriverWheelCollision(runtime)
end

function Structure:SetSuspension(Chassis: Model, Data: any, Name: string)
	local Primary = ResolvePrimaryPart(Chassis)
	if not Primary then return end

	local Attachment = Primary:FindFirstChild(Name) :: Attachment
	if not Attachment then return end

	local Wheels = Chassis:FindFirstChild 'Wheels'
	if not Wheels then return end

	local Wheel = Wheels:FindFirstChild(Name) :: Model
	if not Wheel then return end
	if not Wheel.PrimaryPart then return end

	local Motor6D = Wheel.PrimaryPart:FindFirstChildOfClass 'Motor6D'
	if not Motor6D then return end

	local isLeft = string_sub(Wheel.Name, 2, 2) == 'L'
	local isRear = string_sub(Wheel.Name, 1, 1) == 'R'
	if isLeft then
		if isRear then
			Motor6D.C1 = Attachment.CFrame - Vector3.new(0, Data.RearFreeLength, 0)
		else
			Motor6D.C1 = Attachment.CFrame - Vector3.new(0, Data.FrontFreeLength, 0)
		end
	else
		if isRear then
			Motor6D.C1 = Attachment.CFrame*cframe_offset1 - Vector3.new(0, Data.RearFreeLength, 0)
		else
			Motor6D.C1 = Attachment.CFrame*cframe_offset1 - Vector3.new(0, Data.FrontFreeLength, 0)
		end
	end
end

function Structure:SetWheel(Chassis: Model, Data: any, WheelModel: Model, Name: string)
	local Primary = ResolvePrimaryPart(Chassis)
	if not Primary then return end

	local WheelPrimary = WheelModel.PrimaryPart
	if not WheelPrimary then return end

	local Attachment = Primary:FindFirstChild(Name) :: Attachment
	if not Attachment then return end

	local Wheels = Chassis:FindFirstChild 'Wheels'
	if not Wheels then return end

	local Wheel = Wheels:FindFirstChild(Name)
	if Wheel then
		Wheel:Destroy()
	end

	Wheel = WheelModel
	Wheel.Name = Name

	for _, Descendant in Wheel:GetDescendants() do
		if Descendant:IsA 'BasePart' then
			if Descendant ~= WheelPrimary then
				local Weld = Instance.new 'WeldConstraint'
				Weld.Part0 = WheelPrimary
				Weld.Part1 = Descendant
				Weld.Parent = WheelPrimary
			end

			Descendant.CollisionGroup = VEHICLE_DYNAMIC_GROUP
			Descendant.Anchored = false
			Descendant.Massless = true
			Descendant.CanCollide = true
			Descendant.EnableFluidForces = false
		end
	end

	local Motor6D = Instance.new 'Motor6D'
	Motor6D.Part0 = WheelPrimary
	Motor6D.Part1 = Primary
	Motor6D.Parent = WheelPrimary

	Wheel.Parent = Wheels
	self:SetSuspension(Chassis, Data, Name)
end

function Structure:Build(Chassis: Model)
	self:Init()

	if builtVehicles[Chassis] ~= nil then
		return
	end
	if Chassis:FindFirstChild('Wheels') ~= nil then
		return
	end

	local Primary = ResolvePrimaryPart(Chassis)
	if not Primary then return end

	local DataModule = Chassis:FindFirstChild 'Data' :: ModuleScript
	if not DataModule then return end

	local Data = require(DataModule) :: any
	VehicleFuel:PrepareChassis(Chassis)
	local WheelTemplate = ResolveWheelTemplate(Chassis)
	if not WheelTemplate then return end

	local Wheels = Instance.new 'Folder'
	Wheels.Name = 'Wheels'
	Wheels.Parent = Chassis

	self:SetWheel(Chassis, Data, WheelTemplate:Clone(), 'RL')
	self:SetWheel(Chassis, Data, WheelTemplate:Clone(), 'RR')
	self:SetWheel(Chassis, Data, WheelTemplate:Clone(), 'FL')
	self:SetWheel(Chassis, Data, WheelTemplate:Clone(), 'FR')

	Primary.CustomPhysicalProperties = PhysicalProperties.new(
		Data.Weight/(Primary.Size.X*Primary.Size.Y*Primary.Size.Z),
		0, 0, 0, 100
	)
	Primary.CollisionGroup = VEHICLE_DYNAMIC_GROUP
	Primary.CanCollide = false

	local Body = Chassis:WaitForChild 'Body'
	for _, Descendant in Body:GetDescendants() do
		if Descendant:IsA 'BasePart' then
			local Weld = Instance.new 'WeldConstraint'
			Weld.Part0 = Descendant
			Weld.Part1 = Primary
			Weld.Parent = Descendant

			Descendant.Anchored = false
			Descendant.Massless = true
			Descendant.CanCollide = false
			Descendant.EnableFluidForces = false
		end
	end

	local Seats = Chassis:WaitForChild 'Seats'
	for _, Descendant in Seats:GetDescendants() do
		if Descendant:IsA 'BasePart' then
			local Weld = Instance.new 'WeldConstraint'
			Weld.Part0 = Descendant
			Weld.Part1 = Primary
			Weld.Parent = Descendant

			Descendant.Anchored = false
			Descendant.Massless = true
			Descendant.CollisionGroup = VEHICLE_SEAT_GROUP
			Descendant.EnableFluidForces = false
		end
	end

	local Collision = Chassis:WaitForChild 'Collision'
	for _, Descendant in Collision:GetDescendants() do
		if Descendant:IsA 'BasePart' then
			local Weld = Instance.new 'WeldConstraint'
			Weld.Part0 = Descendant
			Weld.Part1 = Primary
			Weld.Parent = Descendant

			Descendant.Anchored = false
			Descendant.Massless = true
			Descendant.CanCollide = true
			Descendant.EnableFluidForces = false

			Descendant.CollisionGroup = VEHICLE_COLLISION_GROUP
		end
	end

	if Chassis:GetAttribute(VEHICLE_SPAWN_LOCKED_ATTRIBUTE) ~= true then
		Primary.Anchored = false
	else
		Primary.AssemblyLinearVelocity = vector3_zero
		Primary.AssemblyAngularVelocity = vector3_zero
	end

	local Attachment = Instance.new 'Attachment'
	Attachment.Name = 'Gravity'
	Attachment.Parent = Primary

	local Force = Instance.new 'VectorForce'
	Force.Attachment0 = Attachment
	Force.RelativeTo = Enum.ActuatorRelativeTo.World
	Force.Force = Vector3.new(0, Data.Gravity > 0 and Primary.AssemblyMass*(workspace.Gravity - Data.Gravity) or 0, 0)
	Force.Parent = Attachment

	local Drive = Seats:FindFirstChildOfClass 'VehicleSeat'
	if not Drive then return end

	if IsDisplayVehicle(Chassis) then
		return
	end

	local runtime: VehicleRuntime = {
		Chassis = Chassis,
		Primary = Primary,
		Wheels = Wheels,
		Data = Data,
		Drive = Drive,
		Maid = Maid.New(),
		Ownership = nil,
		DriverTag = nil,
		AwaitingDriverSimulation = false,
		DriverAssignedAt = 0,
	}

	builtVehicles[Chassis] = runtime

	runtime.Maid:Add(Drive:GetPropertyChangedSignal 'Occupant':Connect(function()
		SyncSeatOccupant(runtime)
	end))

	runtime.Maid:Add(Chassis.Destroying:Connect(function()
		DestroyRuntime(runtime)
	end))

	SyncSeatOccupant(runtime)
end

return Structure
