--!strict
--!native
--!optimize 2

local PHYSICS = script.Parent.Parent

--// Types
local Types = require(PHYSICS.Raw.Types)

export type Definition = Types.Body <{
	SuspensionStiffness: number,
	SuspensionDamping: number,
	SuspensionMinLength: number,
	SuspensionFreeLength: number,
	SuspensionMaxLength: number,
	
	AntirollStiffness: number,
	
	Side: boolean,
	Mass: number,
	Radius: number,
	uStiffness: number,
	vStiffness: number,
	FrictionCoefficient: number,
	
	RayParameters: RaycastParams,
	
	HubMotor: Motor6D,
	HubAttachment: Attachment,
	ContactAttachment: Attachment,
	SuspensionAttachment: Attachment,
	SuspensionSpring: SpringConstraint,
	
	VectorForce: VectorForce,
	
	Root: any,
	Model: Model,
	
	AccumulatedTime: number,
	Zhat: Vector3,
	Resistance: number,
	Steer: number,
	Antiroll: number,
	Compression: number,
	Length: number,
}>

--// Constants
local Util = require(script.Parent.Parent.Raw.Util)
local Units = require(script.Parent.Parent.Raw.Units)

local STATIC_RESISTANCE = 10*Units.Torque_Nm
local DYNAMIC_RESISTANCE = 30*Units.Torque_Nm

local _dtCAP = 1/200

local math_abs = math.abs
local math_max = math.max
local math_sign = math.sign
local math_clamp = math.clamp

local vector3_new = Vector3.new
local vector3_zero = Vector3.zero

local cframe_angles = CFrame.Angles
local cframe_identity = CFrame.identity
local cframe_toobjectspace = cframe_identity.ToObjectSpace
local cframe_vectortoobjectspace = cframe_identity.VectorToObjectSpace
local cframe_vectortoworldspace = cframe_identity.VectorToWorldSpace

local raycast = workspace.Raycast

--// Structure
local Structure: Definition = {} :: Definition
Structure.__index = Structure

function Structure:_stepBefore(dt)
	if not self.HubAttachment or not self.Model or not self.Model:IsDescendantOf(workspace) then
		return
	end

	local WheelRadius = self.Radius
	
	local SuspensionStiffness = self.SuspensionStiffness
	local SuspensionMinLength = self.SuspensionMinLength
	local SuspensionFreeLength = self.SuspensionFreeLength
	local SuspensionMaxLength = self.SuspensionMaxLength
	
	local HubCFrame = cframe_angles(0, self.Steer, 0) + self.HubAttachment.Position
	self.HubAttachment.CFrame = HubCFrame
	
	local HubTransform = self.HubAttachment.WorldCFrame
	local HubDir = HubTransform.UpVector*(-SuspensionMaxLength - WheelRadius)
	
	local Cast = raycast(workspace, HubTransform.Position, HubDir, self.RayParameters)
	local ContactLength = SuspensionFreeLength do
		if Cast then
			ContactLength = math_clamp(Cast.Distance - WheelRadius, SuspensionMinLength, SuspensionFreeLength)
		end
	end
	
	local AngularVelocity = self.AngularVelocity
	local Rotation = self.Rotation + dt*AngularVelocity
	self.Rotation = Rotation

	local ContactCompression = SuspensionFreeLength - ContactLength
	self.Compression = ContactCompression
	self.Length = ContactLength
	
	if Cast and ContactCompression > 0.01 then
		local Contact = HubTransform.Rotation + Cast.Position
		self.ContactAttachment.WorldCFrame = Contact

		local SuspensionStiffness = self.SuspensionStiffness
		local SuspensionDamping = self.SuspensionDamping

		self.SuspensionSpring.Stiffness = SuspensionStiffness
		self.SuspensionSpring.Damping = SuspensionDamping
		self.SuspensionSpring.FreeLength = 1000 + ContactCompression
		self.SuspensionAttachment.WorldCFrame = Contact - 1000*Cast.Normal

		local WorldVelocity = self.Root:GetVelocityAtPosition(Cast.Position)
		local LocalVelocity = cframe_vectortoobjectspace(Contact, WorldVelocity)
		local FloorVelocity = (_dtCAP/math_max(dt, _dtCAP))*vector3_new(LocalVelocity.X, 0, LocalVelocity.Z - WheelRadius*AngularVelocity)

		local sForce = SuspensionStiffness*ContactCompression
		local kFriction = sForce*self.FrictionCoefficient
		local iForce, eForce = Util.clampV3(self.Zhat - self.uStiffness*FloorVelocity, kFriction)
		self.Zhat = vector3_new(iForce.X*math_clamp(1 - 0.02*math_abs(AngularVelocity), 0, 1), 0, iForce.Z*math_clamp(1 - 0.004*math_abs(AngularVelocity), 0, 1))

		local rForce = Util.clampV3(iForce - self.vStiffness*FloorVelocity, kFriction)
		self.VectorForce.Force = cframe_vectortoworldspace(Contact, rForce)

		AngularVelocity -= dt*rForce.Z*WheelRadius/self.Inertia
	else
		self.SuspensionSpring.Stiffness = 0
		self.SuspensionSpring.Damping = 0
		
		self.AccumulatedTime = 0
		self.Zhat = vector3_zero
		self.VectorForce.Force = vector3_zero
	end

	self.AngularVelocity = AngularVelocity

	Util.updateHubMotor(self.HubMotor, HubCFrame, self.Side, Util.wrapAngle(Rotation), 0, ContactLength)
	
	self.Impulse = -math_sign(AngularVelocity)*self.Resistance*dt
	self.AccumulatedImpulse += self.Impulse
