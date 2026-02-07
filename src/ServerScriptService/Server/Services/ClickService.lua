--!nocheck

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")
local Shared = ReplicatedStorage.Shared

local Assets = ReplicatedStorage.Assets

local Server = require(ServerScriptService.Server)
local Networker = require(Shared.Packages.networker)
local Hitbox = require(Shared.CustomPackages.Hitbox)
local Ragdoll = require(Shared.CustomPackages.Ragdoll)
local ScytheData = require(Shared.Data.Scythes)
local DNAData = require(Shared.Data.DNA)
local RankData = require(Shared.Data.Ranks)
local DamagedPlayerRemote = require(Shared.Remotes.DamagedPlayer):Server()
local CollectDroppablesRemote = require(Shared.Remotes.CollectDroppables):Server()

local random = Random.new(tick())

local ClickService = {}

function ClickService._Init(self: ClickService)
	self.Networker = Networker.server.new("ClickService", self, {
		self.OnClick,
	})
end

function ClickService.OnClick(self: ClickService, Player: Player, Combo: number)
	Combo = math.clamp(Combo, 1, 2)

	local profile = Server.Services.DataService:GetProfile(Player)
	if not profile then return end

	local equippedScythe = profile.Data.EquippedScythe
	local scytheInfo = ScytheData.Sorted[equippedScythe]
	local skullsToAdd = scytheInfo and scytheInfo.skullPerClick or 1
	local equippedRank = profile.Data.EquippedRank
	local rankInfo = RankData.Sorted[equippedRank] or RankData.Sorted.Rank1
	local skullBoost = rankInfo and rankInfo.Boosts and rankInfo.Boosts.Skulls or 1
	local boostedSkulls = math.floor(skullsToAdd * skullBoost)
	skullsToAdd = boostedSkulls > 0 and boostedSkulls or skullsToAdd
	local equippedDna = profile.Data.EquippedDNA
	local dnaInfo = DNAData.Sorted[equippedDna] or DNAData.Sorted.dna1
	local maxStorage = dnaInfo and dnaInfo.StorageSpace or 0
	local currentSkulls = profile.Data.Skulls or 0

	if maxStorage > 0 then
		local remaining = maxStorage - currentSkulls
		if remaining <= 0 then
			skullsToAdd = 0
		else
			skullsToAdd = math.min(skullsToAdd, remaining)
		end
	end

	if skullsToAdd > 0 then
		Server.Services.DataService:Increment(Player, "Skulls", skullsToAdd)
	end
	local Character = Player.Character or Player.CharacterAdded:Wait()
	local hitboxCFrame = Character.HumanoidRootPart.CFrame * CFrame.new(0, 0, -5)
	local Vfx = Combo == 1 and Assets.VFX.LeftSwing:Clone() or Assets.VFX.RightSwing:Clone()
	local vfxDelay = Combo == 1 and 0.15 or 0.25

	Character.Humanoid.WalkSpeed = 8

	task.delay(vfxDelay, function()
		Vfx.Parent = Character.HumanoidRootPart

		for _, emitter in Vfx:GetChildren() do
			emitter:Emit(emitter:GetAttribute("EmitCount"))
		end

		task.wait(0.35)
		Character.Humanoid.WalkSpeed = 16

		task.wait(2)
		Vfx:Destroy()
	end)

	local overlapParams = OverlapParams.new()
	overlapParams.FilterType = Enum.RaycastFilterType.Exclude
	overlapParams.FilterDescendantsInstances = { Player.Character }

	local result = Hitbox.Query(hitboxCFrame, Vector3.new(9, 4, 9), {
		OverlapParams = overlapParams,
		Owner = Player,
		AttachTo = Character.HumanoidRootPart,
	}, true)

	if #result == 0 then
		return
	end

	for _, character in result do
		local goblin = Server.Services.GoblinService:IsCharacterGoblin(character)

		if goblin then
			if goblin.Dead or (goblin.Info and goblin.Info.Health and goblin.Info.Health <= 0) then
				continue
			end
			Server.Services.GoblinService:DamageGoblin(Player, goblin)
			return
		end

		local player = Players:GetPlayerFromCharacter(character)

		if player then
			local playerCharacter = player.Character or player.CharacterAdded:Wait()
			local humanoid = playerCharacter.Humanoid
			if humanoid.Health <= 0 then continue end
			local isDead = humanoid.Health - 25 <= 0
			humanoid:TakeDamage(25)
			DamagedPlayerRemote:FireAll(playerCharacter, 25, isDead)

			if isDead then
				local randomAmount = random:NextInteger(3, 6)
				local Shard = Assets.Drops.Shard
				local droppables = {}
				playerCharacter.PrimaryPart.AssemblyLinearVelocity = playerCharacter.PrimaryPart.CFrame.LookVector
					* 2
					* playerCharacter.PrimaryPart.AssemblyMass
				Ragdoll.Ragdoll(playerCharacter)

				Server.Services.DataService:Increment(Player, "SkillPoints", 2)
				Server.Services.DataService:Increment(Player, "Kills", 1)

				for _ = 1, randomAmount do
					local shardDropVfx = Assets.VFX.ShardDrop:Clone()
					local shardDropClone = Shard:Clone() :: Part

					shardDropVfx.Parent = shardDropClone

					for _, emitter in shardDropVfx:GetDescendants() do
						if emitter:IsA("ParticleEmitter") then
							emitter.Enabled = true
						end
					end

					shardDropClone.CFrame = playerCharacter.HumanoidRootPart.CFrame
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

				task.delay(2, function()
					CollectDroppablesRemote:Fire(Player, droppables, character)
				end)
			end
		end
	end
end

type ClickService = typeof(ClickService) & {
	Networker: Networker.Server,
}

return ClickService