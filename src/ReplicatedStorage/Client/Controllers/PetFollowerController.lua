local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Assets = ReplicatedStorage:WaitForChild("Assets")

local AllPets = require(Shared.Data.Eggs:WaitForChild("AllPets"))
local GlobalAnimations = require(Shared.Data:WaitForChild("GlobalAnimations"))
local Client = require(ReplicatedStorage:WaitForChild("Client"))

local Player = Players.LocalPlayer

local PetChanceByName = {}
for _, pet in ipairs(AllPets) do
	if type(pet) ~= "table" then continue end
	if type(pet.Name) ~= "string" then continue end
	if type(pet.Chance) ~= "number" then continue end
	PetChanceByName[pet.Name] = pet.Chance
end

local function HashUnitFromString(value: string, salt: number): number
	local hash = salt
	for index = 1, #value do
		hash = ((hash * 131) + string.byte(value, index)) % 2147483647
	end

	return hash / 2147483647
end

local function HashSignedFromString(value: string, salt: number, magnitude: number): number
	if magnitude <= 0 then
		return 0
	end

	return ((HashUnitFromString(value, salt) * 2) - 1) * magnitude
end

local DEFAULT_PET_ANIMATIONS = {
	Follow = {
		PerRow = 4,
		RowsTarget = 5,
		MaxPerRow = 8,
		BackOffset = 6,
		RowSpacing = 3,
		ArcSpread = math.rad(120),
		RowStagger = 0.6,
		JitterX = 1,
		JitterZ = 0.7,
		DriftAmplitude = 0.5,
		DriftFrequency = 1.5,
		HeightOffset = 2,
		PositionResponsiveness = 10,
		BaseDelay = 0,
		DelayPerPet = 0.1,
		TrailDuration = 1.3,
		YawOffset = 0,
		ModelScale = 1,
	},
	Float = {
		Amplitude = 0.7,
		Frequency = 2,
		VelocityFrequencyScale = 0.02,
	},
	Sway = {
		PitchAmplitude = math.rad(6),
		RollAmplitude = math.rad(5),
		Frequency = 2,
		MaxSpeed = 16,
	},
	VerticalFollow = {
		Stiffness = 20,
		Damping = 10,
		JumpLagStrength = 0.08,
		FallCatchupStrength = 0.03,
		MaxJumpLag = 2.5,
	},
	Fly = {
		ExtraFloatAmplitude = 0.45,
		ExtraFloatFrequency = 4.5,
		LateralAmplitude = 0.35,
		LateralFrequency = 3.2,
		DepthAmplitude = 0.2,
		DepthFrequency = 2.7,
		YawAmplitude = math.rad(8),
		YawFrequency = 2.8,
		PitchAmplitude = math.rad(9),
		RollAmplitude = math.rad(11),
	},
	Ground = {
		HeightOffset = 0,
		RaycastHeight = 8,
		RaycastDistance = 30,
		FallbackDepth = 3,
		HopChance = 0.35,
		HopHeight = 0.7,
		HopFrequency = 5.8,
		HopTilt = math.rad(12),
		HopSpeedThreshold = 0.18,
		StepHeight = 0.35,
		WalkFrequency = 8,
		SideSway = 0.22,
		PitchAmplitude = math.rad(10),
		RollAmplitude = math.rad(8),
		IdleAmplitude = 0.06,
		IdleFrequency = 2.2,
		SpeedForFullWalk = 14,
	},
}

local function NumberOrDefault(value, defaultValue: number): number
	if type(value) == "number" then
		return value
	end

	return defaultValue
end

local function HasTagInModel(model: Model, tagName: string): boolean
	if model:HasTag(tagName) then
		return true
	end

	for _, descendant in model:GetDescendants() do
		if descendant:HasTag(tagName) then
			return true
		end
	end

	return false
end

local PetFollowerController = {}

