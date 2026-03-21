--!strict
--!native
--!optimize 2

local PHYSICS = script.Parent.Parent

--// Types
local Types = require(PHYSICS.Raw.Types)

export type Definition = Types.Body <{
	PeakTorque: number, -- n-m
	PeakTorqueRPM: number,

	IdleRPM: number,
	IdleTorque: number, -- n-m
	IdleTorqueCurve: number,

	RedlineRPM: number,
	RedlineTorque: number, -- n-m
	RedlineTorqueCurve: number,
	
	Throttle: number,
	RPM: number,
	Torque: number,
	Ignired: boolean,
	
	Resistance: number,
	Adjust: number
}>

--// Constants
local Util = require(script.Parent.Parent.Raw.Util)
local Units = require(script.Parent.Parent.Raw.Units)

local STATIC_RESISTANCE = 5*Units.Torque_Nm
local DYNAMIC_RESISTANCE = 10*Units.Torque_Nm

local math_pi = math.pi
local math_max = math.max
local math_abs = math.abs
local math_sign = math.sign
local math_clamp = math.clamp

--// Structure
local Structure: Definition = {} :: Definition
Structure.__index = Structure

function Structure:_stepBefore(dt)
	local AngularVelocity = self.AngularVelocity do
		local idleVel = self.IdleRPM/Units.Rads_RPM
		if self.Ignired and AngularVelocity < idleVel then
			AngularVelocity = idleVel
		end
	end
	
	local RPM = AngularVelocity*Units.Rads_RPM
	self.RPM = RPM
	
	if self.Ignired then
		local Throttle = math_clamp(self.Throttle, 0, 1)
		Throttle = RPM > self.RedlineRPM and 0 or Throttle

		local x = RPM/1000
		local idleTQ = Util.computePower(self.IdleRPM/1000, self.IdleTorque, self.PeakTorqueRPM/1000, self.PeakTorque, self.PeakTorque, self.IdleTorqueCurve, x)
		local redlineTQ = Util.computePower(self.PeakTorqueRPM/1000, self.PeakTorque, self.RedlineRPM/1000, self.RedlineTorque, self.PeakTorque, 1/self.RedlineTorqueCurve, x)
		
		local mechTQ = self.Adjust*Throttle*(self.PeakTorque - idleTQ - redlineTQ)
		self.Torque = mechTQ
		
		AngularVelocity += dt*mechTQ/self.Inertia
	end
	
	self.AngularVelocity = AngularVelocity
	
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

return function(BASE: any): Definition
	local self = BASE or {} do
		self.PeakTorque = 150*Units.Torque_Nm
		self.PeakTorqueRPM = 5_200
		
		self.IdleRPM = 900
		self.IdleTorque = 40*Units.Torque_Nm
		self.IdleTorqueCurve = 0.5
		
		self.Redline = 7_600
		self.RedlineTorque = 90*Units.Torque_Nm
		self.RedlineTorqueCurve = 0.5
	end
	
	self.Inertia = 4
	
	self.AngularVelocity = 0
	
	self.Adjust = 1
	self.Throttle = 0
	self.RPM = 0
	self.Torque = 0
	self.Ignired = false

	self.Resistance = 0
	
	return setmetatable(self, Structure) :: any
end