local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local CollectionService = game:GetService("CollectionService")
local Teams = game:GetService("Teams")
local ServerStorage = game:GetService 'ServerStorage'

local Packages = ReplicatedStorage:WaitForChild("Packages")
local Observers = require(Packages:WaitForChild("Observers"))

local Net = require(ReplicatedStorage.Packages.Net)
local Notification = Net:RemoteEvent("Notification")

local GeneralData = require(ReplicatedStorage.Data.General)
local RankingService = require(ServerStorage.Services.RankingService)
local DataService = require(ServerStorage.Services.DataService)

local LoadoutData = require(ReplicatedStorage.Data.Loadouts)
local Ranks = require(ReplicatedStorage.Data.Ranks)

local LoadoutAssets = ServerStorage.ServerAssets.Loadouts
local ToolAssets = ServerStorage.ServerAssets.Tools

local Remote = Net:RemoteEvent("Loadout")


local AllowMultipleEquip = {
	["Tools"] = true,
	["Weapons"] = true,
	["Accessories"] = true
}

local LoadoutService = {}

local LOADOUT_TOOL_TAG = "LoadoutTool"
local ManagedToolsCache = {}
local TeamToolsCache = {}
local ManagedToolConnections: {[Player]: {RBXScriptConnection}} = {}
local PendingLoadoutApply: {[Player]: RBXScriptConnection} = {}
local CanonicalLoadoutTeamAliases: {[string]: string} = {
	["ICE"] = "HSI",
}
local LegacyLoadoutTeamAliases: {[string]: string} = {
	["HSI"] = "ICE",
}

local function GetCanonicalLoadoutTeam(teamName: string): string
	return CanonicalLoadoutTeamAliases[teamName] or teamName
end

local function GetLegacyLoadoutTeam(teamName: string): string?
	return LegacyLoadoutTeamAliases[teamName]
end

local function NormalizeLegacyLoadoutName(teamName: string, itemName: string): (string, boolean)
	local canonicalTeamName = GetCanonicalLoadoutTeam(teamName)
	if canonicalTeamName ~= "HSI" then return itemName, false end
	if string.sub(itemName, 1, 4) ~= "ICE " then return itemName, false end
	return `HSI {string.sub(itemName, 5)}`, true
end

local function NormalizeLegacyLoadoutValue(teamName: string, value: any): (any, boolean)
	if typeof(value) == "string" then
		return NormalizeLegacyLoadoutName(teamName, value)
	end

	if typeof(value) ~= "table" then
		return value, false
	end

	local normalized = {}
	local changed = false

	if #value > 0 then
		for index, entry in value do
			local normalizedEntry, entryChanged = NormalizeLegacyLoadoutValue(teamName, entry)
			normalized[index] = normalizedEntry
			if entryChanged then
				changed = true
			end
		end
	else
		for key, entry in pairs(value) do
			local normalizedKey = key
			if typeof(key) == "string" then
				local mappedKey, keyChanged = NormalizeLegacyLoadoutName(teamName, key)
				normalizedKey = mappedKey
				if keyChanged then
					changed = true
				end
			end

			local normalizedEntry, entryChanged = NormalizeLegacyLoadoutValue(teamName, entry)
			normalized[normalizedKey] = normalizedEntry
			if entryChanged then
				changed = true
			end
		end
	end

	if not changed then
		return value, false
	end

	return normalized, true
end

