local ReplicatedStorage = game:GetService('ReplicatedStorage')
local Players = game:GetService('Players')
local CollectionService = game:GetService('CollectionService')

local GlobalConfiguration = require(ReplicatedStorage.DataModules.GlobalConfiguration)
local VendingMachinesData = require(ReplicatedStorage.DataModules.VendingMachines)

local SharedUtilities = require(ReplicatedStorage.Utilities.SharedUtilities)

local ToolAdded = ReplicatedStorage.Communication.Remotes.ToolAdded

local player = Players.LocalPlayer

local ClientVendingHandler = {}

function ClientVendingHandler.Initialize()
	
	for _, vending in CollectionService:GetTagged(GlobalConfiguration.VendingMachineTag) do
		local function updateBillboardCount()
			local Proximity: ProximityPrompt = vending:FindFirstChild("UnlockProximity", true)
			if not Proximity then return end
			local ToolContainer: Folder = VendingMachinesData[vending.Name].ToolFolder
			if ToolContainer then
				local CoinTools = ToolContainer:GetChildren()
				local CurrentTools = SharedUtilities.getToolsForBackpackAndEquipped(player)
				local CurrentlyOwned = 0
				for _, v in CoinTools do
					for _, j in CurrentTools do
						if j.Name == v.Name then
							CurrentlyOwned += 1
						end
					end
				end
				Proximity.ActionText = `Insert Coins ({CurrentlyOwned}/{#CoinTools})`
			end
		end
		
		ToolAdded.OnClientEvent:Connect(function()
			updateBillboardCount()
		end)
	end
end

return ClientVendingHandler