function PetFollowerController._Init(self: PetFollowerController)
	self.PetModels = Assets:WaitForChild("Models"):WaitForChild("Pets")
	self:_ResolveAnimationSettings()

	self.Pets = {}
	self.EquippedPets = {}
	self.Followers = {}
	self.OrderedFollowerIds = {}
	self.RootTrail = {}
	self.Time = 0

	self.FollowerFolder = Instance.new("Folder")
	self.FollowerFolder.Name = `ClientPetFollowers_{Player.UserId}`
	self.FollowerFolder.Parent = workspace

	self.GroundRaycastParams = RaycastParams.new()
	self.GroundRaycastParams.FilterType = Enum.RaycastFilterType.Exclude
	self.GroundRaycastParams.IgnoreWater = true
	self.GroundRaycastParams.RespectCanCollide = false
	self.GroundRaycastFilter = { self.FollowerFolder }
	self:_RefreshGroundRaycastFilter()
end

function PetFollowerController._ResolveAnimationSettings(self: PetFollowerController)
	local petsAnimations = GlobalAnimations.Pets or {}
	local follow = petsAnimations.Follow or {}
	local float = petsAnimations.Float or {}
	local sway = petsAnimations.Sway or {}
	local vertical = petsAnimations.VerticalFollow or {}
	local fly = petsAnimations.Fly or {}
	local ground = petsAnimations.Ground or {}
	local defaultFollow = DEFAULT_PET_ANIMATIONS.Follow
	local defaultFloat = DEFAULT_PET_ANIMATIONS.Float
	local defaultSway = DEFAULT_PET_ANIMATIONS.Sway
	local defaultVertical = DEFAULT_PET_ANIMATIONS.VerticalFollow
	local defaultFly = DEFAULT_PET_ANIMATIONS.Fly
	local defaultGround = DEFAULT_PET_ANIMATIONS.Ground
	local n = NumberOrDefault

	self.Settings = {
		Follow = {
			PerRow = math.max(1, math.floor(n(follow.PerRow, defaultFollow.PerRow))),
			RowsTarget = math.max(1, math.floor(n(follow.RowsTarget, defaultFollow.RowsTarget))),
			MaxPerRow = math.max(1, math.floor(n(follow.MaxPerRow, defaultFollow.MaxPerRow))),
			BackOffset = n(follow.BackOffset, defaultFollow.BackOffset),
			RowSpacing = n(follow.RowSpacing, defaultFollow.RowSpacing),
			ArcSpread = n(follow.ArcSpread, defaultFollow.ArcSpread),
			RowStagger = n(follow.RowStagger, defaultFollow.RowStagger),
			JitterX = n(follow.JitterX, defaultFollow.JitterX),
			JitterZ = n(follow.JitterZ, defaultFollow.JitterZ),
			DriftAmplitude = n(follow.DriftAmplitude, defaultFollow.DriftAmplitude),
			DriftFrequency = n(follow.DriftFrequency, defaultFollow.DriftFrequency),
			HeightOffset = n(follow.HeightOffset, defaultFollow.HeightOffset),
			PositionResponsiveness = math.max(
				0.01,
				n(follow.PositionResponsiveness, defaultFollow.PositionResponsiveness)
			),
			BaseDelay = math.max(0, n(follow.BaseDelay, defaultFollow.BaseDelay)),
			DelayPerPet = math.max(0, n(follow.DelayPerPet, defaultFollow.DelayPerPet)),
			TrailDuration = math.max(0.1, n(follow.TrailDuration, defaultFollow.TrailDuration)),
			YawOffset = n(follow.YawOffset, defaultFollow.YawOffset),
			ModelScale = math.max(0.01, n(follow.ModelScale, defaultFollow.ModelScale)),
		},
		Float = {
			Amplitude = n(float.Amplitude, defaultFloat.Amplitude),
			Frequency = n(float.Frequency, defaultFloat.Frequency),
			VelocityFrequencyScale = n(
				float.VelocityFrequencyScale,
				defaultFloat.VelocityFrequencyScale
			),
		},
		Sway = {
			PitchAmplitude = n(sway.PitchAmplitude, defaultSway.PitchAmplitude),
			RollAmplitude = n(sway.RollAmplitude, defaultSway.RollAmplitude),
			Frequency = n(sway.Frequency, defaultSway.Frequency),
			MaxSpeed = math.max(0.1, n(sway.MaxSpeed, defaultSway.MaxSpeed)),
		},
		VerticalFollow = {
			Stiffness = n(vertical.Stiffness, defaultVertical.Stiffness),
			Damping = n(vertical.Damping, defaultVertical.Damping),
			JumpLagStrength = n(vertical.JumpLagStrength, defaultVertical.JumpLagStrength),
			FallCatchupStrength = n(vertical.FallCatchupStrength, defaultVertical.FallCatchupStrength),
			MaxJumpLag = n(vertical.MaxJumpLag, defaultVertical.MaxJumpLag),
		},
		Fly = {
			ExtraFloatAmplitude = n(fly.ExtraFloatAmplitude, defaultFly.ExtraFloatAmplitude),
			ExtraFloatFrequency = n(fly.ExtraFloatFrequency, defaultFly.ExtraFloatFrequency),
			LateralAmplitude = n(fly.LateralAmplitude, defaultFly.LateralAmplitude),
			LateralFrequency = n(fly.LateralFrequency, defaultFly.LateralFrequency),
			DepthAmplitude = n(fly.DepthAmplitude, defaultFly.DepthAmplitude),
			DepthFrequency = n(fly.DepthFrequency, defaultFly.DepthFrequency),
			YawAmplitude = n(fly.YawAmplitude, defaultFly.YawAmplitude),
			YawFrequency = n(fly.YawFrequency, defaultFly.YawFrequency),
			PitchAmplitude = n(fly.PitchAmplitude, defaultFly.PitchAmplitude),
			RollAmplitude = n(fly.RollAmplitude, defaultFly.RollAmplitude),
		},
		Ground = {
			HeightOffset = n(ground.HeightOffset, defaultGround.HeightOffset),
			RaycastHeight = math.max(1, n(ground.RaycastHeight, defaultGround.RaycastHeight)),
			RaycastDistance = math.max(2, n(ground.RaycastDistance, defaultGround.RaycastDistance)),
			FallbackDepth = math.max(0, n(ground.FallbackDepth, defaultGround.FallbackDepth)),
			HopChance = math.clamp(n(ground.HopChance, defaultGround.HopChance), 0, 1),
			HopHeight = math.max(0, n(ground.HopHeight, defaultGround.HopHeight)),
			HopFrequency = math.max(0.1, n(ground.HopFrequency, defaultGround.HopFrequency)),
			HopTilt = n(ground.HopTilt, defaultGround.HopTilt),
			HopSpeedThreshold = math.clamp(n(ground.HopSpeedThreshold, defaultGround.HopSpeedThreshold), 0, 1),
			StepHeight = n(ground.StepHeight, defaultGround.StepHeight),
			WalkFrequency = n(ground.WalkFrequency, defaultGround.WalkFrequency),
			SideSway = n(ground.SideSway, defaultGround.SideSway),
			PitchAmplitude = n(ground.PitchAmplitude, defaultGround.PitchAmplitude),
			RollAmplitude = n(ground.RollAmplitude, defaultGround.RollAmplitude),
			IdleAmplitude = n(ground.IdleAmplitude, defaultGround.IdleAmplitude),
			IdleFrequency = n(ground.IdleFrequency, defaultGround.IdleFrequency),
			SpeedForFullWalk = math.max(0.1, n(ground.SpeedForFullWalk, defaultGround.SpeedForFullWalk)),
		},
	}
