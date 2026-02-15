--!strict
local ReplicatedStorage = game:GetService 'ReplicatedStorage'
local GuiService = game:GetService 'GuiService'
local Players = game:GetService 'Players'
local RunService = game:GetService 'RunService'

local Packages = ReplicatedStorage.Packages
local TableUtil = require(Packages.TableUtil)
local Observers = require(Packages.Observers)
local Trove = require(Packages.Trove)

local Data = ReplicatedStorage.Data
local GeneralData = require(Data.General)
local WaypointData = require(Data.Waypoints)

-- Player UI
local Client = Players.LocalPlayer :: Player
local Camera = workspace.CurrentCamera :: Camera

local PlayerGui = Client:WaitForChild('PlayerGui') :: PlayerGui
local HUD = PlayerGui:WaitForChild("HUD") :: ScreenGui

local Marker = HUD:WaitForChild('Marker') :: Frame

-- Waypoints
local Assets = ReplicatedStorage.Assets.UI

local WaypointTemp = Assets['3DWaypoint']
local BillboardTemp = Assets.BillboardWaypoint

local WaypointPath: Model

-- Util
type WaypointUI = {
	Data: WaypointData.Waypoint?,
	WorldRef: BasePart?,
	Frame: Frame,

	Icon: Frame,
	Bg: Frame,
	Arrow: ImageLabel,
}

local function UpdateIcon(icon: Frame, data: WaypointData.Waypoint): ()
	icon.BackgroundColor3 = data.Color
	
	local img = icon:FindFirstChild('Image')
	if img and img:IsA('ImageLabel') then
		img.Image = data.Icon
	end
end

local function BuildBillboard(holder: BasePart)
	if holder:FindFirstChild(BillboardTemp.Name) then return end
	
	local data = WaypointData[holder.Name]
	if not data then return end
	
	local new = BillboardTemp:Clone()
	
	local icon = new:FindFirstChild('Icon')
	UpdateIcon(icon, data)
	
	local labelHolder = new:FindFirstChild('Label')
	local label = labelHolder:FindFirstChild('Label')
	label.Text = data.DisplayName
	
	local glow = labelHolder:FindFirstChild('Glow')
	glow.ImageColor3 = data.Color

	new.Parent = holder :: any
end

local function UpdateWaypoint(
	ui: WaypointUI, dT: number, cam: CFrame,
	offset: number, viewport: Vector2
): ()
	local ref = ui.WorldRef
	if not ref then return end

	local holderSize = Marker.Size
	
	local vpX, vpY = viewport.X * holderSize.X.Scale, viewport.Y * holderSize.Y.Scale
	local offX, offY = viewport.X * (1 - holderSize.X.Scale) / 2, viewport.Y * (1 - holderSize.Y.Scale) / 2

	local screenPos, onScreen = Camera:WorldToViewportPoint(ref.Position)
	screenPos -= Vector3.new(offX, offY + offset, 0)
	
	local uiSize = ui.Frame.AbsoluteSize.X

	local xPos = math.clamp(screenPos.X, uiSize, math.max(vpX - uiSize, uiSize))
	local yPos = math.clamp(screenPos.Y, uiSize, math.max(vpY - uiSize, uiSize))
	
	if onScreen and xPos == screenPos.X and yPos == screenPos.Y then
		ui.Arrow.Visible = false
	else
		ui.Arrow.Visible = true
		
		-- Dir
		local dir = cam:VectorToObjectSpace(ref.Position - cam.Position)
		local dir2D = Vector2.new(dir.X, dir.Y).Unit
		
		-- Fix pos
		local maxX, maxY = vpX - (uiSize * 2), vpY - (uiSize * 2)
		local fix = dir2D * math.sqrt((maxX / 2) ^ 2 + (maxY / 2) ^ 2)
		
		local isVert = math.abs(fix.Y) > maxY / 2
		local screenPoint = dir2D * math.abs(
			(isVert and maxY or maxX) / 2 / (isVert and dir2D.Y or dir2D.X)
		)
		
		xPos = vpX / 2 + screenPoint.X
		yPos = vpY / 2 - screenPoint.Y
		
		-- Angle
		local angle = math.atan2(dir2D.X, dir2D.Y)
		ui.Bg.Rotation = math.deg(angle)
	end
	
	ui.Frame.Position = ui.Frame.Position:Lerp(
		UDim2.fromOffset(xPos, yPos),
		math.clamp(dT * 12, 0, 1)
	)
