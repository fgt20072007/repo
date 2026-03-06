--!strict

--// Services
local RunService = game:GetService 'RunService'
local UserInputService = game:GetService 'UserInputService'

--// Folders
local PACKAGES = script.Parent.Parent.Packages

--// Dependencies
local SQI = require(PACKAGES.Solvers.SQI)
local Units = require(PACKAGES.Raw.Units)
local Util = require(PACKAGES.Raw.Util)

local Engine = require(PACKAGES.Bodies.Engine)
local Wheelstrut = require(PACKAGES.Bodies.Wheelstrut)

local Brake = require(PACKAGES.Constraints.Brake)
local Clutch = require(PACKAGES.Constraints.Clutch)
local Differential = require(PACKAGES.Constraints.Differential)

local ABS = require(script.Systems.ABS)
local TCS = require(script.Systems.TCS)

--// Types
local Types = require(PACKAGES.Raw.Types)

export type Definition = {
	__index: Definition,
	
	Steer: number,
	
	SteerRatio: number,
	SteerSpeed: number,
	SteerReturnSpeed: number,
	SteerSpeedDecay: number,
	SteerMinSpeed: number,
	SteerDecay: number,
	SteerMinDecayAngle : number,
	SteerOuter: number,
	SteerInner: number,
	
	Gear: number,
	Ratios: {number},
	ShiftTime: number,
	RemainingShiftTime: number,
	Parked: boolean,
	Clutch: number,
	Shift: number,
	
	TransmissionMode: 'Auto' | 'Semi',
	
	SQI: Types.SQI,
	Components: {Types.Constraint <any>},
	Systems: {[string]: any},
	
	Root: BasePart?,
	Drive: VehicleSeat?,
	RayParameters: RaycastParams,
	
	Engine: Engine.Definition,
	Wheels: {Wheelstrut.Definition},
	
	Brakes: {Brake.Definition},
	RearClutch: Clutch.Definition,
	FrontClutch: Clutch.Definition,
	Differential: Differential.Definition,
	
	SetEngine: (self: Definition, BASE: any) -> (),
	SetWheel: (self: Definition, INDEX: number, MODEL: Model) -> (),
	SetSuspension: (self: Definition, INDEX: any, STIFFNESS: number?, DAMPING: number?, MIN_LENGTH: number?, FREE_LENGTH: number?, MAX_LENGTH: number?) -> (),
	SetAntiroll: (self: Definition, INDEX: any, STIFFNESS: number?) -> (),
	
	SetBrakes: (self: Definition, BASE: any) -> (),
	SetDifferential: (self: Definition, BIAS: number?, PRELOAD: number?, MAX_TORQUE: number?, TOP_SPEEDS: {number}?, SHIFT_TIME: number?) -> (),
	
	SetChassis: (self: Definition, MODEL: Model?) -> (),
	SetSteering: (self: Definition, BASE: any) -> (),
	SetSystems: (self: Definition, BASE: any) -> (),
	
	StartInputs: (self: Definition) -> (),
	Step: (self: Definition, dt: number) -> (),
}

--// Constants
local WHEEL_INDEXES = {'RL', 'RR', 'FL', 'FR'}
local TRANSMISSION_MODES = {'Auto', 'Semi'}

local HOTKEYS = {
	['GearUp'] = Enum.KeyCode.E,
	['GearDown'] = Enum.KeyCode.Q,
	['Transmission'] = Enum.KeyCode.M,
	
	['Ignite'] = Enum.KeyCode.F,
	['Park'] = Enum.KeyCode.P,

	['TCS'] = Enum.KeyCode.T,
	['ABS'] = Enum.KeyCode.Y,
}

local table_find = table.find

local math_rad = math.rad
local math_min = math.min
local math_max = math.max
local math_sign = math.sign
local math_clamp = math.clamp

local cframe_identity = CFrame.identity
local cframe_vectortoobjectspace = cframe_identity.VectorToObjectSpace

--// Structure
local Structure: Definition = {} :: Definition
Structure.__index = Structure