end

function PetFollowerController.Spawn(self: PetFollowerController)
	local DataController = Client.Controllers.DataController
	if not DataController then return end

	local Profile = DataController:GetProfile(true)
	self.Pets = type(Profile.Pets) == "table" and Profile.Pets or {}
	self.EquippedPets = type(Profile.EquippedPets) == "table" and Profile.EquippedPets or {}

	self:_SyncFollowers()

	DataController:OnChange("Pets", function(new)
		self.Pets = type(new) == "table" and new or {}
		self:_SyncFollowers()
	end)

	DataController:OnChange("EquippedPets", function(new)
		self.EquippedPets = type(new) == "table" and new or {}
		self:_SyncFollowers()
	end)

	RunService.RenderStepped:Connect(function(dt)
		self:_UpdateFollowers(dt)
	end)
end

function PetFollowerController._GetCharacterRootPart(self: PetFollowerController): BasePart?
	local Character = Player.Character
	if not Character then
		return nil
	end

	local Humanoid = Character:FindFirstChildOfClass("Humanoid")
	if not Humanoid or Humanoid.Health <= 0 then
		return nil
	end

	local RootPart = Character:FindFirstChild("HumanoidRootPart")
	if not RootPart or not RootPart:IsA("BasePart") then
		return nil
	end

	return RootPart
