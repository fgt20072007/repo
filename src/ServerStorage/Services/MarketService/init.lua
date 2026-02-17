local ServerStorage = game:GetService("ServerStorage")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local DataStoreService = game:GetService("DataStoreService")
local MarketplaceService = game:GetService("MarketplaceService")
local Players = game:GetService("Players")

local Packages = ReplicatedStorage.Packages
local Signal = require(Packages.Signal)

local Data = ReplicatedStorage.Data
local Passes = require(Data.Passes)
local DevProducts = require(Data.Products)

local Services = ServerStorage.Services
local DataService = require(Services.DataService)

local ReplicaServer = require(ServerStorage.Packages.ReplicaServer)

local Net = require(ReplicatedStorage.Packages.Net)
local GiftPassEvent = Net:RemoteEvent("GiftPass")
local NotifyEvent = Net:RemoteEvent("Notification")

-- 
local REPLICA_TOKEN = ReplicaServer.Token('Gamepasses')

local ID_TO_PASS: {[number]: string} = {}
local GIFT_PRODUCT_TO_PASS: {[number]: string} = {}
local PROD_TO_XP: {[number]: number} = {}
local PROD_TO_CASH:{[number]:number} = {}
local NORMALIZED_PASS_TO_NAME: {[string]: string} = {}

local PURCHASE_HANDLERS = {}

export type ReceiptInfo = {
	PurchaseId: number,
	PlayerId: number,
	ProductId: number,
	PlaceIdWherePurchased: number,
	CurrencySpent: number,
	CurrencyType: Enum.CurrencyType,
	ProductPurchaseChannel: Enum.ProductPurchaseChannel,
}

local MarketService = {
	PlayersReplica = {} :: {[Player]: ReplicaServer.Replica},
	PendingGifts = {} :: {[number]: {{TargetId: number, PassName: string, ProductId: number}}},
	HistoryDataStore = DataStoreService:GetDataStore("PurchaseHistory"),
	PendingGiftStore = DataStoreService:GetDataStore("PendingGifts"),
	GiftInboxStore = DataStoreService:GetDataStore("GiftInbox"),
	PurchasedPass = Signal.new() :: Signal.Signal<Player, string, string?>,
}

local function NormalizePassName(value: string): string
	return string.lower((string.gsub(value, "[^%w]+", "")))
end

local function ResolvePassNameFromMarketplaceId(passId: number): string?
	local ok, info = pcall(MarketplaceService.GetProductInfo, MarketplaceService, passId, Enum.InfoType.GamePass)
	if not ok or type(info) ~= "table" then
		return nil
	end

	local marketName = info.Name
	if type(marketName) ~= "string" or marketName == "" then
		return nil
	end

	if Passes[marketName] then
		return marketName
	end

	return NORMALIZED_PASS_TO_NAME[NormalizePassName(marketName)]
end

local function AppendPendingGift(userId: number, giftData: {TargetId: number, PassName: string, ProductId: number}): boolean
	local success = pcall(
		MarketService.PendingGiftStore.UpdateAsync,
		MarketService.PendingGiftStore,
		tostring(userId),
		function(current)
			local list = type(current) == "table" and current or {}
			table.insert(list, giftData)
			return list
		end
	)
	return success
end

local function GetPendingGift(userId: number, productId: number, passName: string): {TargetId: number, PassName: string, ProductId: number}?
	local success, current = pcall(
		MarketService.PendingGiftStore.GetAsync,
		MarketService.PendingGiftStore,
		tostring(userId)
	)
	if not success or type(current) ~= "table" then return end
	for _, entry in ipairs(current) do
		if entry.ProductId == productId and entry.PassName == passName then
			return entry
		end
	end
end

local function RemovePendingGift(userId: number, productId: number, passName: string): boolean
	local success = pcall(
		MarketService.PendingGiftStore.UpdateAsync,
		MarketService.PendingGiftStore,
		tostring(userId),
		function(current)
			local list = type(current) == "table" and current or {}
			for i, entry in ipairs(list) do
				if entry.ProductId == productId and entry.PassName == passName then
					table.remove(list, i)
					break
				end
			end
			if #list == 0 then
				return nil
			end
			return list
		end
	)
	return success
end

local function QueueGiftInbox(targetId: number, passName: string): boolean
	local success = pcall(
		MarketService.GiftInboxStore.UpdateAsync,
		MarketService.GiftInboxStore,
		tostring(targetId),
		function(current)
			local list = type(current) == "table" and current or {}
			table.insert(list, passName)
			return list
		end
	)
	return success
end

function MarketService._GetExpHandlerForId(id: number): (string?, any)
	local xpTier = PROD_TO_XP[id]
	if xpTier then return "XP", xpTier end

	local CashTier = PROD_TO_CASH[id]
	if PROD_TO_CASH[id] then return "Cash", CashTier end
	return
end

