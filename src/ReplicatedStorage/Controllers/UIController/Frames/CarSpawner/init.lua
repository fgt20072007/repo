--> CONFIG
local Team_Only_Cars = true


--> Services
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local MarketplaceService = game:GetService("MarketplaceService")

--> Dependencies
local Packages = ReplicatedStorage:WaitForChild("Packages")
local Trove = require(Packages:WaitForChild("Trove"))
local Observers = require(Packages:WaitForChild("Observers"))
local TableUtil = require(Packages:WaitForChild("TableUtil"))

local Util = ReplicatedStorage:WaitForChild("Util")
local ValueFormat = require(Util:WaitForChild("Format"))

local Data = ReplicatedStorage:WaitForChild("Data")
local Settings_Data = require(Data:WaitForChild("Settings"))
local VehiclesData = require(Data:WaitForChild("Vehicles"))
local Gamepasses = require(Data:WaitForChild("Passes"))
local GamepassOwnership = require(ReplicatedStorage.Util.GamepassOwnership)

local Controllers = ReplicatedStorage:WaitForChild("Controllers")
local ReplicaController = require(Controllers.ReplicaController)
local UIController = require(Controllers.UIController)
local UIFilter = require(script.UIFilter)

local Net = require(Packages.Net)


--> Misc
local Player = Players.LocalPlayer :: Player
local PlayerGui = Player:WaitForChild("PlayerGui") :: PlayerGui
local Main = PlayerGui:WaitForChild("Main") :: ScreenGui
local frame = Main:WaitForChild("CarSpawner") :: GuiObject
local Main = frame:WaitForChild("Main")
local closeButton = Main:WaitForChild("CloseButton") :: GuiButton

local PurchaseButton = frame.CarInfo:WaitForChild("PurchaseButton") :: GuiButton

local InteractRemoteEvent = Net:RemoteFunction("VehicleShopInteract")

--> Priv Methods
local nastring = "N/A"
local Colors = {}
local CurrentColor = nil
local Name_To_Vehicle_Index = {}

local function ChangeColor(Color: string)
	for _, ColorFrame: Frame in frame.CarInfo.ColorFrame:GetChildren() do
		if not ColorFrame:IsA("Frame") then
			continue
		end
		ColorFrame.BackgroundColor3 = ColorFrame.Name ~= Color and Color3.fromRGB(40, 40, 40)
			or Color3.new(0.160784, 0.615686, 0.176471)
	end
	CurrentColor = Color
end

for _, ColorFrame: Frame in frame.CarInfo.ColorFrame:GetChildren() do
	if not ColorFrame:IsA("Frame") then
		continue
	end

	ColorFrame.TextButton.MouseButton1Click:Connect(function()
		ChangeColor(ColorFrame.Name ~= CurrentColor and ColorFrame.Name or nil)
	end)
end

local SelectedCardData = nil




--> Module Declaration
local CarSpawner = {}
CarSpawner.__index = CarSpawner

function CarSpawner.new(controller: any)
	local self = setmetatable({}, CarSpawner)

	self._name = "CarSpawner"
	self._uiController = controller
	self._Trove = Trove.new()
	self._UI = frame
	self._openPrompt = nil
	self.LoadedCards = {}
	self.SelectedCardData = nil

	self:_init()

	return self
end

function CarSpawner:_init()
	self._UI.Visible = false
	--Template.Visible = false
	return true
end

--> TODO: Hacer esto standalone
local Filters = {
	["Price"] = {
		"High to Low",
		"Low to High",
	},

	["Type"] = {
		"All Vehicles",
		"SUV",
		"Sedan",
		"Cargo",
		"Military",
	},
}

local filterFunctions = {
	Price = function(tab, FilterType)
		if not FilterType then return tab end

		local isHighToLow = FilterType == Filters.Price[1]
		table.sort(tab, function(a, b)
			if isHighToLow then
				return a.Price > b.Price
			else
				return a.Price < b.Price
			end
		end)

		return tab
	end,

	Type = function(tab, FilterType)
		if not FilterType or FilterType == "All Vehicles" then return tab end

		local Resulting = {}
		for _, Data in tab do
			if Data.VehicleType == FilterType then
				table.insert(Resulting, Data)
			end
		end

		return Resulting
	end,

	Search = function(tab, FilterType)
		if not FilterType or FilterType == "" then return tab end

		local SearchTerm = string.lower(FilterType)
		local Resulting = {}
		for _, Data in tab do
			local name = string.lower(Data.Name or "")
			if string.find(name, SearchTerm, 1, true) then
				table.insert(Resulting, Data)
			end
		end

		return Resulting
	end,
}

local function ApplyFilters(Data, Filters: { string })
	CarSpawner:ClearCards()

	local FilteredData = TableUtil.Copy(Data, true)	
	for FilterName, FilterType in Filters do
		local FilterFunction = filterFunctions[FilterName]
		if not FilterFunction then continue end
		FilteredData = FilterFunction(FilteredData, FilterType)
	end

	CarSpawner:LoadCards(FilteredData)