end

function PetFollowerController._BuildEquippedRecords(self: PetFollowerController)
	local equipped = {}

	for petId, isEquipped in self.EquippedPets do
		if isEquipped ~= true then
			continue
		end

		if typeof(petId) ~= "string" then
			continue
		end

		local petData = self.Pets[petId]
		if type(petData) ~= "table" then
			continue
		end

		local petName = petData.Name
		if type(petName) ~= "string" then
			continue
		end

		local template = self.PetModels:FindFirstChild(petName)
		if not template or not template:IsA("Model") then
			continue
		end

		local chance = tonumber(petData.Chance) or PetChanceByName[petName] or 1
		table.insert(equipped, {
			Id = petId,
			Name = petName,
			Chance = chance,
		})
	end

	table.sort(equipped, function(a, b)
		if a.Chance ~= b.Chance then
			return a.Chance < b.Chance
		end

		if a.Name ~= b.Name then
			return a.Name < b.Name
		end

		return a.Id < b.Id
	end)

	return equipped
end

function PetFollowerController._PrepareFollowerModel(self: PetFollowerController, model: Model)
	local primaryPart = model.PrimaryPart

	for _, descendant in model:GetDescendants() do
		if descendant:IsA("Script") or descendant:IsA("LocalScript") then
			descendant:Destroy()
		elseif descendant:IsA("BasePart") then
			descendant.Anchored = true
			descendant.CanCollide = false
			descendant.CanTouch = false
			descendant.CanQuery = false
			descendant.CastShadow = false

			if not primaryPart then
				primaryPart = descendant
			end
		end
	end

	if primaryPart then
		model.PrimaryPart = primaryPart
	end
end

function PetFollowerController._ResolveFollowerTraits(self: PetFollowerController, template: Model, petId: string)
	local isFlying = HasTagInModel(template, "Fly")
	if isFlying then
		return true, false
	end

	if HasTagInModel(template, "NoHop") then
		return false, false
	end

	if HasTagInModel(template, "Hop") then
		return false, true
	end

	local shouldHop = HashUnitFromString(petId, 97) <= self.Settings.Ground.HopChance
	return false, shouldHop
end

function PetFollowerController._CreateFollower(self: PetFollowerController, record)
	local template = self.PetModels:FindFirstChild(record.Name)
	if not template or not template:IsA("Model") then
		return nil
	end

	local model = template:Clone()
	self:_PrepareFollowerModel(model)
	if not model.PrimaryPart then
		model:Destroy()
		return nil
	end

	local scale = self.Settings.Follow.ModelScale
	if type(scale) == "number" and scale > 0 and scale ~= 1 then
		model:ScaleTo(scale)
	end

	local followSettings = self.Settings.Follow
	local jitterX = HashSignedFromString(record.Id, 17, followSettings.JitterX or 0)
	local jitterZ = HashSignedFromString(record.Id, 59, followSettings.JitterZ or 0)
	local isFlying, shouldHop = self:_ResolveFollowerTraits(template, record.Id)

	model:PivotTo(CFrame.new(0, -1000, 0))
	model.Parent = self.FollowerFolder

	local follower = {
		Id = record.Id,
		Name = record.Name,
		Chance = record.Chance,
		Model = model,
		Phase = math.random() * math.pi * 2,
		JitterX = jitterX,
		JitterZ = jitterZ,
		IsFlying = isFlying,
		ShouldHop = shouldHop,
		GroundLift = model.PrimaryPart.Size.Y * 0.5,
		CurrentCFrame = nil,
		VerticalOffset = 0,
		VerticalVelocity = 0,
	}

	self.Followers[record.Id] = follower
	return follower
end

function PetFollowerController._RemoveFollower(self: PetFollowerController, petId: string)
	local follower = self.Followers[petId]
	if not follower then
		return
	end

	if follower.Model and follower.Model.Parent then
		follower.Model:Destroy()
	end

	self.Followers[petId] = nil
