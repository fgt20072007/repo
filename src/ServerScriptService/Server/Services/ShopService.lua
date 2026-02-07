local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")

local Shared = ReplicatedStorage.Shared
local Assets = ReplicatedStorage.Assets

local Server = require(ServerScriptService.Server)
local ScytheData = require(Shared.Data.Scythes)
local RankData = require(Shared.Data.Ranks)
local DNAData = require(Shared.Data.DNA)
local PlayerData = require(Shared.Data.PlayerData)
local PurchaseItemRemote = require(Shared.Remotes.PurchaseItem):Server()
local BuyAllRemote = require(Shared.Remotes.BuyAll):Server()

local motor_Cframe = CFrame.new(-0.035, -0.8, -0.008) * CFrame.Angles(math.rad(-75), 0, 0)
local connections = {}

local function OnCharacterAdded(Character)
	local Player = Players:GetPlayerFromCharacter(Character)
	local PlayerUi = Assets.Interface.Player:Clone()

	if connections[Player] then
		connections[Player]:Disconnect()
	end

	local rank = Server.Services.DataService:GetProfileAsync(Player).Data.EquippedRank

	PlayerUi.RankImage.Image = RankData.Sorted[rank].imageId
	PlayerUi.Health.Container.Bar.Size = UDim2.fromScale(1, 1)
	PlayerUi.Health.HealthDisplay.Label.Text = `100`
	PlayerUi.Health.xp.bar.Size = UDim2.fromScale(0, 1)
	PlayerUi.Health.xp.Label.Text = `Level: 0`
	PlayerUi.Username.Text = Player.Name

	PlayerUi.Enabled = true
	PlayerUi.Parent = Character.Head
	connections[Player] = Character:WaitForChild("Humanoid").HealthChanged:Connect(function(Health)
		local HealthPercent = Health / Character.Humanoid.MaxHealth
		PlayerUi.Health.Container.Bar.Size = UDim2.fromScale(HealthPercent, 1)
		PlayerUi.Health.HealthDisplay.Label.Text = `${math.floor(Health)}`
	end)
end

local ShopService = {}

function ShopService._Init(self: ShopService)
	self.PlayerScythes = {}

	PurchaseItemRemote:On(function(Player, Category, Item)
		if Category == "Scythes" then
			self:PurchaseScythe(Player, Item)
		elseif Category == "DNA" then
			self:PurchaseDNA(Player, Item)
		elseif Category == "Rank" then
			self:PurchaseRank(Player, Item)
		end
	end)

	BuyAllRemote:On(function(Player, Category)
		if Category == "Scythes" then
			self:BuyAllScythes(Player)
		elseif Category == "DNA" then
			self:BuyAllDNA(Player)
		end
	end)
end

function ShopService.OnPlayerAdded(self: ShopService, Player: Player)
	local DataService = Server.Services.DataService
	local EquippedScythe = DataService:GetStat(Player, "EquippedScythe")

	if Player.Character then
		OnCharacterAdded(Player.Character)
	end

	Player.CharacterAdded:Connect(OnCharacterAdded)

	self:EquipScythe(Player, EquippedScythe)
end

function ShopService.PurchaseScythe(self: ShopService, Player, ScytheName)
	local Scythe = ScytheData.Sorted[ScytheName]
	if not Scythe then return end

	local DataService = Server.Services.DataService
	local Profile = DataService:GetProfile(Player)
	local Coins = DataService:GetStat(Player, "Coins")

	if Profile.Data.Scythes[ScytheName] then
		self:EquipScythe(Player, ScytheName)
		return
	end

	if Coins < Scythe.price then return end

	DataService:Decrement(Player, "Coins", Scythe.price)
	Profile.Data.Scythes[ScytheName] = true
	self:EquipScythe(Player, ScytheName)
end

