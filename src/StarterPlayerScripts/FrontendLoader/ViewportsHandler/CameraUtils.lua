
-- Variables
local DEFAULT_FOV = 70
local PADDING_MULTIPLIER = 1.2

-- Dependencies

local CameraUtils = {}

function CameraUtils:CalculateDistanceFromModel(object, fieldOfView)
	local fov = fieldOfView or DEFAULT_FOV

	local modelCFrame, modelSize

	if object:IsA("Model") then
		modelCFrame, modelSize = object:GetBoundingBox()
	elseif object:IsA("BasePart") then
		modelCFrame = object.CFrame
		modelSize = object.Size
	else
		warn("Provided instance is not a Model or BasePart")
		return 0
	end

	local maxDimension = math.max(modelSize.X, modelSize.Y, modelSize.Z)

	local halfFov = math.rad(fov / 2)
	local distance = (maxDimension / 2) / math.tan(halfFov)

	return distance * PADDING_MULTIPLIER
end

function CameraUtils:GetCameraPositionForModel(object, fieldOfView)
	local distance = self:CalculateDistanceFromModel(object, fieldOfView)

	local objectCFrame
	if object:IsA("Model") then
		objectCFrame = object:GetBoundingBox()
	else
		objectCFrame = object.CFrame
	end

	local cameraPosition = objectCFrame.Position + (objectCFrame.LookVector * distance)

	return cameraPosition, objectCFrame.Position
end

return CameraUtils