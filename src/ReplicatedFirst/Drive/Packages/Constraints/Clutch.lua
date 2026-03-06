--!strict
--!native
--!optimize 2

local PHYSICS = script.Parent.Parent

--// Types
local Types = require(PHYSICS.Raw.Types)

export type Definition = Types.Constraint <{
	Input: number,
	MaxTorque: number,
}>

--// Dependencies
local Units = require(PHYSICS.Raw.Units)

--// Constants
local math_sign = math.sign
local math_clamp = math.clamp

--// Structure
local Structure: Definition = {} :: Definition
Structure.__index = Structure

function Structure:_stepBefore(dt)
	local att1 = self.Attachments[1]
	local att2 = self.Attachments[2]
	
	self.Impulse = math_sign(att1.AngularVelocity - att2.AngularVelocity)*self.MaxTorque*dt

	att1.AccumulatedImpulse -= self.Impulse
	att2.AccumulatedImpulse += self.Impulse
end

function Structure:_setError(dt, err)
	local att1 = self.Attachments[1]
	local att2 = self.Attachments[2]

	local a0 = att1.AngularVelocity + att1.AccumulatedImpulse/att1.Inertia
	local a1 = att2.AngularVelocity + att2.AccumulatedImpulse/att2.Inertia
	local I = 1/att1.Inertia + 1/att2.Inertia

	self.Error = err*(a0 - a1)/I
end

function Structure:_setImpulse(dt)
	local att1 = self.Attachments[1]
	local att2 = self.Attachments[2]
	
	local MaxTorque = self.MaxTorque*dt
	self.Impulse = math_clamp(self.Impulse + self.Error, -MaxTorque, MaxTorque)

	att1.AccumulatedImpulse -= self.Impulse
	att2.AccumulatedImpulse += self.Impulse
end

return function(BASE: any): Definition
	local self = BASE or {} do
		self.MaxTorque = 0
	end
	
	return setmetatable(self, Structure) :: any
end