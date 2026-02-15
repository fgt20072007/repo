local ContextActionService = game:GetService("ContextActionService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")

local app = ReplicatedStorage:WaitForChild("App")
local shared = app:WaitForChild("Shared")

local CharacterAnimationService = require(app.Client.Services.CharacterAnimationService)
local CombatConfig = require(shared.Data.CombatConfig)
local Knifes = require(shared.Data.Knifes)
local MovementStats = require(shared.Data.MovementStats)
local Swords = require(shared.Data.Swords)

local netRoot = shared:WaitForChild("Net")
local Net = require(netRoot:WaitForChild("Client"))
local Maid = require(shared:WaitForChild("Util"):WaitForChild("Maid"))

local CombatService = {}
CombatService.__index = CombatService

local function getTrackLength(track)
	local length = track.Length
	if length > 0 then
		return length
	end

	for _ = 1, 15 do
		task.wait()
		length = track.Length
		if length > 0 then
			return length
		end
	end

	return 0
end

local function resolveNetEvent(container, pascalName)
	if type(container) ~= "table" then
		return nil
	end

	local eventObject = container[pascalName]
	if eventObject ~= nil then
		return eventObject
	end

	local camelName = string.lower(string.sub(pascalName, 1, 1)) .. string.sub(pascalName, 2)
	eventObject = container[camelName]
	if eventObject ~= nil then
		return eventObject
	end

	local eventsContainer = container.Events or container.events
	if type(eventsContainer) == "table" then
		eventObject = eventsContainer[pascalName]
		if eventObject ~= nil then
			return eventObject
		end

		return eventsContainer[camelName]
	end

	return nil
end

local function toAssetId(value)
	if type(value) == "number" then
		if value <= 0 then
			return nil
		end

		return "rbxassetid://" .. tostring(math.floor(value))
	end

	if type(value) ~= "string" or value == "" then
		return nil
	end

	if string.find(value, "rbxassetid://", 1, true) == 1 then
		return value
	end

	return "rbxassetid://" .. value
end

local function isCombatTool(tool)
	if not tool or not tool:IsA("Tool") then
		return false
	end

	return tool:GetAttribute("Knife") == true or tool:GetAttribute("Sword") == true
end

local function resolveWeaponType(tool)
	if not tool then
		return nil
	end

	if tool:GetAttribute("Knife") == true then
		return "Knife"
	end

	if tool:GetAttribute("Sword") == true then
		return "Sword"
	end

	return nil
end

local function resolveWeaponData(tool, weaponType)
	if not tool or not weaponType then
		return nil
	end

	if weaponType == "Knife" then
		return Knifes[tool.Name] or Knifes.Default
	end

	if weaponType == "Sword" then
		return Swords[tool.Name] or Swords.Default
	end

	return nil
end

local function connectTrackFinished(track, callback)
	local connections = {}
	local fired = false

	local function fireOnce()
		if fired then
			return
		end
		fired = true
		callback()
	end

	local stoppedConnection = track.Stopped:Connect(fireOnce)
	table.insert(connections, stoppedConnection)

	local ok, endedSignal = pcall(function()
		return track.Ended
	end)

	if ok and typeof(endedSignal) == "RBXScriptSignal" then
		table.insert(connections, endedSignal:Connect(fireOnce))
	end

	return {
		Disconnect = function()
			for _, connection in ipairs(connections) do
				connection:Disconnect()
			end
			table.clear(connections)
		end,
	}
end

local function getComboContinueWindow(weaponData)
	local comboWindowConfig = CombatConfig.Client.ComboContinueWindow
	local cooldown = weaponData and weaponData.AttackCooldown or nil
	if type(cooldown) == "number" and cooldown > 0 then
		return math.clamp(cooldown * comboWindowConfig.Multiplier, comboWindowConfig.Min, comboWindowConfig.Max)
	end

	return comboWindowConfig.Default
end

