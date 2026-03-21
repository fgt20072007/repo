--!strict

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local app = ReplicatedStorage:WaitForChild("App")
local shared = app:WaitForChild("Shared")

local Net = require(shared:WaitForChild("Net")) :: any
local NotificationService = require(script.Parent:WaitForChild("NotificationService"))

local VehicleFuel = {
	_hasTrackedVehicle = false,
	_hadFuel = false,
}

function VehicleFuel:Init()
	Net.VehicleFuelChanged.On(function(fuelAmount: number, fuelCapacity: number, _fuelPercent: number)
		local hasActiveVehicle = fuelCapacity > 0
		local hasFuel = fuelAmount > 0
		
		if
			hasActiveVehicle == true
			and self._hasTrackedVehicle == true
			and self._hadFuel == true
			and hasFuel == false
		then
			NotificationService:PushFromCatalog("Vehicle", "OutOfFuel")
		end

		self._hasTrackedVehicle = hasActiveVehicle
		self._hadFuel = hasFuel
	end)
end

return VehicleFuel