local function MigrateLegacyLoadout(dataManager: any, player: Player, teamName: string): {[string]: any}?
	local canonicalTeamName = GetCanonicalLoadoutTeam(teamName)
	local legacyTeamName = GetLegacyLoadoutTeam(canonicalTeamName)

	local canonicalLoadout = dataManager:Get(player, {"Loadouts", canonicalTeamName})
	if canonicalLoadout ~= nil then
		local normalizedCanonicalLoadout, canonicalChanged = NormalizeLegacyLoadoutValue(canonicalTeamName, canonicalLoadout)
		if canonicalChanged then
			dataManager:Set(player, {"Loadouts", canonicalTeamName}, normalizedCanonicalLoadout)
			canonicalLoadout = dataManager:Get(player, {"Loadouts", canonicalTeamName})
		end

		if legacyTeamName and dataManager:Get(player, {"Loadouts", legacyTeamName}) ~= nil then
			dataManager:Set(player, {"Loadouts", legacyTeamName}, nil)
		end

		return canonicalLoadout
	end

	if not legacyTeamName then return nil end

	local legacyLoadout = dataManager:Get(player, {"Loadouts", legacyTeamName})
	if legacyLoadout == nil then return nil end

	local normalizedLegacyLoadout, _ = NormalizeLegacyLoadoutValue(canonicalTeamName, legacyLoadout)
	dataManager:Set(player, {"Loadouts", canonicalTeamName}, normalizedLegacyLoadout)
	dataManager:Set(player, {"Loadouts", legacyTeamName}, nil)
	return dataManager:Get(player, {"Loadouts", canonicalTeamName})
end

local function AddAllowedTool(allowed: {[string]: boolean}, item: any)
	if typeof(item) == "string" then allowed[item] = true return end
	if typeof(item) == "table" and typeof(item.Name) == "string" then allowed[item.Name] = true return end
end

local function AddAllowedFromContainer(allowed: {[string]: boolean}, container: any)
	if typeof(container) == "table" then
		if #container > 0 then
			for _, item in container do
				AddAllowedTool(allowed, item)
			end
		else
			for key, value in pairs(container) do
				if value == true and typeof(key) == "string" then
					allowed[key] = true
				elseif typeof(value) == "string" then
					allowed[value] = true
				else
					AddAllowedTool(allowed, value)
				end
			end
		end
	else
		AddAllowedTool(allowed, container)
	end
end

local function BuildAllowedTools(loadout: {[string]: any}): {[string]: boolean}
	local allowed = {}
	if not loadout then return allowed end

	AddAllowedFromContainer(allowed, loadout["Tools"])
	AddAllowedFromContainer(allowed, loadout["Weapons"])

	return allowed
end

local function BuildManagedToolsForTeam(teamName: string): {[string]: boolean}
	teamName = GetCanonicalLoadoutTeam(teamName)
	local cached = ManagedToolsCache[teamName]
	if cached then return cached end

	local managed = {}
	local teamLoadout = LoadoutData[teamName]
	if not teamLoadout then return managed end

	for _, rankData in pairs(teamLoadout) do
		AddAllowedFromContainer(managed, rankData.Tools)
		AddAllowedFromContainer(managed, rankData.Weapons)
	end

	ManagedToolsCache[teamName] = managed
	return managed
end

local function BuildTeamToolsForTeam(teamName: string): {[string]: boolean}
	local cached = TeamToolsCache[teamName]
	if cached then return cached end

	local allowed = {}
	local team = Teams:FindFirstChild(teamName)
	if team then
		for _, child in team:GetChildren() do
			if child:IsA("Tool") then
				allowed[child.Name] = true
			end
		end
	end

	TeamToolsCache[teamName] = allowed
	return allowed
end

local function IsTeamTool(teamName: string, toolName: string): boolean
	local teamTools = BuildTeamToolsForTeam(teamName)
	return teamTools[toolName] == true
end

local function NormalizeEquipped(container: any): {[string]: boolean}
	local map = {}
	if typeof(container) == "table" then
		if #container > 0 then
			for _, name in container do
				if typeof(name) == "string" then
					map[name] = true
				end
			end
		else
			for name, enabled in pairs(container) do
				if typeof(name) == "string" and typeof(enabled) == "boolean" then
					map[name] = enabled
				elseif enabled == true and typeof(name) == "string" then
					map[name] = true
				elseif typeof(enabled) == "string" then
					map[enabled] = true
				end
			end
		end
	elseif container ~= nil then
		map[tostring(container)] = true
	end
	return map
end