function ShopService.EquipScythe(self: ShopService, Player: Player, ScytheName: string)
	local existingScythe = self.PlayerScythes[Player]
	local Character = Player.Character or Player.CharacterAdded:Wait()
	local Scythe = ScytheData.Sorted[ScytheName]
	if not Scythe then return end

	local DataService = Server.Services.DataService
	local Profile = DataService:GetProfile(Player)
	if not Profile.Data.Scythes[ScytheName] then return end

	local previousScythe = Profile.Data.EquippedScythe
	Profile.Data.EquippedScythe = ScytheName

	if existingScythe then
		print(`{Player.Name} unequipped scythe: {previousScythe}`)
		local motor_handle = Character["Right Arm"]:FindFirstChild("Handle")
		existingScythe:Destroy()

		if motor_handle and motor_handle.ClassName == "Motor6D" then
			motor_handle:Destroy()
		end

		self.PlayerScythes[Player] = nil
	end

	local scytheTypeFolder = Assets.Scythes:FindFirstChild(Scythe.type)

	if scytheTypeFolder == nil then
		warn("Scythe type folder not found: " .. Scythe.type)
		return
	end

	local scythe = scytheTypeFolder:FindFirstChild(Scythe.name)

	if scythe == nil then
		warn("Scythe not found in folder: " .. Scythe.name)
		return
	end

	scythe = scythe:Clone()

	local motor = Instance.new("Motor6D")
	local characterArm = Character:FindFirstChild("Right Arm")

	scythe:PivotTo(characterArm.CFrame)

	motor.Name = "Handle"
	motor.Part0 = characterArm
	motor.Part1 = scythe.Handle
	motor.C0 = motor_Cframe
	motor.Parent = characterArm

	scythe.Parent = Character

	self.PlayerScythes[Player] = scythe
	print(`{Player.Name} equipped scythe: {ScytheName}`)
end

function ShopService.PurchaseDNA(self: ShopService, Player: Player, DnaName: string)
	local Dna = DNAData.Sorted[DnaName]
	if not Dna then return end

	local DataService = Server.Services.DataService
	local Profile = DataService:GetProfile(Player)
	local Coins = DataService:GetStat(Player, "Coins")

	if Profile.Data.DNA[DnaName] then
		self:EquipDNA(Player, DnaName)
		return
	end

	if Coins < Dna.Price then return end

	DataService:Decrement(Player, "Coins", Dna.Price)
	Profile.Data.DNA[DnaName] = true
	self:EquipDNA(Player, DnaName)
end

function ShopService.EquipDNA(self: ShopService, Player: Player, DnaName: string)
	local Dna = DNAData.Sorted[DnaName]
	if not Dna then return end

	local DataService = Server.Services.DataService
	local Profile = DataService:GetProfile(Player)

	if not Profile.Data.DNA[DnaName] then return end

	DataService:Set(Player, "EquippedDNA", DnaName)

	local currentSkulls = Profile.Data.Skulls or 0
	if currentSkulls > Dna.StorageSpace then
		DataService:Set(Player, "Skulls", Dna.StorageSpace)
	end
end

function ShopService.PurchaseRank(self: ShopService, Player: Player, RankName: string)
	local Rank = RankData.Sorted[RankName]
	if not Rank then return end

	local DataService = Server.Services.DataService
	local Profile = DataService:GetProfile(Player)
	local Coins = DataService:GetStat(Player, "Coins")

	if Profile.Data.Ranks[RankName] then
		self:EquipRank(Player, RankName)
		return
	end

	if Coins < Rank.Price then return end

	DataService:Decrement(Player, "Coins", Rank.Price)
	local shouldRebirth = not Profile.Data.Ranks[RankName] and self:_IsRankUpgrade(Profile, RankName)
	Profile.Data.Ranks[RankName] = true
	if shouldRebirth then
		self:_HandleRankRebirth(Player)
	end
	self:EquipRank(Player, RankName)
end

function ShopService._GetRankIndex(self: ShopService, RankName: string): number
	for index, rank in RankData.Raw do
		if rank.name == RankName then
			return index
		end
	end

	return 0
end

function ShopService._GetHighestOwnedRankIndex(self: ShopService, Profile): number
	local highest = 0
	for index, rank in RankData.Raw do
		if Profile.Data.Ranks[rank.name] then
			if index > highest then
				highest = index
			end
		end
	end

	return highest
end

function ShopService._IsRankUpgrade(self: ShopService, Profile, RankName: string): boolean
	local newIndex = self:_GetRankIndex(RankName)
	local highestOwned = self:_GetHighestOwnedRankIndex(Profile)
	return newIndex > highestOwned
