-- Services
local ReplicatedStorage = game:GetService('ReplicatedStorage')
local Players = game:GetService('Players')

-- Variables
local Gui = Players.LocalPlayer.PlayerGui:WaitForChild("MainGui")
local Frames = Gui.Frames
local SellFrame = Frames.SellFrame

local Container = SellFrame.Container

local SellAllButton = Container.InventoryValue.SellAll
local SellLabel = Container.InventoryValue.SellValueLabel
local ScrollingFrame = Container.ScrollingFrame

-- Dependencies
local DataService = require(ReplicatedStorage.Utilities.DataService)
local SharedFunctions = require(ReplicatedStorage.DataModules.SharedFunctions)
local Format = require(ReplicatedStorage.Utilities.Format)

local Rarities = require(ReplicatedStorage.DataModules.Rarities)
local Entities = require(ReplicatedStorage.DataModules.Entities)
local RemoteBank = require(ReplicatedStorage.RemoteBank)
local Janitor = require(ReplicatedStorage.Utilities.Janitor)

local ViewportHandler = require("../ViewportsHandler")

local Frame = {}
local janitor = Janitor.new()

function Frame.UpdateGui()
	janitor:Cleanup()
	
	local inventoryData = DataService.client:get("inventory")
	local TotalAmount = 0
	
	local Cache = {}
	
	for id, value in inventoryData do
		if value and typeof(value) == "table" and value.tag == "Entity" then
			local entitySellValue, name, mutation = SharedFunctions.GetValueFromId(id)
			if entitySellValue then
				TotalAmount += entitySellValue
				if Cache[name .. mutation] then
					Cache[name .. mutation]()
					continue
				end

				local informations = Entities[name]
				if not informations then warn("No informations for " .. name .. " could not be found.") end
				local gradient = Rarities[informations.Rarity].Gradient:Clone()

				local newFrame = janitor:Add(script.Template:Clone())
				newFrame.EntityNameLabel.Text = informations.DisplayName or name
				newFrame.RarityLabel.Text = informations.Rarity
				newFrame.SellValueLabel.Text = "$" .. Format.abbreviateCash(entitySellValue)
				gradient.Parent = newFrame.RarityLabel
				newFrame.Parent = ScrollingFrame
				newFrame.Visible = true

				ViewportHandler(informations.Model:FindFirstChild(mutation), newFrame.ViewportFrame, informations.Animation)

				local amountOwned = 1
				Cache[name .. mutation] = function()
					amountOwned += 1
					newFrame.AmountOwnedLabel.Text = amountOwned .. "x Owned"
				end

				janitor:Add(newFrame.SellButton.Activated:Connect(function()
					RemoteBank.SellRemote:InvokeServer("Sell", id)
				end))
			end
		end
	end
	
	janitor:Add(function()
		for i, v in Cache do
			Cache[i] = nil
		end
	end)
	
	SellLabel.Text = "$" .. Format.abbreviateCash(TotalAmount)
end

-- Initialization function for the script
function Frame:Initialize()
	SellAllButton.Activated:Connect(function()
		RemoteBank.SellRemote:InvokeServer("SellAll")
	end)
	
	Frame.UpdateGui()
	
	DataService.client:getChangedSignal("inventory"):Connect(function()
		Frame.UpdateGui()
	end)
	
	DataService.client:getIndexChangedSignal("inventory"):Connect(function()
		Frame.UpdateGui()
	end)
end

return Frame
