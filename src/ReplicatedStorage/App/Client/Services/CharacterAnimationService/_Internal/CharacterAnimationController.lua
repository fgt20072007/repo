local RunService = game:GetService("RunService")

local TrackBank = require(script.Parent:WaitForChild("TrackBank"))
local LocomotionStateMachine = require(script.Parent:WaitForChild("LocomotionStateMachine"))

local CharacterAnimationController = {}
CharacterAnimationController.__index = CharacterAnimationController

local REQUIRED_CHILD_TIMEOUT = 10

local function flattenTrackDefinitions(groupedDefinitions)
	local flattened = {}

	for groupName, states in pairs(groupedDefinitions or {}) do
		if type(states) == "table" then
			for stateName, value in pairs(states) do
				if type(value) == "string" and value ~= "" then
					flattened[groupName .. "_" .. stateName] = value
				end
			end
		end
	end

	return flattened
end

local function flattenNonLoopedDefinitions(groupedDefinitions)
	local flattened = {}

	for groupName, states in pairs(groupedDefinitions or {}) do
		if type(states) == "table" then
			for stateName, value in pairs(states) do
				if value == true then
					flattened[groupName .. "_" .. stateName] = true
				end
			end
		end
	end

	return flattened
end

local function flattenSingleGroupTrackDefinitions(groupName, states)
	local flattened = {}

	if type(states) ~= "table" then
		return flattened
	end

	for stateName, value in pairs(states) do
		if type(value) == "string" and value ~= "" then
			flattened[groupName .. "_" .. stateName] = value
		end
	end

	return flattened
end

local function flattenSingleGroupNonLoopedDefinitions(groupName, states)
	local flattened = {}

	if type(states) ~= "table" then
		return flattened
	end

	for stateName, value in pairs(states) do
		if value == true then
			flattened[groupName .. "_" .. stateName] = true
		end
	end

	return flattened
end

function CharacterAnimationController.new(character, config)
	local self = setmetatable({}, CharacterAnimationController)
	self._character = character
	self._config = config
	self._connections = {}
	self._humanoid = nil
	self._rootPart = nil
	self._animator = nil
	self._coreTrackBank = nil
	self._overlayTrackBank = nil
	self._stateMachine = LocomotionStateMachine.new(config)
	self._updateAccumulator = 0
	self._baseSuppressionCount = 0
	self._isRodEquipped = false
	self._isSprinting = false
	self._idleBreakState = "Shared_IdleBreak"
	self._idleBreakElapsed = 0
	self._idleBreakActive = false
	self._isRunning = false
	self._destroyed = false
	self._actionTracks = {}
	self._activeActionGroups = {}

	local movementAnimations = config.Animations.Movement
	local movementNonLooped = config.NonLoopedStates.Movement

	self._coreTrackDefinitions = flattenTrackDefinitions({
		Default = movementAnimations.Default,
		Shared = movementAnimations.Shared,
	})
	self._coreNonLoopedDefinitions = flattenNonLoopedDefinitions({
		Default = movementNonLooped.Default,
		Shared = movementNonLooped.Shared,
	})
	self._overlayTrackDefinitions = flattenSingleGroupTrackDefinitions("Rod", movementAnimations.Rod)
	self._overlayNonLoopedDefinitions = flattenSingleGroupNonLoopedDefinitions("Rod", movementNonLooped.Rod)

	return self
end

function CharacterAnimationController:_getOrCreateActionTrack(assetId)
	local existing = self._actionTracks[assetId]
	if existing then
		return existing
	end

	if not self._animator then
		return nil
	end

	local animation = Instance.new("Animation")
	animation.AnimationId = assetId

	local track = self._animator:LoadAnimation(animation)
	animation:Destroy()

	self._actionTracks[assetId] = track
	return track
end

function CharacterAnimationController:_addConnection(connection)
	table.insert(self._connections, connection)
	return connection
end