function MarketService._ProcessReceipt(receiptInfo: ReceiptInfo): Enum.ProductPurchaseDecision
	local success, result = pcall(
		MarketService.HistoryDataStore.UpdateAsync,
		MarketService.HistoryDataStore,
		receiptInfo.PurchaseId,
		function(wasPurchased: boolean?): boolean?
			if wasPurchased then return true end

			local giftPassName = GIFT_PRODUCT_TO_PASS[receiptInfo.ProductId]
			if giftPassName then
				local player = Players:GetPlayerByUserId(receiptInfo.PlayerId)
				local pendingList = MarketService.PendingGifts[receiptInfo.PlayerId]
				local pending
				local pendingIndex
				if pendingList then
					for i, entry in ipairs(pendingList) do
						if entry.ProductId == receiptInfo.ProductId and entry.PassName == giftPassName then
							pending = entry
							pendingIndex = i
							break
						end
					end
				end

				if not pending then
					pending = GetPendingGift(receiptInfo.PlayerId, receiptInfo.ProductId, giftPassName)
				end

				if not pending then
					if player then NotifyEvent:FireClient(player, "GiftPass/PlayerNotFound") end
					return
				end

				local function finalizePending()
					if pendingList and pendingIndex then
						table.remove(pendingList, pendingIndex)
						if #pendingList == 0 then
							MarketService.PendingGifts[receiptInfo.PlayerId] = nil
						end
					end
					RemovePendingGift(receiptInfo.PlayerId, receiptInfo.ProductId, giftPassName)
				end

				local target = Players:GetPlayerByUserId(pending.TargetId)
				if not target then
					local queued = QueueGiftInbox(pending.TargetId, giftPassName)
					if not queued then return end
					finalizePending()
					if player then NotifyEvent:FireClient(player, "GiftPass/PassGiftSuccess") end
					return true
				end

				if not MarketService._GetReplicaFor(target) then
					local queued = QueueGiftInbox(pending.TargetId, giftPassName)
					if not queued then return end
					finalizePending()
					if player then NotifyEvent:FireClient(player, "GiftPass/PassGiftSuccess") end
					return true
				end

				MarketService._ForceOwnership(target, Passes[giftPassName])
				finalizePending()
				if player then NotifyEvent:FireClient(player, "GiftPass/PassGiftSuccess") end
				NotifyEvent:FireClient(target, "GiftPass/PassGiftReceived")
				return true
			end

			local player = Players:GetPlayerByUserId(receiptInfo.PlayerId)
			if not player then return end

			local handlerName, handlerData = MarketService._GetExpHandlerForId(receiptInfo.ProductId)
			local handler = handlerName and PURCHASE_HANDLERS[handlerName] or nil

			if not handler then
				warn(`[MarketService] No handler for ProductId: {receiptInfo.ProductId}`)
				return
			end

			local processed, response = pcall(handler, receiptInfo, player, handlerData)
			if not processed then
				warn(`[MarketService] Failed to process purchase for ProductId: {receiptInfo.ProductId} - {response}`)
				return
			end
			return if response~=true then nil else true
		end
	)

	if not success then
		warn(`Failed to process receipt due to data store error: {result}`)
		return Enum.ProductPurchaseDecision.NotProcessedYet
	end

	return if result == true
		then Enum.ProductPurchaseDecision.PurchaseGranted
		else Enum.ProductPurchaseDecision.NotProcessedYet
end

function MarketService._FetchOwnershipFor(player: Player, id: number): boolean?
	if not (player and id) then return end

	local success, response = pcall(
		MarketplaceService.UserOwnsGamePassAsync,
		MarketplaceService,
		player.UserId,
		id
	)

	return if success then response else nil
end

function MarketService._ClearReplicaFor(player: Player)
	local replica = MarketService.PlayersReplica[player]
	if not replica then return end

	replica:Destroy()
	MarketService.PlayersReplica[player] = nil
end

function MarketService._GetReplicaFor(player: Player): ReplicaServer.Replica?
	return MarketService.PlayersReplica[player]
end

function MarketService._ForceOwnership(player: Player, id: number)
	local fixedId: string = ID_TO_PASS[id]
	if not fixedId then
		local resolved = ResolvePassNameFromMarketplaceId(id)
		if resolved then
			fixedId = resolved
			ID_TO_PASS[id] = resolved
		else
			warn(`[MarketService] Unknown gamepass id for ownership grant: {id}`)
			return
		end
	end

	local replica = MarketService._GetReplicaFor(player)
	if not replica then return end

	replica:Set({fixedId}, true)
	MarketService.PurchasedPass:Fire(player, fixedId, "purchase")
	return DataService.InsertPass(player, fixedId)-- and MarketService.OwnsPass(player, fixedId)
end

function MarketService._RemoveOwnership(player: Player, id: number)
	local fixedId: string = ID_TO_PASS[id]
	if not fixedId then  return end

	local replica = MarketService._GetReplicaFor(player)
	if not replica then return end

	replica:Set({fixedId}, false)
	return DataService.RemovePass(player, fixedId)-- and MarketService.OwnsPass(player, fixedId)
end

function MarketService._LoadPlayer(player: Player)
	if MarketService._GetReplicaFor(player) then return end

	local replica = ReplicaServer.New({
		Token = REPLICA_TOKEN,
		Tags = {UserId = player.UserId},
		Data = {},
	})

	replica:Subscribe(player)
	MarketService.PlayersReplica[player] = replica

	for passName, _ in Passes do
		--TODO: Hacer que el gamepass manager se ejecute para el jugador
		MarketService.OwnsPass(player, passName)
	end

	MarketService._ConsumeGiftInbox(player)
