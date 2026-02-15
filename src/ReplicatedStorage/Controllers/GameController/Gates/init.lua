--!strict
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService('Players')

local Client = Players.LocalPlayer :: Player

local Packages = ReplicatedStorage:WaitForChild("Packages")
local Observers = require(Packages:WaitForChild("Observers"))

local BoomObj = require(script.Boom)
local VehicleObj = require(script.Vehicle)

local Gate = {
	Registered = {
		Boom = {},
		Vehicle = {},
	} :: {
		Boom: {[Model]: BoomObj.Class},
		Vehicle: {[Model]: VehicleObj.Class}
	}
}

local function OnTeamChange()
	for _, obj in Gate.Registered.Boom :: any do
		obj:UpdatePrompt()
	end
end

function Gate.Init()
	Observers.observeTag("BoomGate", function(gateModel: Model)
		if not gateModel then return end

		local has = Gate.Registered.Boom[gateModel]
		if has then return end

		local new = BoomObj.new(gateModel)
		Gate.Registered.Boom[gateModel] = new
	end)

	Observers.observeTag("VehicleGate", function(gateModel: Model)
		if not gateModel then return end

		local has = Gate.Registered.Vehicle[gateModel]
		if has then return end

		local new = VehicleObj.new(gateModel)
		Gate.Registered.Vehicle[gateModel] = new
	end)

	Client:GetPropertyChangedSignal('Team'):Connect(function()
		OnTeamChange()
	end)
end

return Gate