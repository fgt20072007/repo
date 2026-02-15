local LocomotionStateMachine = {}
LocomotionStateMachine.__index = LocomotionStateMachine

local JUMP_STATES = {
	[Enum.HumanoidStateType.Jumping] = true,
	[Enum.HumanoidStateType.Climbing] = true,
}

local FALL_STATES = {
	[Enum.HumanoidStateType.Freefall] = true,
	[Enum.HumanoidStateType.FallingDown] = true,
}

function LocomotionStateMachine.new(config)
	local self = setmetatable({}, LocomotionStateMachine)
	self._config = config
	self._wasGroundMoving = false
	return self
end

function LocomotionStateMachine:_getHorizontalSpeed(humanoid, rootPart)
	if rootPart and rootPart:IsA("BasePart") then
		local linearVelocity = rootPart.AssemblyLinearVelocity
		return Vector3.new(linearVelocity.X, 0, linearVelocity.Z).Magnitude
	end

	return humanoid.MoveDirection.Magnitude * humanoid.WalkSpeed
end

function LocomotionStateMachine:GetState(humanoid, rootPart)
	if humanoid.Health <= 0 then
		self._wasGroundMoving = false
		return "Idle", 0
	end

	local currentState = humanoid:GetState()
	if JUMP_STATES[currentState] then
		self._wasGroundMoving = false
		return "Jump", 0
	end

	if FALL_STATES[currentState] then
		self._wasGroundMoving = false
		return "Fall", 0
	end

	if humanoid.FloorMaterial == Enum.Material.Air then
		self._wasGroundMoving = false
		if rootPart and rootPart:IsA("BasePart") and rootPart.AssemblyLinearVelocity.Y > 0 then
			return "Jump", 0
		end

		return "Fall", 0
	end

	local speed = self:_getHorizontalSpeed(humanoid, rootPart)
	local defaultThreshold = self._config.MoveThreshold or 0.08
	local startThreshold = self._config.MoveThresholdStart or defaultThreshold
	local stopThreshold = self._config.MoveThresholdStop or defaultThreshold

	if self._wasGroundMoving then
		if speed <= stopThreshold then
			self._wasGroundMoving = false
			return "Idle", speed
		end

		return "Walk", speed
	end

	if speed >= startThreshold then
		self._wasGroundMoving = true
		return "Walk", speed
	end

	return "Idle", speed
end

return LocomotionStateMachine