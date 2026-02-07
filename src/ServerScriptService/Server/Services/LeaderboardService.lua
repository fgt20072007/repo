local DataStoreService = game:GetService("DataStoreService")
local MemoryStoreService = game:GetService("MemoryStoreService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")

local Shared = ReplicatedStorage.Shared

local Server = require(ServerScriptService.Server)
local GetLeaderboardRemote = require(Shared.Remotes.GetLeaderboard):Server()
local LeaderboardDataRemote = require(Shared.Remotes.LeaderboardData):Server()

local EXPIRATION_TIME = 86400 * 30

local LEADERBOARD_CONFIG = {
	Coins = {
		SortedMap = MemoryStoreService:GetSortedMap("Leaderboard_Coins"),
		OrderedStore = DataStoreService:GetOrderedDataStore("Leaderboard_Coins_v1"),
		StatName = "Coins",
	},
	Shards = {
		SortedMap = MemoryStoreService:GetSortedMap("Leaderboard_Shards"),
		OrderedStore = DataStoreService:GetOrderedDataStore("Leaderboard_Shards_v1"),
		StatName = "Shards",
	},
	Kills = {
		SortedMap = MemoryStoreService:GetSortedMap("Leaderboard_Kills"),
		OrderedStore = DataStoreService:GetOrderedDataStore("Leaderboard_Kills_v1"),
		StatName = "Kills",
	},
	PlayTime = {
		SortedMap = MemoryStoreService:GetSortedMap("Leaderboard_PlayTime"),
		OrderedStore = DataStoreService:GetOrderedDataStore("Leaderboard_PlayTime_v1"),
		StatName = "PlayTime",
	},
	Robux = {
		SortedMap = MemoryStoreService:GetSortedMap("Leaderboard_Robux"),
		OrderedStore = DataStoreService:GetOrderedDataStore("Leaderboard_Robux_v1"),
		StatName = "RobuxSpent",
	},
	BossWins = {
		SortedMap = MemoryStoreService:GetSortedMap("Leaderboard_BossWins"),
		OrderedStore = DataStoreService:GetOrderedDataStore("Leaderboard_BossWins_v1"),
		StatName = "BossWins",
	},
	KOTH = {
		SortedMap = MemoryStoreService:GetSortedMap("Leaderboard_KOTH"),
		OrderedStore = DataStoreService:GetOrderedDataStore("Leaderboard_KOTH_v1"),
		StatName = "KOTHTime",
	},
}

local MEMORY_UPDATE_INTERVAL = 10
local DATASTORE_BACKUP_INTERVAL = 300
local MAX_ENTRIES = 100

local LeaderboardService = {}

function LeaderboardService._Init(self: LeaderboardService)
	self.CachedLeaderboards = {}

	for name in LEADERBOARD_CONFIG do
		self.CachedLeaderboards[name] = {}
	end

	GetLeaderboardRemote:On(function(Player, LeaderboardName)
		local data = self:GetLeaderboard(Player, LeaderboardName)
		LeaderboardDataRemote:Fire(Player, LeaderboardName, data)
	end)

	task.spawn(function()
		task.wait(2)
		self:LoadFromDataStore()
		self:UpdateAllMemoryStore()
		self:FetchAllFromMemoryStore()

		local lastBackup = 0

		while true do
			task.wait(MEMORY_UPDATE_INTERVAL)
			self:UpdateAllMemoryStore()
			self:FetchAllFromMemoryStore()

			if os.clock() - lastBackup >= DATASTORE_BACKUP_INTERVAL then
				lastBackup = os.clock()
				self:BackupToDataStore()
			end
		end
	end)
end

function LeaderboardService.LoadFromDataStore(self: LeaderboardService)
	for name, config in LEADERBOARD_CONFIG do
		task.spawn(function()
			local success, pages = pcall(function()
				return config.OrderedStore:GetSortedAsync(false, MAX_ENTRIES)
			end)

			if not success or not pages then return end

			while true do
				local pageData = pages:GetCurrentPage()

				for _, entry in pageData do
					pcall(function()
						config.SortedMap:SetAsync(entry.key, entry.value, EXPIRATION_TIME)
					end)
				end

				if pages.IsFinished then break end

				pcall(function()
					pages:AdvanceToNextPageAsync()
				end)
			end
		end)
	end
