export type OtherParams = {
	OverlapParams: OverlapParams?,
	HitboxColor: Color3?,
	Owner: Player?,
	AttachTo: BasePart?,
}

local CollectionService = game:GetService("CollectionService")
local Players = game:GetService("Players")

local function visualizeHitbox(Origin: CFrame, Size: Vector3, color: Color3?, owner: Player?, attachTo: BasePart?)
	task.spawn(function()
		local hitbox = Instance.new("Part")
		hitbox.Size = Size
		hitbox.CanCollide = false
		hitbox.CanQuery = false
		hitbox.CanTouch = false
		hitbox.Massless = true
		hitbox.Color = color or Color3.fromRGB(255, 0, 0)
		hitbox.Transparency = 0.85
		hitbox.CFrame = Origin
		hitbox.Anchored = true
		hitbox.Parent = workspace

		if attachTo and attachTo:IsA("BasePart") then
			hitbox.Anchored = false
			local weld = Instance.new("WeldConstraint")
			weld.Part0 = attachTo
			weld.Part1 = hitbox
			weld.Parent = hitbox
		end

		if owner and owner.Parent == Players then
			pcall(function()
				hitbox:SetNetworkOwner(owner)
			end)
		end

		task.delay(0.5, function()
			hitbox:Destroy()
		end)
	end)
end

local function getOverlapParams(overlapParams)
	if not overlapParams then
		overlapParams = OverlapParams.new()
		overlapParams.FilterType = Enum.RaycastFilterType.Include
		overlapParams.FilterDescendantsInstances = CollectionService:GetTagged("Goblin")
	end

	return overlapParams
end

local Hitbox = {
	Debug = true,
}

function Hitbox.Query(Origin: CFrame, Size: Vector3, OtherParams: OtherParams?, CharactersOnly: boolean?)
	if not Origin or not Size then
		warn("No cframe or size found", debug.traceback())

		return
	end

	local params
	local hitboxColor
	local owner
	local attachTo

	if typeof(OtherParams) == "table" then
		params = OtherParams.OverlapParams
		hitboxColor = OtherParams.HitboxColor
		owner = OtherParams.Owner
		attachTo = OtherParams.AttachTo
	else
		params = OtherParams
	end

	if not params then
		params = getOverlapParams()
	end

	local partsBoundInBox = workspace:GetPartBoundsInBox(Origin, Size, params)

	if Hitbox.Debug then
		visualizeHitbox(Origin, Size, hitboxColor, owner, attachTo)
	end

	if CharactersOnly then
		local result = {}

		for _, part in partsBoundInBox do
			local parent = part:FindFirstAncestorWhichIsA("Model")
			if not parent or table.find(result, parent) then
				continue
			end

			if Hitbox.Debug then
				warn("Hitbox query result: " .. parent.Name)
			end

			table.insert(result, parent)
		end

		return result
	end

	return partsBoundInBox
end

return Hitbox
