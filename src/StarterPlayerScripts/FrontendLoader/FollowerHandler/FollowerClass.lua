local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local RemoteBank = require(ReplicatedStorage.RemoteBank)
local Zone = require(ReplicatedStorage.Utilities.Zone)

local Player = Players.LocalPlayer

local DEFENDER_SPEED_MULTIPLIER = 1.2
local DEFAULT_DEFENDER_VISUAL_YAW_DEGREES = 270
local STOP_MOVE_DISTANCE = 4
local CHASE_SLOWDOWN_DISTANCE = 12
local MIN_CHASE_SPEED_RATIO = 0.25
local ATTACK_DISTANCE = 10
local ATTACK_COOLDOWN = 0.75
local INITIAL_STABILIZE_TIME = 0.15

local function toAnimationAssetId(value)
	local numericValue = tonumber(value)
	if not numericValue or numericValue <= 0 then
		return nil
	end

	return "rbxassetid://" .. tostring(numericValue)
end

local function Attack(humanoidCFrame)
	local character = Player.Character
	if not character then
		return
	end

	RemoteBank.DropEntity:InvokeServer(true, humanoidCFrame)
end

local function getCharacterRoot(): BasePart?
	local character = Player.Character
	if not character then
		return nil
	end

	local root = character:FindFirstChild("HumanoidRootPart")
	if root and root:IsA("BasePart") then
		return root
	end

	return nil
end

local function getModelRoot(model: Model): BasePart?
	local root = model.PrimaryPart
	if root and root:IsA("BasePart") then
		return root
	end

	local humanoidRoot = model:FindFirstChild("HumanoidRootPart")
	if humanoidRoot and humanoidRoot:IsA("BasePart") then
		model.PrimaryPart = humanoidRoot
		return humanoidRoot
	end

	return nil
end

local function getRootMotor(modelRoot: BasePart): Motor6D?
	local torsoMotor = modelRoot:FindFirstChild("Torso")
	if torsoMotor and torsoMotor:IsA("Motor6D") then
		return torsoMotor
	end

	local rootJoint = modelRoot:FindFirstChild("RootJoint")
	if rootJoint and rootJoint:IsA("Motor6D") then
		return rootJoint
	end

	for _, child in modelRoot:GetChildren() do
		if child:IsA("Motor6D") then
			return child
		end
	end

	return nil
end

local function getVisualYawRadians(orientationDegrees: any): number
	if typeof(orientationDegrees) == "number" then
		return math.rad(orientationDegrees)
	end

	return math.rad(DEFAULT_DEFENDER_VISUAL_YAW_DEGREES)
end

local function withFixedY(cframe: CFrame, fixedY: number): CFrame
	return CFrame.fromMatrix(
		Vector3.new(cframe.Position.X, fixedY, cframe.Position.Z),
		cframe.XVector,
		cframe.YVector,
		cframe.ZVector
	)
end

local function forEachBasePart(model: Model, callback: (BasePart) -> ())
	for _, descendant in model:GetDescendants() do
		if descendant:IsA("BasePart") then
			callback(descendant)
		end
	end
end

local function zeroModelMotion(model: Model)
	forEachBasePart(model, function(part)
		part.AssemblyLinearVelocity = Vector3.zero
		part.AssemblyAngularVelocity = Vector3.zero
	end)
end

local function setupChaserPhysics(model: Model, modelRoot: BasePart, facingPart: BasePart?)
	forEachBasePart(model, function(part)
		if facingPart and part == facingPart then
			return
		end

		part.Anchored = false
		if part == modelRoot then
			part.CanCollide = false
			part.Massless = false
		else
			part.CanCollide = false
			part.Massless = true
		end
	end)
end

local function applyVisualYawOffset(model: Model, modelRoot: BasePart, orientationDegrees: any)
	if model:GetAttribute("VisualYawOffsetApplied") then
		return
	end

	local rotationOffset = CFrame.Angles(0, getVisualYawRadians(orientationDegrees), 0)
	local rootMotor = getRootMotor(modelRoot)
	if rootMotor then
		rootMotor.C0 = rootMotor.C0 * rotationOffset
		model:SetAttribute("VisualYawOffsetApplied", true)
	end
end

local function getFacingPart(model: Model): BasePart?
	local facingPart = model:FindFirstChild("Facing", true)
	if facingPart and facingPart:IsA("BasePart") then
		return facingPart
	end

	return nil
end

local function setupFacingPart(facingPart: BasePart)
	facingPart.CanCollide = false
	facingPart.CanTouch = false
	facingPart.CanQuery = false
	facingPart.Massless = true
	for _, joint in facingPart:GetJoints() do
		joint:Destroy()
	end
	facingPart.Anchored = true
end

local function getFlatForwardDirection(root: BasePart): Vector3
	local forward = Vector3.new(root.CFrame.LookVector.X, 0, root.CFrame.LookVector.Z)
	if forward.Magnitude <= 0.001 then
		return Vector3.new(0, 0, -1)
	end

	return forward.Unit
