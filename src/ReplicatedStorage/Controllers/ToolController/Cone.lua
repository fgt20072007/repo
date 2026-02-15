--!strict
local ReplicatedStorage = game:GetService('ReplicatedStorage')
local ContextActionService = game:GetService('ContextActionService')
local RunService = game:GetService('RunService')
local Players = game:GetService('Players')

local Client = Players.LocalPlayer :: Player
local Mouse = Client:GetMouse()
local Camera = workspace.CurrentCamera :: Camera

local Packages = ReplicatedStorage:WaitForChild('Packages')
local Trove = require(Packages.Trove)
local Net = require(Packages.Net)

local Util = ReplicatedStorage:WaitForChild('Util')
local Placement = require(Util.Placement)

local Assets = ReplicatedStorage:WaitForChild('Assets')
	:WaitForChild('Tools'):WaitForChild('Placement')
local ConeTemp = Assets:WaitForChild('Cone')
local HighlightTemp = Assets:WaitForChild('Highlight')

local Controllers = ReplicatedStorage:WaitForChild('Controllers')
local UIController = require(Controllers.UIController)

-- Comm
local PlaceEvent = Net:RemoteEvent('Cone_Place')
local RemoveEvent = Net:RemoteEvent('Cone_Remove')

-- Constants
local ROT_INCREASE = 30
local MIN_DELTA = 1/60

local RAY_PARAMS = RaycastParams.new()
	RAY_PARAMS.FilterType = Enum.RaycastFilterType.Exclude
	RAY_PARAMS.FilterDescendantsInstances = {Camera}
	RAY_PARAMS.RespectCanCollide = true
	RAY_PARAMS.IgnoreWater = true
	
local OVERLAP_PARAMS = OverlapParams.new()
	OVERLAP_PARAMS.FilterType = Enum.RaycastFilterType.Exclude
	OVERLAP_PARAMS.FilterDescendantsInstances = {Camera}
	OVERLAP_PARAMS.RespectCanCollide = false
	
local MAY_NOTIFY: {Placement.ConeVisualState} = {
	'ExceedingAngle', 'TooFar', 'Obstructed',
	'NotOwned', 'Floating', 'Maxxed'
}

-- Def
local Manager = {
	Visualizing = false,
	VisualizeSource = nil :: Tool?,
	Rotation = 0,
	
	VisualState = 'TooFar' :: Placement.ConeVisualState,
	LastResult = nil :: RaycastResult?,
	LastOrigin = nil :: Vector3?,
	LastHit = nil :: CFrame?,
	
	Loaded = {} :: {[Tool]: Class},
	Trove = Trove.new(),
	
	_LastAttempt = nil :: number?,
}

local Class = {}
Class.__index = Class

export type Class = typeof(setmetatable({} :: {
	Tool: Tool,
	Trove: Trove.Trove,
}, Class))

-- Class
function Class.new(tool: Tool): Class
	local self: Class = setmetatable({
		Tool = tool,
		Trove = Trove.new(),
	}, Class)
	
	task.defer(self._Init, self)
	return self
end

function Class._Init(self: Class)
	-- Clean-up
	self.Trove:Add(self.Tool.AncestryChanged:Connect(function()
		if self.Tool.Parent then return end
		self:Destroy()
	end))
	
	self.Trove:Add(self.Tool.Destroying:Connect(function()
		self:Destroy()
	end))
	
	-- Equipped
	self.Trove:Add(self.Tool.Equipped:Connect(function()
		Manager.Visualize(self.Tool)
	end))
	
	-- Unequipped
	self.Trove:Add(self.Tool.Unequipped:Connect(function()
		Manager.UnVisualize()
	end))
end

function Class.Destroy(self: Class)
	if Manager.VisualizeSource == self.Tool then
		Manager.UnVisualize()
	end
	
	self.Trove:Destroy()
	
	Manager.Loaded[self.Tool] = nil
	table.clear(self :: any)
end

-- Manager
function Manager.BuildVisual(): (BasePart, Highlight)
	local cone = ConeTemp:Clone() :: BasePart
		cone.Name = 'Cone_Visual'
		cone.Transparency = 1
		cone.CFrame = CFrame.new()
		cone.Parent = Camera
	
	local highlight = HighlightTemp:Clone() :: Highlight
		highlight.Name = 'Cone_Highlight'
		highlight.Adornee = cone
		highlight.Parent = Camera
	
	return cone, highlight