function Structure:SetEngine(BASE)
	self.Engine.PeakTorque = BASE.PeakTorque*Units.Torque_Nm
	self.Engine.PeakTorqueRPM = BASE.PeakTorqueRPM

	self.Engine.IdleRPM = BASE.IdleRPM 
	self.Engine.IdleTorque = BASE.IdleTorque*Units.Torque_Nm
	self.Engine.IdleTorqueCurve = BASE.IdleTorqueCurve

	self.Engine.RedlineRPM = BASE.RedlineRPM
	self.Engine.RedlineTorque = BASE.RedlineTorque*Units.Torque_Nm
	self.Engine.RedlineTorqueCurve = BASE.RedlineTorqueCurve
	
	self.Engine.Inertia = BASE.FlywheelInertia
end

function Structure:SetWheel(INDEX, MODEL)
	self.Wheels[INDEX].Model = MODEL
	self.Wheels[INDEX]:_replace()
end

function Structure:SetSuspension(INDEX, STIFFNESS, DAMPING, MIN_LENGTH, FREE_LENGTH, MAX_LENGTH)
	self.Wheels[INDEX].SuspensionStiffness = STIFFNESS or self.Wheels[INDEX].SuspensionStiffness
	self.Wheels[INDEX].SuspensionDamping = DAMPING or self.Wheels[INDEX].SuspensionDamping
	self.Wheels[INDEX].SuspensionMinLength = MIN_LENGTH or self.Wheels[INDEX].SuspensionMinLength
	self.Wheels[INDEX].SuspensionFreeLength = FREE_LENGTH or self.Wheels[INDEX].SuspensionFreeLength
	self.Wheels[INDEX].SuspensionMaxLength = MAX_LENGTH or self.Wheels[INDEX].SuspensionMaxLength
end

function Structure:SetAntiroll(INDEX, STIFFNESS)
	self.Wheels[INDEX].AntirollStiffness = STIFFNESS or self.Wheels[INDEX].AntirollStiffness
end

function Structure:SetBrakes(BASE)
	self.Brakes[1].MaxTorque = BASE.ParkingBrakeForce*Units.Torque_Nm
	self.Brakes[2].MaxTorque = BASE.ParkingBrakeForce*Units.Torque_Nm
	
	local bM = 1 - BASE.BrakeBias
	self.Brakes[3].MaxTorque = BASE.BrakeForce*bM*Units.Torque_Nm
	self.Brakes[4].MaxTorque = BASE.BrakeForce*bM*Units.Torque_Nm
	
	local fM = BASE.BrakeBias
	self.Brakes[5].MaxTorque = BASE.BrakeForce*fM*Units.Torque_Nm
	self.Brakes[6].MaxTorque = BASE.BrakeForce*fM*Units.Torque_Nm
end

function Structure:SetDifferential(BIAS, PRELOAD, MAX_TORQUE, TOP_SPEEDS, SHIFT_TIME)
	self.Differential.Bias = BIAS or self.Differential.Bias
	self.Differential.MaxTorque = MAX_TORQUE and MAX_TORQUE*Units.Torque_Nm or self.Differential.MaxTorque
	
	if PRELOAD then
		self.RearClutch.MaxTorque = (1 - self.Differential.Bias)*PRELOAD
		self.FrontClutch.MaxTorque = self.Differential.Bias*PRELOAD
	end
	
	if TOP_SPEEDS then
		local avgWheelRadius = 0 do
			for _, Wheel in self.Wheels do
				avgWheelRadius += Wheel.Radius
			end
			
			avgWheelRadius /= #self.Wheels
		end
		
		for i, v in TOP_SPEEDS do
			self.Ratios[i] = math_sign(i)*self.Engine.RedlineRPM*avgWheelRadius*Units.Studs_Meters*Units.RPM_KMH/v
		end
		
		self.Differential.Input = 0
		self.Differential.Ratio = self.Ratios[1]
	end
	
	self.ShiftTime = SHIFT_TIME or self.ShiftTime
end