function CharacterAnimationController:_cleanupConnections()
	for _, connection in ipairs(self._connections) do
		connection:Disconnect()
	end

	table.clear(self._connections)
end

function CharacterAnimationController:_ensureHumanoidAndAnimator()
	local humanoid = self._character:FindFirstChildOfClass("Humanoid")
	if not humanoid then
		humanoid = self._character:WaitForChild("Humanoid", REQUIRED_CHILD_TIMEOUT)
		if not humanoid then
			return false
		end
	end

	local rootPart = self._character:FindFirstChild("HumanoidRootPart")
	if not rootPart then
		rootPart = self._character:WaitForChild("HumanoidRootPart", REQUIRED_CHILD_TIMEOUT)
		if not rootPart then
			return false
		end
	end

	local animator = humanoid:FindFirstChildOfClass("Animator")
	if not animator then
		animator = Instance.new("Animator")
		animator.Parent = humanoid
	end

	self._humanoid = humanoid
	self._rootPart = rootPart
	self._animator = animator

	return true
end

function CharacterAnimationController:_disableDefaultAnimateScript()
	if not self._config.KeepAnimateDisabled then
		return
	end

	local animateScript = self._character:FindFirstChild("Animate")
	if animateScript and animateScript:IsA("LocalScript") then
		animateScript.Enabled = false
	end
end

function CharacterAnimationController:_computeLocomotionState()
	return self._stateMachine:GetState(self._humanoid, self._rootPart)
end

function CharacterAnimationController:_isRodToolEquipped()
	for _, child in ipairs(self._character:GetChildren()) do
		if child:IsA("Tool") and child:GetAttribute("Rod") == true then
			return true
		end
	end

	return false
end

function CharacterAnimationController:_hasIdleBreakEligibleToolEquipped()
	for _, child in ipairs(self._character:GetChildren()) do
		if child:IsA("Tool") then
			if child:GetAttribute("Knife") == true or child:GetAttribute("Rod") == true or child:GetAttribute("Sword") == true then
				return true
			end
		end
	end

	return false
end

function CharacterAnimationController:_resolveCoreTrackKey(baseStateName)
	local preferredKey = "Default_" .. baseStateName
	if self._coreTrackBank and self._coreTrackBank:HasState(preferredKey) then
		return preferredKey
	end

	local fallbackKey = "Default_Idle"
	if self._coreTrackBank and self._coreTrackBank:HasState(fallbackKey) then
		return fallbackKey
	end

	return nil
end

function CharacterAnimationController:_resolveOverlayTrackKey(baseStateName)
	if not self._overlayTrackBank or not self._isRodEquipped then
		return nil
	end

	local preferredKey = "Rod_" .. baseStateName
	if self._overlayTrackBank:HasState(preferredKey) then
		return preferredKey
	end

	return nil
end

function CharacterAnimationController:_applyMovementSpeedScale(trackBank, trackKey, baseStateName, horizontalSpeed)
	if not trackBank then
		return
	end

	if baseStateName == "Walk" then
		local ratio = math.clamp(horizontalSpeed / self._config.DefaultWalkSpeed, 0.85, 1.35)
		trackBank:SetPlaybackSpeed(trackKey, ratio)
		return
	end

	if baseStateName == "Sprint" then
		local sprintReferenceSpeed = self._config.DefaultSprintSpeed or self._config.DefaultWalkSpeed
		local ratio = math.clamp(horizontalSpeed / sprintReferenceSpeed, 0.9, 1.45)
		trackBank:SetPlaybackSpeed(trackKey, ratio)
		return
	end

	trackBank:SetPlaybackSpeed(trackKey, 1)
end