end

local function HasGamepass(GamepassName:string)
	return GamepassOwnership.Owns(GamepassName)
end

local function VisualizeDataDescription(VehicleData)
	local CarInfo = frame.CarInfo
	CarInfo.CarName.Text = VehicleData and VehicleData.Name or nastring

	--TODO: Cambiar entre MPH y KM/H, basado en la configuración del jugador


	local replica: ReplicaController.Replica = ReplicaController.GetReplica("PlayerData")
	local PlayerVehicleData = (replica and replica.Data) and replica.Data.Vehicles or nil

	local OwnedByPlayer = PlayerVehicleData and VehicleData and table.find(PlayerVehicleData, VehicleData.Name)
	local GamepassRequired = VehicleData and VehicleData.GamepassOnly
	local GamepassProvided = VehicleData and VehicleData.GamepassProvidesVehicle
	local GamepassOwned = GamepassRequired and HasGamepass(GamepassRequired)


	local Case1 = not GamepassRequired and OwnedByPlayer
	local Case2 = GamepassRequired and HasGamepass(GamepassRequired) and GamepassProvided
	local Case3 = GamepassRequired and HasGamepass(GamepassRequired) and not GamepassProvided and OwnedByPlayer

	local VehicleOwned = (Case1 or Case2 or Case3) and true or false

	local InfoFrame = CarInfo.Info
	InfoFrame.PriceInfo.Price.Text = VehicleData and (GamepassProvided and "Free With Gamepass" or `${ValueFormat.WithCommas(VehicleData.Price)}`) or nastring
	InfoFrame.SpeedInfo.Speed.Text = VehicleData and `{VehicleData.TopSpeed} KM/H` or nastring
	InfoFrame.HorsePowerInfo.HorsePower.Text = VehicleData and `{VehicleData.HorsePower} HP` or nastring
	CarInfo.ViewportFrame.Visible = VehicleData and VehicleData.ImageRbxAssetId and true or false
	CarInfo.ViewportFrame.CarImage.Image = VehicleData and VehicleData.ImageRbxAssetId or ""
	CarInfo.PurchaseButton.Visible = VehicleData and true or false

	CarInfo.Visible = VehicleData and true or false
	local GamepassRequired = VehicleData and VehicleData.GamepassOnly


	--Update button

	CarInfo.PurchaseButton.PurchaseGradient.Enabled = not VehicleOwned
	CarInfo.PurchaseButton.SpawnGradient.Enabled = VehicleOwned
	CarInfo.PurchaseButton.PriceLabel.Text = VehicleOwned and "Spawn" or GamepassRequired and not GamepassOwned and "Purchase Gamepass" or "Purchase"
end


local function UpdateVehicleCard(CardName)
	local replica: ReplicaController.Replica = ReplicaController.GetReplica("PlayerData")
	local PlayerVehicleData = (replica and replica.Data) and replica.Data.Vehicles or nil
	if not PlayerVehicleData then return end

	local HolderFrame = Main.ScrollingFrame
	local VehicleCard = CardName and HolderFrame:FindFirstChild(CardName)
	if not VehicleCard then return end

	local VehicleDataIndex = Name_To_Vehicle_Index[CardName]
	local VehicleData = VehicleDataIndex and VehiclesData[VehicleDataIndex]
	if not VehicleData then return end

	local Frame = VehicleCard.HolderFrame
	Frame.CarName.Text = VehicleData.Name or "N/A"
	Frame.CarType.Text = VehicleData.VehicleType or "N/A"
	Frame.CarYear.Text = VehicleData.CarYear or "N/A"
	Frame.CarImage.Image = VehicleData.ImageRbxAssetId or "N/A"

	local OwnedByPlayer = table.find(PlayerVehicleData, VehicleData.Name)
	local GamepassRequired = VehicleData.GamepassOnly
	local GamepassProvided = VehicleData.GamepassProvidesVehicle


	local Case1 = not GamepassRequired and OwnedByPlayer
	local Case2 = GamepassRequired and HasGamepass(GamepassRequired) and GamepassProvided
	local Case3 = GamepassRequired and HasGamepass(GamepassRequired) and not GamepassProvided and OwnedByPlayer

	local Locked = not (Case1 or Case2 or Case3) and true or false
	Frame.LockedFrame.Visible = Locked
end

local CurrentSearchFilters = {}

function CarSpawner:_SetupSortFilters()
	local ResultingFilters = {}
	for _, Frame: Frame in frame.Main.Filters:GetChildren() do
		if not Frame:IsA("Frame") then continue end

		local SortType = Frame:GetAttribute("SortType")
		if not SortType then continue end

		local FilterOptions = Filters[Frame.Name]
		local FilterResult = UIFilter:CreateFilterInteraction(Frame, FilterOptions)
		if FilterResult then
			ResultingFilters[Frame.Name] = FilterResult
		end
	end

	return ResultingFilters
end