function CombatService.new()
	return setmetatable({
		_runtime = {
			initialized = false,
			started = false,
			maid = Maid.New(),
			characterMaid = Maid.New(),
		},
		_characterState = {
			character = nil,
			humanoid = nil,
			tool = nil,
			weaponType = nil,
			weaponData = nil,
		},
		_combat = {
			nextParryAt = 0,
			comboIndex = 1,
			comboContinueUntil = 0,
			attackSerial = 0,
			queuedAttack = false,
			activeAttackTrack = nil,
			activeParryTrack = nil,
			parryRequestActive = false,
		},
		_flags = {
			pickupActive = false,
			attackActive = false,
			parryActive = false,
			idleActive = false,
		},
		_cache = {
			warnedMissingEvent = {},
			preloadedActionAssets = {},
		},

		_netEvents = {
			CombatRequestAttack = resolveNetEvent(Net, "CombatRequestAttack"),
			CombatRequestParry = resolveNetEvent(Net, "CombatRequestParry"),
			CombatRequestParryEnd = resolveNetEvent(Net, "CombatRequestParryEnd"),
		},
	}, CombatService)
end

function CombatService:_fireNet(eventName, ...)
	local eventObject = self._netEvents[eventName]
	if type(eventObject) ~= "table" then
		if not self._cache.warnedMissingEvent[eventName] then
			self._cache.warnedMissingEvent[eventName] = true
		end
		return
	end

	local fire = eventObject.Fire
	if type(fire) ~= "function" then
		if not self._cache.warnedMissingEvent[eventName] then
			self._cache.warnedMissingEvent[eventName] = true
		end
		return
	end

	fire(...)
end

function CombatService:_cancelPendingAttack()
	self._combat.attackSerial += 1
	self._combat.queuedAttack = false
	self._combat.activeAttackTrack = nil
	self._flags.attackActive = false
	self:_setCombatSprintLocked(false)
	self._combat.comboContinueUntil = 0
	self._combat.comboIndex = 1
	self:_restorePostAttackMovement()
end

function CombatService:_endParry(shouldNotifyServer)
	local hadParryState = self._flags.parryActive
		or self._combat.parryRequestActive
		or (self._combat.activeParryTrack ~= nil)
	local wasParryRequestActive = self._combat.parryRequestActive == true
	self._combat.parryRequestActive = false
	self._flags.parryActive = false

	local activeParryTrack = self._combat.activeParryTrack
	self._combat.activeParryTrack = nil
	if activeParryTrack then
		activeParryTrack:AdjustSpeed(1)
		if activeParryTrack.IsPlaying then
			activeParryTrack:Stop(0.04)
		end
	end

	CharacterAnimationService.StopActionGroup("Combat_Parry", 0.04)

	if shouldNotifyServer and wasParryRequestActive then
		self:_fireNet("CombatRequestParryEnd")
	end

	if hadParryState then
		self:_syncIdleState()
	end
end

function CombatService:_setCombatSprintLocked(isLocked)
	local character = self._characterState.character
	if not character then
		return
	end

	local nextValue = isLocked == true
	local sprintLockAttribute = CombatConfig.Client.SprintLockAttribute
	if character:GetAttribute(sprintLockAttribute) == nextValue then
		return
	end

	character:SetAttribute(sprintLockAttribute, nextValue)
end

function CombatService:_applyAttackMovementRestrictions()
	local humanoid = self._characterState.humanoid
	if not humanoid or humanoid.Health <= 0 then
		return
	end

	if humanoid.WalkSpeed ~= CombatConfig.Client.AttackWalkSpeed then
		humanoid.WalkSpeed = CombatConfig.Client.AttackWalkSpeed
	end
end

function CombatService:_restorePostAttackMovement()
	local humanoid = self._characterState.humanoid
	if not humanoid or humanoid.Health <= 0 then
		return
	end

	if humanoid.WalkSpeed ~= MovementStats.DefaultWalkSpeed then
		humanoid.WalkSpeed = MovementStats.DefaultWalkSpeed
	end
end

function CombatService:_preloadCombatAnimations(weaponData)
	if not weaponData then
		return
	end

	local animations = weaponData.Animations
	if type(animations) ~= "table" then
		return
	end

	local function preload(assetValue)
		local assetId = toAssetId(assetValue)
		if not assetId or self._cache.preloadedActionAssets[assetId] then
			return
		end

		local track = CharacterAnimationService.PreloadActionTrack(assetId)
		if track then
			self._cache.preloadedActionAssets[assetId] = true
		end
	end

	preload(animations.Idle)
	preload(animations.Pickup)
	preload(animations.Parry)

	if type(animations.Combo) == "table" then
		for _, comboAnimation in ipairs(animations.Combo) do
			preload(comboAnimation)
		end
	end
