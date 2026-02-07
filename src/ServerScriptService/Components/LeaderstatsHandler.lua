-- Services
local ReplicatedStorage = game:GetService('ReplicatedStorage')
local Players = game:GetService('Players')

-- Variables

-- Dependencies
local DataService = require(ReplicatedStorage.Utilities.DataService)

local LeaderstatsHandler = {}

function LeaderstatsHandler.onPlayerAdded(player)
	DataService.server:waitForData(player)

	print("Initialized Player Stats")

	local data = DataService.server:get(player)
	local leaderstats = Instance.new('Folder')
	leaderstats.Name = 'leaderstats'
	leaderstats.Parent = player

	local cash = Instance.new("IntValue")
	cash.Name = "Cash"
	cash.Value = data.cash
	cash.Parent = leaderstats

	DataService.server:getChangedSignal(player, "cash"):Connect(function()
		cash.Value = DataService.server:get(player, "cash")
	end)
end

-- Initialization function for the script
function LeaderstatsHandler:Initialize()
	for _, v in Players:GetPlayers() do
		LeaderstatsHandler.onPlayerAdded(v)
	end
	
	Players.PlayerAdded:Connect(function(player)
		LeaderstatsHandler.onPlayerAdded(player)
	end)
end

return LeaderstatsHandler
