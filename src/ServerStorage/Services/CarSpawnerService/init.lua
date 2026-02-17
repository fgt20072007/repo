--> Services
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerStorage = game:GetService("ServerStorage")
local CollectionService = game:GetService("CollectionService")
local Players = game:GetService("Players")
local Teams = game:GetService("Teams")
local Workspace = game:GetService("Workspace")

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
local PromptConnections = {}
local ActivePromptContexts = {}

local CARSPAWNER_INTERFACE = "CarSpawner"
local CARSPAWN_TAG = "InterfacePrompt"
local PROMPT_CONTEXT_TTL = 180
local PROMPT_DISTANCE_BUFFER = 12

local TEAM_ALIASES = table.freeze({
	ICE = "HSI",
	HSI = "ICE",
})


--> Priv Methods
local function Trim(text: string): string
	return string.match(text, "^%s*(.-)%s*$") or text
end

local function PlayerTeamMatches(playerTeamName: string, allowedTeamName: string): boolean
	if playerTeamName == allowedTeamName then
		return true
	end

	local playerAlias = TEAM_ALIASES[playerTeamName]
	if playerAlias and playerAlias == allowedTeamName then
		return true
	end

	local allowedAlias = TEAM_ALIASES[allowedTeamName]
	if allowedAlias and allowedAlias == playerTeamName then
		return true
	end

	return false
end

local function PromptTokenMatchesPlayer(player: Player, token: string): boolean
	local team = player.Team
	if not team then return false end

	local normalizedToken = string.lower(Trim(token))
	if normalizedToken == "" then return false end
	if normalizedToken == "all" then return true end
	if normalizedToken == "federal" then
		return team:HasTag("Federal")
	end

	local playerTeamName = team.Name
	if string.lower(playerTeamName) == normalizedToken then
		return true
	end

	local canonicalToken = nil
	for teamName in TEAM_ALIASES do
		if string.lower(teamName) == normalizedToken then
			canonicalToken = teamName
			break
		end
	end

	if canonicalToken then
		return PlayerTeamMatches(playerTeamName, canonicalToken)
	end

	for _, teamInstance in Teams:GetChildren() do
		if not teamInstance:IsA("Team") then continue end
		if string.lower(teamInstance.Name) ~= normalizedToken then continue end
		return PlayerTeamMatches(playerTeamName, teamInstance.Name)
	end

	return false
end

local function ParsePromptAllowedTeams(prompt: ProximityPrompt): {string}?
	local raw = prompt:GetAttribute("AllowedTeams")
	if type(raw) ~= "string" or raw == "" then
		raw = prompt:GetAttribute("TeamWhitelist")
	end
	if type(raw) ~= "string" or raw == "" then
		return nil
	end

	local parsed = {}
	for token in string.gmatch(raw, "[^,;]+") do
		token = Trim(token)
		if token ~= "" then
			table.insert(parsed, token)
		end
	end

	return #parsed > 0 and parsed or nil
end

local function GetPromptWorldPosition(prompt: ProximityPrompt): Vector3?
	local parent = prompt.Parent
	if not parent then return nil end

	if parent:IsA("Attachment") then
		return parent.WorldPosition
	end

	if parent:IsA("BasePart") then
		return parent.Position
	end

	local base = parent:FindFirstAncestorWhichIsA("BasePart")
	if base then
		return base.Position
	end

	local model = parent:FindFirstAncestorWhichIsA("Model")
	if model then
		return model:GetPivot().Position
	end

	return nil
end

local function ResolveNearestSpawnPlotName(prompt: ProximityPrompt): string?
	local spawnPlotsFolder = Workspace:FindFirstChild("CarSpawnPlot")
	if not spawnPlotsFolder then return nil end

	local promptPosition = GetPromptWorldPosition(prompt)
	if not promptPosition then return nil end

	local nearestPlotName = nil
	local nearestDistance = math.huge

	for _, spawnPlot in spawnPlotsFolder:GetChildren() do
		local plotDistance = math.huge
		local hasAnchorPoint = false

		for _, descendant in spawnPlot:GetDescendants() do
			if descendant:IsA("Attachment") then
				hasAnchorPoint = true
				local distance = (descendant.WorldPosition - promptPosition).Magnitude
				if distance < plotDistance then
					plotDistance = distance
				end
			end
		end

		if not hasAnchorPoint then
			local base = spawnPlot:IsA("BasePart") and spawnPlot or spawnPlot:FindFirstChildWhichIsA("BasePart", true)
			if base then
				plotDistance = (base.Position - promptPosition).Magnitude
			end
		end

		if plotDistance < nearestDistance then
			nearestDistance = plotDistance
			nearestPlotName = spawnPlot.Name
		end
	end

	return nearestPlotName