function Structure:SetChassis(MODEL)
	if MODEL then
		local ROOT = MODEL:WaitForChild 'Primary'
		for i, Wheel in self.Wheels do
			Wheel.Root = ROOT
			Wheel.HubAttachment = ROOT:WaitForChild(WHEEL_INDEXES[i]) :: Attachment
			Wheel.Rotation = Util.wrapAngle(Wheel.Rotation)
			Wheel.AngularVelocity = 0
		end
		
		self.Engine.AngularVelocity = 0
		self.Engine.Ignired = false
		
		self.Root = ROOT :: BasePart
		self.Drive = MODEL:WaitForChild 'Seats':FindFirstChildOfClass 'VehicleSeat'
		
		self.Parked = false
		
		self.Clutch = 1
		self.Gear = 0
		self.Shift = 0

		self.Engine.Adjust = 1
	else
		self.Root = nil
	end
end

function Structure:SetSteering(BASE)
	self.SteerSpeed = BASE.SteerSpeed
	self.SteerReturnSpeed = BASE.SteerReturnSpeed
	self.SteerSpeedDecay = BASE.SteerSpeedDecay
	self.SteerMinSpeed = 1 - BASE.SteerMinSpeed/100
	self.SteerDecay = BASE.SteerDecay/Units.KMH_Studs
	self.SteerMinDecayAngle = 1 - BASE.SteerMinDecayAngle/100

	self.SteerOuter = (BASE.SteerLock*180)/BASE.SteerRatio
	self.SteerInner = math.min(self.SteerOuter - (self.SteerOuter*(1 - BASE.SteerAckerman)), self.SteerOuter*1.2)
end

function Structure:SetSystems(BASE)
	self.Systems.ABS.Limit = BASE.ABSLimit/100
	self.Systems.ABS.Threshold = BASE.ABSThreshold * Units.KMH_Studs
	
	self.Systems.TCS.Limit = 1 - BASE.TCSLimit/100
	self.Systems.TCS.Gradient = BASE.TCSGradient*Units.KMH_Studs
	self.Systems.TCS.Threshold = BASE.TCSThreshold*Units.KMH_Studs
end

function Structure:StartInputs()
	UserInputService.InputBegan:Connect(function(Input, GPE)
		if GPE then return end
		if not self.Root then return end
		if not self.Drive then return end

		if Input.KeyCode == HOTKEYS.GearDown then
			self.Shift = -1
			return
		end

		if Input.KeyCode == HOTKEYS.GearUp then
			self.Shift = 1
			return
		end
		
		if Input.KeyCode == HOTKEYS.Transmission then
			local i = table_find(TRANSMISSION_MODES, self.TransmissionMode) :: number
			self.TransmissionMode = (TRANSMISSION_MODES[i + 1] or TRANSMISSION_MODES[1]) :: any
		end
		
		if Input.KeyCode == HOTKEYS.Ignite then
			self.Engine.Ignired = not self.Engine.Ignired
			return
		end

		if Input.KeyCode == HOTKEYS.Park then
			self.Parked = not self.Parked
			return
		end
		
		if Input.KeyCode == HOTKEYS.TCS then
			self.Systems.TCS.Enabled = not self.Systems.TCS.Enabled
			return
		end
		
		if Input.KeyCode == HOTKEYS.ABS then
			self.Systems.ABS.Enabled = not self.Systems.ABS.Enabled
		end
	end)
end