end

function CombatService:_queueAttackInput()
	self._combat.queuedAttack = true

	local activeTrack = self._combat.activeAttackTrack
	if not activeTrack or not activeTrack.IsPlaying then
		return
	end

	local length = activeTrack.Length
	if length <= 0 then
		return
	end

	if activeTrack.TimePosition >= (length * 0.85) then
		activeTrack:Stop(0.08)
	end
end

function CombatService:_playQueuedAttack(expectedSerial, tool, weaponData)
	if expectedSerial ~= self._combat.attackSerial then
		return
	end

	if self._flags.attackActive then
		return
	end

	if not self._combat.queuedAttack then
		self:_setCombatSprintLocked(false)
		self._combat.comboIndex = 1
		self:_syncIdleState()
		return
	end

	self._combat.queuedAttack = false

	if self._characterState.tool ~= tool or self._characterState.weaponData ~= weaponData then
		self:_setCombatSprintLocked(false)
		self._combat.comboIndex = 1
		self:_syncIdleState()
		return
	end

	local attackStarted = self:_requestAttack(true)
	if not attackStarted then
		self:_setCombatSprintLocked(false)
		self._combat.comboIndex = 1
		self:_syncIdleState()
	end
end

function CombatService:_stopCombatGroups()
	self._flags.pickupActive = false
	self._flags.idleActive = false
	self:_cancelPendingAttack()
	self:_endParry(true)

	CharacterAnimationService.StopActionGroup("Combat_Pickup", 0.06)
	CharacterAnimationService.StopActionGroup("Combat_Attack", 0.035)
	CharacterAnimationService.StopActionGroup("Combat_Parry", 0.06)
	CharacterAnimationService.StopActionGroup("Combat_Idle", 0.08)
end

function CombatService:_isMovementIdle()
	local humanoid = self._characterState.humanoid
	if not humanoid or humanoid.Health <= 0 then
		return false
	end

	if humanoid.SeatPart ~= nil then
		return false
	end

	if humanoid.MoveDirection.Magnitude > 0.05 then
		return false
	end

	local state = humanoid:GetState()
	if state == Enum.HumanoidStateType.Jumping
		or state == Enum.HumanoidStateType.Freefall
		or state == Enum.HumanoidStateType.FallingDown
		or state == Enum.HumanoidStateType.Climbing
		or state == Enum.HumanoidStateType.Swimming
		or state == Enum.HumanoidStateType.Seated
		or state == Enum.HumanoidStateType.Dead
	then
		return false
	end

	return true
end

function CombatService:_setIdleEnabled(isEnabled)
	if isEnabled then
		if self._flags.idleActive then
			return
		end

		self._flags.idleActive = true
		self:_playIdle()
		return
	end

	if not self._flags.idleActive then
		return
	end

	self._flags.idleActive = false
	CharacterAnimationService.StopActionGroup("Combat_Idle", 0.06)
end

function CombatService:_syncIdleState()
	local shouldIdle = self._characterState.tool ~= nil
		and self._flags.pickupActive == false
		and self._flags.attackActive == false
		and self._flags.parryActive == false
		and self:_isMovementIdle()

	self:_setIdleEnabled(shouldIdle)
end

function CombatService:_playIdle()
	if not self._characterState.tool or not self._characterState.weaponData then
		return
	end

	local idleAssetId = toAssetId(self._characterState.weaponData.Animations.Idle)
	if not idleAssetId then
		return
	end

	CharacterAnimationService.PlayActionTrack(idleAssetId, {
		Group = "Combat_Idle",
		Looped = true,
		FadeTime = 0.08,
		Priority = Enum.AnimationPriority.Action,
	})
end

