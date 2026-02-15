--!strict
local ReplicatedStorage = game:GetService('ReplicatedStorage')
local RunService = game:GetService('RunService')
local Players = game:GetService('Players')

local Client = Players.LocalPlayer :: Player
local Camera = workspace.CurrentCamera :: Camera
local PlayerGui = Client:WaitForChild('PlayerGui') :: PlayerGui

local Assets = ReplicatedStorage:WaitForChild('Assets'):WaitForChild('UI')
local Template = Assets:WaitForChild('Notification')

local Data = ReplicatedStorage:WaitForChild('Data')
local NotifData = require(Data:WaitForChild('Notifications'))

local Util = ReplicatedStorage:WaitForChild('Util')
local Format = require(Util.Format)
local Sounds = require(Util.Sounds)

local Packages = ReplicatedStorage:WaitForChild('Packages')
local Trove = require(Packages.Trove)
local Net = require(Packages.Net)

local HUD = PlayerGui:WaitForChild("Main") :: ScreenGui
local Holder = HUD:WaitForChild('Notifications') :: Frame
local Scale = Holder:WaitForChild('UIScale') :: UIScale

local FADE_TIME = .2
local PADDING = 12

local TYPE_TO_COLOR: {[NotifData.Type]: Color3} = {
	Warning = Color3.fromRGB(255, 199, 69),
	Error = Color3.fromRGB(255, 62, 62),
	Info = Color3.fromRGB(62, 162, 255),
	Success = Color3.fromRGB(48, 255, 100),
}
local TYPE_TO_ICON: {[NotifData.Type]: string} = {
	Warning = 'rbxassetid://3944668821',
	Error = 'rbxassetid://3944669799',
	Info = 'rbxassetid://3944670656',
	Success = 'rbxassetid://3944680095',
}

-- References
local Manager = {
	Active = {} :: {Class},
	_LastOrder = 0,
}

local Notification = {}
Notification.__index = Notification

export type Class = typeof(setmetatable({} :: {
	Object: Frame,
	Content: GuiButton,
	ProgressBar: Frame,
	Type: NotifData.Type,

	DisplayTime: number,
	Visible: boolean,
	Trove: Trove.Trove
}, Notification))

-- Util
local function NumLerp(a: number, b: number, t: number): number
	return a + (b - a) * t
end

local function GetDataForId(id: string): NotifData.Item?
	local group, innerId = string.match(id, "([^/]+)/([^/]+)")
	if not (group and innerId) then return nil end

	local groupData = NotifData[group]
	return groupData and groupData[innerId] or nil
end

