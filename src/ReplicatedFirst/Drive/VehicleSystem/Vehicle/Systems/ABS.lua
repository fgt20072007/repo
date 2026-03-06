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

	Brakes: {any},
	Active: boolean,
	Enabled: boolean,
	
	Limit: number,
	Threshold: number,
}

local math_abs = math.abs
local math_sign = math.sign

local vector3_zero = Vector3.zero
local vector3_dot = vector3_zero.Dot

local cframe_identity = CFrame.identity

--// Structure
local Structure: Definition = {} :: Definition
Structure.__index = Structure

function Structure:Step(dt)
	if not self.Enabled then return end
	
	local Limit = self.Limit
	local Threshold = self.Threshold
	
	local Active = false
	for _, Brake in self.Brakes do
		local Attachment = Brake.Attachments[1]
		if not Attachment.Root then continue end

		local tq = Attachment.AngularVelocity*Attachment.Radius
		
		local HubAttachment = Attachment.HubAttachment
		local WorldVelocity = Attachment.Root:GetVelocityAtPosition(HubAttachment.Position)
		local ZVelocity = vector3_dot(HubAttachment.WorldCFrame.LookVector, WorldVelocity)
		
		if Brake.Input > 0 and math_abs(math_abs(tq) - math_abs(ZVelocity)) > Threshold then
			Brake.Input *= Limit
			Active = true
		end
	end
	
	self.Active = Active
end

return function(BASE: any): Definition
	local self = BASE or {} do
		self.Active = false
		self.Enabled = true

		self.Limit = self.Limit or 0
		self.Threshold = self.Threshold or 4*Units.KMH_Studs
	end
	
	return setmetatable(self, Structure) :: any
end