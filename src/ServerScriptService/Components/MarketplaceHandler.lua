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

local Gears = require(ReplicatedStorage.DataModules.Gears)
local InventoryHandler = require("./InventoryHandler")

local Zones = require(ReplicatedStorage.DataModules.Zones)

local SignalBank = require(ServerStorage.SignalBank)

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

local Receiving = {}
local MarketplaceHandler = {}

local InProcessing = {}

function MarketplaceHandler.Purchase(Player, IsGamepass, Id, ...)
	if not Id or IsGamepass == nil then return end
	local processedSignal = Signal.new()
	InProcessing[Player] = processedSignal
	
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
				local arguments = Receiving[Player][ProcessReceipt.ProductId] or {}
				devProductFunction(Player, table.unpack(arguments))
			end		
			
			return Enum.ProductPurchaseDecision.PurchaseGranted
		end
		return Enum.ProductPurchaseDecision.NotProcessedYet
	end

	MarketplaceService.PromptGamePassPurchaseFinished:Connect(function(a0: Player, a1: number, a2: boolean)
		InProcessing[a0]:Fire(a2)
		InProcessing[a0]:Destroy(a2)
		
		if a2 then
			Fireworks.PlayFireworks(a0)
			RemoteBank.SendNotification:FireClient(a0, "Thanks for purchasing! ❤️")
			RemoteBank.Confetti:FireClient(a0, 40)
			InventoryHandler.AddToolsAndClear(a0)
		end
	end)
	
	MarketplaceService.PromptProductPurchaseFinished:Connect(function(userid, productid, ispurchased)
		local player = Players:GetPlayerByUserId(userid)
		InProcessing[player]:Fire(ispurchased)
		InProcessing[player]:Destroy()
		if ispurchased then
			Fireworks.PlayFireworks(player)
			RemoteBank.SendNotification:FireClient(player, "Thanks for purchasing! ❤️")
			RemoteBank.Confetti:FireClient(player, 40)
		end
	end)

	RemoteBank.Purchase.OnServerInvoke = MarketplaceHandler.Purchase
	
	Players.PlayerAdded:Connect(function(Player)
		Receiving[Player] = {}
	end)
end

return MarketplaceHandler
