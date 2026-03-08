--!strict

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")

local appServer = ServerScriptService:WaitForChild("App"):WaitForChild("Server")
local servicesFolder = appServer:WaitForChild("Services")
local PlayerProfileService = require(servicesFolder:WaitForChild("PlayerProfileService")) :: any

local sharedData = ReplicatedStorage:WaitForChild("App"):WaitForChild("Shared"):WaitForChild("Data")
local Gen = require(sharedData:WaitForChild("General"):WaitForChild("Gen"))

local GARAGE_COST = Gen.Garage.Cost

local pendingGarages: { [Player]: Model } = {}

local GarageService = {}

function GarageService.SetPending(player: Player, garageModel: Model)
	pendingGarages[player] = garageModel
end

function GarageService.ConsumePending(player: Player): Model?
	local garageModel = pendingGarages[player]
	pendingGarages[player] = nil
	return garageModel
end

function GarageService.Activate(player: Player, garageModel: Model, isRobux: boolean)
	if isRobux ~= true then
		local economy = PlayerProfileService:GetValue(player, "Economy")
		if economy == nil then
			return
		end

		if economy.Money < GARAGE_COST then
			return
		end

		economy.Money -= GARAGE_COST
		PlayerProfileService:SetValue(player, "Economy", economy)
	end

	print(`Player: {player.Name} | Model: {garageModel:GetFullName()}`)
end

return table.freeze(GarageService)