local function ResolveManagedCategory(teamName: string, toolName: string): string?
	teamName = GetCanonicalLoadoutTeam(teamName)
	local teamLoadout = LoadoutData[teamName]
	if not teamLoadout then return nil end

	for _, rankData in pairs(teamLoadout) do
		if rankData.Weapons then
			for _, weaponData in rankData.Weapons do
				if typeof(weaponData) == "string" and weaponData == toolName then
					return "Weapons"
				end
				if typeof(weaponData) == "table" and weaponData.Name == toolName then
					return "Weapons"
				end
			end
		end

		if rankData.Tools then
			for _, toolData in rankData.Tools do
				if typeof(toolData) == "string" and toolData == toolName then
					return "Tools"
				end
				if typeof(toolData) == "table" and toolData.Name == toolName then
					return "Tools"
				end
			end
		end
	end

	return nil
end

local function DisconnectManagedToolConnections(player: Player)
	local connections = ManagedToolConnections[player]
	if not connections then return end
	for _, connection in connections do
		connection:Disconnect()
	end
	ManagedToolConnections[player] = nil
end

local function EnforceManagedTools(player: Player, character: Model)
	DisconnectManagedToolConnections(player)
	if not player then return end
	if not character then return end

	local backpack = player:FindFirstChildOfClass("Backpack")
	local starterGear = player:FindFirstChildOfClass("StarterGear")
	if not backpack then return end

	local function IsAllowed(toolName: string): boolean
		local rawTeamName = player.Team and player.Team.Name
		if not rawTeamName then return false end
		if IsTeamTool(rawTeamName, toolName) then return true end
		local dataManager = DataService.GetManager("PlayerData")
		if not dataManager then return false end
		local loadout = MigrateLegacyLoadout(dataManager, player, GetCanonicalLoadoutTeam(rawTeamName))
		local allowed = BuildAllowedTools(loadout)
		return allowed[toolName] == true
	end

	local function HandleTool(instance: Instance)
		if not instance:IsA("Tool") then return end
		local rawTeamName = player.Team and player.Team.Name
		if not rawTeamName then return end
		local managed = BuildManagedToolsForTeam(GetCanonicalLoadoutTeam(rawTeamName))
		if not managed[instance.Name] then return end
		if IsTeamTool(rawTeamName, instance.Name) then return end
		if IsAllowed(instance.Name) then return end
		LoadoutService:RegisterExternalTool(player, instance.Name)
	end

	local connections = {}
	connections[1] = backpack.ChildAdded:Connect(HandleTool)
	connections[2] = character.ChildAdded:Connect(HandleTool)
	if starterGear then
		connections[3] = starterGear.ChildAdded:Connect(HandleTool)
	end
	ManagedToolConnections[player] = connections
end

local function EnsurePlayerDataLoaded(player: Player): boolean
	if not player then return false end
	if player:GetAttribute("LoadedData") then return true end
	if PendingLoadoutApply[player] then return false end

	PendingLoadoutApply[player] = DataService.PlayerLoaded:Connect(function(loadedPlayer: Player)
		if loadedPlayer ~= player then return end
		local connection = PendingLoadoutApply[player]
		if connection then connection:Disconnect() end
		PendingLoadoutApply[player] = nil
		task.defer(function()
			LoadoutService:ApplyLoadout(player)
		end)
	end)

	return false
end

local function RemoveUnlistedTools(player: Player, character: Model, allowed: {[string]: boolean}, managed: {[string]: boolean})
	if not (player and character) then return end

	local function ShouldRemove(name: string): boolean
		return not allowed[name]
	end

	local backpack = player:FindFirstChildOfClass("Backpack")
	local starterGear = player:FindFirstChildOfClass("StarterGear")
	local containers = {character, backpack, starterGear}
	for _, container in containers do
		if not container then continue end
		for _, item in container:GetChildren() do
			if not item:IsA("Tool") then continue end
			if not (CollectionService:HasTag(item, LOADOUT_TOOL_TAG) or managed[item.Name]) then continue end
			if player.Team and IsTeamTool(player.Team.Name, item.Name) then continue end
			if ShouldRemove(item.Name) then item:Destroy() 
				warn("destroying accesory")
			end
		end
	end
end


