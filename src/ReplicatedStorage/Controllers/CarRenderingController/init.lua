
--> Services
local CollectionService = game:GetService("CollectionService")
local RunService = game:GetService("RunService")



local module = {}

local LightController = require(script.LightController)

local function PrepareCar(Car:Model)
	LightController:PrepareCar(Car)
end

local Listeners = {}



local function RemoveCarListener(Vehicle:Model)
	if not Listeners[Vehicle] then return end
	
	for _, Connection:RBXScriptConnection in Listeners[Vehicle] do
		Connection:Disconnect()
	end
	Listeners[Vehicle] = nil
end

local function CreateCarListener(Vehicle:Model)
	RemoveCarListener(Vehicle) -- Avoid duped listeners, shouldn't appear but...
	
	PrepareCar(Vehicle)
	Listeners[Vehicle] = {
		Vehicle:GetAttributeChangedSignal("Siren"):Connect(function()
			local IsActive = Vehicle:GetAttribute("Siren")

			LightController:ChangePattern(Vehicle)

			if not IsActive then
				LightController:TurnOffLights(Vehicle)
				return
			end
		end),

		Vehicle:GetAttributeChangedSignal("SirenSound"):Connect(function()
			LightController:ChangeSound(Vehicle)
		end)
	}
end


function module.Init()
	for _, Vehicle:Model in CollectionService:GetTagged("Car") do
		CreateCarListener(Vehicle)
	end
	
	CollectionService:GetInstanceAddedSignal("Car"):Connect(function(Vehicle:Instance)
		CreateCarListener(Vehicle)
	end)
	
	CollectionService:GetInstanceRemovedSignal("Car"):Connect(function(Vehicle:Instance)
		RemoveCarListener(Vehicle)
	end)

	RunService.Heartbeat:Connect(function()
		LightController:UpdateAllCars()
	end)
end

return module
