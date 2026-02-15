--!strict
local ReplicatedStorage = game:GetService('ReplicatedStorage')
local TweenService = game:GetService('TweenService')
local Players = game:GetService('Players')

local Client = Players.LocalPlayer :: Player

local Packages = ReplicatedStorage:WaitForChild('Packages')
local Trove = require(Packages.Trove)

local FED_TAG = 'Federal'
local OPEN_ATT = '_IsOpen'

local OPEN_ANGLE = -75
local OPEN_TIME = .5
local CLOSE_TIME = .5

local OPEN_TWEEN_INFO = TweenInfo.new(OPEN_TIME, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
local CLOSE_TWEEN_INFO = TweenInfo.new(CLOSE_TIME, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)

local Gate = {}
Gate.__index = Gate

export type Class = typeof(setmetatable({} :: {
	Trove: Trove.Trove,
	CurrentState: boolean,

	OpenedC1: CFrame,
	ClosedC1: CFrame,

	OpenTween: Tween,
	CloseTween: Tween,

	Automatic: boolean,
	FederalOnly: boolean,

	Model: Model,
	Prompt: ProximityPrompt?,

	Visual: Model,
	Arm: Model?,
	Motor: Motor6D,
}, Gate))

function Gate.new(model: Model): Class
	local att = model:FindFirstChild('PromptAttachment')
	local prompt = att and att:FindFirstChildOfClass('ProximityPrompt')

	local visual = model:FindFirstChild('Visual')
	assert(visual and visual:IsA('Model'), `Wrong visual gate setup: {model:GetFullName()}`)

	local arm = visual:FindFirstChild('Arm')
	local motor = visual:FindFirstChild('Motor')
	assert(motor and motor:IsA('Motor6D'), `Wrong motor gate setup: {model:GetFullName()}`)

	local isAuto: boolean = model:GetAttribute('Auto') or false
	local fedOnly: boolean = model:GetAttribute('FederalOnly') or false
	local currentState: boolean = model:GetAttribute(OPEN_ATT) or false

	local defC1 = (motor :: Motor6D).C1
	local openC1 = defC1 * CFrame.Angles(0, 0, math.rad(OPEN_ANGLE))

	local openTween = TweenService:Create(motor, OPEN_TWEEN_INFO, {C1 = openC1})
	local closeTween = TweenService:Create(motor, CLOSE_TWEEN_INFO, {C1 = defC1})

	local trove = Trove.new()
	local self: Class = setmetatable({
		Trove = trove,
		CurrentState = currentState,

		OpenedC1 = openC1,
		ClosedC1 = defC1,

		OpenTween = openTween,
		CloseTween = closeTween,

		Automatic = isAuto,
		FederalOnly = fedOnly,

		Model = model,
		Prompt = prompt,

		Visual = visual :: any,
		Motor = motor :: any,
		Arm = arm :: any,
	}, Gate)

	task.defer(self._Init, self)
	return self
end

function Gate._Init(self: Class)
	-- Observer
	self.Trove:Add(self.Model:GetAttributeChangedSignal(OPEN_ATT):Connect(function()
		self:OnUpdate()
	end))

	-- Tween
	self.Trove:Add(self.OpenTween:GetPropertyChangedSignal('PlaybackState'):Connect(function()
		if self.OpenTween.PlaybackState ~= Enum.PlaybackState.Completed then return end
		self:UpdateCollisions()
	end))
	self.Trove:Add(self.CloseTween:GetPropertyChangedSignal('PlaybackState'):Connect(function()
		if self.CloseTween.PlaybackState ~= Enum.PlaybackState.Completed then return end
		self:UpdateCollisions()
	end))

	-- Prompt
	if self.Prompt then
		self.Trove:Add(self.Prompt:GetAttributeChangedSignal('Locked'):Connect(function()
			self:UpdatePrompt()
		end))
	end

	self:UpdatePrompt()
	self:ForceSet(self.CurrentState)
end

function Gate.ForceSet(self: Class, to: boolean)
	self.CurrentState = to

	self.OpenTween:Cancel()
	self.CloseTween:Cancel()

	self.Motor.C1 = to and self.OpenedC1 or self.ClosedC1
	self:UpdateCollisions()
end

function Gate.OnUpdate(self: Class)
	local newState: boolean = self.Model:GetAttribute(OPEN_ATT) or false
	if newState == self.CurrentState then return end

	self.CurrentState = newState
	if newState then
		self.OpenTween:Play()
		self.CloseTween:Cancel()
	else
		self.CloseTween:Play()
		self.OpenTween:Cancel()
	end
end

function Gate.UpdatePrompt(self: Class)
	if not self.Prompt then return end

	local locked = self.Prompt:GetAttribute('Locked') == true

	if self.FederalOnly and not locked then
		if Client then
			local newTeam = Client.Team
			local isFed = newTeam and newTeam:HasTag(FED_TAG) or false

			self.Prompt.Enabled = isFed
		else
			self.Prompt.Enabled = true
		end
	else
		self.Prompt.Enabled = not locked
	end
end

function Gate.UpdateCollisions(self: Class)
	if not self.Arm then return end

	for _, des in self.Arm:GetDescendants() do
		if not des:IsA('BasePart') then continue end

		local defCollision = des:GetAttribute('_DefaultCollision')
		if defCollision == nil then
			des:SetAttribute('_DefaultCollision', des.CanCollide)
			defCollision = des.CanCollide
		end

		des.CanCollide = if self.CurrentState then false else defCollision
	end
end

return Gate