local function GetPlayerRank(player:Player, TargetRank:string)
	local CurrentIntitution = RankingService.GetCurrentInstitution(player)
	if not CurrentIntitution then return end

	local CurrentExp = DataService.GetInstitutionXP(player, CurrentIntitution) or 0
	local rankIndex, CurrentRank = nil, nil
	local RankReached = false
	for thisRankIndex, RankData in Ranks[CurrentIntitution].Ranks do
		if RankData.Requirement > CurrentExp then continue end
		rankIndex = thisRankIndex
		CurrentRank = RankData.Name

		if TargetRank and TargetRank == RankData.Name then
			RankReached = true
		end
	end

	return rankIndex, CurrentRank, RankReached, CurrentIntitution
end

local function InitializeDefaultLoadout(player: Player)
	local rawTeamName = player.Team and player.Team.Name
	if not rawTeamName then return end
	local teamName = GetCanonicalLoadoutTeam(rawTeamName)

	local teamLoadout = LoadoutData[teamName]
	if not teamLoadout then return end

	local DataManager = DataService.GetManager("PlayerData")
	if not DataManager then return end

	local existingLoadout = MigrateLegacyLoadout(DataManager, player, teamName)
	if existingLoadout and existingLoadout.Weapons then return end

	local rankIndex, currentRank, _, currentInstitution = GetPlayerRank(player)
	if not currentInstitution then return end

	local ranksData = Ranks[currentInstitution]
	if not ranksData then return end

	local defaultWeapons = {}
	for _, rankData in ranksData.Ranks do
		if rankData.Requirement > (DataService.GetInstitutionXP(player, currentInstitution) or 0) then continue end

		local rankLoadout = teamLoadout[rankData.Name]
		if not rankLoadout or not rankLoadout.Weapons then continue end

		for _, weaponData in rankLoadout.Weapons do
			if weaponData.DefaultEquipped == false then continue end
			table.insert(defaultWeapons, weaponData.Name)
		end
	end

	if #defaultWeapons > 0 then
		if not existingLoadout then
			DataManager:Set(player, {"Loadouts", teamName}, {})
		end
		DataManager:Set(player, {"Loadouts", teamName, "Weapons"}, defaultWeapons)
	end
end


local function ResolveCategoryFolder(category: string): Instance?
	if category == "Weapons" or category == "Tools" then return ToolAssets end
	return LoadoutAssets:FindFirstChild(category)
end

local function ApplyObject(Character:Model, Category:string, ObjectName:string)
	local Player = game.Players:GetPlayerFromCharacter(Character)
	if not Player then return end

	local CategoryFolder = ResolveCategoryFolder(Category)
	local Object = CategoryFolder and CategoryFolder:FindFirstChild(ObjectName)
	if not Object then return end

	if Category == "Shirts" or Category == "Pants" then
		local FindString = Category == "Shirts" and "Shirt" or Category
		local Replacement:Shirt = Character:FindFirstChildOfClass(FindString)
		if not Replacement then print("Not found replacement") return end

		if not Replacement:GetAttribute("Previous") then
			Replacement:SetAttribute("Previous", Replacement[`{FindString}Template`])
		end

		local Property = Replacement[`{FindString}Template`]
		if Property ~= nil then
			Replacement[`{FindString}Template`] = Object[`{FindString}Template`]
		else
			print("Shirt template nil?")
		end
	elseif Category == "Weapons" or Category == "Tools" then
		if Player.Backpack:FindFirstChild(ObjectName) or Character:FindFirstChild(ObjectName) then return end
		local Clone = Object:Clone()
		CollectionService:AddTag(Clone, LOADOUT_TOOL_TAG)
		Clone.Parent = Player.Backpack
	else
		if Character:FindFirstChild(ObjectName) then return end
		Object:Clone().Parent = Character
	end

end

