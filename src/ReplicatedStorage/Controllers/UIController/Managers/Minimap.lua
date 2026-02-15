--!strict
local Players = game:GetService 'Players'
local RunService = game:GetService 'RunService'
local ReplicatedStorage = game:GetService 'ReplicatedStorage'

local Packages = ReplicatedStorage.Packages
local Observers = require(Packages.Observers)
local Trove = require(Packages.Trove)

-- Player UI
local Client = Players.LocalPlayer :: Player

local PlayerGui = Client:WaitForChild('PlayerGui') :: PlayerGui
local HUD = PlayerGui:WaitForChild("HUD") :: ScreenGui

local MiniMap = HUD:WaitForChild('Minimap'):WaitForChild('Main') :: CanvasGroup
local Background = MiniMap:WaitForChild('Background') :: Frame
local BgAspectRatio = Background:WaitForChild('UIAspectRatioConstraint') :: UIAspectRatioConstraint
local Indicator = MiniMap:WaitForChild('Indicator') :: Frame

-- Bounds
local Bounds = workspace:WaitForChild('_MapBounds_')
local BoundCFrame, BoundSize = Bounds:GetBoundingBox()

-- Waypoints
local WaypointData = require(ReplicatedStorage.Data.Waypoints)
local WaypointTemp = ReplicatedStorage.Assets.UI.MapWaypoint

-- Constants
local ZOOM = 26
local HORZ_SCALE = BgAspectRatio.AspectRatio * ZOOM

-- Util
local function Round(input: number, decimals: number): number
	local pow = 10 ^ decimals
	return math.floor(input * pow + .5) / pow
end

local function WorldToUV(input: Vector3): (number, number)
	local localPos = BoundCFrame:PointToObjectSpace(input)
	
	local u = (localPos.X / BoundSize.X) + .5
	local v = (localPos.Z / BoundSize.Z) + .5

	return Round(1 - v, 6), Round(u, 6)
end

-- Manager
local Manager = {
	_LastPos = nil :: Vector3?,
	Trove = Trove.new(),
}

function Manager._OnStep(location: CFrame)
	local position = location.Position
	
	-- Position
	if Manager._LastPos ~= position then
		Manager._LastPos = position
		
		local u, v = WorldToUV(position)
		Background.Position = UDim2.fromScale(
			.5 + (u - .5) * HORZ_SCALE,
			.5 + (v - .5) * ZOOM
		)
	end
	
	-- Angle
	local forward = location.LookVector
	local angle = math.deg(math.atan2(forward.Z, forward.X))
	Indicator.Rotation = angle
end

function Manager._Bind()
	Manager._Clean()
	
	local character = Client.Character
	if not character then return end
	
	local root = character.PrimaryPart or character:WaitForChild('HumanoidRootPart') :: BasePart?
	if not root then return end
	
	Manager.Trove:Add(RunService.RenderStepped:Connect(function()
		if not (root and root:IsDescendantOf(workspace)) then
			return Manager._Clean()
		end
		
		Manager._OnStep(root.CFrame)
	end))
end

function Manager._Clean()
	Manager.Trove:Clean()
end

function Manager.AddWaypoint(id: string, location: Vector3)
	local data = WaypointData[id]
	if not data then return end
	
	local new = WaypointTemp:Clone()
	new.Name = `{id}_{new.Name}`
	
	local icon = new:FindFirstChild('Icon') :: Frame
	local img = icon:FindFirstChild('Icon') :: ImageLabel
	
	icon.BackgroundColor3 = data.Color
	img.Image = data.Icon
	
	local u, v = WorldToUV(location)
	new.Position = UDim2.fromScale(1 - u, 1 - v)
	new.Parent = Background :: any
end

function Manager.Init()
	Background.Size = UDim2.fromScale(ZOOM, ZOOM)
	
	task.spawn(function()
		local waypointPath = workspace:WaitForChild('_MapWaypoints_')
		
		for _, inst in waypointPath:GetChildren() do
			if not inst:IsA('BasePart') then continue end
			task.spawn(Manager.AddWaypoint, inst.Name, inst.Position)
		end
	end)
	
	Observers.observeCharacter(function(player: Player, char: Model)
		if player ~= Client then return end

		task.spawn(Manager._Bind)
		return Manager._Clean :: any
	end)
end

return Manager