end

function PetFollowerController._SyncFollowers(self: PetFollowerController)
	local equippedRecords = self:_BuildEquippedRecords()
	local keep = {}
	local orderedIds = {}

	for _, record in ipairs(equippedRecords) do
		keep[record.Id] = true
		table.insert(orderedIds, record.Id)

		local follower = self.Followers[record.Id]
		if follower then
			if follower.Name ~= record.Name then
				self:_RemoveFollower(record.Id)
				self:_CreateFollower(record)
				continue
			end

			follower.Name = record.Name
			follower.Chance = record.Chance
			local template = self.PetModels:FindFirstChild(record.Name)
			if template and template:IsA("Model") then
				local isFlying, shouldHop = self:_ResolveFollowerTraits(template, record.Id)
				follower.IsFlying = isFlying
				follower.ShouldHop = shouldHop
			end
		else
			self:_CreateFollower(record)
		end
	end

	local toRemove = {}
	for petId in self.Followers do
		if keep[petId] then
			continue
		end

		table.insert(toRemove, petId)
	end

	for _, petId in ipairs(toRemove) do
		self:_RemoveFollower(petId)
	end

	self.OrderedFollowerIds = orderedIds
	self:_SnapFollowersToTargets()
end

function PetFollowerController._ResolveLookVector(
	self: PetFollowerController,
	rootCFrame: CFrame,
	rootVelocity: Vector3
): Vector3
	local lookVector = Vector3.new(rootVelocity.X, 0, rootVelocity.Z)
	if lookVector.Magnitude < 0.05 then
		lookVector = Vector3.new(rootCFrame.LookVector.X, 0, rootCFrame.LookVector.Z)
	end
	if lookVector.Magnitude < 1e-4 then
		return Vector3.new(0, 0, -1)
	end

	return lookVector.Unit
end

function PetFollowerController._RefreshGroundRaycastFilter(self: PetFollowerController)
	local filter = self.GroundRaycastFilter
	filter[1] = self.FollowerFolder

	local character = Player.Character
	if character then
		filter[2] = character
		filter[3] = nil
	else
		filter[2] = nil
	end

	self.GroundRaycastParams.FilterDescendantsInstances = filter
end

function PetFollowerController._SampleGroundData(self: PetFollowerController, position: Vector3): (number, Vector3)
	local groundSettings = self.Settings.Ground
	local castOrigin = position + Vector3.new(0, groundSettings.RaycastHeight, 0)
	local castDistance = groundSettings.RaycastHeight + groundSettings.RaycastDistance
	local result = workspace:Raycast(castOrigin, Vector3.new(0, -castDistance, 0), self.GroundRaycastParams)
	if result then
		return result.Position.Y, result.Normal
	end

	return position.Y - groundSettings.FallbackDepth, Vector3.new(0, 1, 0)
end

function PetFollowerController._GetPetsPerRow(self: PetFollowerController, total: number): number
	local followSettings = self.Settings.Follow
	local basePerRow = math.max(1, math.floor(followSettings.PerRow))
	local targetRows = math.max(1, math.floor(followSettings.RowsTarget))
	local maxPerRow = math.max(basePerRow, math.floor(followSettings.MaxPerRow))
	local suggested = math.ceil(total / targetRows)

	return math.clamp(suggested, basePerRow, maxPerRow)
end