function Structure:Step(dt)
	if not self.Root then return end
	if not self.Drive then return end
	
	--// STEERING BEHAVIOR
	local dt60 = 60*dt
	local vel = self.Root.AssemblyLinearVelocity.Magnitude/Units.KMH_Studs
	
	local SteerAlpha = 1 - math_min(vel/self.SteerSpeedDecay, self.SteerMinSpeed)
	local SteerSpeed = self.SteerSpeed*SteerAlpha
	local SteerReturnSpeed = self.SteerReturnSpeed*SteerAlpha
	
	local Steer = self.Drive.SteerFloat
	if self.Steer < Steer then
		if self.Steer < 0 then
			self.Steer = math_min(Steer, self.Steer + dt60*SteerReturnSpeed)
		else
			self.Steer = math_min(Steer, self.Steer + dt60*SteerSpeed)
		end
	else
		if self.Steer > 0 then
			self.Steer = math_max(Steer, self.Steer - dt60*SteerReturnSpeed)
		else
			self.Steer = math_max(Steer, self.Steer - dt60*SteerSpeed)
		end
	end
	
	local SteerDecay = 1 - math_min(vel/self.SteerDecay, self.SteerMinDecayAngle)
	if self.Steer >= 0 then
		self.Wheels[3].Steer = -math_rad(self.Steer*self.SteerOuter*SteerDecay)
		self.Wheels[4].Steer = -math_rad(self.Steer*self.SteerInner*SteerDecay)
	else
		self.Wheels[3].Steer = -math_rad(self.Steer*self.SteerInner*SteerDecay)
		self.Wheels[4].Steer = -math_rad(self.Steer*self.SteerOuter*SteerDecay)
	end
	
	--// TRANSMISSION
	local engineRPM = self.Engine.RPM
	local driveshaftRPM = 0 do
		local diffBias = self.Differential.Bias

		local hAt, tw = 0.5*#self.Wheels, 0
		for i, v in self.Wheels do
			local w = i > hAt and diffBias or 1 - diffBias
			driveshaftRPM += w*v.AngularVelocity
			tw += w
		end
		
		driveshaftRPM *= -2*self.Differential.Ratio*Units.Rads_RPM/tw
	end
	
	local throttle = self.Drive.ThrottleFloat
	local throttleInput, brakeInput = math_max(0, throttle), math_max(0, -throttle)
	if self.Gear == -1 and self.TransmissionMode == 'Auto' then
		throttleInput, brakeInput = brakeInput, throttleInput
	end
	
	local parkInput = self.Parked and 1 or 0
	for i = 1, 2 do
		self.Brakes[i].Input = parkInput
	end
	
	for i = 3, #self.Brakes do
		self.Brakes[i].Input = brakeInput
	end
	
	local autoClutch = 1 do
		if self.RemainingShiftTime > 0 then
			if engineRPM < driveshaftRPM and engineRPM < self.Engine.RedlineRPM then
				self.RemainingShiftTime += dt
				throttleInput = 1
			else
				throttleInput *= 0.5
			end
		end

		if engineRPM < self.Engine.IdleRPM and driveshaftRPM < 1.25*self.Engine.IdleRPM then
			local stallRPM = 0.5*self.Engine.IdleRPM

			local rampTQ = engineRPM/self.Engine.IdleRPM
			autoClutch *= (1 - math_clamp(rampTQ*self.Engine.Torque/(2*self.Differential.MaxTorque), 0, 1))*(1 - throttleInput)
		end
		
		local hShift = 0.5*self.ShiftTime
		if self.RemainingShiftTime > hShift then
			autoClutch = 0
		elseif self.RemainingShiftTime > 0 then
			autoClutch *= (1 - self.RemainingShiftTime)/hShift
		end

		autoClutch *= 1 - brakeInput
		
		if self.Gear == 0 then
			autoClutch = 0
		end
		
		autoClutch = math_clamp(autoClutch, 0, 1)
	end
	
	if self.TransmissionMode == 'Auto' and self.RemainingShiftTime == 0 then
		local redlineRPM = self.Engine.RedlineRPM
		
		local baseRPM = redlineRPM/self.Ratios[1]
		if self.Gear > 0 and driveshaftRPM > redlineRPM then
			self.Shift = 1
		elseif self.Gear > 1 and driveshaftRPM < 0.7*redlineRPM/(self.Ratios[self.Gear - 1]/self.Ratios[self.Gear]) then
			self.Shift = -1
		elseif self.Gear == 0 and throttleInput > 0 and engineRPM > baseRPM then
			self.Shift = 1
		elseif self.Gear == 1 and throttleInput == 0 and driveshaftRPM < baseRPM then
			self.Shift = -1
		elseif self.Gear == -1 and brakeInput > 0 and driveshaftRPM < baseRPM then
			self.Shift = 1
		elseif self.Gear == 0 and brakeInput > 0 and driveshaftRPM < baseRPM then
			self.Shift = -1
		elseif self.Gear == -1 and throttleInput == 0 and driveshaftRPM < baseRPM then
			self.Shift = 1
		end
	end
	
	if self.Shift == -1 and self.Gear == -1 then
		self.Shift = 0
	end

	if self.Shift == 1 and self.Gear == #self.Ratios - 1 then
		self.Shift = 0
	end

	self.RemainingShiftTime = math_max(0, self.RemainingShiftTime - dt)
	if self.RemainingShiftTime < 0.5*self.ShiftTime and self.Shift ~= 0 then
		self.RemainingShiftTime = self.ShiftTime
		
		self.Gear += self.Shift
		self.Shift = 0
	end
	
	--// SIMULATION
	self.Engine.Throttle = throttleInput
	self.Differential.Ratio = self.Gear == 0 and 0 or -self.Ratios[self.Gear]
	self.Differential.Input = autoClutch*self.Clutch
	
	for _, System in self.Systems do
		System:Step(dt)
	end
	
	self.SQI:Step(dt, self.Components)
	
	self.Wheels[1].Antiroll = self.Wheels[2].Compression
	self.Wheels[2].Antiroll = self.Wheels[1].Compression
	self.Wheels[3].Antiroll = self.Wheels[4].Compression
	self.Wheels[4].Antiroll = self.Wheels[3].Compression
