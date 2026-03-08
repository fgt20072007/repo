--!strict
--!native
--!optimize 2

--// Services


--// Folders
local PACKAGES = script.Parent.Parent.Parent.Parent.Packages

--// Dependencies
local Units = require(PACKAGES.Raw.Units)

type Definition = {
	__index: Definition,
	
	Step: (self: Definition, dt: number) -> (),
	
	Engine: any,
	Brakes: {any},
	Active: boolean,
	Enabled: boolean,
	
	Limit: number,
	Gradient: number,
	Threshold: number,
}

local math_abs = math.abs
local math_max = math.max
local math_sign = math.sign
local math_clamp = math.clamp

local vector3_zero = Vector3.zero
local vector3_dot = vector3_zero.Dot

local cframe_identity = CFrame.identity

--// Structure
local Structure: Definition = {} :: Definition
Structure.__index = Structure

function Structure:Step(dt)
	if not self.Enabled then return end
	if self.Engine.Throttle == 0 then
		self.Engine.Adjust = 1
		return
	end
	
	local Limit = self.Limit
	local Gradient = self.Gradient
	local Threshold = self.Threshold
	
	local Adjust = 0
	for _, Brake in self.Brakes do
		local Attachment = Brake.Attachments[1]
		if not Attachment.Root then continue end

		local tq = Attachment.AngularVelocity*Attachment.Radius
		
		local HubAttachment = Attachment.HubAttachment
		local WorldVelocity = Attachment.Root:GetVelocityAtPosition(HubAttachment.Position)
		local ZVelocity = vector3_dot(HubAttachment.WorldCFrame.LookVector, WorldVelocity)
		
		local Coast = Limit*math_clamp((math_abs(tq) - math_abs(ZVelocity) - Gradient)/Threshold, 0, 1)
		Brake.Input = math_max(Brake.Input, Coast)
		
		Adjust = math_max(Adjust, Coast)
	end
	
	self.Active = Adjust ~= 0
	self.Engine.Adjust = 1 - Adjust
end

return function(BASE: any): Definition
	local self = BASE or {} do
		self.Active = false
		self.Enabled = true
		
		self.Limit = self.Limit or 1 - 8/100
		self.Gradient = self.Gradient or 20*Units.KMH_Studs
		self.Threshold = self.Threshold or 10*Units.KMH_Studs
	end
	
	return setmetatable(self, Structure) :: any
end