local ContextActionService = game:GetService("ContextActionService")
local Players = game:GetService("Players")


local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Workspace = game:GetService("Workspace")

local app = ReplicatedStorage:WaitForChild("App")
local CharacterAnimationService = require(app.Client.Services.CharacterAnimationService)
local MovementStats = require(app.Shared.Data.MovementStats)

local SprintController = {}
SprintController.__index = SprintController

local ACTION_NAME = "SprintController_Sprint"
local SPRINT_KEYS = {
	Enum.KeyCode.LeftShift,
	Enum.KeyCode.RightShift,
	Enum.KeyCode.ButtonL3,
}

function SprintController.new()
	local self = setmetatable({}, SprintController)
	self._started = false
	self._connections = {}
	self._character = nil
	self._humanoid = nil
	self._isSprinting = false
	self._normalFov = MovementStats.DefaultFov
	self._targetFov = MovementStats.DefaultFov
	self._isRecoveringFov = false
	return self
end

function SprintController:_addConnection(connection)
	table.insert(self._connections, connection)
	return connection
end

function SprintController:_disconnectAll()
	for _, connection in ipairs(self._connections) do
		connection:Disconnect()
	end
	table.clear(self._connections)
end

function SprintController:_canSprint()
	if not self._humanoid then
		return false
	end

	if self._humanoid.Health <= 0 then
		return false
	end

	if self._humanoid.SeatPart ~= nil then
		return false
	end

	return true
end

function SprintController:_setHumanoidWalkSpeed(speed)
	if not self._humanoid then
		return
	end

	if self._humanoid.Health <= 0 then
		return
	end

	self._humanoid.WalkSpeed = speed
end

function SprintController:_hasEquippedTool()
	if not self._character then
		return false
	end

	for _, child in ipairs(self._character:GetChildren()) do
		if child:IsA("Tool") then
			return true
		end
	end

	return false
end

function SprintController:_getSprintWalkSpeed()
	if self:_hasEquippedTool() then
		return MovementStats.SprintWalkSpeedWithTool
	end

	return MovementStats.SprintWalkSpeedWithoutTool
end

function SprintController:_setSprinting(isSprinting)
	local nextState = isSprinting == true
	if nextState and not self:_canSprint() then
		nextState = false
	end

	if self._isSprinting == nextState then
		return
	end

	self._isSprinting = nextState
	CharacterAnimationService.SetSprinting(nextState)
	local camera = Workspace.CurrentCamera

	if nextState then
		if camera then
			self._normalFov = camera.FieldOfView
		end
		self:_setHumanoidWalkSpeed(self:_getSprintWalkSpeed())
		self._targetFov = MovementStats.SprintFov
		self._isRecoveringFov = false
	else
		self:_setHumanoidWalkSpeed(MovementStats.DefaultWalkSpeed)
		self._targetFov = self._normalFov
		self._isRecoveringFov = true
	end
end

function SprintController:_syncCharacter(character)
	self._character = character
	if not character then
		self._humanoid = nil
		self:_setSprinting(false)
		self._targetFov = self._normalFov
		self._isRecoveringFov = true
		return
	end

	local humanoid = character:FindFirstChildOfClass("Humanoid")
	if not humanoid then
		humanoid = character:WaitForChild("Humanoid", 10)
	end

	self._humanoid = humanoid
	self:_setSprinting(false)
	self:_setHumanoidWalkSpeed(MovementStats.DefaultWalkSpeed)

	if humanoid then
		self:_addConnection(humanoid.Died:Connect(function()
			self:_setSprinting(false)
			self._targetFov = self._normalFov
			self._isRecoveringFov = true
		end))
	end

	self:_addConnection(character.ChildAdded:Connect(function(child)
		if child:IsA("Tool") and self._isSprinting then
			self:_setHumanoidWalkSpeed(self:_getSprintWalkSpeed())
		end
	end))

	self:_addConnection(character.ChildRemoved:Connect(function(child)
		if child:IsA("Tool") and self._isSprinting then
			self:_setHumanoidWalkSpeed(self:_getSprintWalkSpeed())
		end
	end))
end

function SprintController:_onSprintAction(_, inputState)
	if inputState == Enum.UserInputState.Begin then
		if UserInputService:GetFocusedTextBox() ~= nil then
			return Enum.ContextActionResult.Pass
		end
		self:_setSprinting(true)
	elseif inputState == Enum.UserInputState.End or inputState == Enum.UserInputState.Cancel then
		self:_setSprinting(false)
	end

	return Enum.ContextActionResult.Pass
end

function SprintController:_startFovUpdater()
	self:_addConnection(RunService.RenderStepped:Connect(function(deltaTime)
		local camera = Workspace.CurrentCamera
		if not camera then
			return
		end

		if self._isSprinting and not self:_canSprint() then
			self:_setSprinting(false)
		end

		if not self._isSprinting and not self._isRecoveringFov then
			self._normalFov = camera.FieldOfView
			self._targetFov = camera.FieldOfView
		end

		local targetFov = self._targetFov

		local sharpness = math.max(0.01, MovementStats.FovSmoothSharpness)
		local alpha = 1 - math.exp(-sharpness * deltaTime)
		camera.FieldOfView = camera.FieldOfView + (targetFov - camera.FieldOfView) * alpha

		if self._isRecoveringFov and math.abs(camera.FieldOfView - targetFov) < 0.05 then
			camera.FieldOfView = targetFov
			self._isRecoveringFov = false
		end
	end))
end

function SprintController:Start()
	if self._started then
		return
	end
	self._started = true

	local localPlayer = Players.LocalPlayer
	if not localPlayer then
		return
	end

	local camera = Workspace.CurrentCamera
	if camera then
		self._normalFov = camera.FieldOfView
		self._targetFov = camera.FieldOfView
	end

	ContextActionService:BindAction(ACTION_NAME, function(...)
		return self:_onSprintAction(...)
	end, false, table.unpack(SPRINT_KEYS))

	self:_addConnection(localPlayer.CharacterAdded:Connect(function(character)
		self:_syncCharacter(character)
	end))

	self:_addConnection(localPlayer.CharacterRemoving:Connect(function()
		self:_setSprinting(false)
		self._humanoid = nil
		self._isRecoveringFov = true
	end))

	self:_startFovUpdater()
	self:_syncCharacter(localPlayer.Character)
end

local singleton = SprintController.new()

return table.freeze({
	Start = function()
		singleton:Start()
	end,
})