end

function ShopService._HandleRankRebirth(self: ShopService, Player: Player)
	local DataService = Server.Services.DataService
	local Profile = DataService:GetProfile(Player)

	local defaultScythes = table.clone(PlayerData.Scythes)
	local defaultDNA = table.clone(PlayerData.DNA)
	local defaultScythe = PlayerData.EquippedScythe
	local defaultDna = PlayerData.EquippedDNA

	DataService:Set(Player, "Coins", PlayerData.Coins)
	DataService:Set(Player, "Skulls", PlayerData.Skulls)
	DataService:Set(Player, "Shards", PlayerData.Shards)
	DataService:Set(Player, "Scythes", defaultScythes)
	DataService:Set(Player, "DNA", defaultDNA)
	DataService:Set(Player, "EquippedScythe", defaultScythe)

	self:EquipScythe(Player, defaultScythe)
	self:EquipDNA(Player, defaultDna)

	if PlayerData.Islands and Profile.Data.Islands then
		DataService:Set(Player, "Islands", table.clone(PlayerData.Islands))
		if PlayerData.EquippedIsland then
			DataService:Set(Player, "EquippedIsland", PlayerData.EquippedIsland)
		end
	end
end

function ShopService.EquipRank(self: ShopService, Player: Player, RankName: string)
	local Rank = RankData.Sorted[RankName]
	if not Rank then return end

	local DataService = Server.Services.DataService
	local Profile = DataService:GetProfile(Player)

	if not Profile.Data.Ranks[RankName] then return end

	local previousRank = Profile.Data.EquippedRank
	DataService:Set(Player, "EquippedRank", RankName)
	print(`{Player.Name} unequipped rank: {previousRank}, equipped rank: {RankName}`)

	local Character = Player.Character
	if not Character then return end

	local Head = Character:FindFirstChild("Head")
	if not Head then return end

	local PlayerUi = Head:FindFirstChildWhichIsA("BillboardGui")
	if not PlayerUi then return end

	local RankImage = PlayerUi:FindFirstChild("RankImage")
	if RankImage then
		RankImage.Image = Rank.imageId
	end
end

function ShopService.BuyAllScythes(self: ShopService, Player: Player)
	local DataService = Server.Services.DataService
	local Profile = DataService:GetProfile(Player)
	local lastPurchased = nil
	local purchasedCount = 0
	local coins = DataService:GetStat(Player, "Coins")

	for _, scythe in ScytheData.Raw do
		if Profile.Data.Scythes[scythe.name] then
			lastPurchased = scythe.name
			continue
		end

		if coins < scythe.price then break end

		DataService:Decrement(Player, "Coins", scythe.price)
		coins -= scythe.price
		Profile.Data.Scythes[scythe.name] = true
		lastPurchased = scythe.name
		purchasedCount += 1
	end

	if purchasedCount > 0 then
		print(`{Player.Name} BuyAll Scythes: purchased {purchasedCount} scythes`)
		self:EquipScythe(Player, lastPurchased)
	else
		print(`{Player.Name} BuyAll Scythes: could not purchase any`)
	end
end

function ShopService.BuyAllDNA(self: ShopService, Player: Player)
	local DataService = Server.Services.DataService
	local Profile = DataService:GetProfile(Player)
	local lastPurchased = nil
	local purchasedCount = 0
	local coins = DataService:GetStat(Player, "Coins")

	for _, dna in DNAData.Raw do
		if Profile.Data.DNA[dna.name] then
			lastPurchased = dna.name
			continue
		end

		if coins < dna.Price then break end

		DataService:Decrement(Player, "Coins", dna.Price)
		coins -= dna.Price
		Profile.Data.DNA[dna.name] = true
		lastPurchased = dna.name
		purchasedCount += 1
	end

	if purchasedCount > 0 then
		print(`{Player.Name} BuyAll DNA: purchased {purchasedCount} DNA`)
		self:EquipDNA(Player, lastPurchased)
	else
		print(`{Player.Name} BuyAll DNA: could not purchase any`)
	end
end

type ShopController = typeof(ShopService) & {
	PlayerScythes: { [Player]: Model },
}

return ShopService