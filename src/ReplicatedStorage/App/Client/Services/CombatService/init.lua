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
local Swords = require(shared.Data.Swords)

local netRoot = shared:WaitForChild("Net")
local Net = require(netRoot:WaitForChild("Client"))
local Maid = require(shared:WaitForChild("Util"):WaitForChild("Maid"))

local CombatService = {}
CombatService.__index = CombatService

local ACTION_ATTACK = "CombatService_Attack"
local ACTION_PARRY = "CombatService_Parry"

local GROUP_PICKUP = "Combat_Pickup"
local GROUP_IDLE = "Combat_Idle"
local GROUP_ATTACK = "Combat_Attack"
local GROUP_PARRY = "Combat_Parry"
local MOVE_IDLE_THRESHOLD = 0.05
local ATTACK_FADE_TIME = 0.035
local ATTACK_HIT_FALLBACK_TIME = 0.11
local ATTACK_HIT_FALLBACK_RATIO = 0.35

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
	local ok, endedSignal = pcall(function()
		return track.Ended
	end)

	if ok and typeof(endedSignal) == "RBXScriptSignal" then
		return endedSignal:Connect(callback)
	end

	return track.Stopped:Connect(callback)
end

function CombatService.new()
	local self = setmetatable({}, CombatService)

	self._initialized = false
	self._started = false
	self._maid = Maid.New()
	self._characterMaid = Maid.New()

	self._character = nil
	self._humanoid = nil
	self._currentTool = nil
	self._currentWeaponType = nil
	self._currentWeaponData = nil

	self._nextParryAt = 0
	self._comboIndex = 1
	self._attackSerial = 0
	self._queuedAttack = false
	self._activeAttackTrack = nil
	self._activeAttackHitSent = false
	self._warnedMissingEvent = {}
	self._isPickupActive = false
	self._isAttackActive = false
	self._isParryActive = false
	self._isIdleActive = false

	self._netEvents = {
		CombatRequestAttack = resolveNetEvent(Net, "CombatRequestAttack"),
		CombatRequestParry = resolveNetEvent(Net, "CombatRequestParry"),
	}

	return self
end

function CombatService:_fireNet(eventName, ...)
	local eventObject = self._netEvents[eventName]
	if type(eventObject) ~= "table" then
		if not self._warnedMissingEvent[eventName] then
			self._warnedMissingEvent[eventName] = true
		end
		return
	end

	local fire = eventObject.Fire
	if type(fire) ~= "function" then
		if not self._warnedMissingEvent[eventName] then
			self._warnedMissingEvent[eventName] = true
		end
		return
	end

	fire(...)
end

function CombatService:_cancelPendingAttack()
	self._attackSerial += 1
	self._queuedAttack = false
	self._activeAttackTrack = nil
	self._activeAttackHitSent = false
	self._isAttackActive = false
	self._comboIndex = 1
end

function CombatService:_queueAttackInput()
	self._queuedAttack = true

	local activeTrack = self._activeAttackTrack
	if not activeTrack or not activeTrack.IsPlaying then
		return
	end

	if self._activeAttackHitSent then
		activeTrack:Stop(ATTACK_FADE_TIME)
	end
end

function CombatService:_playQueuedAttack(expectedSerial, tool, weaponData)
	if expectedSerial ~= self._attackSerial then
		return
	end

	if self._isAttackActive then
		return
	end

	if not self._queuedAttack then
		self._comboIndex = 1
		self:_syncIdleState()
		return
	end

	self._queuedAttack = false

	if self._currentTool ~= tool or self._currentWeaponData ~= weaponData then
		self._comboIndex = 1
		self:_syncIdleState()
		return
	end

	local attackStarted = self:_requestAttack(true)
	if not attackStarted then
		self._comboIndex = 1
		self:_syncIdleState()
	end
end

function CombatService:_stopCombatGroups()
	self._isPickupActive = false
	self._isParryActive = false
	self._isIdleActive = false
	self:_cancelPendingAttack()

	CharacterAnimationService.StopActionGroup(GROUP_PICKUP, 0.06)
	CharacterAnimationService.StopActionGroup(GROUP_ATTACK, ATTACK_FADE_TIME)
	CharacterAnimationService.StopActionGroup(GROUP_PARRY, 0.06)
	CharacterAnimationService.StopActionGroup(GROUP_IDLE, 0.08)
end

function CombatService:_isMovementIdle()
	local humanoid = self._humanoid
	if not humanoid or humanoid.Health <= 0 then
		return false
	end

	if humanoid.SeatPart ~= nil then
		return false
	end

	if humanoid.MoveDirection.Magnitude > MOVE_IDLE_THRESHOLD then
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
		if self._isIdleActive then
			return
		end

		self._isIdleActive = true
		self:_playIdle()
		return
	end

	if not self._isIdleActive then
		return
	end

	self._isIdleActive = false
	CharacterAnimationService.StopActionGroup(GROUP_IDLE, 0.06)