end

local function setFacingIdle(facingPart: BasePart, modelRoot: BasePart, facingPositionOffset: Vector3)
	local facingPosition = modelRoot.CFrame:PointToWorldSpace(facingPositionOffset)
	local flatForward = getFlatForwardDirection(modelRoot)
	facingPart.CFrame = CFrame.lookAt(facingPosition, facingPosition + flatForward)
end

local function updateModelFacing(modelRoot: BasePart, targetRoot: BasePart, fixedY: number)
	local modelPosition = Vector3.new(modelRoot.Position.X, fixedY, modelRoot.Position.Z)
	local targetPosition = Vector3.new(targetRoot.Position.X, fixedY, targetRoot.Position.Z)
	local flatDelta = targetPosition - modelPosition
	if flatDelta.Magnitude <= 0.001 then
		return
	end

	local lookCFrame = CFrame.lookAt(modelPosition, targetPosition)
	modelRoot.CFrame = lookCFrame
end

local function updateFacingPart(facingPart: BasePart, modelRoot: BasePart, targetRoot: BasePart, facingPositionOffset: Vector3)
	local facingPosition = modelRoot.CFrame:PointToWorldSpace(facingPositionOffset)
	local targetPosition = targetRoot.Position
	if (targetPosition - facingPosition).Magnitude <= 0.001 then
		setFacingIdle(facingPart, modelRoot, facingPositionOffset)
		return
	end

	facingPart.CFrame = CFrame.lookAt(facingPosition, targetPosition)
end

local function getDesiredHorizontalVelocity(fromPosition: Vector3, toPosition: Vector3, maxSpeed: number): (Vector3, number)
	local delta = toPosition - fromPosition
	local flatDelta = Vector3.new(delta.X, 0, delta.Z)
	local distance = flatDelta.Magnitude
	if distance <= STOP_MOVE_DISTANCE or distance <= 0.001 then
		return Vector3.zero, distance
	end

	local direction = flatDelta.Unit
	local slowdownAlpha = math.clamp((distance - STOP_MOVE_DISTANCE) / CHASE_SLOWDOWN_DISTANCE, 0, 1)
	local speedRatio = math.max(MIN_CHASE_SPEED_RATIO, slowdownAlpha)
	local speed = maxSpeed * speedRatio

	return direction * speed, distance
end