end

return function(): Definition
	local self = {}
	
	self.Steer = 0
	
	self.Gear = 0
	self.Ratios = {}
	self.ShiftTime = 0
	self.RemainingShiftTime = 0
	self.Parked = true
	self.Clutch = 1
	self.Shift = 0
	
	self.TransmissionMode = 'Auto'
	
	self.SQI = SQI()
	self.Components = {}
	self.Systems = {}
	
	self.RayParameters = RaycastParams.new()
	self.RayParameters.FilterDescendantsInstances = {workspace.Vehicles}
	self.RayParameters.IgnoreWater = true
	self.RayParameters.RespectCanCollide = true
	
	self.Engine = Engine()
	self.Wheels = {
		Wheelstrut {RayParameters = self.RayParameters, Side = false}, Wheelstrut {RayParameters = self.RayParameters, Side = true},
		Wheelstrut {RayParameters = self.RayParameters, Side = false}, Wheelstrut {RayParameters = self.RayParameters, Side = true}
	}
	
	self.Brakes = {
		Brake {Attachments = {self.Wheels[1]}}, Brake {Attachments = {self.Wheels[2]}},
		Brake {Attachments = {self.Wheels[1]}}, Brake {Attachments = {self.Wheels[2]}},
		Brake {Attachments = {self.Wheels[3]}}, Brake {Attachments = {self.Wheels[4]}},
	}
	
	self.RearClutch = Clutch {Attachments = {self.Wheels[1], self.Wheels[2]}}
	self.FrontClutch = Clutch {Attachments = {self.Wheels[3], self.Wheels[4]}}
	self.Differential = Differential {
		Attachments = {
			self.Engine,
			self.Wheels[1], self.Wheels[2],
			self.Wheels[3], self.Wheels[4]
		}
	}

	table.insert(self.Components :: any, self.Engine)
	for _, Wheel in self.Wheels do table.insert(self.Components :: any, Wheel) end
	for _, Brake in self.Brakes do table.insert(self.Components :: any, Brake) end
	
	table.insert(self.Components :: any, self.Differential)
	table.insert(self.Components :: any, self.RearClutch)
	table.insert(self.Components :: any, self.FrontClutch)

	self.Systems.ABS = ABS {
		Brakes = {
			self.Brakes[3], self.Brakes[4],
			self.Brakes[5], self.Brakes[6]
		}
	}
	
	self.Systems.TCS = TCS {
		Engine = self.Engine,
		Brakes = {
			self.Brakes[3], self.Brakes[4],
			self.Brakes[5], self.Brakes[6]
		}
	}
	
	return setmetatable(self, Structure) :: any
end