end

function CombatService:_syncIdleState()
	local shouldIdle = self._currentTool ~= nil
		and self._isPickupActive == false
		and self._isAttackActive == false
		and self._isParryActive == false
		and self:_isMovementIdle()

	self:_setIdleEnabled(shouldIdle)
end

function CombatService:_playIdle()
	if not self._currentTool or not self._currentWeaponData then
		return
	end

	local idleAssetId = toAssetId(self._currentWeaponData.Animations.Idle)
	if not idleAssetId then
		return
	end

	CharacterAnimationService.PlayActionTrack(idleAssetId, {
		Group = GROUP_IDLE,
		Looped = true,
		FadeTime = 0.08,
		Priority = Enum.AnimationPriority.Action,
	})
end

function CombatService:_playPickup()
	if not self._currentTool or not self._currentWeaponData then
		return
	end

	self._isPickupActive = true
	self:_setIdleEnabled(false)
	CharacterAnimationService.StopActionGroup(GROUP_IDLE, 0.06)

	local pickupAssetId = toAssetId(self._currentWeaponData.Animations.Pickup)
	if not pickupAssetId then
		self._isPickupActive = false
		self:_syncIdleState()
		return
	end

	local pickupTrack = CharacterAnimationService.PlayActionTrack(pickupAssetId, {
		Group = GROUP_PICKUP,
		Looped = false,
		FadeTime = 0.06,
		Priority = Enum.AnimationPriority.Action2,
	})

	if not pickupTrack then
		self._isPickupActive = false
		self:_syncIdleState()
		return
	end

	pickupTrack.Stopped:Once(function()
		self._isPickupActive = false
		self:_syncIdleState()
	end)
end

function CombatService:_setEquippedTool(tool)
	if self._currentTool == tool then
		return
	end

	self._currentTool = tool
	self._currentWeaponType = resolveWeaponType(tool)
	self._currentWeaponData = resolveWeaponData(tool, self._currentWeaponType)
	self._comboIndex = 1
	self._isPickupActive = false
	self._isAttackActive = false
	self._isParryActive = false
	self._isIdleActive = false

	self:_stopCombatGroups()
	if self._currentTool then
		self:_playPickup()
	else
		self:_setIdleEnabled(false)
	end
end

function CombatService:_refreshEquippedTool()
	if not self._character then
		self:_setEquippedTool(nil)
		return
	end

	for _, child in ipairs(self._character:GetChildren()) do
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
	if inputState ~= Enum.UserInputState.Begin then
		return Enum.ContextActionResult.Pass
	end

	if UserInputService:GetFocusedTextBox() ~= nil then
		return Enum.ContextActionResult.Pass
	end

	self:_requestParry()
	return Enum.ContextActionResult.Pass
end

function CombatService:_requestAttack(isQueuedAttack)
	local tool = self._currentTool
	local weaponData = self._currentWeaponData
	if not tool or not weaponData then
		return false
	end

	local comboAnimations = weaponData.Animations.Combo
	local comboCount = #comboAnimations
	if comboCount <= 0 then
		return false
	end

	if self._isAttackActive then
		self:_queueAttackInput()
		return false
	end

	local comboIndex = 1
	if isQueuedAttack == true then
		comboIndex = (self._comboIndex % comboCount) + 1
	end
	self._comboIndex = comboIndex
	self._isAttackActive = true

	self:_setIdleEnabled(false)
	CharacterAnimationService.StopActionGroup(GROUP_PARRY, 0.05)

	local attackAssetId = toAssetId(comboAnimations[comboIndex])
	if not attackAssetId then
		self:_cancelPendingAttack()
		self._comboIndex = 1
		self:_syncIdleState()
		return false
	end

	local track = CharacterAnimationService.PlayActionTrack(attackAssetId, {
		Group = GROUP_ATTACK,
		Looped = false,
		FadeTime = ATTACK_FADE_TIME,
		Priority = Enum.AnimationPriority.Action4,
	})

	if not track then
		self:_cancelPendingAttack()
		self._comboIndex = 1
		self:_syncIdleState()
		return false
	end

	self._attackSerial += 1
	local localSerial = self._attackSerial
	local hitSent = false
	self._activeAttackTrack = track
	self._activeAttackHitSent = false
	local markerConnection
	local finishedConnection

	local function fireAttackHit()
		if hitSent or localSerial ~= self._attackSerial then
			return
		end

		hitSent = true
		self._activeAttackHitSent = true
		self:_fireNet("CombatRequestAttack", comboIndex)

		if self._queuedAttack and track.IsPlaying then
			track:Stop(ATTACK_FADE_TIME)
		end
	end

	markerConnection = track:GetMarkerReachedSignal("Hit"):Connect(fireAttackHit)

	local fallbackDelay = ATTACK_HIT_FALLBACK_TIME
	if track.Length > 0 then
		fallbackDelay = math.max(ATTACK_HIT_FALLBACK_TIME, track.Length * ATTACK_HIT_FALLBACK_RATIO)
	end

	task.delay(fallbackDelay, function()
		fireAttackHit()
	end)

	finishedConnection = connectTrackFinished(track, function()
		if markerConnection then
			markerConnection:Disconnect()
			markerConnection = nil
		end
		if finishedConnection then
			finishedConnection:Disconnect()
			finishedConnection = nil
		end

		fireAttackHit()

		if localSerial == self._attackSerial then
			self._isAttackActive = false
			self._activeAttackTrack = nil
			self._activeAttackHitSent = false

			if self._queuedAttack then
				task.defer(function()
					self:_playQueuedAttack(localSerial, tool, weaponData)
				end)
				return
			end

			self._comboIndex = 1
			self:_syncIdleState()
		end
	end)

	return true