function PetFollowerController._GetFollowerTargetCFrame(
	self: PetFollowerController,
	rootCFrame: CFrame,
	rootVelocity: Vector3,
	index: number,
	total: number,
	follower
)
	local followSettings = self.Settings.Follow
	local floatSettings = self.Settings.Float
	local swaySettings = self.Settings.Sway
	local flySettings = self.Settings.Fly
	local groundSettings = self.Settings.Ground
	local phase = follower.Phase or 0
	local jitterX = follower.JitterX
	local jitterZ = follower.JitterZ

	local petsPerRow = self:_GetPetsPerRow(total)
	local row = math.floor((index - 1) / petsPerRow)
	local indexInRow = ((index - 1) % petsPerRow) + 1
	local rowStart = (row * petsPerRow) + 1
	local rowCount = math.min(petsPerRow, total - rowStart + 1)
	local normalized = 0
	if rowCount > 1 then
		normalized = ((indexInRow - 1) / (rowCount - 1) * 2) - 1
	end

	local arcSpread = followSettings.ArcSpread or 0
	local arcAngle = normalized * (arcSpread * 0.5)

	local radius = followSettings.BackOffset + (row * followSettings.RowSpacing)
	local xOffset = math.sin(arcAngle) * radius
	local zOffset = math.cos(arcAngle) * radius

	local rowStagger = followSettings.RowStagger or 0
	if rowStagger ~= 0 and rowCount > 1 then
		local staggerSign = (row % 2 == 0) and 1 or -1
		xOffset += staggerSign * rowStagger
	end

	xOffset += jitterX or 0
	zOffset += jitterZ or 0

	local driftAmplitude = followSettings.DriftAmplitude or 0
	if driftAmplitude ~= 0 then
		local driftFrequency = followSettings.DriftFrequency or 1
		xOffset += math.sin((self.Time * driftFrequency) + phase) * driftAmplitude
		zOffset += math.cos((self.Time * driftFrequency * 0.85) + (phase * 0.7)) * (driftAmplitude * 0.6)
	end

	local rootPosition = rootCFrame.Position
	local horizontalVelocity = Vector3.new(rootVelocity.X, 0, rootVelocity.Z)
	local horizontalSpeed = horizontalVelocity.Magnitude
	local lookVector = self:_ResolveLookVector(rootCFrame, rootVelocity)
	local moveAlpha = math.clamp(horizontalSpeed / swaySettings.MaxSpeed, 0, 1)

	if follower.IsFlying then
		local wave = (self.Time * (floatSettings.Frequency + (horizontalSpeed * floatSettings.VelocityFrequencyScale))) + phase
		local floatOffset = math.sin(wave) * floatSettings.Amplitude
		local flightIntensity = 0.4 + (moveAlpha * 0.6)

		floatOffset += math.sin((self.Time * flySettings.ExtraFloatFrequency) + (phase * 1.3))
			* flySettings.ExtraFloatAmplitude
			* flightIntensity
		xOffset += math.sin((self.Time * flySettings.LateralFrequency) + (phase * 0.6))
			* flySettings.LateralAmplitude
			* flightIntensity
		zOffset += math.cos((self.Time * flySettings.DepthFrequency) + (phase * 0.85))
			* flySettings.DepthAmplitude
			* flightIntensity

		local targetPosition = rootPosition
			+ (rootCFrame.RightVector * xOffset)
			- (rootCFrame.LookVector * zOffset)
			+ Vector3.new(0, followSettings.HeightOffset + floatOffset, 0)

		local swayWave = (self.Time * swaySettings.Frequency) + phase
		local pitch = math.sin(swayWave) * swaySettings.PitchAmplitude * moveAlpha
		local roll = math.cos(swayWave * 0.9) * swaySettings.RollAmplitude * moveAlpha
		local flyWave = (self.Time * flySettings.ExtraFloatFrequency) + phase
		pitch += math.sin(flyWave * 0.8) * flySettings.PitchAmplitude * flightIntensity
		roll += math.cos(flyWave * 0.95) * flySettings.RollAmplitude * flightIntensity
		local yawOscillation = math.sin((self.Time * flySettings.YawFrequency) + (phase * 0.7))
			* flySettings.YawAmplitude
			* flightIntensity

		local facing = CFrame.lookAt(targetPosition, targetPosition + lookVector)
		return facing
			* CFrame.fromOrientation(0, followSettings.YawOffset + yawOscillation, 0)
			* CFrame.fromOrientation(pitch, 0, roll)
	end

	local speedAlpha = math.clamp(horizontalSpeed / groundSettings.SpeedForFullWalk, 0, 1)
	local walkFrequency = groundSettings.WalkFrequency * (0.35 + (speedAlpha * 1.15))
	local walkWave = (self.Time * walkFrequency) + phase
	local stepLift = math.abs(math.sin(walkWave)) * groundSettings.StepHeight * speedAlpha
	local idleLift = math.sin((self.Time * groundSettings.IdleFrequency) + (phase * 0.6))
		* groundSettings.IdleAmplitude
		* (1 - speedAlpha)
	local sideSway = math.sin((walkWave * 0.5) + phase) * groundSettings.SideSway * speedAlpha
	local hopLift = 0
	local hopPitch = 0

	if follower.ShouldHop then
		stepLift *= 0.45

		if speedAlpha >= groundSettings.HopSpeedThreshold then
			local hopWave = (self.Time * groundSettings.HopFrequency) + phase
			local hopAlpha = math.max(0, math.sin(hopWave))
			hopLift = hopAlpha * hopAlpha * groundSettings.HopHeight * speedAlpha
			hopPitch = -hopAlpha * groundSettings.HopTilt * speedAlpha
		end
	end

	local baseGroundPosition = rootPosition
		+ (rootCFrame.RightVector * (xOffset + sideSway))
		- (rootCFrame.LookVector * zOffset)
	local groundY, groundNormal = self:_SampleGroundData(baseGroundPosition)
	local targetPosition = Vector3.new(
		baseGroundPosition.X,
		groundY + (follower.GroundLift or 0) + groundSettings.HeightOffset + stepLift + idleLift + hopLift,
		baseGroundPosition.Z
	)

	local pitch = math.sin(walkWave) * groundSettings.PitchAmplitude * speedAlpha + hopPitch
	local roll = math.cos(walkWave * 0.9) * groundSettings.RollAmplitude * speedAlpha
	local facing = CFrame.lookAt(targetPosition, targetPosition + lookVector, groundNormal)

	return facing
		* CFrame.fromOrientation(0, followSettings.YawOffset, 0)
		* CFrame.fromOrientation(pitch, 0, roll)
