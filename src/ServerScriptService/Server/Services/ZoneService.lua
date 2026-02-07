local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")
local Shared = ReplicatedStorage:WaitForChild("Shared")

local Server = require(ServerScriptService.Server)
local Networker = require(Shared.Packages.networker)
local RankData = require(Shared.Data.Ranks)

local ZoneService = {}

function ZoneService._Init(self: ZoneService)
	self.Networker = Networker.server.new("ZoneService", self, {
		self.ConvertSkulls,
	})
end

function ZoneService.ConvertSkulls(self: ZoneService, Player: Player)
	local DataService = Server.Services.DataService
	local Skulls = DataService:GetStat(Player, "Skulls")
	local Profile = DataService:GetProfile(Player)
	local equippedRank = Profile and Profile.Data and Profile.Data.EquippedRank
	local rankInfo = RankData.Sorted[equippedRank] or RankData.Sorted.Rank1
	local coinBoost = rankInfo and rankInfo.Boosts and rankInfo.Boosts.Coins or 1
	local coinsToAdd = math.floor(Skulls * coinBoost)
	if coinsToAdd < 0 then coinsToAdd = 0 end

	DataService:Set(Player, "Skulls", 0)
	DataService:Increment(Player, "Coins", coinsToAdd)
end

type ZoneService = typeof(ZoneService) & {
	Networker: Networker.Client,
}

return ZoneService
