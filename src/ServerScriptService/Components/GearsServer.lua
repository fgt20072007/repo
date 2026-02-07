-- Services
local ReplicatedStorage = game:GetService('ReplicatedStorage')
local Players = game:GetService('Players')

-- Variables

-- Dependencies
local DataService = require(ReplicatedStorage.Utilities.DataService)
local Gears = require(ReplicatedStorage.DataModules.Gears)
local RemoteBank = require(ReplicatedStorage.RemoteBank)

local InventoryHandler = require("./InventoryHandler")

local GearsServer = {}

-- Initialization function for the script
function GearsServer:Initialize()
	RemoteBank.PurchaseGear.OnServerInvoke = function(player, gearname)
		local Informations = Gears[gearname]
		if Informations then
			local gears = DataService.server:get(player, "gears")
			if table.find(gears, gearname) then
				return "You already own this gear", Color3.new(1, 0.137255, 0.137255)
			else
				local Price = Informations.Price
				
				local purchased = false
				DataService.server:update(player, "cash", function(old)
					if old >= Price then
						DataService.server:arrayInsert(player, "gears", gearname)
						
						purchased = true
						
						InventoryHandler.AddToolsAndClear(player)
						
						return old - Price
					end
					
					return old
				end)
				
				if purchased then
					return "Succesfully purchased " .. gearname, Color3.new(0.65098, 1, 0)
				else
					return "You don't have enough to buy " .. gearname, Color3.new(1, 0.172549, 0.172549)
				end
			end
		else
			return "Cant find the gear in the data module"
		end
	end
end

return GearsServer
