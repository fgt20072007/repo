local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")

local ServerPackages = ServerScriptService.ServerPackages
local Shared = ReplicatedStorage.Shared

local Atoms = require(ReplicatedStorage.Shared.Atoms)
local CharmSync = require(Shared.Packages.CharmSync)
local Charm = require(Shared.Packages.Charm)
local ProfileStore = require(ServerPackages.ProfileStore)
local DataTemplate = require(Shared.Data.PlayerData)
local Immut = require(Shared.Packages.Immut)
local Server_Immutable = require(ServerScriptService.Server.Modules.ServerImmutable)
local Sift = require(Shared.Packages.Sift)

local SyncAtoms = require(Shared.Remotes.SyncAtoms):Server()
local InitAtoms = require(Shared.Remotes.InitAtoms):Server()

local subscriptions = {}
local ProfileCollection = ProfileStore.New(Server_Immutable.DATA_KEY, DataTemplate)

local DataService = {
	Profiles = {},
}

local function Initialize(Player: Player, Profile: typeof(ProfileCollection.StartSessionAsync()))
	local leaderstats = Instance.new("Folder")
	leaderstats.Name = "leaderstats"
	leaderstats.Parent = Player

	local Coins = Instance.new("IntValue")
	Coins.Name = "Coins"
	Coins.Value = Profile.Data.Coins
	Coins.Parent = leaderstats

	Atoms.DataStore((Immut.produce(Atoms.DataStore(), function(draft)
		draft[tostring(Player.UserId)] = Sift.Dictionary.copy(Profile.Data)
	end)))

	if not subscriptions[Player] then
		subscriptions[Player] = {}
	end
end

function DataService._Init(self: DataService)
	self.syncer = CharmSync.server({
		atoms = {
			DataStore = Atoms.DataStore,
		},
		interval = 0,
		autoSerialize = false,
	})

	self.syncer:connect(function(player, ...)
		SyncAtoms:Fire(player, ...)
	end)

	InitAtoms:On(function(player)
		local profile = self:GetProfileAsync(player)
		if profile then
			Atoms.DataStore((Immut.produce(Atoms.DataStore(), function(draft)
				draft[tostring(player.UserId)] = Sift.Dictionary.copy(profile.Data)
			end)))

			self.syncer:hydrate(player)
		else
			warn("No profile found for player:", player)
		end
	end)
end

function DataService.OnPlayerAdded(self: DataService, Player: Player)
	if DataService.Profiles[Player] then
		return
	end
	local Profile = ProfileCollection:StartSessionAsync(tostring(Player.UserId), {
		Cancel = function()
			return Player.Parent ~= game.Players
		end,
	})

	if Profile ~= nil then
		Profile:AddUserId(Player.UserId)
		Profile:Reconcile()

		Profile.OnSessionEnd:Connect(function()
			DataService.Profiles[Player] = nil
			Player:Kick(`Profile session end - Please rejoin`)
		end)

		if Player.Parent == game.Players then
			DataService.Profiles[Player] = Profile
			Initialize(Player, Profile)
			print(Profile)
		else
			Profile:EndSession()
		end
	else
		Player:Kick(`Profile load fail - Please rejoin`)
	end
end

function DataService.OnPlayerRemoving(self: DataService, Player: Player)
	local Profile = self:GetProfile(Player)
	local passedTime = os.time() - Player:GetAttribute("JoinTime")

	if Profile.Data.ClaimedReward1 and Profile.Data.TimeForReward1 <= 0 then
		Profile.Data.TimeForReward2 = math.max(Profile.Data.TimeForReward2 - passedTime, 0)
		return
	end

	if Profile.Data.TimeForReward1 > 0 then
		Profile.Data.TimeForReward1 = math.max(Profile.Data.TimeForReward1 - passedTime, 0)
	end
end

function DataService.Increment(self: DataService, Player: Player, Stat: string, incrementValue: number?)
	local Profile = DataService.Profiles[Player]
	local isLeaderstats = Player.leaderstats:FindFirstChild(Stat)

	Profile.Data[Stat] += incrementValue

	if isLeaderstats then
		Player.leaderstats[Stat].Value = Profile.Data[Stat]
	end

	local atomPath = Atoms.DataStore()[tostring(Player.UserId)]

	if atomPath then
		Atoms.DataStore((Immut.produce(Atoms.DataStore(), function(draft)
			draft[tostring(Player.UserId)][Stat] += incrementValue
		end)))

		self.syncer:hydrate(Player)
	end

	return Profile.Data[Stat]
end

function DataService.Decrement(self: DataService, Player: Player, Stat: string, decrementValue: number?)
	local Profile = DataService.Profiles[Player]
	local isLeaderstats = Player.leaderstats:FindFirstChild(Stat)

	Profile.Data[Stat] -= decrementValue

	if isLeaderstats then
		Player.leaderstats[Stat].Value = Profile.Data[Stat]
	end

	local atomPath = Atoms.DataStore()[tostring(Player.UserId)]

	if atomPath then
		Atoms.DataStore((Immut.produce(Atoms.DataStore(), function(draft)
			draft[tostring(Player.UserId)][Stat] -= decrementValue
		end)))

		self.syncer:hydrate(Player)
	end
end

function DataService.Set(self: DataService, Player: Player, Stat, ValueToSet)
	local Profile = DataService.Profiles[Player]
	local isLeaderstats = Player.leaderstats:FindFirstChild(Stat)

	Profile.Data[Stat] = ValueToSet

	if isLeaderstats then
		Player.leaderstats[Stat].Value = Profile.Data[Stat]
	end

	local atomPath = Atoms.DataStore()[tostring(Player.UserId)]

	if atomPath then
		Atoms.DataStore((Immut.produce(Atoms.DataStore(), function(draft)
			draft[tostring(Player.UserId)][Stat] = ValueToSet
		end)))

		self.syncer:hydrate(Player)
	end
end

function DataService.OnChange(self: DataService, player: Player, path: string, callback: (any) -> any)
	local userId = tostring(player.UserId)

	local pathAtom = Charm.computed(function()
		return Atoms.DataStore()[userId][path]
	end)

	local cleanup = Charm.subscribe(pathAtom, callback)

	if not subscriptions[player] then
		subscriptions[player] = {}
	end
	table.insert(subscriptions[player], cleanup)

	return cleanup
end

function DataService.GetStat(self: DataService, Player: Player, Stat)
	local Profile = self:GetProfileAsync(Player)
	return Profile.Data[Stat]
end

function DataService.GetProfile(self: DataService, Player: Player)
	local Profile = DataService.Profiles[Player]

	return Profile
end

function DataService.GetProfileAsync(self: DataService, Player: Player)
	local Profile = DataService.Profiles[Player]

	while not Profile do
		Profile = DataService.Profiles[Player]
		task.wait(0.2)
	end
	return Profile
end

type DataService = typeof(DataService) & {
	Profiles: { [Player]: { typeof(ProfileCollection.StartSessionAsync()) } },
}

return DataService