function LoadoutService:ApplyLoadout(player:Player)	
	local Character = player.Character
	if not Character then return end
	if not player.Team then return end
	if not EnsurePlayerDataLoaded(player) then return end

	InitializeDefaultLoadout(player)

	local DataManager = DataService.GetManager("PlayerData")
	if not DataManager then return end

	local rankIndex, CurrentRank, RankReached, CurrentInstitution = GetPlayerRank(player)
	if not CurrentInstitution then return end

	local teamName = GetCanonicalLoadoutTeam(player.Team.Name)
	local Loadout = MigrateLegacyLoadout(DataManager, player, teamName)
	if not Loadout then
		DataManager:Set(player, {"Loadouts", teamName}, {})
		Loadout = DataManager:Get(player, {"Loadouts", teamName})
	end
	if not Loadout then return end

	local AllowedTools = BuildAllowedTools(Loadout)
	local ManagedTools = BuildManagedToolsForTeam(teamName)
	RemoveUnlistedTools(player, Character, AllowedTools, ManagedTools)
	EnforceManagedTools(player, Character)

	--> Apply Objects
	for Category, ObjectName in Loadout do
		if typeof(ObjectName) == "table" then
			if #ObjectName > 0 then
				for _, name in ObjectName do
					ApplyObject(Character, Category, name)
				end
			else
				for name, enabled in pairs(ObjectName) do
					if enabled == true then
						ApplyObject(Character, Category, name)
					end
				end
			end
		else
			ApplyObject(Character, Category, ObjectName)
		end
	end


	local Humanoid = Character:FindFirstChildOfClass("Humanoid")
	local Description = Humanoid and Humanoid:FindFirstChildOfClass("HumanoidDescription")
	local EquippedAccessories = NormalizeEquipped(Loadout["Accessories"])
	local HasEquippedAccessories = false
	for _, enabled in pairs(EquippedAccessories) do
		if enabled == true then
			HasEquippedAccessories = true
			break
		end
	end

	--> Remove Accessories
	for _, Accessory in Character:GetChildren() do
		if Accessory:IsA("Accessory") then
			local IsLoadoutAccessory = LoadoutAssets.Accessories:FindFirstChild(Accessory.Name) ~= nil
			local IsEquipped = EquippedAccessories[Accessory.Name] == true
			if not HasEquippedAccessories then
				local Transparent = Accessory:FindFirstChildOfClass("Part") or Accessory:FindFirstChildOfClass("MeshPart")

				if IsLoadoutAccessory then
				
					Accessory:Destroy()
					continue
				end

				--if Transparent then
				--	Transparent.Transparency = 0
				--end
			else
				if not IsEquipped then
					if IsLoadoutAccessory then
		
						Accessory:Destroy()
					else
						--local Transparent = Accessory:FindFirstChildOfClass("Part") or Accessory:FindFirstChildOfClass("MeshPart")
						--if Transparent then
						--	Transparent.Transparency = 1
						--end
					end
				else
					--local Transparent = Accessory:FindFirstChildOfClass("Part") or Accessory:FindFirstChildOfClass("MeshPart")
					--if Transparent then
					--	Transparent.Transparency = 0
					--end
				end
			end
		end
	end

	if not Loadout["Shirts"] then
		local Shirt = Character:FindFirstChild("Shirt")

		local Template = Shirt:GetAttribute("Previous")
		if Template then
			Shirt.ShirtTemplate = Template
		end
	end

	if not Loadout["Pants"] then
		local Pants:Pants = Character:FindFirstChild("Pants")
		local Template = Pants:GetAttribute("Previous")
		if Template then
			Pants.PantsTemplate = Template
		end
	end

end

function LoadoutService:RemoveBundle(player)
	local rawTeamName = player and player.Team and player.Team.Name
	if not rawTeamName then print("Not current team") return end
	local CurrentTeam = GetCanonicalLoadoutTeam(rawTeamName)
	local LoadoutRoot = LoadoutData[CurrentTeam]
	if not LoadoutRoot then print("Not loadout root") return end

	--> Get Current Rank
	local DataManager = DataService.GetManager("PlayerData")
	if not DataManager then return end

	DataManager:Set(player, {"Loadouts", CurrentTeam}, {})
	local legacyTeamName = GetLegacyLoadoutTeam(CurrentTeam)
	if legacyTeamName then
		DataManager:Set(player, {"Loadouts", legacyTeamName}, nil)
	end
	LoadoutService:ApplyLoadout(player)
	print("Removed")
end