function CombatService:_playPickup()
	if not self._characterState.tool or not self._characterState.weaponData then
		return
	end

	self._flags.pickupActive = true
	self:_setIdleEnabled(false)
	CharacterAnimationService.StopActionGroup("Combat_Idle", 0.06)

	local pickupAssetId = toAssetId(self._characterState.weaponData.Animations.Pickup)
	if not pickupAssetId then
		self._flags.pickupActive = false
		self:_syncIdleState()
		return
	end

	local pickupTrack = CharacterAnimationService.PlayActionTrack(pickupAssetId, {
		Group = "Combat_Pickup",
		Looped = false,
		FadeTime = 0.06,
		Priority = Enum.AnimationPriority.Action2,
	})

	if not pickupTrack then
		self._flags.pickupActive = false
		self:_syncIdleState()
		return
	end

	pickupTrack.Stopped:Once(function()
		self._flags.pickupActive = false
		self:_syncIdleState()
	end)
end

function CombatService:_setEquippedTool(tool)
	if self._characterState.tool == tool then return end

	self._characterState.tool = tool
	
	self._characterState.weaponType = resolveWeaponType(tool)
	self._characterState.weaponData = resolveWeaponData(tool, self._characterState.weaponType)
	
	self._combat.comboIndex = 1
	self._combat.comboContinueUntil = 0
	
	self._flags.pickupActive = false
	self._flags.attackActive = false
	self._flags.parryActive = false
	self._flags.idleActive = false

	self:_stopCombatGroups()
	if self._characterState.tool then
		self:_preloadCombatAnimations(self._characterState.weaponData)
		self:_playPickup()
	else
		self:_setIdleEnabled(false)
	end
end

function CombatService:_refreshEquippedTool()
	if not self._characterState.character then
		self:_setEquippedTool(nil)
		return
	end

	for _, child in ipairs(self._characterState.character:GetChildren()) do
		if isCombatTool(child) then
			self:_setEquippedTool(child)
			return
		end
	end

	self:_setEquippedTool(nil)
end

function CombatService:_onAttackAction(_, inputState)
	if inputState ~= Enum.UserInputState.Begin then
		return Enum.ContextActionResult.Pass
	end

	if UserInputService:GetFocusedTextBox() ~= nil then
		return Enum.ContextActionResult.Pass
	end

	self:_requestAttack()
	return Enum.ContextActionResult.Pass
end

function CombatService:_onParryAction(_, inputState)
	if inputState == Enum.UserInputState.Begin then
		if UserInputService:GetFocusedTextBox() ~= nil then
			return Enum.ContextActionResult.Pass
		end

		self:_beginParry()
		return Enum.ContextActionResult.Pass
	end

	if inputState ~= Enum.UserInputState.End and inputState ~= Enum.UserInputState.Cancel then
		return Enum.ContextActionResult.Pass
	end

	self:_endParry(true)
	return Enum.ContextActionResult.Pass
end

