local HttpService = game:GetService("HttpService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local PhysicsService = game:GetService("PhysicsService")
local ServerScriptService = game:GetService("ServerScriptService")
local SoundService = game:GetService("SoundService")

PhysicsService:RegisterCollisionGroup("Goblin")
PhysicsService:RegisterCollisionGroup("Droppable")
PhysicsService:RegisterCollisionGroup("Player")

PhysicsService:CollisionGroupSetCollidable("Goblin", "Droppable", false)
PhysicsService:CollisionGroupSetCollidable("Player", "Droppable", false)
PhysicsService:CollisionGroupSetCollidable("Player", "Goblin", false)

local Shared = ReplicatedStorage.Shared
local Assets = ReplicatedStorage.Assets

local Server = require(ServerScriptService.Server)
local Ragdoll = require(Shared.CustomPackages.Ragdoll)
local Math = require(Shared.CustomPackages.Math)
local RankData = require(Shared.Data.Ranks)
local DamagedGoblinRemote = require(Shared.Remotes.DamagedGoblin):Server()
local CollectDroppablesRemote = require(Shared.Remotes.CollectDroppables):Server()

local random = Random.new(tick())

local MIN_GOBLIN_DISTANCE = 10

local function GenerateGoblinInfo()
	return {
		Health = 100,
		MaxHealth = 100,
	}
end

local GoblinService = {}

function GoblinService.GetNearbyGoblinCount(self: GoblinService, position: Vector3, radius: number): number
	local count = 0
	for _, goblinData in self.Goblins do
		if not goblinData.Model or not goblinData.Model.PrimaryPart then continue end
		local dist = (goblinData.Model.PrimaryPart.Position - position).Magnitude
		if dist < radius then count += 1 end
	end
	return count
end

function GoblinService.FindValidSpawnPosition(self: GoblinService, basePos: CFrame, maxAttempts: number): CFrame?
	for _ = 1, maxAttempts do
		local randomOffset = CFrame.new(random:NextNumber(-8, 8), 0, random:NextNumber(-8, 8))
		local testPos = basePos * randomOffset
		if self:GetNearbyGoblinCount(testPos.Position, MIN_GOBLIN_DISTANCE) == 0 then
			return testPos * CFrame.fromOrientation(0, math.rad(random:NextInteger(1, 360)), 0)
		end
	end
	return nil
end

function GoblinService._Init(self: GoblinService)
	self.Goblins = {}

	for _, part in Assets.Models.Goblin:GetDescendants() do
		if not part:IsA("BasePart") then
			continue
		end
		part.CollisionGroup = "Goblin"
	end

	for _, spawner in workspace.GoblinSpawns:GetChildren() do
		self:CreateGoblin(spawner.Part.CFrame)
	end
end

function GoblinService.OnPlayerAdded(self: GoblinService, Player: Player)
	local Character = Player.Character or Player.CharacterAdded:Wait()

	for _, part in Character:GetDescendants() do
		if not part:IsA("BasePart") then
			continue
		end

		part.CollisionGroup = "Player"
	end
end

function GoblinService.CreateGoblin(self: GoblinService, SpawnPos: CFrame)
	local finalSpawn = self:FindValidSpawnPosition(SpawnPos, 10)
	if not finalSpawn then return end

	local Goblin = Assets.Models.Goblin:Clone()
	local Id = HttpService:GenerateGUID(false)
	local Info = GenerateGoblinInfo()
	local HealthUi = Goblin.Head.Health
	local Animator = Goblin.Humanoid.Animator
	local IdleTrack = Animator:LoadAnimation(Assets.Animations.ZombieIdle)

	IdleTrack.Looped = true
	HealthUi.Container.HpText.Text = Math.FormatCurrency(Info.Health)

	Goblin:PivotTo(finalSpawn * CFrame.new(0, Goblin:GetExtentsSize().Y / 2, 0))
	Goblin.Name = Id

	for _, part in Goblin:GetDescendants() do
		if not part:IsA("BasePart") then
			continue
		end

		part.CollisionGroup = "Goblin"
	end

	Goblin.Parent = workspace.Goblins
	IdleTrack:Play()

	self.Goblins[Id] = {
		Model = Goblin,
		Info = Info,
		Animations = {
			LeftHit = Animator:LoadAnimation(Assets.Animations.ZombieLeft),
			RightHit = Animator:LoadAnimation(Assets.Animations.ZombieRight),
		},
		SpawnPos = SpawnPos,
		Id = Id,
	}
end

function GoblinService.DamageGoblin(self: GoblinService, Player: Player, Goblin: {})
	if Goblin.Dead then
		return
	end

	local trackToPlay = random:NextInteger(1, 2) == 1 and Goblin.Animations.LeftHit or Goblin.Animations.RightHit
	local HealthUi = Goblin.Model.Head.Health
	local isDead = Goblin.Info.Health - 50 <= 0
	local character = Player.Character or Player.CharacterAdded:Wait()
	local droppables = {}

	trackToPlay:Play()

	Goblin.Info.Health -= 50
	HealthUi.Container.HpBar.Bar.Size = UDim2.fromScale(math.clamp(Goblin.Info.Health / Goblin.Info.MaxHealth, 0, 1), 1)
	HealthUi.Container.HpText.Text = Math.FormatCurrency(Goblin.Info.Health)

	if isDead then
		local Shard = Assets.Drops.Shard
		local randomAmount = random:NextInteger(2, 4)
		local Spawn = Goblin.SpawnPos
		local deathSound = SoundService.Goblin.Death:Clone()

		Goblin.Dead = true

		deathSound.Parent = Goblin.Model.HumanoidRootPart
		deathSound:Play()
		deathSound.Ended:Once(function()
			deathSound:Destroy()
		end)

		for _ = 1, randomAmount do
			local shardDropVfx = Assets.VFX.ShardDrop:Clone()
			local shardDropClone = Shard:Clone() :: Part

			shardDropVfx.Parent = shardDropClone

			for _, emitter in shardDropVfx:GetDescendants() do
				if emitter:IsA("ParticleEmitter") then
					emitter.Enabled = true
				end
			end

			shardDropClone.CFrame = Goblin.Model.HumanoidRootPart.CFrame
			shardDropClone.CollisionGroup = "Droppable"
			shardDropClone.AssemblyLinearVelocity = Vector3.new(
				random:NextNumber(-4, 4),
				random:NextNumber(4, 6),
				random:NextNumber(-4, 4)
			) * 8
			shardDropClone.CollisionGroup = "Droppable"
			shardDropClone.Parent = workspace
			shardDropClone:SetNetworkOwner(Player)
			shardDropClone.BillboardGui.Enabled = true

			table.insert(droppables, shardDropClone)
		end
		local Profile = Server.Services.DataService:GetProfile(Player)
		local equippedRank = Profile and Profile.Data and Profile.Data.EquippedRank
		local rankInfo = RankData.Sorted[equippedRank] or RankData.Sorted.Rank1
		local shardBoost = rankInfo and rankInfo.Boosts and rankInfo.Boosts.Shards or 1
		local shardsToAdd = math.floor(randomAmount * shardBoost)
		if shardsToAdd <= 0 then shardsToAdd = randomAmount end

		Server.Services.DataService:Increment(Player, "Shards", shardsToAdd)
		Server.Services.DataService:Increment(Player, "SkillPoints", 1)

		task.delay(2, function()
			CollectDroppablesRemote:Fire(Player, droppables, character)
		end)

		Goblin.Model.PrimaryPart.AssemblyLinearVelocity = -Goblin.Model.PrimaryPart.CFrame.LookVector
			* 5
			* Goblin.Model.PrimaryPart.AssemblyMass
		Ragdoll.Ragdoll(Goblin.Model)

		task.delay(3, function()
			Goblin.Model:Destroy()
			self.Goblins[Goblin.Model.Name] = nil

			for _, droppable in droppables do
				droppable:Destroy()
			end

			task.wait(10)
			self:CreateGoblin(Spawn)
		end)
	else
		local soundToPlay = random:NextInteger(1, 2) == 1 and SoundService.Goblin.Hurt1
			or SoundService.Goblin.Hurt2 :: Sound

		soundToPlay = soundToPlay:Clone()
		trackToPlay:Play()

		soundToPlay.Parent = Goblin.Model.HumanoidRootPart
		soundToPlay:Play()

		soundToPlay.Ended:Once(function()
			soundToPlay:Destroy()
		end)
	end

	DamagedGoblinRemote:FireAll(Goblin.Model, 50, isDead, character)
end

function GoblinService.IsCharacterGoblin(self: GoblinService, Character: Model)
	return self.Goblins[Character.Name]
end

type GoblinService = typeof(GoblinService) & {
	Goblins: { [string]: { Model: Model, Info: {}, Animations: {}, SpawnPos: CFrame } },
}

return GoblinService