end

function PetFollowerController._PushRootTrail(self: PetFollowerController, rootPart: BasePart)
	table.insert(self.RootTrail, {
		Time = self.Time,
		CFrame = rootPart.CFrame,
		Velocity = rootPart.AssemblyLinearVelocity,
	})

	local followSettings = self.Settings.Follow
	local trailDuration = followSettings.TrailDuration or 1.35
	local minTime = self.Time - trailDuration

	local cutIndex = 0
	for index, sample in ipairs(self.RootTrail) do
		if sample.Time >= minTime then
			break
		end
		cutIndex = index
	end

	if cutIndex <= 0 then
		return
	end

	for _ = 1, cutIndex do
		table.remove(self.RootTrail, 1)
	end
end

function PetFollowerController._SampleRootTrail(self: PetFollowerController, delay: number)
	local trail = self.RootTrail
	local count = #trail
	if count == 0 then
		return nil, nil
	end

	local targetTime = self.Time - math.max(0, delay)

	local first = trail[1]
	if targetTime <= first.Time then
		return first.CFrame, first.Velocity
	end

	local last = trail[count]
	if targetTime >= last.Time then
		return last.CFrame, last.Velocity
	end

	for index = count, 2, -1 do
		local newer = trail[index]
		local older = trail[index - 1]
		if targetTime < older.Time then
			continue
		end

		local span = newer.Time - older.Time
		if span <= 0 then
			return newer.CFrame, newer.Velocity
		end

		local alpha = (targetTime - older.Time) / span
		return older.CFrame:Lerp(newer.CFrame, alpha), older.Velocity:Lerp(newer.Velocity, alpha)
	end

	return first.CFrame, first.Velocity
end

function PetFollowerController._SnapFollowersToTargets(self: PetFollowerController)
	local rootPart = self:_GetCharacterRootPart()
	if not rootPart then
		return
	end

	if #self.RootTrail == 0 then
		self:_PushRootTrail(rootPart)
	end

	local followSettings = self.Settings.Follow
	local baseDelay = followSettings.BaseDelay or 0
	local delayPerPet = followSettings.DelayPerPet or 0
	local total = #self.OrderedFollowerIds
	self:_RefreshGroundRaycastFilter()
	for index, petId in ipairs(self.OrderedFollowerIds) do
		local follower = self.Followers[petId]
		if not follower or not follower.Model or not follower.Model.Parent then
			continue
		end

		local delay = baseDelay + ((index - 1) * delayPerPet)
		local sampleCFrame, sampleVelocity = self:_SampleRootTrail(delay)
		if not sampleCFrame then
			sampleCFrame = rootPart.CFrame
			sampleVelocity = rootPart.AssemblyLinearVelocity
		end

		local targetCFrame = self:_GetFollowerTargetCFrame(
			sampleCFrame,
			sampleVelocity,
			index,
			total,
			follower
		)
		follower.VerticalOffset = 0
		follower.VerticalVelocity = 0
		follower.CurrentCFrame = targetCFrame
		follower.Model:PivotTo(targetCFrame)
	end