function CharacterAnimationController:_update(deltaTime)
	if not self._isRunning or self._destroyed then
		return
	end

	self._updateAccumulator += deltaTime
	if self._updateAccumulator < self._config.UpdateRate then
		return
	end
	local stepDelta = self._updateAccumulator
	self._updateAccumulator = 0

	if self._baseSuppressionCount > 0 then
		if self._coreTrackBank then
			self._coreTrackBank:StopAll()
		end
		if self._overlayTrackBank then
			self._overlayTrackBank:StopAll()
		end
		self._idleBreakActive = false
		self._idleBreakElapsed = 0
		return
	end

	self._isRodEquipped = self:_isRodToolEquipped()

	local baseStateName, speed = self:_computeLocomotionState()
	if self._isSprinting and baseStateName == "Walk" then
		baseStateName = "Sprint"
	end

	if baseStateName ~= "Idle" then
		self._idleBreakActive = false
		self._idleBreakElapsed = 0
	else
		local canPlayIdleBreak = self:_hasIdleBreakEligibleToolEquipped()
		if not canPlayIdleBreak then
			self._idleBreakActive = false
			self._idleBreakElapsed = 0
		else
			if self._idleBreakActive then
				if self._coreTrackBank and self._coreTrackBank:IsStatePlaying(self._idleBreakState) then
					return
				end

				self._idleBreakActive = false
			end

			self._idleBreakElapsed += stepDelta
			if self._coreTrackBank and self._idleBreakElapsed >= self._config.IdleBreakInterval and self._coreTrackBank:HasState(self._idleBreakState) then
				self._idleBreakElapsed = 0
				self._idleBreakActive = true
				self._coreTrackBank:PlayState(self._idleBreakState)
				self._coreTrackBank:SetPlaybackSpeed(self._idleBreakState, 1)
				if self._overlayTrackBank then
					self._overlayTrackBank:StopAll()
				end
				return
			end
		end
	end

	local coreTrackKey = self:_resolveCoreTrackKey(baseStateName)
	if not coreTrackKey then
		coreTrackKey = self:_resolveCoreTrackKey("Idle")
		baseStateName = "Idle"
	end

	if not coreTrackKey then
		return
	end

	self._coreTrackBank:PlayState(coreTrackKey)
	self:_applyMovementSpeedScale(self._coreTrackBank, coreTrackKey, baseStateName, speed)

	local overlayTrackKey = self:_resolveOverlayTrackKey(baseStateName)
	if overlayTrackKey then
		self._overlayTrackBank:PlayState(overlayTrackKey)
		self:_applyMovementSpeedScale(self._overlayTrackBank, overlayTrackKey, baseStateName, speed)
	elseif self._overlayTrackBank and self._overlayTrackBank:GetCurrentState() ~= nil then
		self._overlayTrackBank:StopAll()
	end
end

function CharacterAnimationController:SetBaseSuppressed(source, isSuppressed)
	if source == nil then
		return
	end

	if isSuppressed then
		self._baseSuppressionCount += 1
		return
	end

	self._baseSuppressionCount = math.max(0, self._baseSuppressionCount - 1)
end

function CharacterAnimationController:SetSprinting(isSprinting)
	self._isSprinting = isSprinting == true
end

function CharacterAnimationController:GetCurrentState()
	if not self._coreTrackBank then
		return "Idle"
	end

	return self._coreTrackBank:GetCurrentState() or "Idle"
end

function CharacterAnimationController:PreloadActionTrack(assetId)
	if self._destroyed or not self._isRunning then
		return nil
	end

	if type(assetId) ~= "string" or assetId == "" then
		return nil
	end

	return self:_getOrCreateActionTrack(assetId)
end

function CharacterAnimationController:PlayActionTrack(assetId, options)
	if self._destroyed or not self._isRunning then
		return nil
	end

	if type(assetId) ~= "string" or assetId == "" then
		return nil
	end

	local track = self:_getOrCreateActionTrack(assetId)
	if not track then
		return nil
	end

	local settings = options or {}
	local groupName = settings.Group
	if type(groupName) == "string" and groupName ~= "" then
		local activeTrack = self._activeActionGroups[groupName]
		if activeTrack and activeTrack ~= track and activeTrack.IsPlaying then
			activeTrack:Stop(settings.FadeTime or self._config.TransitionFadeTime)
		end
		self._activeActionGroups[groupName] = track
	end

	track.Priority = settings.Priority or self._config.OverlayPriority or self._config.BasePriority
	track.Looped = settings.Looped == true
	track:Play(settings.FadeTime or self._config.TransitionFadeTime, settings.Weight or 1, settings.Speed or 1)

	return track