end

function CombatService:_requestParry()
	local tool = self._currentTool
	local weaponData = self._currentWeaponData
	if not tool or not weaponData then
		return
	end

	local now = os.clock()
	if now < self._nextParryAt then
		return
	end

	self._nextParryAt = now + CombatConfig.ParryCooldown
	self._comboIndex = 1
	self._isParryActive = true
	self:_cancelPendingAttack()

	CharacterAnimationService.StopActionGroup(GROUP_ATTACK, ATTACK_FADE_TIME)
	self:_setIdleEnabled(false)

	local parryAssetId = toAssetId(weaponData.Animations.Parry)
	local track = nil
	if parryAssetId then
		track = CharacterAnimationService.PlayActionTrack(parryAssetId, {
			Group = GROUP_PARRY,
			Looped = false,
			FadeTime = 0.04,
			Priority = Enum.AnimationPriority.Action3,
		})
	end

	self:_fireNet("CombatRequestParry")

	if track then
		track.Stopped:Once(function()
			self._isParryActive = false
			self:_syncIdleState()
		end)
	else
		self._isParryActive = false
		self:_syncIdleState()
	end
end

function CombatService:_syncCharacter(character)
	self._characterMaid:Cleanup()
	self._characterMaid = Maid.New()
	self._character = character
	self._humanoid = nil

	if not character then
		self:_setEquippedTool(nil)
		return
	end

	self._characterMaid:Add(character.ChildAdded:Connect(function(child)
		if child:IsA("Tool") then
			task.defer(function()
				self:_refreshEquippedTool()
			end)
		end
	end))

	self._characterMaid:Add(character.ChildRemoved:Connect(function(child)
		if child:IsA("Tool") then
			task.defer(function()
				self:_refreshEquippedTool()
			end)
		end
	end))

	local humanoid = character:FindFirstChildOfClass("Humanoid")
	if humanoid then
		self._humanoid = humanoid

		self._characterMaid:Add(humanoid.StateChanged:Connect(function()
			self:_syncIdleState()
		end))

		self._characterMaid:Add(humanoid.Running:Connect(function()
			self:_syncIdleState()
		end))

		self._characterMaid:Add(humanoid.Died:Connect(function()
			self:_setEquippedTool(nil)
		end))
	end

	self:_refreshEquippedTool()
	self:_syncIdleState()
end

function CombatService:Init()
	if self._initialized then
		return
	end
	self._initialized = true
end

function CombatService:Start()
	if self._started then
		return
	end
	self._started = true

	local localPlayer = Players.LocalPlayer
	if not localPlayer then
		return
	end

	local parryInput = CombatConfig.ParryInput

	ContextActionService:BindAction(ACTION_ATTACK, function(...)
		return self:_onAttackAction(...)
	end, false, Enum.UserInputType.MouseButton1, Enum.KeyCode.ButtonR2)

	ContextActionService:BindAction(ACTION_PARRY, function(...)
		return self:_onParryAction(...)
	end, false, parryInput.Keyboard, parryInput.Gamepad)

	self._maid:Add(localPlayer.CharacterAdded:Connect(function(character)
		self:_syncCharacter(character)
	end))

	self._maid:Add(localPlayer.CharacterRemoving:Connect(function()
		self:_syncCharacter(nil)
	end))

	self._maid:Add(RunService.RenderStepped:Connect(function()
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
