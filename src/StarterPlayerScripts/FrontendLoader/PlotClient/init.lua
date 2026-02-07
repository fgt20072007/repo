-- Services
local ReplicatedStorage = game:GetService('ReplicatedStorage')
local Players = game:GetService('Players')

-- Variables

-- Dependencies
local DataService = require(ReplicatedStorage.Utilities.DataService)
local RemoteBank = require(ReplicatedStorage.RemoteBank)

local EconomyCalculations = require(ReplicatedStorage.DataModules.EconomyCalculations)
local Format = require(ReplicatedStorage.Utilities.Format)

local DevProducts = require(ReplicatedStorage.DataModules.DevProducts)

local PlotClient = {}

-- Initialization function for the script
function PlotClient:Initialize()
	local PlayerPlot: Folder = RemoteBank.GetPlot:InvokeServer()
	
	local NewHomeBillboard = script.HomeBillboard:Clone()
	NewHomeBillboard.Parent = PlayerPlot:WaitForChild("BillboardSpawnPart")
	
	local NewSign = script.Sign:Clone()
	local Extra = script.PlaceAble:Clone()
	local SignSpawnPoint = PlayerPlot:FindFirstChild("SignSpawn")
	local ExtraSpawnPoint = PlayerPlot:FindFirstChild("ExtraSpawn")
	
	--[[if ExtraSpawnPoint then
		Extra.Parent = PlayerPlot
		Extra:PivotTo(ExtraSpawnPoint:GetPivot())
		
		local TouchPart = Extra.Buyable.TouchPart
		TouchPart.Touched:Connect(function()
			RemoteBank.Purchase:InvokeServer(false, DevProducts.StarterPack.Id)
		end)
	end]]
	
	if SignSpawnPoint then
		NewSign.Parent = PlayerPlot
		NewSign:PivotTo(SignSpawnPoint:GetPivot())
		
		NewSign.Main.ProximityPrompt.Triggered:Connect(function()
			RemoteBank.PurchaseUpgrade:FireServer("StandUpgrade")
		end)
		
		local function UpdateStands()
			local currentStandAmount = #DataService.client:get("stands")
			NewSign.Main.SurfaceGui.PriceLabel.Text = "$" .. Format.abbreviateCash(EconomyCalculations.calculateSlowUpgradePrice(currentStandAmount + 1))
		end
		
		UpdateStands()
		
		DataService.client:getIndexChangedSignal("stands"):Connect(UpdateStands)
	end
	
end

return PlotClient
