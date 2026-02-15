--!strict
local Lighting = game:GetService 'Lighting' 
local ServerStorage = game:GetService 'ServerStorage'
local Selection = game:GetService 'Selection'

local Photobooth = require(ServerStorage.PhotoboothBindings)

local CurrentCam = workspace.CurrentCamera :: Camera
local Bounds = workspace:FindFirstChild('_MapBounds_')

local X_DIVISIONS = 4
local Z_DIVISIONS = 2

local RENDER_FOV = 1.25

local SAVED_PROPS: {
	Atmosphere: Instance?,
	CameraType: Enum.CameraType,
	FOV: number,
} = {} :: any

local function SaveProps(): ()
	SAVED_PROPS.FOV = CurrentCam.FieldOfView
	CurrentCam.FieldOfView = RENDER_FOV
	
	SAVED_PROPS.CameraType = CurrentCam.CameraType
	CurrentCam.CameraType = Enum.CameraType.Scriptable
	--CurrentCam.CameraSubject = Bounds
	
	local hasAtmos = Lighting:FindFirstChildOfClass('Atmosphere')
	if hasAtmos then
		hasAtmos.Parent = ServerStorage :: any
		SAVED_PROPS.Atmosphere = hasAtmos
	end
end

local function ResetProps(): ()
	CurrentCam.FieldOfView = SAVED_PROPS.FOV

	CurrentCam.CFrame = CFrame.new(Bounds:GetPivot().Position)
	CurrentCam.CameraType = SAVED_PROPS.CameraType
	--CurrentCam.CameraSubject = nil
	
	if SAVED_PROPS.Atmosphere then
		SAVED_PROPS.Atmosphere.Parent = Lighting
	end
end

local function GetCameraPos(): {CFrame}
	local cf, size = Bounds:GetBoundingBox()
	
	local sectionSizeX = size.X / X_DIVISIONS
	local sectionSizeZ = size.Z / Z_DIVISIONS

	local result = table.create(X_DIVISIONS * Z_DIVISIONS) :: {CFrame}
	
	local startOffsetX = -size.X / 2 + sectionSizeX / 2
	local startOffsetZ = -size.Z / 2 + sectionSizeZ / 2

	local index = 1

	for z = 0, Z_DIVISIONS - 1 do
		for x = 0, X_DIVISIONS - 1 do
			local xOffset = startOffsetX + sectionSizeX * x
			local zOffset = startOffsetZ + sectionSizeZ * z

			local maxSectionSize = math.max(
				sectionSizeX,
				sectionSizeZ,
				size.Y
			)

			local dist =
				(maxSectionSize / 2)
				/ math.tan(math.rad(CurrentCam.FieldOfView) / 2)

			local sectionCenter =
				cf.Position
				+ cf.RightVector * xOffset
				+ cf.LookVector * zOffset

			result[index] = CFrame.new(
				sectionCenter + Vector3.yAxis * dist,
				sectionCenter
			)

			index += 1
		end
	end

	return result
end

local function TakePicture(cf: CFrame): MeshPart
	CurrentCam.CFrame = cf
	
	local rect = Rect.new(Vector2.zero, CurrentCam.ViewportSize)
	return Photobooth.captureViewport(rect, 'NoSkybox')
end

local function TakeSequence(): ()
	local seq = GetCameraPos()
	
	local folder = Instance.new('Folder')
		folder.Name = `_Map_{os.date('%c')}`
		folder.Parent = ServerStorage._________DEV
	
	for i, cf in ipairs(seq) do
		local pic = TakePicture(cf)
			pic.Name = tostring(i)
			pic.Parent = folder
	end
	
	Selection:Set({folder})
end

-- Run
warn('Began Render')
SaveProps()

pcall(TakeSequence)

ResetProps()
warn('Ended Render')