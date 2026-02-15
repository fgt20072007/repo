--!strict
local ReplicatedStorage = game:GetService('ReplicatedStorage')
local TweenService = game:GetService('TweenService')
local Players = game:GetService('Players')

local Client = Players.LocalPlayer :: Player

local Packages = ReplicatedStorage:WaitForChild('Packages')
local Trove = require(Packages.Trove)

local VFX = ReplicatedStorage:WaitForChild('Assets'):WaitForChild('VFX')
local Explotion = require(VFX.Explotion)

local OPEN_ATT = '_IsOpen'
local INDEXER = table.freeze {'Left', 'Right'}

local OPEN_ANGLE = 120
local OPEN_TIME = .5
local CLOSE_TIME = .5

local OPEN_TWEEN_INFO = TweenInfo.new(OPEN_TIME, Enum.EasingStyle.Back, Enum.EasingDirection.Out)
local CLOSE_TWEEN_INFO = TweenInfo.new(CLOSE_TIME, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)

local Gate = {}
Gate.__index = Gate

type SideData = {
	Motor: Motor6D,
	
	OpenC1: CFrame,
	ClosedC1: CFrame,
	
	OpenTween: Tween,
	CloseTween: Tween,
}

export type Class = typeof(setmetatable({} :: {
	Trove: Trove.Trove,
	CurrentState: boolean,
	
	Left: SideData,
	Right: SideData,

	Model: Model,
	PromptHolder: BasePart,
	Block: BasePart?,
	Visual: Model,
}, Gate))

local function BuildData(motor: Motor6D): SideData
	local defC1 = motor.C1
	local openC1 = defC1 * CFrame.Angles(0, 0, math.rad(OPEN_ANGLE))
	
	return {
		Motor = motor,
		
		OpenC1 = openC1,
		ClosedC1 = defC1,
		
		OpenTween = TweenService:Create(motor, OPEN_TWEEN_INFO, {C1 = openC1}),
		CloseTween = TweenService:Create(motor, CLOSE_TWEEN_INFO, {C1 = defC1}),
	}
end

function Gate.new(model: Model): Class
	local promptHolder = model:FindFirstChild('Prompt')
	assert(promptHolder and promptHolder:IsA('BasePart'), `Wrong prompt gate setup: {model:GetFullName()}`)

	local visual = model:FindFirstChild('Visual')
	assert(visual and visual:IsA('Model'), `Wrong visual gate setup: {model:GetFullName()}`)

	local rightMotor = visual:FindFirstChild('RightHinge')
	assert(rightMotor and rightMotor:IsA('Motor6D'), `Wrong right motor gate setup: {model:GetFullName()}`)

	local leftMotor = visual:FindFirstChild('LeftHinge')
	assert(leftMotor and leftMotor:IsA('Motor6D'), `Wrong left motor gate setup: {model:GetFullName()}`)
	
	local block = model:FindFirstChild('Block')
	local currentState: boolean = model:GetAttribute(OPEN_ATT) or false

	local trove = Trove.new()
	local self: Class = setmetatable({
		Trove = trove,
		CurrentState = currentState,
		
		Right = BuildData(rightMotor),
		Left = BuildData(leftMotor),

		Model = model,
		PromptHolder = promptHolder,
		Block = block :: any,
		Visual = visual :: any,
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
	self.Trove:Add(self.Right.OpenTween:GetPropertyChangedSignal('PlaybackState'):Connect(function()
		if self.Right.OpenTween.PlaybackState ~= Enum.PlaybackState.Completed then return end
		self:UpdateCollisions()
	end))
	self.Trove:Add(self.Right.CloseTween:GetPropertyChangedSignal('PlaybackState'):Connect(function()
		if self.Right.CloseTween.PlaybackState ~= Enum.PlaybackState.Completed then return end
		self:UpdateCollisions()
	end))

	self:ForceSet(self.CurrentState)
end

function Gate.ForceSet(self: Class, to: boolean)
	self.CurrentState = to

	for _, index in INDEXER do
		local list: SideData = (self :: any)[index]
		for id, value in list :: any do
			if typeof(value)~='Instance'
				or not value:IsA('Tween')
			then continue end
			value:Cancel()
		end
		
		for id, value in list :: any do
			if typeof(value)~='Instance'
				or not value:IsA('Motor6D')
			then continue end
			value.C1 = to and list.OpenC1 or list.ClosedC1
		end
	end

	self:UpdateCollisions()
end

function Gate.OnUpdate(self: Class)
	local newState: boolean = self.Model:GetAttribute(OPEN_ATT) or false
	if newState == self.CurrentState then return end

	self.CurrentState = newState
	if newState then
		Explotion.Run(self.PromptHolder.Position)
	end

	for _, index in INDEXER do
		local list: SideData = (self :: any)[index]

		if newState then
			list.OpenTween:Play()
			list.CloseTween:Cancel()
		else
			list.CloseTween:Play()
			list.OpenTween:Cancel()
		end
	end
end

function Gate.UpdateCollisions(self: Class)
	if not self.Visual then return end
	
	if self.Block then
		self.Block.CanCollide = if self.CurrentState then false else true
	end

	for _, des in self.Visual:QueryDescendants('BasePart')  do
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