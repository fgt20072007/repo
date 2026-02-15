--!strict
local ReplicatedStorage = game:GetService('ReplicatedStorage')
local Players = game:GetService('Players')

local Packages = ReplicatedStorage.Packages
local Trove = require(Packages.Trove)

local Util = ReplicatedStorage.Util
local Placement = require(Util.Placement)

local AUTO_REV_ATT = 'AutoRevision'
local AUTO_TIME_ATT = 'AutoOpenTime'

local FED_TAG = 'Federal'
local OPEN_ATT = '_IsOpen'

local AUTO_DELAY = .75
local AUTO_OPEN_TIME = 2
local CHANGE_RATELIMIT = .7

local Gate = {}
Gate.__index = Gate

export type Class = typeof(setmetatable({} :: {
	Model: Model,
	Collider: BasePart,
	Prompt: ProximityPrompt?,
	
	Trove: Trove.Trove,
	CurrentState: boolean,
	LastChange: number,
	
	Automatic: boolean,
	FederalOnly: boolean,
	
	AutoOpenTime: number?,
	
	OpenThread: thread?,
	AutoThread: thread?,
	PromptThread: thread?,
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
	
	local att = model:FindFirstChild('PromptAttachment')
	local prompt = att and att:FindFirstChildOfClass('ProximityPrompt')
	
	local isAuto: boolean = model:GetAttribute('Auto') or false
	local fedOnly: boolean = model:GetAttribute('FederalOnly') or false
	local currentState: boolean = model:GetAttribute(OPEN_ATT) or false

	local trove = Trove.new()
	local self: Class = setmetatable({
		Model = model,	
		Collider = collider,
		Prompt = prompt,
		
		Trove = trove,
		CurrentState = currentState,
		LastChange = 0,

		Automatic = isAuto,
		FederalOnly = fedOnly,
		
		AutoRevision = model:GetAttribute(AUTO_REV_ATT),
		AutoOpenTime = model:GetAttribute(AUTO_TIME_ATT),
		
		OpenThread = nil :: any,
		AutoThread = nil :: any,
		PromptThread = nil :: any,
	}, Gate)
	
	task.defer(self._Init, self)
	return self
end

function Gate._Init(self: Class)
	self.Model.ModelStreamingMode = Enum.ModelStreamingMode.Atomic
	
	self.Collider.Transparency = 1
	self.Collider.CanCollide = false
	self.Collider.Anchored = true
	
	if self.Automatic then
		self.Trove:Add(self.Collider.Touched:Connect(function(other: BasePart)
			if self.CurrentState then return end

			local ancestor = Placement.FindLastAncestorOfClass(other, 'Model') :: Model?
			if not ancestor then return end

			local seat = FindVehicleModel(ancestor)
			if not seat then return end

			local hum = seat.Occupant
			if not hum then return end
			
			local player = Players:GetPlayerFromCharacter(hum.Parent :: any)
			if not (player and self:_CheckPlayer(player)) then return end
			
			self:Open()
		end))
	end
	
	if self.Prompt then
		self.Trove:Add(self.Prompt.Triggered:Connect(function(player: Player)
			if self.Prompt:GetAttribute('Locked') or not self:_CheckPlayer(player) then return end	
			self:Toggle()
		end))
	end
end

function Gate._CheckPlayer(self: Class, player: Player): boolean
	if self.AutoRevision then
		local revision = player:GetAttribute('Revision')
		
		if revision == self.AutoRevision then
			return true
		end

		if not self.FederalOnly then return false end
	else
		if not self.FederalOnly then return true end
	end
	
	local team = player.Team
	return team and team:HasTag(FED_TAG) or false
end

function Gate._MayUpdate(self: Class): (boolean, number)
	local now, last = os.clock(), self.LastChange
	return if last then now - last >= CHANGE_RATELIMIT else true, now
end

function Gate._CountdownPrompt(self: Class, addDelay: boolean?)
	if not self.Prompt then return end
	self.Prompt:SetAttribute('Locked', true)
	
	local activeThread = self.PromptThread
	if activeThread then
		CleanThread(activeThread)
		self.PromptThread = nil
	end
	
	self.PromptThread = task.delay(
		if self.Automatic and addDelay then
			CHANGE_RATELIMIT + AUTO_DELAY
			else CHANGE_RATELIMIT,
		function()
			self.Prompt:SetAttribute('Locked', false)
		end
	)
end

function Gate.Open(self: Class): boolean
	local may, now = self:_MayUpdate()
	if not may then return false end
	
	self.LastChange = now
	self.CurrentState = true
	
	local openThread = self.OpenThread
	if openThread and coroutine.running() ~= openThread then
		CleanThread(openThread)
		self.OpenThread = nil
	end

	self:_CountdownPrompt(true)
	self.OpenThread = task.spawn(function()
		if self.Automatic then
			task.wait(AUTO_DELAY)
		end
		
		self.Model:SetAttribute(OPEN_ATT, true)
		self:_StartThread()
		
		self.OpenThread = nil
	end)

	return true
end

function Gate._StartThread(self: Class)
	if not self.Automatic then return end
	
	local activeThread = self.AutoThread
	if activeThread then
		CleanThread(activeThread)
		self.AutoThread = nil
	end

	self.AutoThread = task.delay(self.AutoOpenTime or AUTO_OPEN_TIME, function()
		local succ = self:SafeClose()
		if succ then return end
		
		self:_StartThread()
	end)
end

function Gate._HasAny(self: Class): boolean
	local hasChecked = {}
	for _, other in workspace:GetPartsInPart(self.Collider) do
		local ancestor = Placement.FindLastAncestorOfClass(other, 'Model') :: Model?
		if not ancestor or table.find(hasChecked, ancestor) then continue end

		table.insert(hasChecked, ancestor)

		local seat = FindVehicleModel(ancestor)
		if not seat then continue end

		local hum = seat.Occupant
		if not hum then continue end

		local player = Players:GetPlayerFromCharacter(hum.Parent :: any)
		if not (player and self:_CheckPlayer(player)) then continue end

		return true
	end
	
	return false
end

function Gate.SafeClose(self: Class): boolean
	if self:_HasAny() then return false end
	return self:Close()
end

function Gate.Close(self: Class): boolean
	local may, now = self:_MayUpdate()
	if not may then return false end

	self.LastChange = now
	self.CurrentState = false
	
	self.Model:SetAttribute(OPEN_ATT, false)
	self:_CountdownPrompt()
	
	local openThread = self.OpenThread
	if openThread and coroutine.running() ~= openThread then
		CleanThread(openThread)
		self.OpenThread = nil
	end
	
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
