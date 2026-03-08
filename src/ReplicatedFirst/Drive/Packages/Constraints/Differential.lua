--!strict
--!native
--!optimize 2

local PHYSICS = script.Parent.Parent

--// Types
local Types = require(PHYSICS.Raw.Types)

export type Definition = Types.Constraint <{
	Input: number,
	Bias: number,
	Ratio: number,
	Preload: number,
	MaxTorque: number,
}>

--// Dependencies
local Units = require(PHYSICS.Raw.Units)

--// Constants
local math_clamp = math.clamp

--// Structure
local Structure: Definition = {} :: Definition
Structure.__index = Structure

function Structure:_stepBefore(dt)
	local att1 = self.Attachments[1]
	local att2 = self.Attachments[2]
	local att3 = self.Attachments[3]
	local att4 = self.Attachments[4]
	local att5 = self.Attachments[5]
	
	local bR = 1 - self.Bias
	local bF = self.Bias

	local MaxTorque = self.Input*self.MaxTorque*dt

	local vR = att2.AngularVelocity + att3.AngularVelocity
	local vF = att4.AngularVelocity + att5.AngularVelocity

	local iR = bR/att2.Inertia + bR/att3.Inertia
	local iF = bF/att4.Inertia + bF/att5.Inertia

	local F = att1.AngularVelocity + self.Ratio*(bR*vR + bF*vF)
	local I = 1/att1.Inertia + self.Ratio*self.Ratio*(iR + iF)

	self.Impulse = math_clamp(F/I, -MaxTorque, MaxTorque)

	att1.AccumulatedImpulse -= self.Impulse

	local impR = bR*self.Ratio*self.Impulse
	local impF = bF*self.Ratio*self.Impulse

	att2.AccumulatedImpulse -= impR
	att3.AccumulatedImpulse -= impR
	att4.AccumulatedImpulse -= impF
	att5.AccumulatedImpulse -= impF
end

function Structure:_setError(dt, err)
	local att1 = self.Attachments[1]
	local att2 = self.Attachments[2]
	local att3 = self.Attachments[3]
	local att4 = self.Attachments[4]
	local att5 = self.Attachments[5]
	
	local bR = 1 - self.Bias
	local bF = self.Bias

	local aP = att1.AngularVelocity + att1.AccumulatedImpulse/att1.Inertia

	local aRL = att2.AngularVelocity + att2.AccumulatedImpulse/att2.Inertia
	local aRR = att3.AngularVelocity + att3.AccumulatedImpulse/att3.Inertia
	local aFL = att4.AngularVelocity + att4.AccumulatedImpulse/att4.Inertia
	local aFR = att5.AngularVelocity + att5.AccumulatedImpulse/att5.Inertia

	local iR = bR/att2.Inertia + bR/att3.Inertia
	local iF = bF/att4.Inertia + bF/att5.Inertia

	local I = 1/att1.Inertia + self.Ratio*self.Ratio*(iR + iF)

	self.Error = err*(aP + self.Ratio*(bR*(aRL + aRR) + bF*(aFL + aFR)))/I
end

function Structure:_setImpulse(dt)
	local att1 = self.Attachments[1]
	local att2 = self.Attachments[2]
	local att3 = self.Attachments[3]
	local att4 = self.Attachments[4]
	local att5 = self.Attachments[5]
	
	local bR = 1 - self.Bias
	local bF = self.Bias

	local MaxTorque = self.Input*self.MaxTorque*dt
	self.Impulse = math_clamp(self.Impulse + self.Error, -MaxTorque, MaxTorque)

	att1.AccumulatedImpulse -= self.Impulse

	local impR = bR*self.Ratio*self.Impulse
	local impF = bF*self.Ratio*self.Impulse

	att2.AccumulatedImpulse -= impR
	att3.AccumulatedImpulse -= impR
	att4.AccumulatedImpulse -= impF
	att5.AccumulatedImpulse -= impF
end

return function(BASE: any): Definition
	local self = BASE or {} do
		self.Input = 0
		self.Bias = 0.5
		self.Ratio = 1
		self.Preload = 0
		self.MaxTorque = 0
	end

	return setmetatable(self, Structure) :: any
end