function LoadoutService:RegisterExternalTool(player: Player, toolName: string, categoryOverride: string?)
	if not player or not player.Team then return end

	local teamName = GetCanonicalLoadoutTeam(player.Team.Name)
	local category = categoryOverride or ResolveManagedCategory(teamName, toolName)
	if not category then return end

	local dataManager = DataService.GetManager("PlayerData")
	if not dataManager then return end
	MigrateLegacyLoadout(dataManager, player, teamName)

	if AllowMultipleEquip[category] then
		local current = dataManager:Get(player, {"Loadouts", teamName, category})
		local equippedMap = NormalizeEquipped(current)
		equippedMap[toolName] = true
		dataManager:Set(player, {"Loadouts", teamName, category}, equippedMap)
	else
		dataManager:Set(player, {"Loadouts", teamName, category}, toolName)
	end

	self:ApplyLoadout(player)
end


function LoadoutService.Init()
	Remote.OnServerEvent:Connect(function(player:Player, Root)
		local forcedAction: string? = nil
		if typeof(Root) == "table" then
			forcedAction = Root.Action
			Root = Root.Root
		end
		if typeof(Root) ~= "string" then return end

		if Root == "RemoveBundle" then
			LoadoutService:RemoveBundle(player)
			return
		end

		local CurrentTeam = player and player.Team and player.Team.Name
		if not CurrentTeam then print("Not current team") return end
		CurrentTeam = GetCanonicalLoadoutTeam(CurrentTeam)
		local LoadoutRoot = LoadoutData[CurrentTeam]
		if not LoadoutRoot then print("Not loadout root") return end

		--> Get Current Rank
		local TargetRank = string.split(Root, "/")[1]
		local RankIndex, CurrentRank, IsRankReached = GetPlayerRank(player, TargetRank)
		if not (RankIndex and CurrentRank) then print("No rank or current rank index") return end
		if not IsRankReached then print("Not rank reached") return end

		--> Check if command is valid
		local Target = LoadoutRoot
		local CurrentItem = nil
		for iteration, Current in Root:split("/") do
			if iteration < 4 then
				if iteration == 3 then Current = tonumber(Current) end

				if not Target[Current] then return end
				Target = Target[Current]
				CurrentItem = Current
			end

			if iteration == 4 and Target and Target.Name ~= Current then
				print("NOT FOUND TARGET LOADOUT SERVICE", Current)
				return end
		end
		if not Target then print("not target") return end

		local DataManager = DataService.GetManager("PlayerData")
		if not DataManager then return end
		MigrateLegacyLoadout(DataManager, player, CurrentTeam)

		local PlayerTeamLoadoutData = DataManager:Get(player, {"Loadouts", CurrentTeam})
		if not PlayerTeamLoadoutData then
			local Key = {'Loadouts', CurrentTeam}
			DataManager:Set(player, Key, {})
			PlayerTeamLoadoutData = DataManager:Get(player, Key)
			print("Not team loadout data, creating")
		end

		local Category = Root:split("/")[2]
		local CurrentEquipped = DataManager:Get(player, {"Loadouts", CurrentTeam, Category})

		local equippedMap = NormalizeEquipped(CurrentEquipped)
		local Equip = not (equippedMap[Target.Name] == true)
		if forcedAction == "Equip" then
			Equip = true
		elseif forcedAction == "Unequip" then
			Equip = false
		end


		local t = Equip and "Equip" or "Unequip"
		Remote:FireClient(player, {
			Action = t,
			Name = Target.Name,
			Category = Category,
			Team = CurrentTeam,
		})

		if AllowMultipleEquip[Category] then
			if Equip then
				equippedMap[Target.Name] = true
			else
				equippedMap[Target.Name] = nil
			end

			if next(equippedMap) ~= nil then
				DataManager:Set(player, {"Loadouts", CurrentTeam, Category}, equippedMap)
			else
				DataManager:Set(player, {"Loadouts", CurrentTeam, Category}, nil)
			end
		else
			DataManager:Set(player, {"Loadouts", CurrentTeam, Category}, CurrentEquipped ~= Target.Name and Target.Name or nil)
		end

		LoadoutService:ApplyLoadout(player)

	end) 
end

return LoadoutService
