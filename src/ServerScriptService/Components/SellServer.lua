-- Services
local ReplicatedStorage = game:GetService('ReplicatedStorage')
local Players = game:GetService('Players')

-- Variables

-- Dependencies
local DataService = require(ReplicatedStorage.Utilities.DataService)
local SharedFunctions = require(ReplicatedStorage.DataModules.SharedFunctions)
local SharedUtilities = require(ReplicatedStorage.Utilities.SharedUtilities)
local Format = require(ReplicatedStorage.Utilities.Format)

local RemoteBank = require(ReplicatedStorage.RemoteBank)

local InventoryHandler = require("./InventoryHandler")

local SellServer = {}

function SellServer.SellEntity(Player: Player, id)
	print("Selling entity")
	local Entityvalue, Name = SharedFunctions.GetValueFromId(id, Player)
	if Entityvalue and Name then
		DataService.server:update(Player, "cash", function(oldCash)
			return oldCash + Entityvalue
		end)
		
		DataService.server:set(Player, {"inventory", id}, false)
		
		for _, v in SharedUtilities.getToolsForBackpackAndEquipped(Player) do
			if v:HasTag("Entity") and v:IsA("Tool") then
				if v:GetAttribute("Id") == id then
					v:Destroy()
				end
			end
		end
		
		RemoteBank.SendNotification:FireClient(Player, "Succesfully sold " .. Name .. " for " .. Format.abbreviateCash(Entityvalue) .. "$" )
	end
end

function SellServer.SellAll(Player: Player)
	print("Selling all")
	DataService.server:update(Player, "inventory", function(old)
		local totalSum = 0
		for id, info in old do
			if info and typeof(info) == "table" and info.tag == "Entity" then
				local Entityvalue = SharedFunctions.GetValueFromId(id, Player)
				if Entityvalue then
					totalSum += Entityvalue
				end
			end
		end
		
		if totalSum == 0 then return old end
		
		DataService.server:update(Player, "cash", function(oldCash)
			return oldCash + totalSum
		end)
		
		RemoteBank.SendNotification:FireClient(Player, "Succesfully sold inventor for " .. Format.abbreviateCash(totalSum) .. "$" )
		
		return {}
	end)
	
	for _, v in SharedUtilities.getToolsForBackpackAndEquipped(Player) do
		if v:HasTag("Entity") and v:IsA("Tool") then
			v:Destroy()
		end
	end
end

-- Initialization function for the script
function SellServer:Initialize()
	RemoteBank.SellRemote.OnServerInvoke = function(player, type, id)
		if type == "SellAll" then
			SellServer.SellAll(player)
		elseif type == "Sell" then
			SellServer.SellEntity(player, id)
		end
	end
end

return SellServer
