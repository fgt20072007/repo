--!strict
local ReplicatedStorage = game:GetService 'ReplicatedStorage'
local Players = game:GetService 'Players'
local RunService = game:GetService 'RunService'

local Assets = ReplicatedStorage:WaitForChild('Assets')
	:WaitForChild('Tools'):WaitForChild('Placement')
local ConeTemplate = Assets:WaitForChild('Cone')

local Data = ReplicatedStorage:WaitForChild('Data')
local ToolsData = require(Data.Tools)

-- Config
local CONE_CONFIG = ToolsData.Cone.Config

-- Constants
local IGNORE_TAGS = table.freeze {'StrongBorderHitbox', 'MidBorderHitbox', 'IgnorePlacement'} :: {string}
local IGNORE_ANCESTOR_TAGS = table.freeze {'IgnorePlacement'} :: {string}

local BLOCK_TAGS = table.freeze {} :: {string}
local BLOCK_ANCESTOR_TAGS = table.freeze {'Cone'} :: {string}

local AVOID_FOLDER_NAME = 'AvoidConos'

local GLOBAL_FORWARD = -Vector3.zAxis

local AvoidConosController = {}
AvoidConosController.__index = AvoidConosController

function AvoidConosController.new()
	return setmetatable({}, AvoidConosController)
end

function AvoidConosController:Init()
	if not RunService:IsServer() then return end

	local folder = workspace:FindFirstChild(AVOID_FOLDER_NAME)
	if not folder then folder = workspace:WaitForChild(AVOID_FOLDER_NAME, 10) end
	if not folder then return end

	for _, instance in folder:GetDescendants() do
		if instance:IsA("BasePart") then
			instance.Transparency = 1
		end
	end

	folder.DescendantAdded:Connect(function(instance)
		if instance:IsA("BasePart") then
			instance.Transparency = 1
		end
	end)
end

AvoidConosController.new():Init()

-- Types
export type ResultType = 'Success' | 'Warning' | 'Error'
export type PlacementResult<T> = {
	Type: ResultType,
	PreviewVisible: boolean,
	AdornHitResult: boolean,
	Position: CFrame?,
	VisualState: T,
}

export type ConeVisualState = 'Allowed' | 'Destroying' |
'ExceedingAngle' | 'TooFar' | 'Obstructed'|
'NotOwned' | 'Floating' | 'Maxxed'

local Placement = {
	TypeToColor = {
		Success = Color3.fromRGB(0, 255, 0),
		Error = Color3.fromRGB(255, 0, 0),
		Warning = Color3.fromRGB(255, 255, 0),
	} :: {[ResultType]: Color3}
}
function Placement.IsInAvoidZone(instance: Instance): boolean
	local avoid = workspace:FindFirstChild(AVOID_FOLDER_NAME)

	if not avoid then return false end
	if instance:IsDescendantOf(avoid) then return true end

	return false
end

function Placement.HasAnyTag(instance: Instance, tagList: {string}): boolean
	if #tagList == 0 then return false end

	for _, tag in instance:GetTags() do
		if not table.find(tagList, tag :: string) then continue end
		return true
	end

	return false
end

function Placement.FindLastAncestorOfClass(input: Instance, class: string): Instance?
	local last: Instance?
	while true do
		local found = (last or input):FindFirstAncestorOfClass(class)
		if not found then break end
		last = found
	end
	return last
end

function Placement.IsColliding(position: CFrame, size: Vector3, overlap: OverlapParams, ignore: {Instance}?): boolean
	local overlaps = workspace:GetPartBoundsInBox(position, size, overlap)

	for _, other in overlaps do
		if Placement.IsInAvoidZone(other) then return true end
		if Placement.HasAnyTag(other, IGNORE_TAGS) or
			(ignore and table.find(ignore, other))
		then continue end

		local ancestor = other:FindFirstAncestorOfClass('Model')
		if ancestor and (
			ancestor:FindFirstChildOfClass('Humanoid')
				or Placement.HasAnyTag(ancestor, IGNORE_ANCESTOR_TAGS)
			) then continue end

		if not other.CanCollide and (
			Placement.HasAnyTag(other, BLOCK_TAGS)
				or (ancestor and Placement.HasAnyTag(ancestor, BLOCK_ANCESTOR_TAGS))
			) then continue end

		return true
	end

	return false
end

