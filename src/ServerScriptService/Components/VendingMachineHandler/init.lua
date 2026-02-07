local ReplicatedStorage = game:GetService('ReplicatedStorage')
local CollectionService = game:GetService('CollectionService')

local VendingMachines = require(ReplicatedStorage.DataModules.VendingMachines)
local GlobalConfiguration = require(ReplicatedStorage.DataModules.GlobalConfiguration)
local ToolGiver = require("./ToolGiverHandler")

local SharedUtilities = require(ReplicatedStorage.Utilities.SharedUtilities)
local EntityHandler = require("./EntityComponent")

local VendingMachineHandler = {}

function VendingMachineHandler.HandleVendingMachine(VendingMachine: Folder)
	local CoinsFolder: Folder & {BasePart} = VendingMachine.Coins
	local Data = VendingMachines[VendingMachine.Name]
	local CoinTools = Data.ToolFolder
	local UnlockProximity: ProximityPrompt = VendingMachine:FindFirstChild("UnlockProximity", true)
	for _, v in pairs(CoinsFolder:GetChildren()) do
		local ProximityPrompt = script.ProximityPrompt:Clone()
		ProximityPrompt.ActionText = `Collect {v.Name} coin`
		ProximityPrompt.Parent = v
		ProximityPrompt.Triggered:Connect(function(playerTriggered)
			local NewTool = CoinTools:FindFirstChild(v.Name)
			if NewTool then
				ToolGiver.GiveTool(playerTriggered, NewTool)
			end
		end)
	end
	
	UnlockProximity.Triggered:Connect(function(player)
		local tools = SharedUtilities.getToolsForBackpackAndEquipped(player)
		local list = CoinTools:GetChildren()
		local owned = 0
		
		for _, v in list do
			for _, j in tools do
				if j.Name == v.Name then
					owned += 1
				end
			end
		end
		
		if owned == #list then
			local EntityToGive = Data.EntityToGive
			EntityHandler.GiveEntity(player, EntityToGive, true)
			ToolGiver.ClearTools(player)
		end
	end)
end

function VendingMachineHandler.Initialize()
	for _, vending in CollectionService:GetTagged(GlobalConfiguration.VendingMachineTag) do
		VendingMachineHandler.HandleVendingMachine(vending)
	end
end

return VendingMachineHandler
