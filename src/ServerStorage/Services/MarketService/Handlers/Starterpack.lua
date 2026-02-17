--!strict
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerStorage = game:GetService("ServerStorage")
local Services = ServerStorage:WaitForChild("Services")

local ToolPath = ServerStorage.ServerAssets.Tools
local VehiclesData = require(ReplicatedStorage.Data.Vehicles)
local MarketService = require(Services.MarketService)
local DataService = require(Services.DataService)

local STARTERPACK_PASS_NAME = "Starterpack"
local STARTERPACK_CASH_REWARD = 75_000

local module = {}
local STARTERPACK_VEHICLES = {}

for _, vehicleData in VehiclesData do
	if vehicleData.GamepassOnly ~= STARTERPACK_PASS_NAME then continue end
	if vehicleData.GamepassProvidesVehicle ~= true then continue end
	if type(vehicleData.Name) ~= "string" or vehicleData.Name == "" then continue end
	table.insert(STARTERPACK_VEHICLES, vehicleData.Name)
end

local function GiveTool(player: Player, toolName: string): Instance?
	local found = ToolPath:FindFirstChild(toolName)
	if not found then
		warn(`[Starterpack] Missing tool asset: {toolName}`)
		return nil
	end

	local backpack = player:FindFirstChildOfClass("Backpack") or player:WaitForChild("Backpack", 5)
	if not backpack then
		return nil
	end

	local new = found:Clone()
	new.Parent = backpack
	return new
end

local function GrantStarterpackVehicles(player: Player)
	local manager = DataService.GetManager("PlayerData")
	if not manager then return end

	local ownedVehicles = manager:Get(player, {"Vehicles"})
	if type(ownedVehicles) ~= "table" then return end

	local ownershipIndex: {[string]: true} = {}
	for _, vehicleName in ipairs(ownedVehicles) do
		if type(vehicleName) == "string" then
			ownershipIndex[vehicleName] = true
		end
	end

	for _, vehicleName in ipairs(STARTERPACK_VEHICLES) do
		if ownershipIndex[vehicleName] then continue end
		if DataService.InsertVehicle(player, vehicleName) then
			ownershipIndex[vehicleName] = true
		end
	end
end

function module:ApplyEffect(player: Player)
	GiveTool(player, "Glock")
	GiveTool(player, "C4")
	GrantStarterpackVehicles(player)
	DataService.AdjustBalance(player, STARTERPACK_CASH_REWARD)
end

MarketService.PurchasedPass:Connect(function(player: Player, fixedId: string)
	if fixedId ~= STARTERPACK_PASS_NAME then return end
	module:ApplyEffect(player)
end)

DataService.PlayerLoaded:Connect(function(player: Player)
	task.spawn(MarketService.OwnsPass, player, STARTERPACK_PASS_NAME)
end)

task.spawn(function()
	for _, player in DataService.GetLoaded() do
		task.spawn(MarketService.OwnsPass, player, STARTERPACK_PASS_NAME)
	end
end)

return module
