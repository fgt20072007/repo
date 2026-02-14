local Debris = game:GetService("Debris")
local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")

local CombatHitbox = {}
local DEFAULT_SIZE = Vector3.new(4.5, 4, 5.5)
local DEFAULT_OFFSET = CFrame.new(0, 0, -3)
local DEFAULT_LIFETIME = 0.08

local function getHumanoidFromPart(part)
	local model = part:FindFirstAncestorOfClass("Model")
	if not model then
		return nil
	end

	return model:FindFirstChildOfClass("Humanoid")
end

local function createHitboxPart(attackerCharacter, rootPart, cframe, size, lifetime)
	local hitboxPart = Instance.new("Part")
	hitboxPart.Name = "CombatHitbox"
	hitboxPart.Anchored = false
	hitboxPart.Massless = true
	hitboxPart.CastShadow = false
	hitboxPart.CanCollide = false
	hitboxPart.CanTouch = false
	hitboxPart.CanQuery = false
	hitboxPart.Transparency = 0.55
	hitboxPart.Color = Color3.fromRGB(255, 72, 72)
	hitboxPart.Material = Enum.Material.Neon
	hitboxPart.Size = size
	hitboxPart.CFrame = cframe

	local weld = Instance.new("WeldConstraint")
	weld.Part0 = rootPart
	weld.Part1 = hitboxPart
	weld.Parent = hitboxPart

	hitboxPart.Parent = Workspace

	local attackerPlayer = Players:GetPlayerFromCharacter(attackerCharacter)
	if attackerPlayer then
		pcall(function()
			hitboxPart:SetNetworkOwner(attackerPlayer)
		end)
	end

	Debris:AddItem(hitboxPart, lifetime + 0.1)

	return hitboxPart
end

function CombatHitbox.Cast(attackerCharacter, hitboxConfig)
	if not attackerCharacter or type(hitboxConfig) ~= "table" then
		return {}
	end

	local rootPart = attackerCharacter:FindFirstChild("HumanoidRootPart")
	if not rootPart or not rootPart:IsA("BasePart") then
		return {}
	end

	local size = hitboxConfig.Size
	local offset = hitboxConfig.Offset
	local lifetime = hitboxConfig.Lifetime
	if typeof(size) ~= "Vector3" then
		size = DEFAULT_SIZE
	end

	if typeof(offset) ~= "CFrame" then
		offset = DEFAULT_OFFSET
	end

	if type(lifetime) ~= "number" then
		lifetime = DEFAULT_LIFETIME
	end

	if size.X <= 0 or size.Y <= 0 or size.Z <= 0 then
		return {}
	end

	lifetime = math.max(0.01, lifetime)
	local samples = math.max(1, math.floor(hitboxConfig.Samples or 1))
	local sampleDelay = lifetime / samples

	local overlapParams = OverlapParams.new()
	overlapParams.FilterType = Enum.RaycastFilterType.Exclude
	overlapParams.FilterDescendantsInstances = { attackerCharacter }
	overlapParams.MaxParts = 64

	local victimsMap = {}
	local hitboxPart = nil

	for sampleIndex = 1, samples do
		local hitboxCFrame = rootPart.CFrame * offset
		if not hitboxPart then
			hitboxPart = createHitboxPart(attackerCharacter, rootPart, hitboxCFrame, size, lifetime)
			overlapParams.FilterDescendantsInstances = { attackerCharacter, hitboxPart }
		else
			hitboxPart.CFrame = hitboxCFrame
		end

		local touchedParts = Workspace:GetPartBoundsInBox(hitboxCFrame, size, overlapParams)
		for _, part in ipairs(touchedParts) do
			local humanoid = getHumanoidFromPart(part)
			if humanoid and humanoid.Health > 0 then
				victimsMap[humanoid] = true
			end
		end

		if sampleIndex < samples and sampleDelay > 0 then
			task.wait(sampleDelay)
		end
	end

	local victims = {}
	for humanoid in pairs(victimsMap) do
		table.insert(victims, humanoid)
	end

	return victims
end

return CombatHitbox