end

local function ResolvePromptSpawnPlotName(player: Player, prompt: ProximityPrompt): string?
	local spawnPlotsFolder = Workspace:FindFirstChild("CarSpawnPlot")
	if not spawnPlotsFolder then return nil end

	local attrPlot = prompt:GetAttribute("CarSpawnPlot")
	if type(attrPlot) ~= "string" or attrPlot == "" then
		attrPlot = prompt:GetAttribute("SpawnPlot")
	end

	if type(attrPlot) == "string" and attrPlot ~= "" then
		local plot = spawnPlotsFolder:FindFirstChild(attrPlot)
		if plot then return plot.Name end
	end

	local nearestPlot = ResolveNearestSpawnPlotName(prompt)
	if nearestPlot then return nearestPlot end

	local team = player.Team
	if not team then return nil end

	local teamPlot = spawnPlotsFolder:FindFirstChild(team.Name)
	return teamPlot and teamPlot.Name or nil
end

local function ConfigurePromptDefaults(prompt: ProximityPrompt): string?
	local spawnPlotsFolder = Workspace:FindFirstChild("CarSpawnPlot")
	if not spawnPlotsFolder then return nil end

	local configuredPlot = prompt:GetAttribute("CarSpawnPlot")
	if type(configuredPlot) ~= "string" or configuredPlot == "" then
		configuredPlot = prompt:GetAttribute("SpawnPlot")
	end

	local spawnPlotName = nil
	if type(configuredPlot) == "string" and configuredPlot ~= "" and spawnPlotsFolder:FindFirstChild(configuredPlot) then
		spawnPlotName = configuredPlot
	else
		spawnPlotName = ResolveNearestSpawnPlotName(prompt)
	end

	local currentPromptPlot = prompt:GetAttribute("CarSpawnPlot")
	if spawnPlotName and (type(currentPromptPlot) ~= "string" or currentPromptPlot == "") then
		pcall(prompt.SetAttribute, prompt, "CarSpawnPlot", spawnPlotName)
	end

	local configuredWhitelist = ParsePromptAllowedTeams(prompt)
	if not configuredWhitelist and spawnPlotName and Teams:FindFirstChild(spawnPlotName) then
		pcall(prompt.SetAttribute, prompt, "AllowedTeams", spawnPlotName)
	end

	return spawnPlotName
end

local function PromptAllowsPlayer(player: Player, prompt: ProximityPrompt, spawnPlotName: string?): boolean
	local allowedTeams = ParsePromptAllowedTeams(prompt)
	if allowedTeams then
		for _, token in allowedTeams do
			if PromptTokenMatchesPlayer(player, token) then
				return true
			end
		end
		return false
	end

	if spawnPlotName and Teams:FindFirstChild(spawnPlotName) then
		local team = player.Team
		if not team then return false end
		return PlayerTeamMatches(team.Name, spawnPlotName)
	end

	return true
end

local function IsPlayerNearPrompt(player: Player, prompt: ProximityPrompt): boolean
	local character = player.Character
	if not character then return false end

	local humanoid = character:FindFirstChildOfClass("Humanoid")
	if not humanoid or humanoid.Health <= 0 then return false end

	local root = character:FindFirstChild("HumanoidRootPart")
	if not root then return false end

	local promptPosition = GetPromptWorldPosition(prompt)
	if not promptPosition then return false end

	local maxDistance = math.max(8, (prompt.MaxActivationDistance or 8) + PROMPT_DISTANCE_BUFFER)
	return (root.Position - promptPosition).Magnitude <= maxDistance
end