end

-- Pooling
local Pooling = {
	Pool = {} :: {WaypointUI},
	Active = {} :: {[BasePart]: WaypointUI},
}

function Pooling.GetFromRef(ref: BasePart): WaypointUI?
	return Pooling.Active[ref]
end

function Pooling.GetFromPool(ref: BasePart): WaypointUI?
	local id = ref.Name
	local wpData = WaypointData[id]
	if not wpData then return nil end
	
	-- Find pooled
	local pooled = table.remove(Pooling.Pool)
	if pooled then
		pooled.WorldRef = ref
		pooled.Data = wpData
		
		pooled.Frame.Name = `{id}_Waypoint`
		pooled.Frame.Parent = Marker
		UpdateIcon(pooled.Icon, wpData)
		
		Pooling.Active[ref] = pooled
		return pooled
	end
	
	-- Build new
	local new = WaypointTemp:Clone()
		new.Name = `{id}_Waypoint`
		new.Parent = Marker :: any
	
	local icon = new:FindFirstChild('Icon')
	local main = new:FindFirstChild('Main')
	
	local arrow = main and main:FindFirstChild('Arrow') or nil
	if not (icon and arrow) then
		new:Destroy()
		return nil
	end
	
	UpdateIcon(icon, wpData)
	
	local newData: WaypointUI = {
		Data = wpData,
		WorldRef = ref,
		Frame = new,
		
		Icon = icon :: any,
		Bg = main :: any,
		Arrow = arrow :: any,
	}
	
	Pooling.Active[ref] = newData
	return newData
end

function Pooling.ReturnToPool(ref: BasePart): ()
	local data = Pooling.GetFromRef(ref)
	if not data then return end
	
	Pooling.Active[ref] = nil

	data.WorldRef = nil
	data.Data = nil

	data.Frame.Parent = script
	data.Frame.Name = '_Available'

	table.insert(Pooling.Pool, data)
end

function Pooling.ReturnAll()
	for ref, _ in Pooling.Active do
		Pooling.ReturnToPool(ref)
	end
end

-- Manager
local Manager = {
	Trove = Trove.new(),
}

function Manager._OnStep(location: Vector3, dT: number)
	local camCFrame = Camera.CFrame
	
	local offset = 0 -- GuiService.TopbarInset.Height
	local viewport = Camera.ViewportSize - Vector2.yAxis * offset
	
	for _, child in WaypointPath:GetChildren() do
		if not child:IsA('BasePart') then continue end

		local id = child.Name
		local data = WaypointData[id]
		if not data then continue end
		
		if data.MaxDistance then
			local dist = (location - child.Position).Magnitude
			if dist > data.MaxDistance then
				Pooling.ReturnToPool(child)
				continue
			end
		end
	
		local ui = Pooling.GetFromRef(child) or Pooling.GetFromPool(child)
		if not ui then continue end
		
		UpdateWaypoint(ui, dT, camCFrame, offset, viewport)
	end
end

function Manager._Bind()
	Manager._Clean()
	
	local character = Client.Character
	if not character then return end

	local root = character.PrimaryPart or character:FindFirstChild('HumanoidRootPart') :: BasePart?
	if not root then return end
	
	Manager.Trove:Add(RunService.RenderStepped:Connect(function(dT: number)
		if not (root and root:IsDescendantOf(workspace)) then
			return Manager._Clean()
		end

		Manager._OnStep(root.CFrame.Position, dT)
	end))
end

function Manager._Clean()
	Pooling.ReturnAll()
	Manager.Trove:Clean()
end

function Manager.Init()
	-- Don't stop anything :)
	task.spawn(function()
		WaypointPath = workspace:WaitForChild('_MapWaypoints_')
		
		for _, child in WaypointPath:GetChildren() do
			if not child:IsA('BasePart') then continue end
			child.Transparency = 1
			
			BuildBillboard(child)
		end

		if GeneralData.DynamicWaypointsEnabled then
			Observers.observeCharacter(function(player: Player, char: Model)
				if player ~= Client then return end

				task.spawn(Manager._Bind)
				return Manager._Clean :: any
			end)
		end
	end)
end

return Manager
