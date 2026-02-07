-- Services
local ReplicatedStorage = game:GetService('ReplicatedStorage')
local Players = game:GetService('Players')

-- Variables

-- Dependencies
local DataService = require(ReplicatedStorage.Utilities.DataService)
local Bases = require(ReplicatedStorage.DataModules.Bases)
local Zone = require(ReplicatedStorage.Utilities.Zone)
local Class = require("@self/FollowerClass")

local RemoteBank = require(ReplicatedStorage.RemoteBank)

local FollowerHandler = {}

-- Initialization function for the script
function FollowerHandler:Initialize()
	local BasesOwned = DataService.client:get("bases")
	local Cache = {}
	
	for _, v in workspace.Map.Bases:GetChildren() do
		local BaseNumber = tonumber(v.Name)
		local SpawnPosition = v.NPCSpawn.CFrame
		
		local Informations = Bases[BaseNumber]
		
		local OwnsBase = table.find(BasesOwned, BaseNumber)
		local PurchaseZone = v:FindFirstChild("PurchaseZone")
		
		local connection
		
		if PurchaseZone and not OwnsBase then
			local NewZone = Zone.new(PurchaseZone)
			connection = NewZone.localPlayerEntered:Connect(function()
				RemoteBank.TryPurchaseBase:InvokeServer(BaseNumber)
			end)
		end
		
		if OwnsBase then
			v:FindFirstChild("Button"):Destroy()
			v:FindFirstChild("Lasers"):Destroy()
		end
		
		Cache[BaseNumber] = function()
			v:FindFirstChild("Button"):Destroy()
			v:FindFirstChild("Lasers"):Destroy()
			if connection then
				connection:Disconnect()
			end
		end
		
		
		if Informations and Informations.BaseDefender then
			local NewModel = Informations.BaseDefender:Clone()
			NewModel.Parent = workspace
			
			NewModel:PivotTo(SpawnPosition)
			
			Class(SpawnPosition, NewModel, BaseNumber, v:FindFirstChild("Zone"), Informations.Speed, Informations.IdleAnimation, Informations.WalkingAnimation)
		end
	end
	
	DataService.client:getArrayInsertedSignal("bases"):Connect(function(index, value)
		if Cache[value] then
			Cache[value]()
		end
	end)
end

return FollowerHandler