local function BuildPromptContext(player: Player, prompt: ProximityPrompt)
	if prompt:GetAttribute("Interface") ~= CARSPAWNER_INTERFACE then
		return nil, "NotAuthorized"
	end
	if not CollectionService:HasTag(prompt, CARSPAWN_TAG) then
		return nil, "NotAuthorized"
	end

	local defaultPlotName = ConfigurePromptDefaults(prompt)
	local spawnPlotName = ResolvePromptSpawnPlotName(player, prompt) or defaultPlotName
	if not spawnPlotName then
		return nil, "SpawnerUnavailable"
	end
	if not PromptAllowsPlayer(player, prompt, spawnPlotName) then
		return nil, "NotAuthorized"
	end
	if not IsPlayerNearPrompt(player, prompt) then
		return nil, "NotAuthorized"
	end

	return {
		Prompt = prompt,
		SpawnPlotName = spawnPlotName,
		ExpiresAt = os.clock() + PROMPT_CONTEXT_TTL,
	}
end

local function RememberPromptContext(player: Player, prompt: ProximityPrompt)
	local context = BuildPromptContext(player, prompt)
	if not context then
		ActivePromptContexts[player] = nil
		return
	end

	ActivePromptContexts[player] = context
end

local function ResolveContextFromNearbyPrompt(player: Player)
	local character = player.Character
	local root = character and character:FindFirstChild("HumanoidRootPart")
	if not root then
		return nil
	end

	local bestPrompt = nil
	local bestContext = nil
	local bestDistance = math.huge

	for prompt in PromptConnections do
		if not (prompt and prompt.Parent and prompt:IsA("ProximityPrompt")) then continue end
		local context = BuildPromptContext(player, prompt)
		if not context then continue end

		local promptPosition = GetPromptWorldPosition(prompt)
		if not promptPosition then continue end

		local distance = (root.Position - promptPosition).Magnitude
		if distance >= bestDistance then continue end

		bestDistance = distance
		bestPrompt = prompt
		bestContext = context
	end

	if not (bestPrompt and bestContext) then
		return nil
	end

	ActivePromptContexts[player] = bestContext
	return bestContext
end

local function ValidatePromptContext(player: Player, requestedPrompt): (boolean, string)
	local directContext = nil
	local directErr = nil

	if requestedPrompt then
		local ok, isPrompt = pcall(function()
			return requestedPrompt:IsA("ProximityPrompt")
		end)

		if ok and isPrompt and requestedPrompt.Parent then
			directContext, directErr = BuildPromptContext(player, requestedPrompt)
			if directContext then
				ActivePromptContexts[player] = directContext
				return true, directContext.SpawnPlotName
			end
		else
			directErr = "NotAuthorized"
		end
	end

	local context = ActivePromptContexts[player]
	if context and (context.ExpiresAt or 0) < os.clock() then
		ActivePromptContexts[player] = nil
		context = nil
	end

	local lastErr = directErr
	if context and context.Prompt and context.Prompt.Parent then
		local refreshedContext, refreshErr = BuildPromptContext(player, context.Prompt)
		if refreshedContext then
			ActivePromptContexts[player] = refreshedContext
			return true, refreshedContext.SpawnPlotName
		end
		ActivePromptContexts[player] = nil
		lastErr = refreshErr or lastErr
	end

	local nearbyContext = ResolveContextFromNearbyPrompt(player)
	if nearbyContext then
		return true, nearbyContext.SpawnPlotName
	end

	return false, lastErr or "NotAuthorized"
end

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
CarSpawnLocation_OverlapParams.FilterDescendantsInstances = {Workspace:FindFirstChild("CarSpawnPlot")}

local function GetSpawnLocation(Player:Player, CarModel:Model, SpawnPlotName:string?)
	local spawnPlotsFolder = Workspace:FindFirstChild("CarSpawnPlot")
	if not spawnPlotsFolder then return nil end

	local team = Player.Team
	local teamName = team and team.Name or nil
	local SpawnPlot = SpawnPlotName and spawnPlotsFolder:FindFirstChild(SpawnPlotName) or nil
	if not SpawnPlot and teamName then
		SpawnPlot = spawnPlotsFolder:FindFirstChild(teamName)
	end
	if not SpawnPlot then return nil end

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
	for _, Attachment:Attachment in SpawnPlot:GetChildren() do
		if not Attachment:IsA("Attachment") then continue end

		local cf = Attachment.WorldCFrame
		cf += (Vector3.yAxis * ExtentsSize.Y * .5)

		local PartsInPart = Workspace:GetPartBoundsInBox(cf ,ExtentsSize, CarSpawnLocation_OverlapParams)--workspace:GetPartsInPart(Part, CarSpawnLocation_OverlapParams)
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