local function GetFixedMessage(data: NotifData.Item, args: {[string]: any}?): string?
	local len = #data.Messages
	if len <= 0 then return nil end

	local index = math.random(1, #data.Messages)
	local message = data.Messages[index]

	if args then
		for key, value in args do
			message = string.gsub(message, "{" .. key .. "}", tostring(value))
		end
	end

	return message
end

local function Build(order: number, message: string, data: NotifData.Item): (Frame, GuiButton, Frame)
	local object = Template:Clone() :: Frame

	local content = object:FindFirstChild('Content') :: GuiButton
	local inner = content:FindFirstChild('Inner') :: Frame
	local timer = content:FindFirstChild('Timer') :: Frame

	local progress = timer:FindFirstChild('Progress') :: Frame

	local icon = inner:FindFirstChild('Icon'):FindFirstChild('Inner') :: ImageLabel
	local label = inner:FindFirstChild('Label'):FindFirstChild('Label') :: TextLabel

	local typeColor = TYPE_TO_COLOR[data.Type] or TYPE_TO_COLOR.Info
	local typeIcon = TYPE_TO_ICON[data.Type] or TYPE_TO_ICON.Info

	icon.Image = typeIcon
	label.Text = message

	icon.ImageColor3 = typeColor
	progress.BackgroundColor3 = typeColor

	object.LayoutOrder = order
	object.Parent = Holder
	return object, content, progress
end

-- Notification
function Notification.new(
	id: string,
	args: {[string]: any}?,
	order: number
): Class
	local data = GetDataForId(id)
	assert(data, `Id '{id}' not found`)

	local message = GetFixedMessage(data, args)
	assert(message, `Notification data for id '{id}' isn't properly set up`)

	local trove = Trove.new()
	local object, content, progress = Build(order, message, data)
	trove:Add(object)

	local self: Class = setmetatable({
		Object = object,
		Content = content,
		ProgressBar = progress,
		Type = data.Type,

		DisplayTime = Format.CalculateDisplayTime(message),
		Visible = false,
		Trove = trove,
	}, Notification)

	trove:Add(content.MouseButton1Up:Connect(function()
		self:_Finish()
	end))

	trove:Add(content:GetPropertyChangedSignal('AbsoluteSize'):Connect(function()
		self:_OnSizeChange()
	end))

	task.defer(self._Start, self)
	return self
end

function Notification._OnSizeChange(self: Class)
	if not self.Visible then return end

	local absSize = self.Content.AbsoluteSize / Scale.Scale
	local height = absSize.Y + PADDING

	self.Object.Size = UDim2.new(1, 0, 0, height)
end

function Notification._Start(self: Class)
	local began = tick()
	self.Trove:Add(task.spawn(function()
		Sounds.Play(`SFX/Notification/{self.Type}`)

		while task.wait() do
			local elapsed = tick() - began
			local progress = math.clamp(elapsed / FADE_TIME, 0, 1)

			local absSize = self.Content.AbsoluteSize / Scale.Scale
			local height = absSize.Y + PADDING
			self.Object.Size = UDim2.new(1, 0, 0, height * progress)

			if progress >= 1 then break end
		end

		task.spawn(self._Countdown, self)
	end))
end

function Notification._Countdown(self: Class)
	self.Visible = true

	local began = tick()
	local conn: RBXScriptConnection

	conn = RunService.RenderStepped:Connect(function()
		local elapsed = tick() - began
		local progress = math.clamp(elapsed / self.DisplayTime, 0, 1)

		self.ProgressBar.Size = UDim2.fromScale(1 - progress, 1)
		if progress < 1 or not conn then return end

		conn = conn:Disconnect() :: any
		self:_Finish()
	end)

	self.Trove:Add(conn)
end

function Notification._Finish(self: Class)
	if not self.Visible then return end
	self.Visible = false

	local began = tick()
	self.Trove:Add(task.spawn(function()
		while task.wait() do
			local elapsed = tick() - began
			local progress = math.clamp(elapsed / FADE_TIME, 0, 1)

			local absSize = self.Content.AbsoluteSize / Scale.Scale
			local height = absSize.Y + PADDING
			self.Object.Size = UDim2.new(1, 0, 0, NumLerp(height, 0, progress))

			if progress >= 1 then break end
		end

		Manager.Remove(self)
	end))
end

function Notification.Destroy(self: Class)
	self.Trove:Destroy()
	table.clear(self :: any)
end

-- Manager
function Manager.UpdateScale()
	local vpSize = Camera.ViewportSize
	local size = Holder:GetAttribute('Scale') :: Vector2

	local virtualSize = vpSize * size
	local realSize = Holder.Size

	local xScale = virtualSize.X / realSize.X.Offset
	local yScale = virtualSize.Y / realSize.Y.Offset

	local finalScale = math.min(xScale, yScale)
	Scale.Scale = finalScale
end

function Manager.Add(id: string, args: {[string]: any}?): Class?
	Manager._LastOrder += 1

	local succ, res = pcall(function()
		return Notification.new(id, args, Manager._LastOrder)
	end)

	if not succ then
		print(res)
		return nil
	end

	table.insert(Manager.Active, res)
	return res
end

function Manager.Remove(object: Class)
	local index = table.find(Manager.Active, object)
	if index then
		table.remove(Manager.Active, index)
	end

	object:Destroy()
end

function Manager.Init()
	local remote = Net:RemoteEvent('Notification')
	remote.OnClientEvent:Connect(Manager.Add :: any)

	Camera:GetPropertyChangedSignal('ViewportSize'):Connect(Manager.UpdateScale)
	Manager.UpdateScale()
end

return Manager