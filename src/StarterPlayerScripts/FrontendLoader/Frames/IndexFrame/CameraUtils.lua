-- Services
local RunService = game:GetService('RunService')

-- Variables
local DEFAULT_FOV = 70
local PADDING_MULTIPLIER = 1.2

-- Dependencies

local CameraUtils = {}

function CameraUtils:CalculateDistanceFromModel(model, fieldOfView)
	local fov = fieldOfView or DEFAULT_FOV

	if not model:IsA("Model") then
		warn("Provided instance is not a Model")
		return 0
	end

	local modelCFrame, modelSize = model:GetBoundingBox()
	local maxDimension = math.max(modelSize.X, modelSize.Y, modelSize.Z)

	local halfFov = math.rad(fov / 2)
	local distance = (maxDimension / 2) / math.tan(halfFov)

	return distance * PADDING_MULTIPLIER
end

function CameraUtils:GetCameraPositionForModel(model, fieldOfView)
	local distance = self:CalculateDistanceFromModel(model, fieldOfView)
	local modelCFrame = model:GetBoundingBox()

	local cameraPosition = modelCFrame.Position + (modelCFrame.LookVector * distance)

	return cameraPosition, modelCFrame.Position
end

return CameraUtils