function CombatService:_requestAttack(isQueuedAttack)
	local tool = self._characterState.tool
	local weaponData = self._characterState.weaponData
	if not tool or not weaponData then
		return false
	end

	if self._flags.parryActive then
		return false
	end

	self:_preloadCombatAnimations(weaponData)

	local comboAnimations = weaponData.Animations.Combo
	local comboCount = #comboAnimations
	if comboCount <= 0 then
		return false
	end

	if self._flags.attackActive then
		self:_queueAttackInput()
		return false
	end

	local now = os.clock()
	local comboIndex = 1
	if isQueuedAttack == true then
		comboIndex = (self._combat.comboIndex % comboCount) + 1
	elseif now <= self._combat.comboContinueUntil then
		comboIndex = (self._combat.comboIndex % comboCount) + 1
	end
	self._combat.comboContinueUntil = 0
	self._combat.comboIndex = comboIndex
	self._flags.attackActive = true
	self:_setCombatSprintLocked(true)
	self:_applyAttackMovementRestrictions()

	self:_setIdleEnabled(false)
	CharacterAnimationService.StopActionGroup("Combat_Parry", 0.05)

	local attackAssetId = toAssetId(comboAnimations[comboIndex])
	if not attackAssetId then
		self:_cancelPendingAttack()
		self._combat.comboIndex = 1
		self:_syncIdleState()
		return false
	end

	local track = CharacterAnimationService.PlayActionTrack(attackAssetId, {
		Group = "Combat_Attack",
		Looped = false,
		FadeTime = 0.035,
		Priority = Enum.AnimationPriority.Action4,
	})

	if not track then
		self:_cancelPendingAttack()
		self._combat.comboIndex = 1
		self:_syncIdleState()
		return false
	end

	self._combat.attackSerial += 1
	local localSerial = self._combat.attackSerial
	local hitSent = false
	self._combat.activeAttackTrack = track
	local markerConnection
	local keyframeConnection
	local chainMarkerConnection
	local chainKeyframeConnection
	local finishedConnection
	local chainFallbackTaskSerial = localSerial
	local attackFinalized = false

	local function fireAttackHit()
		if hitSent or localSerial ~= self._combat.attackSerial then
			return
		end

		hitSent = true
		self:_fireNet("CombatRequestAttack", comboIndex)
	end

	markerConnection = track:GetMarkerReachedSignal("Hit"):Connect(fireAttackHit)
	keyframeConnection = track.KeyframeReached:Connect(function(keyframeName)
		if keyframeName == "Hit" then
			fireAttackHit()
		end
	end)

	local function requestChainFinish()
		if localSerial ~= self._combat.attackSerial then
			return
		end

		if not self._combat.queuedAttack then
			return
		end

		if track.IsPlaying then
			track:Stop(0.08)
		end
	end

	chainMarkerConnection = track:GetMarkerReachedSignal("Chain"):Connect(requestChainFinish)
	chainKeyframeConnection = track.KeyframeReached:Connect(function(keyframeName)
		if keyframeName == "Chain" then
			requestChainFinish()
		end
	end)

	local function finishAttack()
		if attackFinalized then
			return
		end
		attackFinalized = true

		if markerConnection then
			markerConnection:Disconnect()
			markerConnection = nil
		end
		if keyframeConnection then
			keyframeConnection:Disconnect()
			keyframeConnection = nil
		end
		if chainMarkerConnection then
			chainMarkerConnection:Disconnect()
			chainMarkerConnection = nil
		end
		if chainKeyframeConnection then
			chainKeyframeConnection:Disconnect()
			chainKeyframeConnection = nil
		end
		if finishedConnection then
			finishedConnection:Disconnect()
			finishedConnection = nil
		end

		if localSerial ~= self._combat.attackSerial then
			return
		end

		self._flags.attackActive = false
		self._combat.activeAttackTrack = nil

		if self._combat.queuedAttack then
			task.defer(function()
				self:_playQueuedAttack(localSerial, tool, weaponData)
			end)
			return
		end

		self:_setCombatSprintLocked(false)
		self:_restorePostAttackMovement()
		self._combat.comboContinueUntil = os.clock() + getComboContinueWindow(weaponData)
		self:_syncIdleState()
	end

	task.spawn(function()
		local length = getTrackLength(track)
		if length <= 0 then
			return
		end

		local waitTime = math.max(0, length * 0.85)
		if waitTime > 0 then
			task.wait(waitTime)
		end

		if chainFallbackTaskSerial ~= self._combat.attackSerial then
			return
		end

		requestChainFinish()
	end)

	task.spawn(function()
		local length = getTrackLength(track)
		local timeout = 0.9
		if length > 0 then
			timeout = math.max(timeout, length + 0.2)
		end

		task.wait(timeout)

		if attackFinalized or localSerial ~= self._combat.attackSerial or self._flags.attackActive == false then
			return
		end

		if track.IsPlaying then
			track:Stop(0.08)
		end

		task.defer(finishAttack)
	end)

	finishedConnection = connectTrackFinished(track, finishAttack)

	return true
end