end

function PetFollowerController._UpdateFollowers(self: PetFollowerController, dt: number)
	if #self.OrderedFollowerIds == 0 then
		return
	end

	local rootPart = self:_GetCharacterRootPart()
	if not rootPart then
		return
	end

	self.Time += dt
	self:_PushRootTrail(rootPart)

	local total = #self.OrderedFollowerIds
	local followSettings = self.Settings.Follow
	local verticalSettings = self.Settings.VerticalFollow
	local baseResponsiveness = followSettings.PositionResponsiveness
	local baseDelay = followSettings.BaseDelay or 0
	local delayPerPet = followSettings.DelayPerPet or 0
	self:_RefreshGroundRaycastFilter()

	for index, petId in ipairs(self.OrderedFollowerIds) do
		local follower = self.Followers[petId]
		if not follower or not follower.Model or not follower.Model.Parent then
			continue
		end

		local delay = baseDelay + ((index - 1) * delayPerPet)
		local lagMultiplier = 1 + (delay * 6)
		local response = baseResponsiveness / lagMultiplier
		local alpha = 1 - math.exp(-response * dt)

		local sampleCFrame, sampleVelocity = self:_SampleRootTrail(delay)
		if not sampleCFrame then
			sampleCFrame = rootPart.CFrame
			sampleVelocity = rootPart.AssemblyLinearVelocity
		end

		local targetCFrame = self:_GetFollowerTargetCFrame(
			sampleCFrame,
			sampleVelocity,
			index,
			total,
			follower
		)
		local targetRotation = targetCFrame - targetCFrame.Position
		local targetPosition = targetCFrame.Position

		local sampledVelocityY = sampleVelocity.Y
		local desiredVerticalOffset = 0
		if verticalSettings then
			local verticalLagMultiplier = 1 + (delay * 4)
			local jumpLag = math.max(0, sampledVelocityY) * verticalSettings.JumpLagStrength * verticalLagMultiplier
			local fallCatchup = math.max(0, -sampledVelocityY) * verticalSettings.FallCatchupStrength * verticalLagMultiplier
			desiredVerticalOffset = math.clamp(
				fallCatchup - jumpLag,
				-verticalSettings.MaxJumpLag,
				verticalSettings.MaxJumpLag
			)

			local offsetError = desiredVerticalOffset - follower.VerticalOffset
			local acceleration = (offsetError * verticalSettings.Stiffness) - (follower.VerticalVelocity * verticalSettings.Damping)
			follower.VerticalVelocity += acceleration * dt
			follower.VerticalOffset += follower.VerticalVelocity * dt
		else
			follower.VerticalOffset = 0
			follower.VerticalVelocity = 0
		end

		local laggedTarget = CFrame.new(targetPosition + Vector3.new(0, follower.VerticalOffset, 0)) * targetRotation

		if not follower.CurrentCFrame then
			follower.CurrentCFrame = laggedTarget
		else
			follower.CurrentCFrame = follower.CurrentCFrame:Lerp(laggedTarget, alpha)
		end

		follower.Model:PivotTo(follower.CurrentCFrame)
	end
end

type PetFollowerController = typeof(PetFollowerController) & {
	PetModels: Folder,
	FollowerFolder: Folder,
	Settings: { [string]: { [string]: number } },
	Pets: { [string]: any },
	EquippedPets: { [string]: boolean },
	Followers: { [string]: any },
	OrderedFollowerIds: { string },
	RootTrail: { { Time: number, CFrame: CFrame, Velocity: Vector3 } },
	Time: number,
}

return PetFollowerController