end

function Manager.GetRayResult(): (Vector3, RaycastResult?)
	local origin = Camera.CFrame.Position
	local unit = (Mouse.Hit.Position - origin).Unit
	return origin, workspace:Raycast(origin, unit * 100, RAY_PARAMS)
end

function Manager.Place()
	local now = tick()
	if Manager._LastAttempt and now - Manager._LastAttempt < 1/3 then return end
	
	Manager._LastAttempt = now
	
	if not (Manager.Visualizing and Manager.LastHit) then return end
	
	local visual = Manager.VisualState
	if table.find(MAY_NOTIFY :: any, visual)~=nil then
		local uiManager = UIController.Managers.Notifications
		if uiManager then
			uiManager.Add(`Placement/{visual}`)
		end
	end

	local rayResult = Manager.LastResult
	local origin = Manager.LastOrigin
	if not (rayResult and origin) then return end
	
	if visual == 'Allowed' then
		PlaceEvent:FireServer(origin, rayResult.Position, Manager.Rotation)
	elseif visual == 'Destroying' then
		RemoveEvent:FireServer(rayResult.Instance)
	end
end

function Manager.Bind(obj: BasePart, highlight: Highlight)
	local char = Client.Character :: Instance?
	local filter = char and {Camera, char} or {Camera} :: {Instance}
	
	RAY_PARAMS.FilterDescendantsInstances = filter
	OVERLAP_PARAMS.FilterDescendantsInstances = filter
	
	Manager.Trove:Add(obj)
	Manager.Trove:Add(highlight)

	local lastUpdate: number
	Manager.Trove:Add(RunService.RenderStepped:Connect(function()
		local now = tick()
		if lastUpdate and now-lastUpdate < MIN_DELTA then return end

		lastUpdate = now

		local origin, rayResult = Manager.GetRayResult()
		Manager.LastOrigin = origin
		Manager.LastResult = rayResult

		local result = Placement.GetConeResult(
			rayResult, OVERLAP_PARAMS, RAY_PARAMS,
			Client, Manager.Rotation
		)
		
		local color = Placement.TypeToColor[result.Type]
		local fixed = result.Position and
			result.Position
			or obj.CFrame
		
		Manager.VisualState = result.VisualState :: any
		Manager.LastHit = result.Position

		obj.Transparency = result.PreviewVisible and 0 or 1
		obj.CFrame = fixed
		
		highlight.FillColor = color
		highlight.OutlineColor = color
		highlight.Adornee = (rayResult and result.AdornHitResult) and rayResult.Instance or obj
	end))
	
	ContextActionService:BindAction("Cone_Rotate", function(_, state: Enum.UserInputState)
		if state ~= Enum.UserInputState.End then return end
		Manager.Rotate()
	end, false, Enum.KeyCode.R)
	ContextActionService:BindAction("Cone_Place", function(_, state: Enum.UserInputState)
		if state ~= Enum.UserInputState.End then return end
		Manager.Place()
	end, false, Enum.UserInputType.MouseButton1)
	
	game.UserInputService.TouchEnded:Connect(function()
		Manager.Place()
	end)
end

function Manager.UnBind()
	Manager.Trove:Clean()
	
	ContextActionService:UnbindAction('Cone_Rotate')
	ContextActionService:UnbindAction('Cone_Place')
end

function Manager.Visualize(source: Tool)
	if Manager.Visualizing then return end
	
	Manager.VisualizeSource = source
	Manager.Visualizing = true
	
	local visual, highlight = Manager.BuildVisual()
	Manager.Bind(visual, highlight)
end

function Manager.UnVisualize()
	if not Manager.Visualizing then return end
	
	Manager.Visualizing = false
	Manager.VisualizeSource = nil
	
	Manager.UnBind()
end

function Manager.Rotate()
	Manager.Rotation = (Manager.Rotation + ROT_INCREASE) % 360
end

function Manager.Load(tool: Tool)
	if Manager.Loaded[tool] then return end
	
	local new = Class.new(tool)
	Manager.Loaded[tool] = new
end

return Manager