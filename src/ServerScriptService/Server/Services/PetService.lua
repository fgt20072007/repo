local HttpService = game:GetService("HttpService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")

local Shared = ReplicatedStorage.Shared
local Server = require(ServerScriptService.Server)

local EggData = Shared.Data.Eggs

local HatchEggRemote = require(Shared.Remotes.HatchEgg):Server()
local HatchResultRemote = require(Shared.Remotes.HatchResult):Server()
local EquipPetRemote = require(Shared.Remotes.EquipPet):Server()
local UnequipPetRemote = require(Shared.Remotes.UnequipPet):Server()
local DeletePetsRemote = require(Shared.Remotes.DeletePets):Server()

local random = Random.new(tick())
local MAX_EQUIPPED_PETS = 3

local PetService = {}

function PetService._Init(self: PetService)
	self.PetFolder = Instance.new("Folder")
	self.PetFolder.Name = "PlayerPets"
	self.PetFolder.Parent = workspace

	self.ChanceCache = {}
	self.PlayerPets = {}

	HatchEggRemote:On(function(Player: Player, EggType, Amount)
		self:HatchPetFromEgg(Player, EggType, Amount)
	end)

	EquipPetRemote:On(function(Player: Player, PetId)
		if typeof(PetId) ~= "string" then return end
		self:EquipPet(Player, PetId)
	end)

	UnequipPetRemote:On(function(Player: Player, PetId)
		if typeof(PetId) ~= "string" then return end
		self:UnequipPet(Player, PetId)
	end)

	DeletePetsRemote:On(function(Player: Player, PetIds)
		if typeof(PetIds) ~= "table" then return end

		local uniquePetIds = {}
		local processed = 0
		for _, petId in PetIds do
			if typeof(petId) ~= "string" then continue end
			if uniquePetIds[petId] then continue end

			uniquePetIds[petId] = true
			processed += 1

			if processed >= 200 then
				break
			end
		end

		local deletedAny = false
		for petId in uniquePetIds do
			if self:DeletePet(Player, petId, true) then
				deletedAny = true
			end
		end

		if not deletedAny then return end

		local DataService = Server.Services.DataService
		local Profile = DataService:GetProfile(Player)
		if not Profile then return end

		DataService:Set(Player, "Pets", Profile.Data.Pets)
		DataService:Set(Player, "EquippedPets", Profile.Data.EquippedPets)
	end)
end

function PetService.OnPlayerAdded(self: PetService, Player: Player)
	self.PlayerPets[Player] = {}

	local playerPetsFolder = Instance.new("Folder")
	playerPetsFolder.Name = Player.UserId
	playerPetsFolder.Parent = self.PetFolder
end

function PetService.HatchPetFromEgg(self: PetService, Player: Player, EggType: string, Amount)
	local eggModule = EggData:FindFirstChild(EggType)
	if not eggModule then return end

	local eggInfo = require(eggModule)
	if not eggInfo then return end
	if typeof(Amount) ~= "number" then return end

	local DataService = Server.Services.DataService
	local Profile = DataService:GetProfile(Player)
	if not Profile then return end

	Amount = math.clamp(math.floor(Amount), 1, 3)

	local totalChance = self.ChanceCache[EggType]
	if not totalChance then
		totalChance = 0
		for _, pet in eggInfo do
			totalChance += pet.Chance
		end
		self.ChanceCache[EggType] = totalChance
	end

	local results = {}
	for _ = 1, Amount do
		local roll = random:NextNumber(0, totalChance)
		local cumulativeChance, rolledPet = 0, nil

		for _, pet in eggInfo do
			cumulativeChance += pet.Chance
			if roll <= cumulativeChance then
				rolledPet = pet
				break
			end
		end

		rolledPet = rolledPet or eggInfo[1]

		local petId = HttpService:GenerateGUID(false)
		local petData = {
			Id = petId,
			Name = rolledPet.Name,
			EggType = EggType,
			Chance = rolledPet.Chance,
			ObtainedAt = os.time(),
		}

		Profile.Data.Pets[petId] = petData

		table.insert(results, {
			EggType = EggType,
			PetType = rolledPet.Name,
			PetChance = rolledPet.Chance,
			PetId = petId,
		})
	end

	DataService:Set(Player, "Pets", Profile.Data.Pets)
	HatchResultRemote:Fire(Player, results)
end

function PetService.GetPets(self: PetService, Player: Player)
	local Profile = Server.Services.DataService:GetProfile(Player)
	if not Profile then return {} end
	return Profile.Data.Pets
end

function PetService.GetPet(self: PetService, Player: Player, PetId: string)
	local Profile = Server.Services.DataService:GetProfile(Player)
	if not Profile then return nil end
	return Profile.Data.Pets[PetId]
end

function PetService.DeletePet(self: PetService, Player: Player, PetId: string, SkipSync: boolean?)
	local DataService = Server.Services.DataService
	local Profile = DataService:GetProfile(Player)
	if not Profile then return false end
	if not Profile.Data.Pets[PetId] then return false end

	Profile.Data.Pets[PetId] = nil
	Profile.Data.EquippedPets[PetId] = nil

	if not SkipSync then
		DataService:Set(Player, "Pets", Profile.Data.Pets)
		DataService:Set(Player, "EquippedPets", Profile.Data.EquippedPets)
	end

	return true
end

function PetService.EquipPet(self: PetService, Player: Player, PetId: string, SkipSync: boolean?)
	local DataService = Server.Services.DataService
	local Profile = DataService:GetProfile(Player)
	if not Profile then return false end
	if not Profile.Data.Pets[PetId] then return false end
	if Profile.Data.EquippedPets[PetId] then return false end

	local equippedCount = 0
	for _ in Profile.Data.EquippedPets do
		equippedCount += 1
	end
	if equippedCount >= MAX_EQUIPPED_PETS then return false end

	Profile.Data.EquippedPets[PetId] = true

	if not SkipSync then
		DataService:Set(Player, "EquippedPets", Profile.Data.EquippedPets)
	end

	return true
end

function PetService.UnequipPet(self: PetService, Player: Player, PetId: string, SkipSync: boolean?)
	local DataService = Server.Services.DataService
	local Profile = DataService:GetProfile(Player)
	if not Profile then return false end
	if not Profile.Data.EquippedPets[PetId] then return false end

	Profile.Data.EquippedPets[PetId] = nil

	if not SkipSync then
		DataService:Set(Player, "EquippedPets", Profile.Data.EquippedPets)
	end

	return true
end

function PetService.GetEquippedPets(self: PetService, Player: Player)
	local Profile = Server.Services.DataService:GetProfile(Player)
	if not Profile then return {} end

	local equipped = {}
	for petId in Profile.Data.EquippedPets do
		local pet = Profile.Data.Pets[petId]
		if pet then equipped[petId] = pet end
	end
	return equipped
end

type PetService = typeof(PetService) & {
	PetFolder: Folder,
	PlayerPets: { [Player]: {} },
	ChanceCache: { [string]: number },
}

return PetService