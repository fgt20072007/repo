export type GroundSettings = {
	Position: Vector3,
	Distance: number,
	SizeOfParts: Vector3,
	MaxRocks: number,
	DespawnTime: number,
	Filter: { Model? },
}

export type ScatterSettings = {
	AmountOfRocks: number,
	Force: number,
	MinDespawnTime: number,
	MaxDespawnTime: number,
	OriginPosition: Vector3,
	SizeRange: number,
}

local TweenService = game:GetService("TweenService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage.Shared

local PartCache = require(Shared.Packages.partcache)
local StorageFolder = workspace:FindFirstChild("RocksDebris") and workspace.RocksDebris or Instance.new("Folder")
StorageFolder.Name = "RocksDebris"
StorageFolder.Parent = workspace

local PartTemplate = PartCache.new(Instance.new("Part"), 500, StorageFolder)
local random = Random.new(tick())

local raycastParams = RaycastParams.new()
raycastParams.FilterType = Enum.RaycastFilterType.Exclude

local Rocks = {
	DefaultSize = Vector3.one * 2,
	DefaultDespawnTime = 3,
}

local function OuterRocksLoop(Settings: GroundSettings, randomAngle, splitAngle)
	for i = 1, Settings.MaxRocks do
		local cf = CFrame.new(Settings.Position)
		local newCF = cf
			* CFrame.fromEulerAnglesXYZ(0, math.rad(randomAngle), 0)
			* CFrame.new(Settings.Distance / 2 + Settings.Distance / 2.7, 10, 0)
		local ray = workspace:Raycast(newCF.Position, Vector3.new(0, -20, 0), raycastParams)
		randomAngle += splitAngle
		if ray then
			local part = PartTemplate:GetPart()
			local hoof = PartTemplate:GetPart()

			part.CFrame = CFrame.new(ray.Position - Vector3.new(0, 0.5, 0), Settings.Position)
				* CFrame.fromEulerAnglesXYZ(
					random:NextNumber(-0.25, 0.5),
					random:NextNumber(-0.25, 0.25),
					random:NextNumber(-0.25, 0.25)
				)
			part.Size = Vector3.new(
				Settings.SizeOfParts.X * 1.3,
				Settings.SizeOfParts.Y / 1.4,
				Settings.SizeOfParts.Z * 1.3
			) * random:NextNumber(1, 1.5)

			hoof.Size = Vector3.new(part.Size.X * 1.01, part.Size.Y * 0.25, part.Size.Z * 1.01)
			hoof.CFrame = part.CFrame * CFrame.new(0, part.Size.Y / 2 - hoof.Size.Y / 2.1, 0)

			part.Parent = StorageFolder
			hoof.Parent = StorageFolder

			if
				ray.Instance.Material == Enum.Material.Concrete
				or ray.Instance.Material == Enum.Material.Air
				or ray.Instance.Material == Enum.Material.Wood
				or ray.Instance.Material == Enum.Material.Neon
				or ray.Instance.Material == Enum.Material.WoodPlanks
			then
				part.Material = ray.Instance.Material
				hoof.Material = ray.Instance.Material
			else
				part.Material = Enum.Material.Concrete
				hoof.Material = ray.Instance.Material
			end

			part.BrickColor = BrickColor.new("Dark grey")
			part.Anchored = true
			part.CanTouch = false
			part.CanCollide = false

			hoof.BrickColor = ray.Instance.BrickColor
			hoof.Anchored = true
			hoof.CanTouch = false
			hoof.CanCollide = false

			task.delay(Settings.DespawnTime, function()
				TweenService:Create(
					part,
					TweenInfo.new(0.6, Enum.EasingStyle.Quad, Enum.EasingDirection.InOut),
					{ Size = Vector3.new(0.01, 0.01, 0.01) }
				):Play()
				TweenService:Create(hoof, TweenInfo.new(0.6, Enum.EasingStyle.Quad, Enum.EasingDirection.InOut), {
					Size = Vector3.new(0.01, 0.01, 0.01),
					CFrame = part.CFrame * CFrame.new(0, part.Size.Y / 2 - part.Size.Y / 2.1, 0),
				}):Play()

				task.wait(0.6)
				PartTemplate:ReturnPart(part)
				PartTemplate:ReturnPart(hoof)
			end)
		end
	end
end

local function InnerRocksLoop(Settings: GroundSettings, randomAngle, splitAngle)
	for i = 1, Settings.MaxRocks do
		local cf = CFrame.new(Settings.Position)
		local newCF = cf
			* CFrame.fromEulerAnglesXYZ(0, math.rad(randomAngle), 0)
			* CFrame.new(Settings.Distance / 2 + Settings.Distance / 10, 10, 0)
		local ray = game.Workspace:Raycast(newCF.Position, Vector3.new(0, -20, 0), raycastParams)
		randomAngle += splitAngle
		if ray then
			local part = PartTemplate:GetPart()
			local hoof = PartTemplate:GetPart()

			part.CFrame = CFrame.new(ray.Position - Vector3.new(0, Settings.SizeOfParts.Y * 0.4, 0), Settings.Position)
				* CFrame.fromEulerAnglesXYZ(
					random:NextNumber(-1, -0.3),
					random:NextNumber(-0.15, 0.15),
					random:NextNumber(-0.15, 0.15)
				)
			part.Size = Vector3.new(
				Settings.SizeOfParts.X * 1.3,
				Settings.SizeOfParts.Y * 0.7,
				Settings.SizeOfParts.Z * 1.3
			) * random:NextNumber(1, 1.5)

			hoof.Size = Vector3.new(part.Size.X * 1.01, part.Size.Y * 0.25, part.Size.Z * 1.01)
			hoof.CFrame = part.CFrame * CFrame.new(0, part.Size.Y / 2 - hoof.Size.Y / 2.1, 0)

			part.Parent = StorageFolder
			hoof.Parent = StorageFolder

			if
				ray.Instance.Material == Enum.Material.Concrete
				or ray.Instance.Material == Enum.Material.Air
				or ray.Instance.Material == Enum.Material.Wood
				or ray.Instance.Material == Enum.Material.Neon
				or ray.Instance.Material == Enum.Material.WoodPlanks
			then
				part.Material = ray.Instance.Material
				hoof.Material = ray.Instance.Material
			else
				part.Material = Enum.Material.Concrete
				hoof.Material = ray.Instance.Material
			end

			part.BrickColor = BrickColor.new("Dark grey")
			part.Anchored = true
			part.CanTouch = false
			part.CanCollide = false

			hoof.BrickColor = ray.Instance.BrickColor
			hoof.Anchored = true
			hoof.CanTouch = false
			hoof.CanCollide = false

			task.delay(Settings.DespawnTime, function()
				TweenService:Create(
					part,
					TweenInfo.new(0.6, Enum.EasingStyle.Quad, Enum.EasingDirection.InOut),
					{ Size = Vector3.new(0.01, 0.01, 0.01) }
				):Play()
				TweenService:Create(hoof, TweenInfo.new(0.6, Enum.EasingStyle.Quad, Enum.EasingDirection.InOut), {
					Size = Vector3.new(0.01, 0.01, 0.01),
					CFrame = part.CFrame * CFrame.new(0, part.Size.Y / 2 - part.Size.Y / 2.1, 0),
				}):Play()

				task.wait(0.6)
				PartTemplate:ReturnPart(part)
				PartTemplate:ReturnPart(hoof)
			end)
		end
	end
end

function Rocks.Ground(Settings: GroundSettings)
	local randomAngle = random:NextInteger(28, 35)
	local splitAngle = 360 / Settings.MaxRocks

	if Settings.Filter and typeof(Settings.Filter) == "table" then
		table.insert(Settings.Filter, StorageFolder)
	else
		Settings.Filter = { StorageFolder }
	end

	Settings.DespawnTime = Settings.DespawnTime or Rocks.DefaultDespawnTime
	Settings.SizeOfParts = Settings.SizeOfParts or Rocks.DefaultSize

	raycastParams.FilterDescendantsInstances = Settings.Filter

	InnerRocksLoop(Settings, randomAngle, splitAngle)
	OuterRocksLoop(Settings, randomAngle, splitAngle)
end

function Rocks.Scatter(Settings: ScatterSettings)
	local result = workspace:Raycast(Settings.OriginPosition, Vector3.new(0, -100, 0), raycastParams)

	if not result then
		return
	end

	for i = 1, Settings.AmountOfRocks do
		local part = PartTemplate:GetPart()
		local offset = Vector3.new(random:NextNumber(-2, 2), random:NextNumber(-2, 2), random:NextNumber(-2, 2))
		part.Size = Vector3.new(
			random:NextNumber(1, Settings.SizeRange),
			random:NextNumber(1, Settings.SizeRange),
			random:NextNumber(1, Settings.SizeRange)
		)

		part.CFrame = CFrame.new(result.Position + offset)
			* CFrame.fromOrientation(0, math.rad(random:NextNumber(1, 360)), 0)
		part.Color = result.Instance.Color
		part.Material = result.Material
		part.Anchored = false
		part.Massless = true
		part.Parent = workspace
		part:ApplyImpulse((-part.CFrame.LookVector + Vector3.new(0, random:NextNumber(0.1, 1.2), 0)) * Settings.Force)

		task.delay(random:NextNumber(Settings.MinDespawnTime, Settings.MaxDespawnTime), function()
			TweenService:Create(
				part,
				TweenInfo.new(0.6, Enum.EasingStyle.Quad, Enum.EasingDirection.InOut),
				{ Size = Vector3.new(0.01, 0.01, 0.01) }
			):Play()

			task.wait(0.7)
			PartTemplate:ReturnPart(part)
		end)
	end
end

return Rocks
