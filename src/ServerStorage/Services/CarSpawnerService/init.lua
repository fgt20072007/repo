--> Services
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerStorage = game:GetService("ServerStorage")
local CollectionService = game:GetService("CollectionService")

local VehiclePath = ServerStorage.ServerAssets.Cars

--> Dependencies
local DataService = require(script.Parent.DataService)

local Packages = ReplicatedStorage.Packages
local Net = require(Packages.Net)
local GenerateLicensePlate = require(script.GenerateLicensePlate)

local MarketService = require(script.Parent.MarketService)

--> Data 
local VehicleData = require(ReplicatedStorage.Data.Vehicles)
local ColorData = require(script.ColorData)

--> Misc
local SpawnEvent = Net:RemoteEvent("SpawnCar")
local InteractEvent = Net:RemoteFunction("VehicleShopInteract")

local SpawnedCars = {}


--> Priv Methods
local function ChangeColor(Vehicle:Model, ColorName:string)
	local Color =  ColorName and ColorData[ColorName] or nil
	local Body = Vehicle:FindFirstChild("Body")
	if not (Color and Body) then return end

	for _, Part in Body:GetChildren() do
		if Part.Name ~= "Color" then continue end
		Part.Color = Color
	end
end


local function SetupCar(VehicleModel:Model, Color:string)
	--> LicensePlate
	ChangeColor(VehicleModel, Color)

	local body = VehicleModel:FindFirstChild("Body")
	local licensePlate = body and body:FindFirstChild("LicensePlate")
	if not licensePlate then return end

	local Owner = game.Players:FindFirstChild(VehicleModel:GetAttribute("Owner"))
	local LicencePlateNumber = GenerateLicensePlate(Owner)

	licensePlate.BackPlate.Plate.SurfaceGui.TextLabel.Text = LicencePlateNumber
	licensePlate.FrontPlate.Plate.SurfaceGui.TextLabel.Text = LicencePlateNumber
end

local function EjectOccupants(car: Model)
	for _, seat in car:GetDescendants() do
		if not (seat:IsA("Seat") or seat:IsA("VehicleSeat")) then continue end

		local occupant = seat.Occupant
		if not occupant then continue end

		local weld = seat:FindFirstChild("SeatWeld")
		if weld then weld:Destroy() end

		occupant.Sit = false
		occupant.Jump = true
	end
end

local function DestroyPlayerCar(player:Player)
	if not SpawnedCars[player] then return end

	local car = SpawnedCars[player]
	SpawnedCars[player] = nil

	EjectOccupants(car)

	task.delay(0.1, function()
		if car and car.Parent then car:Destroy() end
	end)
end


local module = {}


local CarSpawnLocation_OverlapParams = OverlapParams.new()
CarSpawnLocation_OverlapParams.FilterType = Enum.RaycastFilterType.Exclude
CarSpawnLocation_OverlapParams.FilterDescendantsInstances = {workspace.CarSpawnPlot}

local function GetSpawnLocation(Player:Player, CarModel:Model)
	local Team = Player.Team.Name
	local SpawnPlot = Team and workspace.CarSpawnPlot:FindFirstChild(Team)
	local ExtentsSize = CarModel:GetExtentsSize()

	--[[
	local Part = Instance.new("Part")
	Part.Size = ExtentsSize
	Part.Anchored = true
	Part.CanCollide = false
	Part.Name = "Collision_Part"
	Part.Parent = workspace
	]]

	--Iterate to all positions
	local SpawnPosition = nil
	for _, Attachment:Attachment in SpawnPlot:GetChildren() do
		local cf = Attachment.WorldCFrame
		cf += (Vector3.yAxis * ExtentsSize.Y * .5)

		local PartsInPart = workspace:GetPartBoundsInBox(cf ,ExtentsSize, CarSpawnLocation_OverlapParams)--workspace:GetPartsInPart(Part, CarSpawnLocation_OverlapParams)
		local IsBlocked = false
		for _, Part:BasePart in PartsInPart do
			if Part.Name == "Collision_Part" then
				IsBlocked = true
			end
		end

		if not IsBlocked then
			return cf
		end
	end
end


function module:SpawnVehicle(Player:Player, VehicleName:number, VehicleColor:string)
	--> Destroy Previous Car
	DestroyPlayerCar(Player)

	-- Check if vehicle is on list
	local VehicleModel = VehiclePath:FindFirstChild(VehicleName) or VehiclePath:FindFirstChild("Falcon Explorer 2020")
	if not VehicleModel then return end

	local Character = Player.Character

	local CarClone = VehicleModel:Clone()
	CarClone.Parent = workspace
	CarClone:AddTag("Car")

	local SpawnPosition = GetSpawnLocation(Player, CarClone)
	if not SpawnPosition then return false end
	CarClone:PivotTo(SpawnPosition)
	CarClone:SetAttribute("Owner", Player.Name)

	SetupCar(CarClone, VehicleColor)

	task.spawn(function()
		task.wait(.5)

		local VehicleSeat = CarClone:FindFirstChildOfClass("VehicleSeat")
		if VehicleSeat then
			Character:PivotTo(VehicleSeat:GetPivot() + Vector3.new(0, 3.5, 0))
			VehicleSeat:Sit(Character.Humanoid)
		end
	end)


	SpawnedCars[Player] = CarClone

	return true
end

function module.Init()
	InteractEvent.OnServerInvoke = function(player:Player, VehicleListIndex:number, VehicleName:string, VehicleColor:string)
		local DataManager = DataService.GetManager('PlayerData')
		local ThisVehicleData = VehicleData[VehicleListIndex]
		local PlayerVehicleData = DataManager:Get(player, {'Vehicles'})
		if not ThisVehicleData or ThisVehicleData.Name ~= VehicleName then return end

		--> Player has vehicle, attempt to spawn
		if (not (ThisVehicleData.GamepassOnly or ThisVehicleData.GamepassProvidesVehicle) 
			and table.find(PlayerVehicleData, VehicleName)
			)
				or 
				(
					ThisVehicleData.GamepassOnly and table.find(PlayerVehicleData, VehicleName)
				)
				or 
				(
					ThisVehicleData.GamepassOnly
					and ThisVehicleData.GamepassProvidesVehicle
					and MarketService.OwnsPass(player, ThisVehicleData.GamepassOnly)
				) 
		then
			if not module:SpawnVehicle(player, VehicleName, VehicleColor) then
				return false, "CarModelNotFound"
			end

			return true, "VehicleSpawned"
		else
			--> Player attempt to purchase vehicle
			print("ATTEMPT TO PURCHASE")
			if not DataService.AdjustBalance(player, -ThisVehicleData.Price) then
				return false, "NotEnoughCash"
			end

			if not DataService.InsertVehicle(player, ThisVehicleData.Name) then
				--> Devolver el dinero al jugador en caso de no completarse 
				DataService.AdjustBalance(player, ThisVehicleData.Price)
				return false, "CarModelNotFound"
			end	

			return true, "VehiclePurchased"
		end
	end

	game.Players.PlayerRemoving:Connect(function(player:Player)
		DestroyPlayerCar(player)
	end)

	return true
end



return module