function CombatService:_beginParry()
	if self._flags.parryActive or self._combat.parryRequestActive then
		return
	end

	local tool = self._characterState.tool
	local weaponData = self._characterState.weaponData
	if not tool or not weaponData then
		return
	end

	local now = os.clock()
	if now < self._combat.nextParryAt then
		return
	end

	self._combat.nextParryAt = now + CombatConfig.ParryCooldown
	self._combat.comboIndex = 1
	self._combat.comboContinueUntil = 0
	self._combat.parryRequestActive = true
	self._flags.parryActive = true
	self:_cancelPendingAttack()

	CharacterAnimationService.StopActionGroup("Combat_Attack", 0.035)
	self:_setIdleEnabled(false)

	local parryAssetId = toAssetId(weaponData.Animations.Parry)
	self._combat.activeParryTrack = nil
	if parryAssetId then
		local parryTrack = CharacterAnimationService.PlayActionTrack(parryAssetId, {
			Group = "Combat_Parry",
			Looped = false,
			FadeTime = 0.04,
			Priority = Enum.AnimationPriority.Action3,
		})
		self._combat.activeParryTrack = parryTrack

		if parryTrack then
			task.spawn(function()
				local length = getTrackLength(parryTrack)
				if length <= 0 then
					return
				end

				local freezeAt = math.max(0, length - 0.05)
				while self._combat.parryRequestActive
					and self._combat.activeParryTrack == parryTrack
					and parryTrack.IsPlaying
				do
					if parryTrack.TimePosition >= freezeAt then
						parryTrack.TimePosition = freezeAt
						parryTrack:AdjustSpeed(0)
						break
					end
					task.wait()
				end
			end)
		end
	end

	self:_fireNet("CombatRequestParry")
end

function CombatService:_syncCharacter(character)
	self._runtime.characterMaid:Cleanup()
	self._runtime.characterMaid = Maid.New()
	if self._characterState.character and self._characterState.character ~= character then
		self._characterState.character:SetAttribute(CombatConfig.Client.SprintLockAttribute, false)
	end
	self._characterState.character = character
	self._characterState.humanoid = nil
	self._cache.preloadedActionAssets = {}

	if not character then
		self:_setCombatSprintLocked(false)
		self:_setEquippedTool(nil)
		return
	end

	self:_setCombatSprintLocked(false)

	self._runtime.characterMaid:Add(character.ChildAdded:Connect(function(child)
		if child:IsA("Tool") then
			task.defer(function()
				self:_refreshEquippedTool()
			end)
		end
	end))

	self._runtime.characterMaid:Add(character.ChildRemoved:Connect(function(child)
		if child:IsA("Tool") then
			task.defer(function()
				self:_refreshEquippedTool()
			end)
		end
	end))

	local humanoid = character:FindFirstChildOfClass("Humanoid")
	if humanoid then
		self._characterState.humanoid = humanoid

		self._runtime.characterMaid:Add(humanoid.StateChanged:Connect(function()
			self:_syncIdleState()
		end))

		self._runtime.characterMaid:Add(humanoid.Running:Connect(function()
			self:_syncIdleState()
		end))

		self._runtime.characterMaid:Add(humanoid.Died:Connect(function()
			self:_setEquippedTool(nil)
		end))
	end

	self:_refreshEquippedTool()
	self:_syncIdleState()
end

function CombatService:Init()
	if self._runtime.initialized then
		return
	end
	self._runtime.initialized = true
end

function CombatService:Start()
	if self._runtime.started then
		return
	end
	self._runtime.started = true

	local localPlayer = Players.LocalPlayer
	if not localPlayer then
		return
	end

	local parryInput = CombatConfig.ParryInput

	ContextActionService:BindAction("CombatService_Attack", function(...)
		return self:_onAttackAction(...)
	end, false, Enum.UserInputType.MouseButton1, Enum.KeyCode.ButtonR2)

	ContextActionService:BindAction("CombatService_Parry", function(...)
		return self:_onParryAction(...)
	end, false, parryInput.Keyboard, parryInput.Gamepad)

	self._runtime.maid:Add(localPlayer.CharacterAdded:Connect(function(character)
		self:_syncCharacter(character)
	end))

	self._runtime.maid:Add(localPlayer.CharacterRemoving:Connect(function()
		self:_syncCharacter(nil)
	end))

	self._runtime.maid:Add(RunService.RenderStepped:Connect(function()
		if self._flags.attackActive then
			self:_applyAttackMovementRestrictions()
		end
		self:_syncIdleState()
	end))

	self:_syncCharacter(localPlayer.Character)
end

local singleton = CombatService.new()

return table.freeze({
	Init = function()
		singleton:Init()
	end,
	Start = function()
		singleton:Start()
	end,
})
