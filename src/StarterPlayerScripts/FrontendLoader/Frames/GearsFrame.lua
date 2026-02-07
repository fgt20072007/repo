-- Services
local ReplicatedStorage = game:GetService('ReplicatedStorage')
local Players = game:GetService('Players')

-- Variables
local Gui = Players.LocalPlayer.PlayerGui:WaitForChild("MainGui")
local Frames = Gui.Frames

local GearsFrame = Frames.GearsShop
local Container = GearsFrame.Container.ScrollingFrame
local Template = Container.TemplateGear

Template.Parent = script

-- Dependencies
local DataService = require(ReplicatedStorage.Utilities.DataService)
local Gears = require(ReplicatedStorage.DataModules.Gears)
local SharedUtilities = require(ReplicatedStorage.Utilities.SharedUtilities)
local Format = require(ReplicatedStorage.Utilities.Format)

local Rarities = require(ReplicatedStorage.DataModules.Rarities)
local RemoteBank = require(ReplicatedStorage.RemoteBank)

local NotificationComponent = require(ReplicatedStorage.Utilities.NotificationComponent)

local Frame = {}

local CacheToChange = {}

-- Initialization function for the script
function Frame:Initialize()
	local gearData = DataService.client:get("gears")
	for gearname, gearInfo in Gears do
		local newTemplate = Template:Clone()
		newTemplate.NameLabel.Text = gearInfo.DisplayName

		local ownsTool = table.find(gearData, gearname)

		newTemplate.RegularPurchaseButton.TextLabel.Text = if ownsTool then "OWNED" else "$" .. Format.abbreviateCash(gearInfo.Price) 
		newTemplate.RobuxPurchaseButton.PriceLabel.Text = SharedUtilities.getProductPrice(gearInfo.RobuxId, Enum.InfoType.Product) .. "" 

		if not ownsTool then
			CacheToChange[gearname] = function()
				newTemplate.RegularPurchaseButton.TextLabel.Text = "OWNED"
				newTemplate.RobuxPurchaseButton.Visible = false
			end
		else
			newTemplate.RobuxPurchaseButton.Visible = false
		end

		newTemplate.RarityLabel.Text = gearInfo.Description

		newTemplate.ImageContainer.ImageLabel.Image = gearInfo.GearImage
		newTemplate.LayoutOrder = gearInfo.Price

		newTemplate.Visible = true
		newTemplate.Parent = Container

		newTemplate.RegularPurchaseButton.Activated:Connect(function()
			local response, color = RemoteBank.PurchaseGear:InvokeServer(gearname)
			if response then
				NotificationComponent.CreateNewNotification(response, color)
			end
		end)

		newTemplate.RobuxPurchaseButton.Activated:Connect(function()
			RemoteBank.Purchase:InvokeServer(false, gearInfo.RobuxId)
		end)
	end

	DataService.client:getArrayInsertedSignal("gears"):Connect(function(index, value)
		if CacheToChange[value] then
			CacheToChange[value]()
		end
	end)
end

return Frame
