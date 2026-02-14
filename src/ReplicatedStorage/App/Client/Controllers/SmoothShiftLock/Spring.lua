-- Spring.lua
-- A clean, smooth spring simulator for position/velocity interpolation.

local Spring = {}
Spring.__index = Spring

-- Constructor: creates a new spring object
function Spring.new(initialPosition, clockFunc)
	local pos = initialPosition or 0
	local clock = clockFunc or os.clock
	local now = clock()

	return setmetatable({
		_clock = clock,
		_time0 = now,
		_position0 = pos,
		_velocity0 = pos * 0,
		_target = pos,
		_damper = 1,
		_speed = 1,
	}, Spring)
end

-- Adds an impulse (change in velocity)
function Spring:Impulse(impulse)
	self.Velocity += impulse
end

-- Skip forward in time
function Spring:TimeSkip(deltaTime)
	local now = self._clock()
	local pos, vel = self:_compute(now + deltaTime)
	self._position0 = pos
	self._velocity0 = vel
	self._time0 = now
end

-- Index getter
function Spring.__index(self, key)
	if rawget(Spring, key) then
		return Spring[key]
	end

	local now = self._clock()

	if key == "Value" or key == "Position" or key == "p" then
		local pos = self:_compute(now)
		return pos
	elseif key == "Velocity" or key == "v" then
		local _, vel = self:_compute(now)
		return vel
	elseif key == "Target" or key == "t" then
		return self._target
	elseif key == "Damper" or key == "d" then
		return self._damper
	elseif key == "Speed" or key == "s" then
		return self._speed
	elseif key == "Clock" then
		return self._clock
	end

	error(("%q is not a valid member of Spring"):format(tostring(key)), 2)
end

-- Index setter
function Spring.__newindex(self, key, value)
	local now = self._clock()
	local pos, vel = self:_compute(now)

	if key == "Value" or key == "Position" or key == "p" then
		self._position0 = value
		self._velocity0 = vel
	elseif key == "Velocity" or key == "v" then
		self._position0 = pos
		self._velocity0 = value
	elseif key == "Target" or key == "t" then
		self._position0 = pos
		self._velocity0 = vel
		self._target = value
	elseif key == "Damper" or key == "d" then
		self._position0 = pos
		self._velocity0 = vel
		self._damper = value
	elseif key == "Speed" or key == "s" then
		self._position0 = pos
		self._velocity0 = vel
		self._speed = value >= 0 and value or self._speed
	elseif key == "Clock" then
		self._position0 = pos
		self._velocity0 = vel
		self._clock = value
		self._time0 = value()
	else
		error(("%q is not a valid member of Spring"):format(tostring(key)), 2)
	end

	self._time0 = now
end

-- Internal spring calculation (position, velocity)
function Spring:_compute(t)
	local p0 = self._position0
	local v0 = self._velocity0
	local target = self._target
	local damper = self._damper
	local speed = self._speed
	local delta = speed * (t - self._time0)
	local dampingSquared = damper * damper

	local posFactor, velFactor

	if dampingSquared < 1 then
		-- Underdamped
		local c = math.sqrt(1 - dampingSquared)
		local expTerm = math.exp(-damper * delta)
		local cosTerm = math.cos(c * delta)
		local sinTerm = math.sin(c * delta)

		local common = expTerm / c
		posFactor = common * sinTerm
		velFactor = expTerm * cosTerm
	elseif dampingSquared == 1 then
		-- Critically damped
		local expTerm = math.exp(-damper * delta)
		posFactor = expTerm * delta
		velFactor = expTerm
	else
		-- Overdamped
		local c = math.sqrt(dampingSquared - 1)
		local r1 = -damper + c
		local r2 = -damper - c

		local exp1 = math.exp(r1 * delta)
		local exp2 = math.exp(r2 * delta)

		posFactor = (exp1 - exp2) / (2 * c)
		velFactor = (exp1 + exp2) / (2 * c)
	end

	-- Interpolated position and velocity
	local pos = (velFactor * p0 + damper * posFactor * p0) + (1 - (velFactor + damper * posFactor)) * target + (posFactor / speed) * v0
	local vel = -speed * posFactor * p0 + speed * posFactor * target + (velFactor - damper * posFactor) * v0

	return pos, vel
end

return Spring