function Placement.IsLanded(position: CFrame, size: Vector3, rayParams: RaycastParams): boolean
	local half = size * .5
	local y = -half.Y

	local corners = {
		Vector3.new( half.X, y,  half.Z),
		Vector3.new(-half.X, y,  half.Z),
		Vector3.new( half.X, y, -half.Z),
		Vector3.new(-half.X, y, -half.Z),
	}

	for _, corner in ipairs(corners) do
		local worldCorner = position:PointToWorldSpace(corner)

		local origin = worldCorner + Vector3.new(0, .05, 0)
		local result = workspace:Raycast(origin, Vector3.new(0, -.2, 0), rayParams)

		if not result then return false end
	end

	return true
end

function Placement.VerticalAngleFromNormal(normal: Vector3): number
	return math.deg(math.acos(math.clamp(normal:Dot(Vector3.new(0, 1, 0)), -1, 1)))
end

function Placement.ComputePlacementCFrame(result: RaycastResult, rotation: number, height: number)
	local normal = result.Normal
	local pos = result.Position + normal * height * .5

	local forward = GLOBAL_FORWARD - normal * GLOBAL_FORWARD:Dot(normal)
	forward = if forward.Magnitude < 1e-4 then -Vector3.zAxis else forward.Unit

	local right = forward:Cross(normal).Unit
	forward = normal:Cross(right).Unit

	local cframe = CFrame.fromMatrix(pos, right, normal)
	return cframe * CFrame.Angles(0, math.rad(rotation), 0)
end

function Placement.GetConeResult(
	rayResult: RaycastResult?,

	overlapParams: OverlapParams,
	rayParams: RaycastParams,

	player: Player,
	rotation: number
): PlacementResult<ConeVisualState>
	if not rayResult then
		return {
			PreviewVisible = false,
			AdornHitResult = false,
			VisualState = 'TooFar',
			Type = 'Error',
		}
	end

	local cframe = Placement.ComputePlacementCFrame(rayResult, rotation, ConeTemplate.Size.Y)

	if Placement.IsInAvoidZone(rayResult.Instance) then
		return {
			PreviewVisible = true,
			AdornHitResult = false,
			Position = cframe,
			VisualState = 'Obstructed',
			Type = 'Error',
		}
	end

	if rayResult.Instance:HasTag('Cone') then
		local owned = rayResult.Instance:GetAttribute('Owner') == player.UserId
		return {
			PreviewVisible = false,
			AdornHitResult = true,
			Position = cframe,
			VisualState = (owned and 'Destroying' or 'NotOwned') :: any,
			Type = (owned and 'Error' or 'Warning') :: any,
		}
	end

	local placed = player:GetAttribute('_PlacedCones')
	if placed and placed >= CONE_CONFIG.MaxPerPlayer then
		return {
			PreviewVisible = true,
			AdornHitResult = false,
			Position = cframe,
			VisualState = 'Maxxed',
			Type = 'Error',
		}
	end

	if rayResult.Distance > CONE_CONFIG.MaxDistance then
		return {
			PreviewVisible = true,
			AdornHitResult = false,
			Position = cframe,
			VisualState = 'TooFar',
			Type = 'Error',
		}
	end

	local fromVert = Placement.VerticalAngleFromNormal(rayResult.Normal)
	if fromVert > CONE_CONFIG.MaxInclination then
		return {
			PreviewVisible = false,
			AdornHitResult = false,
			VisualState = 'ExceedingAngle',
			Type = 'Warning',
		}
	elseif fromVert > CONE_CONFIG.TriggerInclination then
		return {
			PreviewVisible = true,
			AdornHitResult = false,
			Position = cframe,
			VisualState = 'ExceedingAngle',
			Type = 'Warning',
		}
	end

	local ancestor = rayResult.Instance and Placement.FindLastAncestorOfClass(rayResult.Instance, 'Model')
	if ancestor and ancestor:FindFirstChildOfClass('VehicleSeat') then
		return {
			PreviewVisible = true,
			AdornHitResult = false,
			Position = cframe,
			VisualState = 'Obstructed',
			Type = 'Error',
		}
	end

	if Placement.IsColliding(cframe, ConeTemplate.Size, overlapParams, {rayResult.Instance}) then
		return {
			PreviewVisible = true,
			AdornHitResult = false,
			Position = cframe,
			VisualState = 'Obstructed',
			Type = 'Error',
		}
	end

	if not Placement.IsLanded(cframe, ConeTemplate.Size, rayParams) then
		return {
			PreviewVisible = true,
			AdornHitResult = false,
			Position = cframe,
			VisualState = 'Floating',
			Type = 'Error',
		}
	end

	return {
		PreviewVisible = true,
		AdornHitResult = false,
		Position = cframe,
		VisualState = 'Allowed',
		Type = 'Success',
	}
end

return Placement