function module:SpawnVehicle(Player:Player, VehicleName:number, VehicleColor:string, SpawnPlotName:string?)
	--> Destroy Previous Car
	DestroyPlayerCar(Player)

	-- Check if vehicle is on list
	local VehicleModel = VehiclePath:FindFirstChild(VehicleName) or VehiclePath:FindFirstChild("Falcon Explorer 2020")
	if not VehicleModel then return false, "CarModelNotFound" end

	local Character = Player.Character

	local CarClone = VehicleModel:Clone()
	CarClone.Parent = Workspace
	CarClone:AddTag("Car")

	local SpawnPosition = GetSpawnLocation(Player, CarClone, SpawnPlotName)
	if not SpawnPosition then
		CarClone:Destroy()
		return false, "SpawnerUnavailable"
	end
	CarClone:PivotTo(SpawnPosition)
	CarClone:SetAttribute("Owner", Player.Name)

	SetupCar(CarClone, VehicleColor)

	task.spawn(function()
		task.wait(.5)

		local VehicleSeat = CarClone:FindFirstChildOfClass("VehicleSeat")
		if VehicleSeat and Character and Character.Parent and Character:FindFirstChildOfClass("Humanoid") then
			Character:PivotTo(VehicleSeat:GetPivot() + Vector3.new(0, 3.5, 0))
			VehicleSeat:Sit(Character.Humanoid)
		end
	end)


	SpawnedCars[Player] = CarClone

	return true, "VehicleSpawned"
end

local function BindSpawnerPrompt(prompt: ProximityPrompt)
	if PromptConnections[prompt] then return end
	if prompt:GetAttribute("Interface") ~= CARSPAWNER_INTERFACE then return end
	ConfigurePromptDefaults(prompt)

	PromptConnections[prompt] = prompt.Triggered:Connect(function(player: Player)
		RememberPromptContext(player, prompt)
	end)
end

local function UnBindSpawnerPrompt(prompt: Instance)
	local conn = PromptConnections[prompt]
	if conn then
		conn:Disconnect()
		PromptConnections[prompt] = nil
	end

	for player, context in ActivePromptContexts do
		if context.Prompt == prompt then
			ActivePromptContexts[player] = nil
		end
	end
end

function module.Init()
	local spawnPlotsFolder = Workspace:FindFirstChild("CarSpawnPlot")
	CarSpawnLocation_OverlapParams.FilterDescendantsInstances = spawnPlotsFolder and {spawnPlotsFolder} or {}

	InteractEvent.OnServerInvoke = function(player:Player, VehicleListIndex:number, VehicleName:string, VehicleColor:string, requestedPrompt)
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
			local maySpawn, spawnPlotOrErr = ValidatePromptContext(player, requestedPrompt)
			if not maySpawn then
				return false, spawnPlotOrErr
			end

			local succ, resultErr = module:SpawnVehicle(player, VehicleName, VehicleColor, spawnPlotOrErr)
			if not succ then
				return false, resultErr or "SpawnerUnavailable"
			end

			return true, resultErr or "VehicleSpawned"
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

	for _, tagged in CollectionService:GetTagged(CARSPAWN_TAG) do
		if tagged:IsA("ProximityPrompt") then
			BindSpawnerPrompt(tagged)
		end
	end

	CollectionService:GetInstanceAddedSignal(CARSPAWN_TAG):Connect(function(inst: Instance)
		if not inst:IsA("ProximityPrompt") then return end
		BindSpawnerPrompt(inst)
	end)

	CollectionService:GetInstanceRemovedSignal(CARSPAWN_TAG):Connect(UnBindSpawnerPrompt)

	Players.PlayerRemoving:Connect(function(player:Player)
		DestroyPlayerCar(player)
		ActivePromptContexts[player] = nil
	end)

	return true
end



return module
