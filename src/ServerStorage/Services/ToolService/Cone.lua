--!strict
local ReplicatedStorage = game:GetService 'ReplicatedStorage'
local CollectionService = game:GetService 'CollectionService'
local StarterPlayer = game:GetService 'StarterPlayer'
local Players = game:GetService 'Players'

local Packages = ReplicatedStorage:WaitForChild('Packages')
local RateLimit = require(Packages.ReplicaShared.RateLimit)
local Net = require(Packages.Net)

local Util = ReplicatedStorage:WaitForChild('Util')
local Placement = require(Util.Placement)

local Data = ReplicatedStorage:WaitForChild('Data')
local ConeData = require(Data.Tools).Cone
local ConeConfig = ConeData.Config

local Assets = ReplicatedStorage:WaitForChild('Assets')
	:WaitForChild('Tools'):WaitForChild('Placement')
local ConeTemplate = Assets:WaitForChild('Cone')

-- Comm
local ActionRL = RateLimit.New(3)

local PlaceEvent = Net:RemoteEvent('Cone_Place')
local RemoveEvent = Net:RemoteEvent('Cone_Remove')

-- Constants
local RAY_PARAMS = RaycastParams.new()
	RAY_PARAMS.FilterType = Enum.RaycastFilterType.Exclude
	RAY_PARAMS.RespectCanCollide = true
	RAY_PARAMS.IgnoreWater = true
	
local CAM_RAY_PARAMS = RaycastParams.new()
	RAY_PARAMS.FilterType = Enum.RaycastFilterType.Exclude
	RAY_PARAMS.RespectCanCollide = false
	RAY_PARAMS.IgnoreWater = true

local OVERLAP_PARAMS = OverlapParams.new()
	OVERLAP_PARAMS.FilterType = Enum.RaycastFilterType.Exclude
	OVERLAP_PARAMS.RespectCanCollide = false
	
local HIT_TOLERANCE = .4

-- Util
local function GetAllCharacters(): {Model}
	local list = {}
	
	for _, player in Players:GetPlayers() do
		if not player.Character then continue end
		table.insert(list, player.Character)
	end
	
	return list
end

local function CameraRay(origin: Vector3, target: Vector3, char: Model): RaycastResult?
	local maxDistance = (target - origin).Magnitude
	local direction = (target - origin).Unit * maxDistance
	local currentOrigin = origin

	while true do
		local remainingDistance = (target - currentOrigin).Magnitude
		if remainingDistance <= .05 then return nil end

		local rayResult = workspace:Raycast(currentOrigin, direction, CAM_RAY_PARAMS)
		if not rayResult then return nil end

		local hit = rayResult.Instance
		if not hit:IsA('BasePart') or hit:IsDescendantOf(char) then return rayResult end

		if not hit.CanCollide then
			currentOrigin = rayResult.Position + direction.Unit * .05
			continue
		end

		return rayResult
	end
end

local function IsInCameraRange(player: Player, position: Vector3): boolean
	local char = player.Character
	if not char then return false end
	
	local hrp = char.PrimaryPart or char:FindFirstChild('HumanoidRootPart')
	if not (hrp and hrp:IsA('BasePart')) then return false end
	
	local head = char:FindFirstChild('Head')
	if not (head and head:IsA('BasePart')) then return false end

	local dist = (head.Position - position).Magnitude
	if dist > StarterPlayer.CameraMaxZoomDistance * 1.1 then return false end
	
	local offset = head.Size.Y * .4
	
	local check = {
		hrp.CFrame, -- RootPart
		head.CFrame, -- Head Middle
		head.CFrame * CFrame.new(0, offset, 0), -- Head Top
		head.CFrame * CFrame.new(0, -offset, 0), -- Head Bottom
	}
	
	for _, target in check do
		local dir = target.Position - position
		local rayResult = CameraRay(target.Position, dir, char)

		if not rayResult or rayResult.Instance:IsDescendantOf(char) then
			return true
		end
		
		if (rayResult.Position - target.Position).Magnitude <= HIT_TOLERANCE then
			return true
		end
	end
	
	return false
end

-- Manager
local Manager = {}

function Manager.GetConesFor(userId: number): {BasePart}
	local found = {}
	
	for _, cone in CollectionService:GetTagged('Cone') do
		if not cone:IsA('BasePart') then continue end
		
		local owner = cone:GetAttribute('Owner')
		if owner ~= userId then continue end
		
		table.insert(found, cone)
	end
	
	return found
end

function Manager.GetConesForEach(): {[number]: {BasePart}}
	local found = {}

	for _, cone in CollectionService:GetTagged('Cone') do
		if not cone:IsA('BasePart') then continue end

		local owner = cone:GetAttribute('Owner')
		if not owner then continue end
		
		local list = found[owner]
		if not list then
			local new = {}
			
			found[owner] = new
			list = new
		end
		
		table.insert(list, cone)
	end

	return found
end

function Manager.RecalcFor(player: Player)
	local placed = Manager.GetConesFor(player.UserId)
	player:SetAttribute('_PlacedCones', #placed)
end

function Manager.RecalcAll()
	local forEach = Manager.GetConesForEach()
	for userId, list in forEach do
		local player = Players:GetPlayerByUserId(userId)
		if not player then continue end
		
		player:SetAttribute('_PlacedCones', #forEach)
	end
end

function Manager.RemoveAllFor(player: Player)
	local placed = Manager.GetConesFor(player.UserId)
	for _, cone in placed do cone:Destroy() end
end

function Manager.OnRemoveAttempt(player: Player, target: Instance)
	if not ActionRL:CheckRate(player)
		or not target:IsDescendantOf(workspace)
		or not target:HasTag('Cone')
		or target:GetAttribute('Owner') ~= player.UserId
	then return end
	
	target:Destroy()
	Manager.RecalcFor(player)
end

function Manager.OnPlaceAttempt(
	player: Player, origin: Vector3,
	target: Vector3, rotation: number
)
	local character = player.Character
	if not character then return end
	
	if not ActionRL:CheckRate(player)
		or not IsInCameraRange(player, origin)
	then return end
	
	local dir = target - origin
	if dir.Magnitude >= ConeConfig.MaxDistance then return end
	
	RAY_PARAMS.FilterDescendantsInstances = GetAllCharacters() :: any
	local rayResult = workspace:Raycast(origin, dir.Unit * ConeConfig.MaxDistance, RAY_PARAMS)
	
	local fixedRotation = (rotation // 1) % 360
	local result = Placement.GetConeResult(rayResult, OVERLAP_PARAMS, RAY_PARAMS, player, rotation)

	if not result.Position or result.VisualState ~= 'Allowed' then return end
	
	local new = ConeTemplate:Clone()
		new:SetAttribute('Owner', player.UserId)
		
		new.Anchored = true
		new.CanCollide = true
		new.CFrame = result.Position

		new.Parent = workspace :: any
		new:AddTag('Cone')
	
	Manager.RecalcFor(player)
end

function Manager.Init()
	PlaceEvent.OnServerEvent:Connect(Manager.OnPlaceAttempt)
	RemoveEvent.OnServerEvent:Connect(Manager.OnRemoveAttempt)
	
	Players.PlayerRemoving:Connect(Manager.RemoveAllFor)
end

return Manager
