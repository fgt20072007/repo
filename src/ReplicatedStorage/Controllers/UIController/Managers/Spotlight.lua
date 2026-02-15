--!strict
local Players = game:GetService 'Players'
local ReplicatedStorage = game:GetService 'ReplicatedStorage'

local Client = Players.LocalPlayer :: Player
local PlayerGui = Client:WaitForChild('PlayerGui') :: PlayerGui

local ScreenGui = PlayerGui:WaitForChild('Spotlight') :: ScreenGui
local MainFrame = ScreenGui:WaitForChild('Main') :: Frame

local Trove = require(ReplicatedStorage.Packages.Trove)

local OFFSET = 12.5
local TRACK_PROPS = table.freeze {
	'AnchorPoint', 'AbsoluteSize',
	'AbsolutePosition', 'AbsoluteRotation'
}

local Manager = {
	Tracking = nil :: GuiObject?,
	Trove = Trove.new(),
}

function Manager._Compute()
	local obj = Manager.Tracking
	if not obj then return end

	local absSize = obj.AbsoluteSize
	local absPos = obj.AbsolutePosition
	local anchor = obj.AnchorPoint
	local rotDeg = obj.AbsoluteRotation

	local theta = math.rad(rotDeg)
	local cosT = math.abs(math.cos(theta))
	local sinT = math.abs(math.sin(theta))

	local bboxWidth  = absSize.X * cosT + absSize.Y * sinT
	local bboxHeight = absSize.X * sinT + absSize.Y * cosT

	local center = absPos + Vector2.new(
		(.5 - anchor.X) * absSize.X,
		(.5 - anchor.Y) * absSize.Y
	)

	MainFrame.Rotation = rotDeg
	MainFrame.Size = UDim2.fromOffset(
		bboxWidth + OFFSET,
		bboxHeight + OFFSET
	)
	MainFrame.Position = UDim2.fromOffset(center.X, center.Y)
end

function Manager.Track(obj: GuiObject)
	Manager.Stop()
	
	Manager.Tracking = obj
	Manager._Compute()

	for _, id in TRACK_PROPS do
		Manager.Trove:Add(obj:GetPropertyChangedSignal(id):Connect(Manager._Compute))
	end

	ScreenGui.Enabled = true
end

function Manager.Stop()
	ScreenGui.Enabled = false
	Manager.Tracking = nil
	Manager.Trove:Clean()
end

function Manager.Init()
end

return Manager
