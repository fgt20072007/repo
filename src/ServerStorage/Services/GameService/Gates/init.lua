local ReplicatedStorage = game:GetService('ReplicatedStorage')

local Packages = ReplicatedStorage.Packages
local Observers = require(Packages.Observers)

local BoomObj = require(script.Boom)
local VehicleObj = require(script.Vehicle)

local Gates = {
	Registered = {
		Boom = {},
		Vehicle = {},
	} :: {
		Boom: {[Model]: BoomObj.Class},
		Vehicle: {[Model]: VehicleObj.Class}
	}
}

function Gates.Init()
	Observers.observeTag("BoomGate", function(gateModel: Model)
		if not gateModel:IsA('Model') then return end
		
		local has = Gates.Registered.Boom[gateModel]
		if has then return end
		
		local new = BoomObj.new(gateModel)
		Gates.Registered.Boom[gateModel] = new
	end)
	
	Observers.observeTag("VehicleGate", function(gateModel: Model)
		if not gateModel:IsA('Model') then return end

		local has = Gates.Registered.Vehicle[gateModel]
		if has then return end

		local new = VehicleObj.new(gateModel)
		Gates.Registered.Vehicle[gateModel] = new
	end)
end

return Gates