function CarSpawner:_ClearSortFilters()
	for _, Frame: Frame in frame.Main.Filters:GetChildren() do
		if not Frame:IsA("Frame") then continue end

		local SortType = Frame:GetAttribute("SortType")
		if not SortType then continue end
		UIFilter:RemoveFilterInteraction(Frame)
	end
end

function CarSpawner:LoadCards(CardsToLoad)
	local TemplateCard = Main.ScrollingFrame.Template

	for VehicleIndex, VehicleData in CardsToLoad do
		if not Name_To_Vehicle_Index[VehicleData.Name] then
			Name_To_Vehicle_Index[VehicleData.Name] = VehicleIndex
		end

		-- TEAM ONLY CARS
		if Team_Only_Cars and VehicleData.Teams 
			and not (table.find(VehicleData.Teams, Player.Team.Name) or Player.Team:HasTag("Federal") and table.find(VehicleData.Teams, "Federal")) 
		then continue end

		local Card = TemplateCard:Clone()
		Card.Visible = true
		Card.Name = VehicleData.Name
		Card:SetAttribute("VehicleCard", true)
		Card.Parent = TemplateCard.Parent

		UpdateVehicleCard(Card.Name)

		local Frame = Card.HolderFrame
		Frame.SelectButton.MouseButton1Click:Connect(function()
			SelectedCardData = if SelectedCardData == VehicleData then nil else VehicleData
			VisualizeDataDescription(SelectedCardData)
		end)
	end
end

function CarSpawner:ClearCards()
	for _, Card in Main.ScrollingFrame:GetChildren() do
		if not Card:GetAttribute("VehicleCard") then
			continue
		end
		Card:Destroy()
	end
end


local CurrentRequest = nil
function CarSpawner:_setupConnections()
	-- Close button (only connected while open)
	self._Trove:Connect(closeButton.MouseButton1Click, function()
		self._uiController:Close(self._name)
	end)

	-- Purchase / Spawn button (only connected while open)
	self._Trove:Connect(PurchaseButton.MouseButton1Click, function()
		if not SelectedCardData then return end

		--> Prompt gamepass
		if SelectedCardData.GamepassOnly and not HasGamepass(SelectedCardData.GamepassOnly) then
			local passId = Gamepasses[SelectedCardData.GamepassOnly]
			if not passId then return end
			MarketplaceService:PromptGamePassPurchase(Player, passId)
			return
		end

		--> Pasamos el nombre solo por si acaso
		local VehicleId = nil
		for Id, CarData in VehiclesData do
			if CarData.Name == SelectedCardData.Name then
				VehicleId = Id
				break
			end
		end

		if CurrentRequest then return end
		if not VehicleId then return end
		CurrentRequest = true
		local result, err = InteractRemoteEvent:InvokeServer(
			VehicleId,
			SelectedCardData.Name,
			CurrentColor,
			self._openPrompt
		)
		CurrentRequest = nil

		if result then
			if frame.CarInfo.PurchaseButton.PriceLabel.Text == "Spawn" then
				self._uiController:Close(self._name)
			end
			return
		end

		local uiManager = UIController.Managers.Notifications
		uiManager.Add(`VehicleShop/{err}`)
	end)
end

local SearchFilters = nil

function CarSpawner:OnOpen(openContext)
	self._openPrompt = openContext and openContext.Prompt or nil

	if self._Trove then
		self._Trove:Clean()
	end

	SearchFilters = self:_SetupSortFilters()
	for FilterName, FilterData in SearchFilters do
		table.insert(FilterData.Connections, FilterData.TriggerEvent:Connect(function(event)
			CurrentSearchFilters[FilterName] = FilterData.CurrentDropdownOption
			ApplyFilters(VehiclesData, CurrentSearchFilters)
		end))
	end

	CarSpawner:LoadCards(VehiclesData)
	self:_setupConnections()

	VisualizeDataDescription(nil)
end

task.spawn(function()
	local succ, res: ReplicaController.Replica = ReplicaController.GetReplicaAsync("PlayerData"):await()
	if not succ then return end
	res:OnChange(function(_, path)
		if path[1] == "GiftedPasses" then
			GamepassOwnership.Invalidate()
		end
		if path[1] ~= "Vehicles" and path[1] ~= "GiftedPasses" then return end
		print("Update")
		if SelectedCardData then
			VisualizeDataDescription(SelectedCardData)
		end

		-->Actualizar el resto de botones visibles en el scrollingframe
		local VehicleData = res.Data.Vehicles
		for _, Card in Main.ScrollingFrame:GetChildren() do
			if not Card:GetAttribute("VehicleCard") then continue end
			UpdateVehicleCard(Card.Name)
		end
	end)
end)

function CarSpawner:OnClose()
	SelectedCardData = nil
	self._openPrompt = nil
	CarSpawner:_ClearSortFilters()
	CarSpawner:ClearCards()

	if self._Trove then
		self._Trove:Clean()
	end
end

return CarSpawner
