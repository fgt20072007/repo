--!strict
--!native
--!optimize 2

local PACKAGE = script.Parent.Parent
local Types = require(PACKAGE.Raw.Types)

--// Dependencies


--// Types


--// Constants


--// Structure
local Structure: Types.SQI = {} :: Types.SQI
Structure.__index = Structure

function Structure:Solve(dt, Components)
	for n, Component in Components do
		if Component._resetImpulse then
			Component:_resetImpulse()
		end
	end
	
	for n, Component in Components do
		if Component._stepBefore then
			Component:_stepBefore(dt)
		end
	end

	self._oddeven = self._oddeven and 1 - self._oddeven or 1
	for _ = 0, self.ITERATIONS + self._oddeven - 1 do
		for n, Component in Components do
			if Component._setError then
				Component:_setError(dt, self.ERROR_SCALING)
			end
		end

		for n, Component in Components do
			if Component._resetImpulse then
				Component:_resetImpulse()
			end
		end

		for n, Component in Components do
			if Component._setImpulse then
				Component:_setImpulse(dt)
			end
		end
	end

	for n, Component in Components do
		if Component._stepAfter then
			Component:_stepAfter(dt)
		end
	end
end

function Structure:Step(dt, Components)
	local ndt = dt/self.SUBSTEPS
	
	for _ = 1, self.SUBSTEPS do
		self:Solve(ndt, Components)
	end
end

return function(BASE: any): Types.SQI
	local self = BASE or {} do
		self.ITERATIONS = self.ITERATIONS or 50
		self.SUBSTEPS = self.SUBSTEPS or 4
		self.ERROR_SCALING = 0.3
		
		self._oddeven = 0
	end

	return setmetatable(self, Structure) :: any
end