end

function CharacterAnimationController:StopActionGroup(groupName, fadeTime)
	if type(groupName) ~= "string" or groupName == "" then
		return
	end

	local track = self._activeActionGroups[groupName]
	if not track then
		return
	end

	self._activeActionGroups[groupName] = nil
	if track.IsPlaying then
		track:Stop(fadeTime or self._config.ResetFadeTime)
	end
end

function CharacterAnimationController:StopAllActionTracks(fadeTime)
	for groupName in pairs(self._activeActionGroups) do
		self._activeActionGroups[groupName] = nil
	end

	for _, track in pairs(self._actionTracks) do
		if track.IsPlaying then
			track:Stop(fadeTime or self._config.ResetFadeTime)
		end
	end
end

function CharacterAnimationController:Start()
	if self._isRunning or self._destroyed then
		return
	end

	if not self:_ensureHumanoidAndAnimator() then
		return
	end

	local coreTrackBankConfig = {
		TransitionFadeTime = self._config.TransitionFadeTime,
		ResetFadeTime = self._config.ResetFadeTime,
		BasePriority = self._config.BasePriority,
		TrackDefinitions = self._coreTrackDefinitions,
		NonLoopedTrackDefinitions = self._coreNonLoopedDefinitions,
	}
	local overlayTrackBankConfig = {
		TransitionFadeTime = self._config.TransitionFadeTime,
		ResetFadeTime = self._config.ResetFadeTime,
		BasePriority = self._config.OverlayPriority or self._config.BasePriority,
		TrackDefinitions = self._overlayTrackDefinitions,
		NonLoopedTrackDefinitions = self._overlayNonLoopedDefinitions,
	}

	self._coreTrackBank = TrackBank.new(self._animator, coreTrackBankConfig)
	self._overlayTrackBank = TrackBank.new(self._animator, overlayTrackBankConfig)
	self._isRunning = true
	self:_disableDefaultAnimateScript()

	self:_addConnection(self._character.AncestryChanged:Connect(function(_, parent)
		if parent == nil then
			self:Destroy()
		end
	end))

	self:_addConnection(self._character.ChildAdded:Connect(function(child)
		if child.Name == "Animate" and child:IsA("LocalScript") then
			child.Enabled = false
		end
	end))

	self:_addConnection(self._humanoid.Died:Connect(function()
		if self._coreTrackBank then
			self._coreTrackBank:StopAll()
		end
		if self._overlayTrackBank then
			self._overlayTrackBank:StopAll()
		end
		self:StopAllActionTracks(0)
	end))

	self:_addConnection(RunService.RenderStepped:Connect(function(deltaTime)
		self:_update(deltaTime)
	end))

	self:_update(self._config.UpdateRate)
end

function CharacterAnimationController:Destroy()
	if self._destroyed then
		return
	end
	self._destroyed = true
	self._isRunning = false

	if self._coreTrackBank then
		self._coreTrackBank:Destroy()
		self._coreTrackBank = nil
	end

	if self._overlayTrackBank then
		self._overlayTrackBank:Destroy()
		self._overlayTrackBank = nil
	end

	for assetId, track in pairs(self._actionTracks) do
		track:Stop(0)
		track:Destroy()
		self._actionTracks[assetId] = nil
	end

	for groupName in pairs(self._activeActionGroups) do
		self._activeActionGroups[groupName] = nil
	end

	self:_cleanupConnections()
end

return CharacterAnimationController
