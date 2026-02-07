local ReplicatedStorage = game:GetService('ReplicatedStorage')
local Players = game:GetService('Players')

local DataService = require(ReplicatedStorage.Utilities.DataService)
local EntityData = require(ReplicatedStorage.DataModules.EntityData)

local SharedUtilities = require(ReplicatedStorage.Utilities.SharedUtilities)

local TagComponentHandler = {}

local function getLenghtOfT(t: {})
	return SharedUtilities.getLenghtOfT(t)
end

function TagComponentHandler.Initialize()
	Players.PlayerAdded:Connect(function(player)
		DataService.server:waitForData(player)
		local maxDiscoverables = getLenghtOfT(EntityData)
		local currentBillboard = nil

		local function updateBillboard()
			if not currentBillboard then return end
			local indexData = DataService.server:get(player, "index") or {}
			local discovered = getLenghtOfT(indexData)
			currentBillboard.TextLabel.Text = discovered .. "/" .. maxDiscoverables
		end

		local function onCharSpawn(char: Model)
			local head = char:WaitForChild("Head", 5)
			if not head then return end
			local NewBillboard = script.DiscoveredTag:Clone()
			NewBillboard.Parent = head
			currentBillboard = NewBillboard
			updateBillboard()
		end

		DataService.server:getIndexChangedSignal(player, "index"):Connect(updateBillboard)

		if player.Character then onCharSpawn(player.Character) end
		player.CharacterAdded:Connect(onCharSpawn)
	end)
end

return TagComponentHandler