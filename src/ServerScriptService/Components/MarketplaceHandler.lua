local MarketplaceService = game:GetService("MarketplaceService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService('ReplicatedStorage')
local MessagingService = game:GetService("MessagingService")
local ServerStorage = game:GetService('ServerStorage')

local Zone = require(ReplicatedStorage.Utilities.Zone)
local DataService = require(ReplicatedStorage.Utilities.DataService)
local GlobalConfiguration = require(ReplicatedStorage.DataModules.GlobalConfiguration)

local Signal = require(ReplicatedStorage.Utilities.Signal)
local RemoteBank = require(ReplicatedStorage.RemoteBank)

local DevProductsInformations = require(ReplicatedStorage.DataModules.DevProducts)
local Fireworks = require(ReplicatedStorage.Utilities.Fireworks)

local DevProducts = require(ReplicatedStorage.DataModules.DevProducts)
local ServerUtilities = require(ServerStorage.ServerUtilities)

local Bases = require(ReplicatedStorage.DataModules.Bases)
local Gears = require(ReplicatedStorage.DataModules.Gears)
local InventoryHandler = require("./InventoryHandler")
local GamepassHandler = require("./GamepassHandler")

local Zones = require(ReplicatedStorage.DataModules.Zones)

local SignalBank = require(ServerStorage.SignalBank)
local PURCHASED_BASE_NOTIFICATION_COLOR = Color3.new(0.45098, 1, 0)

local function unlockBaseForPlayer(plr: Player, baseNumber: number)
	local baseSchema = Bases[baseNumber]
	if not plr or not baseSchema then
		return
	end

	local ownedBases = DataService.server:get(plr, "bases")
	if table.find(ownedBases, baseNumber) then
		return
	end

	DataService.server:arrayInsert(plr, "bases", baseNumber)
	RemoteBank.SendNotification:FireClient(plr, "Purchased base", PURCHASED_BASE_NOTIFICATION_COLOR)
end

local DevProductsData = {
	[DevProducts.StarterPack.Id] = function(plr)
		ServerUtilities.ParseTableForRewards(plr, DevProducts.StarterPack.Rewards)
	end,
	[DevProducts.ProPack.Id] = function(plr)
		ServerUtilities.ParseTableForRewards(plr, DevProducts.ProPack.Rewards)
	end,
	[DevProducts.SecretPack.Id] = function(plr)
		ServerUtilities.ParseTableForRewards(plr, DevProducts.SecretPack.Rewards)
	end,
	[DevProducts.InsanePack.Id] = function(plr)
		ServerUtilities.ParseTableForRewards(plr, DevProducts.InsanePack.Rewards)
	end,

	[DevProducts.MythicalUnit.Id] = function(plr)
		ServerUtilities.ParseTableForRewards(plr, {[DevProducts.MythicalUnit.EntityName] = "Entity"})
	end,
	[DevProducts.SecretUnit.Id] = function(plr)
		ServerUtilities.ParseTableForRewards(plr, {[DevProducts.SecretUnit.EntityName] = "Entity"})
	end,
	[DevProducts.CosmicUnit.Id] = function(plr)
		ServerUtilities.ParseTableForRewards(plr, {[DevProducts.CosmicUnit.EntityName] = "Entity"})
	end,

	[DevProducts.Cash1.Id] = function(plr)
		DataService.server:update(plr, "cash", function(old)
			return old + DevProducts.Cash1.Amount
		end)
	end,
	[DevProducts.Cash2.Id] = function(plr)
		DataService.server:update(plr, "cash", function(old)
			return old + DevProducts.Cash2.Amount
		end)
	end,
	[DevProducts.Cash3.Id] = function(plr)
		DataService.server:update(plr, "cash", function(old)
			return old + DevProducts.Cash3.Amount
		end)
	end,
	[DevProducts.Cash4.Id] = function(plr)
		DataService.server:update(plr, "cash", function(old)
			return old + DevProducts.Cash4.Amount
		end)
	end,
}

for _, v in DevProducts.Stealables do
	DevProductsData[v] = function(plr, extraEntityInfo, standNumber, otherPlayer)
		if plr and extraEntityInfo then
			InventoryHandler.CacheTool(plr, "Entity", extraEntityInfo)
			if GlobalConfiguration.StealEntities then
				SignalBank.ClearEntityOnStand:Fire(otherPlayer, standNumber)
			end
		end
	end
end

for i, v in Gears do
	DevProductsData[v.RobuxId] = function(plr)
		DataService.server:arrayInsert(plr, "gears", i)
		InventoryHandler.AddToolsAndClear(plr)
	end
end

for baseNumber, baseSchema in Bases do
	local baseDevProductId = baseSchema.BaseDevProductId
	if type(baseDevProductId) == "number" and baseDevProductId > 0 then
		DevProductsData[baseDevProductId] = function(plr)
			unlockBaseForPlayer(plr, baseNumber)
		end
	end
end

local Receiving = {}
local MarketplaceHandler = {}

local InProcessing = {}

function MarketplaceHandler.Purchase(Player, IsGamepass, Id, ...)
	if not Id or IsGamepass == nil then return end

	local previousSignal = InProcessing[Player]
	if previousSignal then
		previousSignal:Destroy()
	end

	local processedSignal = Signal.new()
	InProcessing[Player] = processedSignal
	Receiving[Player] = Receiving[Player] or {}

	if IsGamepass then
		MarketplaceService:PromptGamePassPurchase(Player, tonumber(Id))
	else
		Receiving[Player][Id] = {...}
		MarketplaceService:PromptProductPurchase(Player, tonumber(Id))
	end
	return processedSignal
end

function MarketplaceHandler.Initialize()
	MarketplaceService.ProcessReceipt = function(ProcessReceipt)
		local Player = Players:GetPlayerByUserId(ProcessReceipt.PlayerId)
		if Player then
			local devProductFunction = DevProductsData[ProcessReceipt.ProductId]
			if devProductFunction then
				local playerReceiving = Receiving[Player] or {}
				local arguments = playerReceiving[ProcessReceipt.ProductId] or {}
				playerReceiving[ProcessReceipt.ProductId] = nil
				Receiving[Player] = playerReceiving
				devProductFunction(Player, table.unpack(arguments))
			end		

			return Enum.ProductPurchaseDecision.PurchaseGranted
		end
		return Enum.ProductPurchaseDecision.NotProcessedYet
	end

	MarketplaceService.PromptGamePassPurchaseFinished:Connect(function(a0: Player, a1: number, a2: boolean)
		GamepassHandler.HandleGamepassPurchaseFinished(a0, a1, a2)

		local signal = InProcessing[a0]
		if signal then
			signal:Fire(a2)
			signal:Destroy()
			InProcessing[a0] = nil
		end

		if a2 then
			Fireworks.PlayFireworks(a0)
			RemoteBank.SendNotification:FireClient(a0, "Thanks for purchasing! ❤️")
			RemoteBank.Confetti:FireClient(a0, 40)
			InventoryHandler.AddToolsAndClear(a0)
		end
	end)

	MarketplaceService.PromptProductPurchaseFinished:Connect(function(userid, productid, ispurchased)
		local player = Players:GetPlayerByUserId(userid)
		if not player then
			return
		end

		local signal = InProcessing[player]
		if signal then
			signal:Fire(ispurchased)
			signal:Destroy()
			InProcessing[player] = nil
		end
		if ispurchased then
			Fireworks.PlayFireworks(player)
			RemoteBank.SendNotification:FireClient(player, "Thanks for purchasing! ❤️")
			RemoteBank.Confetti:FireClient(player, 40)
		end
	end)

	RemoteBank.Purchase.OnServerInvoke = MarketplaceHandler.Purchase

	for _, player in Players:GetPlayers() do
		Receiving[player] = {}
	end

	Players.PlayerAdded:Connect(function(Player)
		Receiving[Player] = {}
	end)

	Players.PlayerRemoving:Connect(function(Player)
		Receiving[Player] = nil
		InProcessing[Player] = nil
	end)
end

return MarketplaceHandler