--!strict
local ReplicatedStorage = game:GetService('ReplicatedStorage')
local Players = game:GetService('Players')

local Packages = ReplicatedStorage.Packages
local Trove = require(Packages.Trove)
local Net = require(Packages.Net)

local Util = ReplicatedStorage.Util
local Placement = require(Util.Placement)

local Assets = ReplicatedStorage.Assets.Tools
local PromptTemplate = Assets.General.ExplodeGatePrompt
local C4Template = Assets.Placement.C4

local Notify = Net:RemoteEvent('Notification')
local PlaySoundAt = Net:RemoteEvent('PlaySoundAt')

local OPEN_ATT = '_IsOpen'
local AUTO_CLOSE_TIME = 10--30
local IGNITION_TIME = 5

local Gate = {}
Gate.__index = Gate

export type Class = typeof(setmetatable({} :: {
	Model: Model,
	Collider: BasePart,
	
	PromptHolder: BasePart,
	Prompt: ProximityPrompt,
	
	Trove: Trove.Trove,
	CurrentState: boolean,
	HasExploded: boolean,

	AutoThread: thread?,
	VisualObj: BasePart,
}, Gate))

-- Util
local function FindVehicleModel(model: Model): VehicleSeat?
	local driveSeat = model:FindFirstChild("DriveSeat")
	return (driveSeat and driveSeat:IsA("VehicleSeat"))
		and driveSeat
		or nil
end

local function CleanThread(chore: thread)
	local cancelled
	if coroutine.running() ~= chore then
		cancelled = pcall(function()
			task.cancel(chore)
		end)
	end

	if not cancelled then
		local toCancel = chore
		task.defer(function()
			task.cancel(toCancel)
		end)
	end
end

-- Object
function Gate.new(model: Model): Class
	local collider = model:FindFirstChild('Collider')
	assert(collider and collider:IsA('BasePart'), `Wrong collider gate setup: {model:GetFullName()}`)
	
	local promptHolder = model:FindFirstChild('Prompt')
	assert(promptHolder and promptHolder:IsA('BasePart'), `Wrong prompt gate setup: {model:GetFullName()}`)
	
	local currentState: boolean = model:GetAttribute(OPEN_ATT) or false
	local prompt = PromptTemplate:Clone()
		prompt.Parent = (promptHolder:FindFirstChild('PromptAtt') or promptHolder) :: any
		
	local c4Inst = C4Template:Clone() 
		c4Inst.Name = '_C4Visual'
		c4Inst:PivotTo(promptHolder.CFrame)
		c4Inst.Parent = model :: any
	
	local trove = Trove.new()
	local self: Class = setmetatable({
		Model = model,	
		Collider = collider,
		
		PromptHolder = promptHolder,
		Prompt = prompt :: any,
		
		Trove = trove,
		CurrentState = currentState,
		HasExploded = false,
		
		AutoThread = nil :: any,
		VisualObj = c4Inst :: any,
	}, Gate)
	
	task.defer(self._Init, self)
	return self
end

function Gate._Init(self: Class)
	self.Model.ModelStreamingMode = Enum.ModelStreamingMode.Atomic
	
	self.Collider.Transparency = 1
	self.Collider.CanCollide = false
	self.Collider.Anchored = true
	
	self.PromptHolder.Transparency = 1
	self.PromptHolder.CanCollide = false
	self.PromptHolder.Anchored = true
	
	local block = self.Model:FindFirstChild('Block')
	if block and block:IsA('BasePart') then
		block.Transparency = 1
	end
	
	self:_SetVisual(false)
	
	self.Trove:Add(self.Prompt.Triggered:Connect(function(player: Player)
		local char = player.Character
		if not char then return end
		
		local tool = char:FindFirstChildOfClass('Tool')
		if not tool or tool.Name ~= 'C4' then
			Notify:FireClient(player, 'Gate/NoC4Found')
			return
		end
		
		local succ = self:Open()
		if succ then tool:Destroy() end
	end))
end

function Gate.Open(self: Class): boolean
	if self.CurrentState then return false end
	
	self.CurrentState = true
	self.Prompt.Enabled = false
	
	task.spawn(function()
		self:_SetVisual(true)

		local iter = IGNITION_TIME // 1
		for i=1, iter do
			PlaySoundAt:FireAllClients('SFX/Interactions/C4/Beep', self.VisualObj.Position)
			task.wait(IGNITION_TIME / iter)
		end

		self.Model:SetAttribute(OPEN_ATT, true)
		self.HasExploded = true
		
		self:_SetVisual(false)
		self:_StartThread()
	end)

	return true
end

function Gate._StartThread(self: Class)
	local activeThread = self.AutoThread
	if activeThread then
		CleanThread(activeThread)
		self.AutoThread = nil
	end

	self.AutoThread = task.delay(AUTO_CLOSE_TIME, self.Close, self)
end

function Gate._GetCars(self: Class): {Model}
	local hasChecked = {}
	local foundCars = {}
	
	for _, other in workspace:GetPartsInPart(self.Collider) do
		local ancestor = Placement.FindLastAncestorOfClass(other, 'Model') :: Model?
		if not ancestor or table.find(hasChecked, ancestor) then continue end

		table.insert(hasChecked, ancestor)

		local seat = FindVehicleModel(ancestor)
		if not seat then continue end

		table.insert(foundCars, ancestor)
	end
	
	return foundCars
end

function Gate._SetVisual(self: Class, to: boolean)
	self.VisualObj.Transparency = to and 0 or 1
end

function Gate.MoveColliding(self: Class)
	local cars = self:_GetCars()
	if #cars <= 0 then return end
	
	local collCFrame = self.Collider.CFrame
	
	local baseOffset = (self.Collider.Size.Z / 2) + 2
	local basePosition = collCFrame * CFrame.new(-Vector3.zAxis * baseOffset)

	local currentXOffset = 0

	for _, car: Model in ipairs(cars) do
		local _, size = car:GetBoundingBox()

		local halfWidth = size.X / 2
		currentXOffset += halfWidth + 1

		local targetPos = basePosition * CFrame.new(currentXOffset, size.Y/2, -size.Z/2)

		car:PivotTo(targetPos)
		currentXOffset += halfWidth
	end
end

function Gate.Close(self: Class): boolean
	if not (self.CurrentState and self.HasExploded) then return false end

	self.HasExploded = false
	self.CurrentState = false
	self:MoveColliding()
	
	self.Prompt.Enabled = true
	self.Model:SetAttribute(OPEN_ATT, false)
	
	local activeThread = self.AutoThread
	if activeThread and coroutine.running() ~= activeThread then
		CleanThread(activeThread)
		self.AutoThread = nil
	end
	
	return true
end

function Gate.Toggle(self: Class): boolean
	return if self.CurrentState
		then self:Close()
		else self:Open()
end

return Gate