local function startFollowing(model: Model, checkForElegibility, normalSpeed, idleAnimationId, walkingAnimationId, orientationDegrees, fixedY: number)
	local humanoid = model:FindFirstChildOfClass("Humanoid")
	if not humanoid then
		return
	end

	local modelRoot = getModelRoot(model)
	if not modelRoot then
		return
	end

	if model:GetAttribute("FollowerLoopStarted") then
		return
	end
	model:SetAttribute("FollowerLoopStarted", true)

	applyVisualYawOffset(model, modelRoot, orientationDegrees)

	local facingPart = getFacingPart(model)
	local facingPositionOffset: Vector3?
	setupChaserPhysics(model, modelRoot, facingPart)
	modelRoot.Anchored = false
	humanoid.AutoRotate = false
	humanoid.WalkSpeed = 0
	if facingPart then
		facingPositionOffset = modelRoot.CFrame:PointToObjectSpace(facingPart.Position)
		setupFacingPart(facingPart)
		setFacingIdle(facingPart, modelRoot, facingPositionOffset)
	end

	local animator = humanoid:FindFirstChildOfClass("Animator")
	local idleTrack: AnimationTrack?
	local walkingTrack: AnimationTrack?

	local idleAnimationAssetId = toAnimationAssetId(idleAnimationId)
	local walkingAnimationAssetId = toAnimationAssetId(walkingAnimationId)
	if animator and idleAnimationAssetId and walkingAnimationAssetId then
		local idleAnimation = Instance.new("Animation")
		idleAnimation.AnimationId = idleAnimationAssetId
		local walkingAnimation = Instance.new("Animation")
		walkingAnimation.AnimationId = walkingAnimationAssetId
		idleTrack = animator:LoadAnimation(idleAnimation)
		walkingTrack = animator:LoadAnimation(walkingAnimation)
		idleAnimation:Destroy()
		walkingAnimation:Destroy()
		idleTrack:Play()
	end

	local playingAnimation = "Idle"
	local function setAnimationState(state: "Idle" | "Walking")
		if playingAnimation == state then
			return
		end

		if state == "Walking" then
			if idleTrack then
				idleTrack:Stop()
			end
			if walkingTrack then
				walkingTrack:Play()
			end
		else
			if walkingTrack then
				walkingTrack:Stop()
			end
			if idleTrack then
				idleTrack:Play()
			end
		end

		playingAnimation = state
	end

	local attackCooldownRemaining = 0
	local maxHorizontalSpeed = normalSpeed * DEFENDER_SPEED_MULTIPLIER
	local stabilizeRemaining = INITIAL_STABILIZE_TIME
	local isChasingPlayer = false

	local function applyIdleMotion(targetRoot: BasePart?)
		humanoid.WalkSpeed = 0
		modelRoot.CFrame = withFixedY(modelRoot.CFrame, fixedY)
		modelRoot.AssemblyLinearVelocity = Vector3.zero
		modelRoot.AssemblyAngularVelocity = Vector3.zero
		setAnimationState("Idle")

		if targetRoot then
			updateModelFacing(modelRoot, targetRoot, fixedY)
			if facingPart and facingPositionOffset then
				updateFacingPart(facingPart, modelRoot, targetRoot, facingPositionOffset)
			end
		elseif facingPart and facingPositionOffset then
			setFacingIdle(facingPart, modelRoot, facingPositionOffset)
		end
	end

	local heartbeatConnection: RBXScriptConnection?
	local destroyConnection: RBXScriptConnection?
	local function cleanupFollower()
		pcall(function()
			model:SetAttribute("FollowerLoopStarted", nil)
		end)
		if heartbeatConnection then
			heartbeatConnection:Disconnect()
			heartbeatConnection = nil
		end
		if destroyConnection then
			destroyConnection:Disconnect()
			destroyConnection = nil
		end
		if idleTrack then
			idleTrack:Stop()
			idleTrack:Destroy()
			idleTrack = nil
		end
		if walkingTrack then
			walkingTrack:Stop()
			walkingTrack:Destroy()
			walkingTrack = nil
		end
	end

	destroyConnection = model.Destroying:Connect(cleanupFollower)
	heartbeatConnection = RunService.Heartbeat:Connect(function(deltaTime)
		if not model.Parent or not humanoid.Parent then
			cleanupFollower()
			return
		end

		attackCooldownRemaining = math.max(0, attackCooldownRemaining - deltaTime)
		if stabilizeRemaining > 0 then
			stabilizeRemaining = math.max(0, stabilizeRemaining - deltaTime)
			applyIdleMotion()
			return
		end

		local currentStatus = checkForElegibility()
		local playerRoot = getCharacterRoot()
		if currentStatus ~= true then
			if isChasingPlayer then
				isChasingPlayer = false
				zeroModelMotion(model)
			end
			applyIdleMotion(playerRoot)
			return
		end

		if not playerRoot then
			applyIdleMotion()
			return
		end

		if not isChasingPlayer then
			isChasingPlayer = true
			modelRoot.CFrame = withFixedY(modelRoot.CFrame, fixedY)
		end

		local desiredVelocity, distanceToPlayer = getDesiredHorizontalVelocity(modelRoot.Position, playerRoot.Position, maxHorizontalSpeed)
		local isMoving = desiredVelocity.Magnitude > 0.01
		setAnimationState(if isMoving then "Walking" else "Idle")

		if isMoving then
			modelRoot.AssemblyLinearVelocity = Vector3.new(desiredVelocity.X, 0, desiredVelocity.Z)
			modelRoot.AssemblyAngularVelocity = Vector3.zero
			updateModelFacing(modelRoot, playerRoot, fixedY)

			if facingPart and facingPositionOffset then
				updateFacingPart(facingPart, modelRoot, playerRoot, facingPositionOffset)
			end
		else
			applyIdleMotion(playerRoot)
		end

		if distanceToPlayer < ATTACK_DISTANCE and attackCooldownRemaining <= 0 then
			attackCooldownRemaining = ATTACK_COOLDOWN
			Attack(model:GetPivot())
		end
	end)
end

return function(spawnPosition, model, baseNumber, zone, baseSpeed, idleAnimationId, walkingAnimationId, orientationDegrees)
	local newZone
	local fixedY = model:GetPivot().Position.Y
	if zone and zone:IsA("BasePart") then
		zone.CollisionGroup = "Default"
		newZone = Zone.new(zone)
	end

	local function check()
		local currentAttributeValue = Player:GetAttribute("Carrying")
		if currentAttributeValue == baseNumber then
			return true
		end

		if not currentAttributeValue and newZone then
			if newZone:findLocalPlayer() then
				return false
			end
		end

		return nil
	end

	local previousValue = false
	local carryingConnection
	carryingConnection = Player:GetAttributeChangedSignal("Carrying"):Connect(function()
		local currentAttributeValue = Player:GetAttribute("Carrying")
		if previousValue == baseNumber then
			model:PivotTo(withFixedY(spawnPosition, fixedY))
			zeroModelMotion(model)
		end
		previousValue = currentAttributeValue
	end)

	model.Destroying:Connect(function()
		if carryingConnection then
			carryingConnection:Disconnect()
			carryingConnection = nil
		end
		if newZone then
			newZone:destroy()
			newZone = nil
		end
	end)

	startFollowing(model, check, baseSpeed, idleAnimationId, walkingAnimationId, orientationDegrees, fixedY)
end
