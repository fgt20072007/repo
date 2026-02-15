local module = {}


local Patterns = require(script.Patterns)

local AllCars = {}
local function FindLights(Directory)
	local Lights = {}
	for _, LightModel:Model in Directory:GetChildren() do
		if #LightModel:GetChildren() < 1 then continue end
		
		for _, Light:Model in LightModel:GetChildren() do
			if not (Light:FindFirstChild("Red") or Light:FindFirstChild("Blue")) then continue end
			Lights[LightModel.Name] = Lights[LightModel.Name] or {}

			Lights[LightModel.Name][Light.Name] = {
				LightObject = Light,
			}
		end
	end
	
	return Lights
end

local function TurnLights(CarModel:Model, CurrentPatternTable, AllLights)
	for LightDirectory, Lights in AllLights do
		task.spawn(function()
			local Body = CarModel.Body
			local LightHolderModel = Body and Body:WaitForChild(LightDirectory)

			for Directory:Model, LightsData in Lights do
				local PatternData = CurrentPatternTable[LightDirectory] and CurrentPatternTable[LightDirectory][Directory] or {}
				--if not PatternData then continue end

				local Model = LightHolderModel:FindFirstChild(Directory)
				for _, LightInstance in Model:GetChildren() do
					local IsActive = table.find(PatternData, tonumber(LightInstance.Name)) and true or false -- table.find(ModelData, LightInstance.Name)
					for _, Surface in LightInstance:GetChildren() do
						if Surface:IsA("SurfaceGui") then
							Surface.Enabled = IsActive
						end
					end
				end
			end
		end) 	
	end
end

local function IterateLights(CarModel:Model, CarData)
	local CurrentSirenPatternIndex = CarModel:GetAttribute("Siren")
	local PatternTable = Patterns[CurrentSirenPatternIndex]
	local CurrentPatternTable = PatternTable[CarData.CurrentPattern]
	
	TurnLights(CarModel, CurrentPatternTable, CarData.AllLights)
	CarData.CurrentPattern = (CarData.CurrentPattern % #PatternTable) + 1
end

function module:ChangePattern(CarModel:Model)
	local CarData = AllCars[CarModel]
	if not CarData then return end
	CarData.CurrentPattern = 1
	CarData.LastIteration = tick()

	--> ChangeCdarSound and update cached siren pattern
	
	CarData.CurrentPatternType = CarModel:GetAttribute("Siren")

	
end

function module:ChangeSound(CarModel:Model)
	local DriveSeat = CarModel:FindFirstChildOfClass("VehicleSeat")
	local SoundsFolder = DriveSeat and DriveSeat:FindFirstChild("ELS")
	if not SoundsFolder then return end

	for _, Sound:Sound in SoundsFolder:GetChildren() do
		if not Sound:IsA("Sound") then continue end
		Sound:Stop()
	end

	local Sound = CarModel:GetAttribute("SirenSound")
	if not Sound then return end
	
	local NewSound:Sound = SoundsFolder:FindFirstChild(Sound)
	if NewSound then
		NewSound:Play()
	end
end


function module:PrepareCar(CarModel:Model)
	local AllLights = {}
	local Body = CarModel:FindFirstChild("Body")
	local ELS = Body and Body:FindFirstChild("ELS")
	if ELS then
		AllLights["ELS"] = FindLights(CarModel.Body.ELS)
	end
	
	AllCars[CarModel] = {
		AllLights = AllLights,
		CurrentPattern = 1,
		LastIteration = tick(),
		CurrentPatternType = CarModel:GetAttribute("Siren")
	}
	
	module:ChangePattern(CarModel)
	module:ChangeSound(CarModel)
	
	
	CarModel.Destroying:Once(function()
		AllCars[CarModel] = nil
	end)
end

function module:TurnOffLights(CarModel)
	local CarData = AllCars[CarModel]
	TurnLights(CarModel, {}, CarData.AllLights)
end

function module:UpdateAllCars()
	local Now = tick()
	
	for CarModel:Model, CarData in AllCars do
		if not CarModel then print("Continue") continue end
		if not CarModel:GetAttribute("Siren") then continue end
		
		local PatternData = Patterns[CarData.CurrentPatternType] or .08
		if tick() - CarData.LastIteration < PatternData.PatternIterationTime then continue end
		IterateLights(CarModel, CarData)
		CarData.LastIteration = Now
	end
end
return module