end

function LeaderboardService.UpdateAllMemoryStore(self: LeaderboardService)
	for _, player in Players:GetPlayers() do
		local profile = Server.Services.DataService:GetProfile(player)
		if not profile then continue end

		for name, config in LEADERBOARD_CONFIG do
			local value = profile.Data[config.StatName]
			if not value or value <= 0 then continue end

			pcall(function()
				config.SortedMap:SetAsync(tostring(player.UserId), value, EXPIRATION_TIME)
			end)
		end
	end
end

function LeaderboardService.FetchAllFromMemoryStore(self: LeaderboardService)
	for name, config in LEADERBOARD_CONFIG do
		task.spawn(function()
			self:FetchFromMemoryStore(name, config)
		end)
	end
end

function LeaderboardService.FetchFromMemoryStore(self: LeaderboardService, Name: string, Config)
	local success, result = pcall(function()
		return Config.SortedMap:GetRangeAsync(Enum.SortDirection.Descending, MAX_ENTRIES)
	end)

	if not success or not result then return end

	local entries = {}

	for rank, item in result do
		table.insert(entries, {
			UserId = tonumber(item.key),
			Value = item.value,
			Rank = rank,
		})
	end

	self.CachedLeaderboards[Name] = entries
end

function LeaderboardService.BackupToDataStore(self: LeaderboardService)
	for name, config in LEADERBOARD_CONFIG do
		task.spawn(function()
			for _, player in Players:GetPlayers() do
				local profile = Server.Services.DataService:GetProfile(player)
				if not profile then continue end

				local value = profile.Data[config.StatName]
				if not value or value <= 0 then continue end

				pcall(function()
					config.OrderedStore:SetAsync(tostring(player.UserId), math.floor(value))
				end)
			end
		end)
	end
end

function LeaderboardService.GetLeaderboard(self: LeaderboardService, Player: Player, LeaderboardName: string)
	if not LEADERBOARD_CONFIG[LeaderboardName] then return {} end

	local cached = self.CachedLeaderboards[LeaderboardName]
	if cached and #cached > 0 then return cached end

	local config = LEADERBOARD_CONFIG[LeaderboardName]
	local entries = {}

	for index, player in Players:GetPlayers() do
		local profile = Server.Services.DataService:GetProfile(player)
		if not profile then continue end

		local value = profile.Data[config.StatName]
		if not value or value <= 0 then continue end

		table.insert(entries, {
			UserId = player.UserId,
			Value = value,
			Rank = 0,
		})
	end

	table.sort(entries, function(a, b)
		return a.Value > b.Value
	end)

	for rank, entry in entries do
		entry.Rank = rank
	end

	return entries
end

function LeaderboardService.GetPlayerStats(self: LeaderboardService, Player: Player)
	local profile = Server.Services.DataService:GetProfileAsync(Player)
	if not profile then return nil end

	return {
		Coins = profile.Data.Coins or 0,
		Shards = profile.Data.Shards or 0,
		Kills = profile.Data.Kills or 0,
		PlayTime = profile.Data.PlayTime or 0,
		KOTHTime = profile.Data.KOTHTime or 0,
		RobuxSpent = profile.Data.RobuxSpent or 0,
		BossWins = profile.Data.BossWins or 0,
	}
end

function LeaderboardService.OnPlayerAdded(self: LeaderboardService, Player: Player)
	task.spawn(function()
		while Player.Parent == Players do
			task.wait(60)
			local profile = Server.Services.DataService:GetProfile(Player)
			if profile then
				Server.Services.DataService:Increment(Player, "PlayTime", 60)
			end
		end
	end)
end

type LeaderboardService = typeof(LeaderboardService) & {
	CachedLeaderboards: { [string]: { { UserId: number, Value: number, Rank: number } } },
}

return LeaderboardService