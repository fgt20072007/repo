local Players = game:GetService("Players")

local internal = script:WaitForChild("_Internal")
local AnimationConfig = require(internal:WaitForChild("AnimationConfig"))
local CharacterAnimationController = require(internal:WaitForChild("CharacterAnimationController"))

local function deepClone(value)
	if type(value) ~= "table" then
		return value
	end

	local copy = {}
	for key, nested in pairs(value) do
		copy[key] = deepClone(nested)
	end

	return copy
end

local function copyConfig(source)
	return {
		Animations = deepClone(source.Animations),
		TransitionFadeTime = source.TransitionFadeTime,
		ResetFadeTime = source.ResetFadeTime,
		MoveThreshold = source.MoveThreshold,
		MoveThresholdStart = source.MoveThresholdStart,
		MoveThresholdStop = source.MoveThresholdStop,
		DefaultWalkSpeed = source.DefaultWalkSpeed,
		DefaultSprintSpeed = source.DefaultSprintSpeed,
		UpdateRate = source.UpdateRate,
		KeepAnimateDisabled = source.KeepAnimateDisabled,
		BasePriority = source.BasePriority,
		OverlayPriority = source.OverlayPriority,
		IdleBreakInterval = source.IdleBreakInterval,
		NonLoopedStates = deepClone(source.NonLoopedStates),
	}
end

local CharacterAnimationService = {}
CharacterAnimationService.__index = CharacterAnimationService

function CharacterAnimationService.new()
	local self = setmetatable({}, CharacterAnimationService)

	self._initialized = false
	self._started = false
	self._connections = {}
	self._controller = nil
	self._baseSuppressionSources = {}
	self._sprintEnabled = false
	self._config = copyConfig(AnimationConfig)

	return self
end

function CharacterAnimationService:_addConnection(connection)
	table.insert(self._connections, connection)
	return connection
end

function CharacterAnimationService:_destroyController()
	if not self._controller then
		return
	end

	self._controller:Destroy()
	self._controller = nil
end

function CharacterAnimationService:_createController(character)
	self:_destroyController()

	local controller = CharacterAnimationController.new(character, self._config)
	controller:Start()

	for source in pairs(self._baseSuppressionSources) do
		controller:SetBaseSuppressed(source, true)
	end

	controller:SetSprinting(self._sprintEnabled)

	self._controller = controller
end

function CharacterAnimationService:SuppressBaseLayer(source)
	if source == nil then
		return
	end

	if self._baseSuppressionSources[source] then
		return
	end

	self._baseSuppressionSources[source] = true
	if self._controller then
		self._controller:SetBaseSuppressed(source, true)
	end
end

function CharacterAnimationService:ResumeBaseLayer(source)
	if source == nil then
		return
	end

	if not self._baseSuppressionSources[source] then
		return
	end

	self._baseSuppressionSources[source] = nil
	if self._controller then
		self._controller:SetBaseSuppressed(source, false)
	end
end

function CharacterAnimationService:GetCurrentBaseState()
	if not self._controller then
		return "Idle"
	end

	return self._controller:GetCurrentState()
end

function CharacterAnimationService:SetSprinting(isSprinting)
	local nextValue = isSprinting == true
	if self._sprintEnabled == nextValue then
		return
	end

	self._sprintEnabled = nextValue
	if self._controller then
		self._controller:SetSprinting(nextValue)
	end
end

function CharacterAnimationService:IsSprinting()
	return self._sprintEnabled
end

function CharacterAnimationService:PlayActionTrack(assetId, options)
	if not self._controller then
		return nil
	end

	return self._controller:PlayActionTrack(assetId, options)
end

function CharacterAnimationService:PreloadActionTrack(assetId)
	if not self._controller then
		return nil
	end

	return self._controller:PreloadActionTrack(assetId)
end

function CharacterAnimationService:StopActionGroup(groupName, fadeTime)
	if not self._controller then
		return
	end

	self._controller:StopActionGroup(groupName, fadeTime)
end

function CharacterAnimationService:StopAllActionTracks(fadeTime)
	if not self._controller then
		return
	end

	self._controller:StopAllActionTracks(fadeTime)
end

function CharacterAnimationService:ConfigureBaseAnimations(assetIds)
	if type(assetIds) ~= "table" then
		return
	end

	local hasChanges = false
	local movementConfig = self._config.Animations.Movement
	local nonLoopedMovement = self._config.NonLoopedStates.Movement
	local directBaseStateToDefault = {
		Idle = true,
		Walk = true,
		Sprint = true,
		Jump = true,
		Fall = true,
	}

	local function assignMovementState(groupName, movementState, assetId)
		if type(assetId) ~= "string" or assetId == "" then
			return
		end

		if movementConfig[groupName] == nil then
			movementConfig[groupName] = {}
		end

		if movementConfig[groupName][movementState] ~= assetId then
			movementConfig[groupName][movementState] = assetId
			hasChanges = true
		end

		if nonLoopedMovement[groupName] and nonLoopedMovement[groupName][movementState] ~= nil then
			nonLoopedMovement[groupName][movementState] = true
		end
	end

	for stateName, assetId in pairs(assetIds) do
		if type(assetId) == "table" then
			if stateName == "Default" or stateName == "Rod" or stateName == "Shared" then
				for movementState, nestedAssetId in pairs(assetId) do
					assignMovementState(stateName, movementState, nestedAssetId)
				end
			end
		elseif directBaseStateToDefault[stateName] then
			assignMovementState("Default", stateName, assetId)
		end
	end

	if not hasChanges then
		return
	end

	local localPlayer = Players.LocalPlayer
	if not localPlayer then
		return
	end

	local character = localPlayer.Character
	if not character then
		self:_destroyController()
		return
	end

	self:_createController(character)
end

function CharacterAnimationService:Init()
	if self._initialized then
		return
	end
	self._initialized = true
end

function CharacterAnimationService:Start()
	if self._started then
		return
	end
	self._started = true

	local localPlayer = Players.LocalPlayer
	if not localPlayer then
		return
	end

	self:_addConnection(localPlayer.CharacterAdded:Connect(function(character)
		self:_createController(character)
	end))

	self:_addConnection(localPlayer.CharacterRemoving:Connect(function()
		self:_destroyController()
	end))

	local character = localPlayer.Character
	if character then
		self:_createController(character)
	end
end

local singleton = CharacterAnimationService.new()

return table.freeze({
	Init = function()
		singleton:Init()
	end,
	Start = function()
		singleton:Start()
	end,
	SuppressBaseLayer = function(source)
		singleton:SuppressBaseLayer(source)
	end,
	ResumeBaseLayer = function(source)
		singleton:ResumeBaseLayer(source)
	end,
	GetCurrentBaseState = function()
		return singleton:GetCurrentBaseState()
	end,
	SetSprinting = function(isSprinting)
		singleton:SetSprinting(isSprinting)
	end,
	IsSprinting = function()
		return singleton:IsSprinting()
	end,
	PlayActionTrack = function(assetId, options)
		return singleton:PlayActionTrack(assetId, options)
	end,
	PreloadActionTrack = function(assetId)
		return singleton:PreloadActionTrack(assetId)
	end,
	StopActionGroup = function(groupName, fadeTime)
		singleton:StopActionGroup(groupName, fadeTime)
	end,
	StopAllActionTracks = function(fadeTime)
		singleton:StopAllActionTracks(fadeTime)
	end,
	ConfigureBaseAnimations = function(assetIds)
		singleton:ConfigureBaseAnimations(assetIds)
	end,
})