end

function Structure:_setError(dt, err)
	self.Error = err*(self.AccumulatedImpulse - self.AngularVelocity*self.Inertia)
end

function Structure:_resetImpulse()
	self.AccumulatedImpulse = 0
end

function Structure:_setImpulse(dt)
	local MaxTorque = self.Resistance*dt
	self.Impulse = math_clamp(self.Impulse + self.Error, -MaxTorque, MaxTorque)
	self.AccumulatedImpulse += self.Impulse
end

function Structure:_stepAfter(DT)
	self.AngularVelocity += self.AccumulatedImpulse/self.Inertia
	self.Resistance = STATIC_RESISTANCE + DYNAMIC_RESISTANCE*math_abs(self.AngularVelocity)*Units.Rads_RPM/1000
end

function Structure:_replace()
	self.ContactAttachment.Parent = self.HubAttachment.Parent
	
	if self.Model.PrimaryPart then
		self.HubMotor = self.Model.PrimaryPart:FindFirstChildOfClass 'Motor6D' :: Motor6D
		self.Mass = self.Model.PrimaryPart.AssemblyMass
	end
	
	self.Radius = 0.5*self.Model:GetExtentsSize().Y
	self.Inertia = 0.5*self.Mass*self.Radius*self.Radius
end

return function(BASE: any): Definition
	local self = BASE or {} do
		self.SuspensionStiffness = self.SuspensionStiffness or 50_000
		self.SuspensionDamping = self.SuspensionDamping or 5_000
		self.SuspensionLength = self.SuspensionLength or 1
	end
	
	self.Rotation = 0
	self.AngularVelocity = 0
	
	self.AccumulatedTime = 0
	self.Zhat = vector3_zero
	self.Resistance = 0
	self.Steer = 0
	self.Antiroll = 0
	self.Length = 0

	self.ContactAttachment = Instance.new 'Attachment'
	self.ContactAttachment.Name = 'ContactAttachment'

	self.SuspensionAttachment = Instance.new 'Attachment'
	self.SuspensionAttachment.Name = 'SuspensionAttachment'
	self.SuspensionAttachment.Parent = workspace.Terrain

	self.VectorForce = Instance.new 'VectorForce'
	self.VectorForce.Force = Vector3.zero
	self.VectorForce.Attachment0 = self.ContactAttachment
	self.VectorForce.RelativeTo = Enum.ActuatorRelativeTo.World
	self.VectorForce.Parent = self.ContactAttachment

	self.SuspensionSpring = Instance.new 'SpringConstraint'
	self.SuspensionSpring.Attachment0 = self.ContactAttachment
	self.SuspensionSpring.Attachment1 = self.SuspensionAttachment
	self.SuspensionSpring.Parent = self.ContactAttachment

	self.Mass = 200
	self.Radius = 1
	self.Inertia = 0.5*self.Mass*self.Radius*self.Radius

	self.uStiffness = 2_400
	self.vStiffness = 1_200
	self.FrictionCoefficient = 1.52
	
	return setmetatable(self, Structure) :: any
end