end

function MarketService._ConsumeGiftInbox(player: Player)
	local inbox
	local success = pcall(
		MarketService.GiftInboxStore.UpdateAsync,
		MarketService.GiftInboxStore,
		tostring(player.UserId),
		function(current)
			if type(current) ~= "table" or #current == 0 then
				return nil
			end
			inbox = current
			return nil
		end
	)

	if not success or not inbox then return end

	for _, passName in ipairs(inbox) do
		local passId = Passes[passName]
		if passId and not MarketService.OwnsPass(player, passName) then
			MarketService._ForceOwnership(player, passId)
		end
	end
end

function MarketService.OwnsPass(player: Player, passName: string): boolean?
	if not  Passes[passName] then return end

	local replica = MarketService._GetReplicaFor(player)
	if not replica then return end

	if replica.Data[passName] == nil then
		local manager = DataService.GetManager("PlayerData")
		local gifted = manager and manager:Get(player, {'GiftedPasses'}) or nil
		local hasGiftedPass = gifted and table.find(gifted, passName) ~= nil or false

		local owns: boolean?
		if hasGiftedPass then
			owns = true
		else
			local passId = Passes[passName]
			owns = MarketService._FetchOwnershipFor(player, passId)
		end

			if owns ~= nil then
				local current = MarketService._GetReplicaFor(player)
				if not current or current ~= replica then return owns end
				if not player.Parent then return owns end
				current:Set({passName}, owns)
				if owns and not hasGiftedPass then
					local inserted = DataService.InsertPass(player, passName)
					if inserted then
						MarketService.PurchasedPass:Fire(player, passName, "sync")
					end
				end
				return owns
			end
	end

	return replica.Data[passName] == true
end

function MarketService.Start() 

end

function MarketService.Init()
	for tier, data in DevProducts.XP do
		PROD_TO_XP[data.ProductId] = tier
	end

	for tier, data in DevProducts.Cash do
		PROD_TO_CASH[data.ProductId] = tier
	end

	for id, passId in Passes do
		ID_TO_PASS[passId] = id
		if string.sub(id, 1, 5) ~= "Gift " then
			NORMALIZED_PASS_TO_NAME[NormalizePassName(id)] = id
		end
		if string.sub(id, 1, 5) == "Gift " then
			local baseName = string.sub(id, 6)
			GIFT_PRODUCT_TO_PASS[passId] = baseName
		end
	end

	for _, module in script.Handlers:GetChildren() do
		if not module:IsA('ModuleScript') then continue end
		PURCHASE_HANDLERS[module.Name] = require(module) :: any
	end

	-- Pass gifting event
	GiftPassEvent.OnServerEvent:Connect(function(player: Player, passId:number, TargetPlayerName:string) 
		local TargetPlayer = nil
		for _, p in game.Players:GetChildren() do
			if string.lower(TargetPlayerName) == string.lower(p.Name) then
				TargetPlayer = p
				break
			end
		end

		if not TargetPlayer then NotifyEvent:FireClient(player, "GiftPass/PlayerNotFound"); return end

		local fixedid = ID_TO_PASS[passId]
		if not fixedid then return end

		local passName = fixedid
		local giftProductId = nil
		if string.sub(fixedid, 1, 5) == "Gift " then
			passName = string.sub(fixedid, 6)
			giftProductId = passId
		else
			local giftKey = `Gift {fixedid}`
			giftProductId = Passes[giftKey]
		end
		if not giftProductId then return end

		local alreadyOwned = MarketService.OwnsPass(TargetPlayer, passName)
		if alreadyOwned then NotifyEvent:FireClient(player, "GiftPass/AlreadyOwned"); return end

		local pendingList = MarketService.PendingGifts[player.UserId]
		if type(pendingList) ~= "table" then
			pendingList = {}
			MarketService.PendingGifts[player.UserId] = pendingList
		end
		local entry = {
			TargetId = TargetPlayer.UserId,
			PassName = passName,
			ProductId = giftProductId,
		}
		table.insert(pendingList, entry)
		AppendPendingGift(player.UserId, entry)

		MarketplaceService:PromptProductPurchase(player, giftProductId)
	end)

	-- MarketplaceService Setup
	MarketplaceService.ProcessReceipt = MarketService._ProcessReceipt
	MarketplaceService.PromptGamePassPurchaseFinished:Connect(function(
		player: Player, passId: number, wasPurchased: boolean
	)
		if not wasPurchased then return end
		MarketService._ForceOwnership(player, passId)
	end)

	-- Player Setup
	Players.PlayerRemoving:Connect(MarketService._ClearReplicaFor)
	DataService.PlayerLoaded:Connect(function(player)
		MarketService._LoadPlayer(player)
	end)

	task.spawn(function()
		for _, player in DataService.GetLoaded() do
			task.spawn(MarketService._LoadPlayer, player)
		end
	end)
end

return MarketService
