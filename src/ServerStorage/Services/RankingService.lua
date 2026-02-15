--!strict
local ReplicatedStorage = game:GetService 'ReplicatedStorage'
local ServerStorage = game:GetService "ServerStorage"
local MarketplaceService = game:GetService 'MarketplaceService'
local Players = game:GetService 'Players'

local Packages = ReplicatedStorage.Packages
local Net = require(Packages.Net)
local RateLimit = require(Packages.ReplicaShared.RateLimit)

local Data = ReplicatedStorage.Data
local RanksData = require(Data.Ranks)
local Products = require(Data.Products)
local GeneralData = require(Data.General)

local Services = ServerStorage.Services
local DataService = require(Services.DataService)

export type Transaction = 'Purchase'|'Kill'|'Arrest'|'Playtime'

-- Util
local function GetUnlockedInBetween(
	ranks: {RanksData.RankData},
	current: number, goal: number
): {number}
	local found = {}
	
	for id, data in ranks do
		if data.Requirement <= current
			or data.Requirement > goal
		then continue end
		
		table.insert(found, id)
	end
	
	return found
end

-- Service
local PromptPurchase = Net:RemoteEvent('PurchaseXP')
local NotifEvent = Net:RemoteEvent('XPTransaction')

local RankingService = {
	PurchaseTarget = {} :: {[Player]: string},
	PlaytimeThreads = {} :: {[Player]: thread},
}

function RankingService.GetCurrentInstitution(player: Player): string?
	local plrTeam = player.Team
	if not plrTeam then return nil end
	
	for id, data in RanksData do
		if not table.find(data.Teams, plrTeam.Name) then continue end
		return id
	end
	
	return nil
end

function RankingService.GetCurrentRank(player: Player)
	
end

function RankingService._AwardInBetween(
	player: Player, instData: RanksData.InstitutionData,
	current: number, target: number
)
	local toUnlock = GetUnlockedInBetween(instData.Ranks, current, target)
	for _, id in toUnlock do
		local rankData = instData.Ranks[id]
		if not (rankData and rankData.Reward) then continue end
		
		DataService.AdjustBalance(player, math.abs(rankData.Reward))
	end
end

function RankingService.AdjustInstitutionXP(player: Player, id: string, amount: number, transType: Transaction?): boolean
	local instData = RanksData[id]
	if not instData then return false end
	
	local current = DataService.GetInstitutionXP(player, id) or 0
	local target = current + amount
	
	local success = DataService._AdjustInstitutionXP(player, id, amount)
	if not success then return false end
	
	if amount > 0 then
		RankingService._AwardInBetween(player, instData, current, target)
		task.spawn(NotifEvent.FireClient, NotifEvent, player, amount, transType)
	end

	return true
end

function RankingService.AdjustXP(player: Player, amount: number, transType: Transaction?): boolean
	local current = RankingService.GetCurrentInstitution(player)
	if not current then return false end
	
	return RankingService.AdjustInstitutionXP(player, current, amount, transType)
end

function RankingService._GrantPurchase(player: Player, amount: number): boolean
	local target = RankingService.PurchaseTarget[player]
	if not target then return false end
	
	return RankingService.AdjustInstitutionXP(player, target, amount, 'Purchase')
end

function RankingService._BindPlayer(player: Player)
	if RankingService.PlaytimeThreads[player] then return end
	
	RankingService.PlaytimeThreads[player] = task.spawn(function()
		while player:IsDescendantOf(Players) do
			task.wait(GeneralData.PlaytimeEvery)
			RankingService.AdjustXP(player, GeneralData.PlaytimeXP, 'Playtime')
		end
	end)
end

function RankingService._UnBindPlayer(player: Player)
	RankingService.PurchaseTarget[player] = nil
	
	local thread = RankingService.PlaytimeThreads[player]
	if not thread then return end
	
	RankingService.PlaytimeThreads[player] = nil
	pcall(task.cancel, thread)
end

function RankingService.Init()
	DataService.PlayerLoaded:Connect(RankingService._BindPlayer)
	Players.PlayerRemoving:Connect(RankingService._UnBindPlayer)
	
	PromptPurchase.OnServerEvent:Connect(function(player: Player, institution: string, tier: number)
		if not RanksData[institution] then return end
		
		local prodData = Products.XP[tier]
		if not prodData then return end
		
		RankingService.PurchaseTarget[player] = institution
		MarketplaceService:PromptProductPurchase(player, prodData.ProductId)
	end)
	
	task.spawn(function()
		for _, player in DataService.GetLoaded() do
			RankingService._BindPlayer(player)
		end
	end)
end

return RankingService