-- Services
local ReplicatedStorage = game:GetService('ReplicatedStorage')
local Players = game:GetService('Players')
local ServerStorage = game:GetService('ServerStorage')

-- Variables

-- Dependencies
local DataService = require(ReplicatedStorage.Utilities.DataService)
local SharedFunctions = require(ReplicatedStorage.DataModules.SharedFunctions)
local RemoteBank = require(ReplicatedStorage.RemoteBank)
local EconomyCalculations = require(ReplicatedStorage.DataModules.EconomyCalculations)
local GlobalConfiguration = require(ReplicatedStorage.DataModules.GlobalConfiguration)

local StandController = require("./StandHandler")
local PlotController = require("./PlotHandler")

local SignalBank = require(ServerStorage.SignalBank)

local UpgradesHandler = {}

function getMultiplePrice(startingLevel, extra, callback)
	local total = 0
	for i = startingLevel + 1, startingLevel + extra do
		total += callback(i)
	end
	return total
end

local list = {
	GrabUpgrade = function(plr, force)
		DataService.server:update(plr, "cash", function(old)
			local price = EconomyCalculations.calculateGrabUpgradePrice(DataService.server:get(plr, "grabAmount") + 1)
			if old >= price or force then
				DataService.server:update(plr, "grabAmount", function(old)
					return old + 1
				end)
				
				RemoteBank.SendNotification:FireClient(plr, "Purchased +1 Grab upgrade", Color3.new(0.517647, 1, 0))

				return not force and old - price or old
			else
				RemoteBank.SendNotification:FireClient(plr, "You don't have enough to purchase", Color3.new(1, 0, 0))
			end
			return old
		end)
	end,
	StandUpgrade = function(plr, force)
		local NumberOfStands = #DataService.server:get(plr, "stands")
		if NumberOfStands >= GlobalConfiguration.MaxFloors * GlobalConfiguration.StandsPerFloor then
			RemoteBank.SendNotification:FireClient(plr, "Max amount of stands reached", Color3.new(1, 0, 0))
			
			return
		end
		DataService.server:update(plr, "cash", function(old)
			local price = EconomyCalculations.calculateSlowUpgradePrice(NumberOfStands + 1)
			if old >= price or force then
				StandController.CreateNewStand(plr, PlotController.getAndWaitForPlot(plr), true)

				RemoteBank.SendNotification:FireClient(plr, "Purchased +1 Stand", Color3.new(0.517647, 1, 0))

				return not force and old - price or old
			else
				RemoteBank.SendNotification:FireClient(plr, "You don't have enough to purchase", Color3.new(1, 0, 0))
			end
			return old
		end)
	end,
	SpeedUpgrade = function(plr, amount, force)
		local numbered = tonumber(amount)
		if numbered then
			DataService.server:update(plr, "cash", function(old)
				local price = getMultiplePrice(DataService.server:get(plr, "speed"), amount, EconomyCalculations.calculateExponentialPrice)
				if old >= price or force then
					DataService.server:update(plr, "speed", function(old)
						return old + amount
					end)
					
					RemoteBank.SendNotification:FireClient(plr, "Purchased +" .. amount .. " Speed", Color3.new(0.517647, 1, 0))
					
					return not force and old - price or old
				else
					RemoteBank.SendNotification:FireClient(plr, "You don't have enough to purchase", Color3.new(1, 0, 0))
				end
				return old
			end)
		end
	end,
}

function UpgradesHandler.Upgrade(player, upgradeName, force)
	if list[upgradeName] then
		list[upgradeName](player, force)
	else
		list.SpeedUpgrade(player, upgradeName, force)
	end
end

-- Initialization function for the script
function UpgradesHandler:Initialize()
	SignalBank.UpgradeAdd:Connect(UpgradesHandler.Upgrade)
	
	RemoteBank.PurchaseUpgrade.OnServerEvent:Connect(function(player, upgradeName)
		UpgradesHandler.Upgrade(player, upgradeName)
	end)
end

return UpgradesHandler
