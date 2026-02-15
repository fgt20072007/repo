--!strict
local ReplicatedStorage = game:GetService 'ReplicatedStorage'
local Players = game:GetService 'Players'

local Packages = ReplicatedStorage.Packages
local Observers = require(Packages.Observers)

local Data = ReplicatedStorage.Data
local ToolsData = require(Data.Tools)

local Assets = ReplicatedStorage.Assets.UI.BodyScanner
local ScreenTemplate = Assets.Screen
local LegalTemplate = Assets.Legal
local IllegalTemplate = Assets.Illegal

local OVERLAP_PARAMS = OverlapParams.new()
	--OVERLAP_PARAMS.RespectCanCollide = true
	
local RESET_DELAY = 5
local SCAN_TIME = 3

-- Util
type ScannedData = {Illegal: boolean, Count: number}

local function IsPlayer(other: Instance): boolean
	return other.Parent and other.Parent:FindFirstChildOfClass('Humanoid')
		and true or false
end

local function GetEquippedTools(player: Player): {Tool}
	local found = {}
	
	local char = player.Character
	if char then
		for _, child in char:GetChildren() do
			if not child:IsA('Tool')
				or table.find(found, child)
			then continue end
			table.insert(found, child)
		end
	end
	
	for _, child in player.Backpack:GetChildren() do
		if not child:IsA('Tool')
			or table.find(found, child)
		then continue end
		table.insert(found, child)
	end
	
	return found
end

local function ScanPlayer(player: Player): {[string]: ScannedData}
	local tools = GetEquippedTools(player)
	
	local checked = {}
	local filtered = {}
	
	local function add(id: string, illegal: boolean)
		local has = filtered[id]
		if has then
			has.Count = has.Count + 1
			return
		end
		
		filtered[id] = {Illegal = illegal, Count = 1} :: any
	end
	
	for _, tool in tools do
		local id = tool.Name
		local data = ToolsData[id]
		if not data then continue end
		
		if not data.DetectionRate or filtered[id] then
			add(id, data.Illegal == true)
			continue
		end
		
		if table.find(checked, id) then continue end
		table.insert(checked, id)
		
		local sel = math.random(0, 10_000) / 100
		if sel > data.DetectionRate then continue end
		
		add(id, data.Illegal == true)
	end
	
	return filtered :: any
end

local function GetPlayersIn(cframe: CFrame, size: Vector3): {Player}
	local found = workspace:GetPartBoundsInBox(cframe, size, OVERLAP_PARAMS)
	local filtered = {}
	
	for _, other in found do
		if not IsPlayer(other) then continue end
		
		local player = Players:GetPlayerFromCharacter(other.Parent :: any)
		if not player or table.find(filtered, player) then continue end
		
		table.insert(filtered, player)
	end
	
	return filtered
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

local function BuildItem(name: string, illegal: boolean, count: number, parent: Instance)
	local temp = illegal and IllegalTemplate or LegalTemplate
	local new = temp:Clone()
		new.Name = name
		new.Parent = parent :: any
		
	local label = new:FindFirstChild('Label')
	if label and label:IsA('TextLabel') then
		label.Text = `x{count} {name}`
	end
	
	return new
end

local function BuildList(list: {[string]: ScannedData}, parent: Instance): {Frame}
	local new = {}

	for name, data in list do
		table.insert(new, BuildItem(name, data.Illegal, data.Count, parent))
	end
	
	return new
end

-- Class
local BodyScanner = {}
BodyScanner.__index = BodyScanner

export type Class = typeof(setmetatable({} :: {
	Screen: ScreenGui,
	Collider: BasePart,
	List: ScrollingFrame,
	
	Built: {Frame},
	
	ShownResult: boolean,
	_Sequence: thread?,
}, BodyScanner))

function BodyScanner.new(model: Model): Class
	local screenModel = model:FindFirstChild('Screen')
	local screen = (screenModel and screenModel:IsA('Model')) and
		(screenModel.PrimaryPart or screenModel:FindFirstChild('Screen'))
		or nil
	assert(screen, `Wrong body scanner screen setup: {model:GetFullName()}`)
	
	local detectorModel = model:FindFirstChild('Detector')
	local collider = (detectorModel and detectorModel:IsA('Model')) and
		(detectorModel.PrimaryPart or detectorModel:FindFirstChild('Collider'))
		or nil
	assert(collider, `Wrong body scanner collider setup: {model:GetFullName()}`)
	
	local gui = ScreenTemplate:Clone() :: any
	gui.Parent = screen
		
	local list = (gui:FindFirstChild('Results') :: any).List :: ScrollingFrame
	
	local self: Class = setmetatable({
		Screen = gui :: ScreenGui,
		Collider = collider :: BasePart,
		List = list,
		
		Built = {},
		
		ShownResult = false,
		_Sequence = nil :: any,
	}, BodyScanner)
	
	task.spawn(self.Init, self)
	return self
end

function BodyScanner.Init(self: Class)
	self.Collider.Transparency = 1
	
	local function onTouched(other: BasePart)
		if not IsPlayer(other) then return end
		self:OnChange()
	end

	self.Collider.Touched:Connect(onTouched)
	self.Collider.TouchEnded:Connect(onTouched)
	
	self:SetMessage('Wait')
end

function BodyScanner.Stop(self: Class)
	self:SetMessage('Wait')
	self.ShownResult = false

	local prev = table.clone(self.Built)
	table.clear(self.Built)
	
	for _, frame in prev do
		frame:Destroy()
	end
end

function BodyScanner.StopSequence(self: Class)
	if self._Sequence then
		CleanThread(self._Sequence)
		self._Sequence = nil
	end
	
	self:Stop()
end

function BodyScanner.OnChange(self: Class)
	if self.ShownResult then return end
	
	local players = GetPlayersIn(
		self.Collider.CFrame,
		self.Collider.Size
	)
	
	self:StopSequence()
	if #players <= 0 then
		return
	elseif #players > 1 then
		return self:SetMessage('Error')
	end

	self:SetMessage('Scanning')
	self._Sequence = task.delay(SCAN_TIME, function()
		self.ShownResult = true
		local found = ScanPlayer(players[1])

		local list = BuildList(found, self.Screen.Results.List :: ScrollingFrame)
		self.Built = list
		
		self:SetMessage('None')
		task.wait(RESET_DELAY)
		
		task.spawn(self.StopSequence, self)
	end)
end

function BodyScanner.SetMessage(self: Class, message: 'Scanning'|'Error'|'Wait'|'None')
	local states = self.Screen:FindFirstChild('States')
	if not states then return end
	
	for _, screen in states:GetChildren() do
		if not screen:IsA('Frame') then continue end
		screen.Visible = screen.Name == message
	end
end

-- Manager
local Manager = {
	Registered = {} :: {[Model]: Class}
}

function Manager.Init()
	Observers.observeTag("BodyScanner", function(gateModel: Model)
		if not gateModel:IsA('Model') then return end

		local has = Manager.Registered[gateModel]
		if has then return end

		local new = BodyScanner.new(gateModel)
		Manager.Registered[gateModel] = new
	end)
end

return Manager
