local Teams = game:GetService("Teams")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerStorage = game:GetService("ServerStorage")
local Players = game:GetService("Players")
local MarketplaceService = game:GetService("MarketplaceService")
local CollectionService = game:GetService("CollectionService")

local LoadoutService = require(script.Parent.LoadoutService)
local MarketService = require(script.Parent.MarketService)


--//packages
local Packages = ReplicatedStorage.Packages
local Net = require(Packages.Net)

local Data = ReplicatedStorage.Data
local Teams_Data = require(Data.Teams)
local Passes_Data = require(Data.Passes)
local LoadoutData = require(Data.Loadouts)

local SignTool = ServerStorage:WaitForChild("ServerAssets"):WaitForChild("Tools"):WaitForChild("Sign")

--//events
local ChangeTeamRE = Net:RemoteEvent("ChangeTeam")

local TeamService = {}
local CanonicalTeamAliases: {[string]: string} = {
	["ICE"] = "HSI",
}
local LegacyTeamAliases: {[string]: string} = {
	["HSI"] = "ICE",
}

local function ResolveTeamDataName(teamName: string): string?
	if Teams_Data[teamName] then return teamName end

	local canonical = CanonicalTeamAliases[teamName]
	if canonical and Teams_Data[canonical] then
		return canonical
	end

	local legacy = LegacyTeamAliases[teamName]
	if legacy and Teams_Data[legacy] then
		return legacy
	end

	return nil
end

local function ResolveTeamInstanceName(teamName: string): string?
	if Teams:FindFirstChild(teamName) then
		return teamName
	end

	local canonical = CanonicalTeamAliases[teamName]
	if canonical and Teams:FindFirstChild(canonical) then
		return canonical
	end

	local legacy = LegacyTeamAliases[teamName]
	if legacy and Teams:FindFirstChild(legacy) then
		return legacy
	end

	return nil
end

local function GetLoadoutWeaponNames(teamName: string): {[string]: boolean}
	local weapons = {}
	local teamLoadout = LoadoutData[teamName]
	if not teamLoadout then return weapons end

	for _, rankData in pairs(teamLoadout) do
		if not rankData.Weapons then continue end
		for _, weaponData in rankData.Weapons do
			if weaponData.Name then weapons[weaponData.Name] = true end
		end
	end

	return weapons
end

local function IsTeamJoinAllowed(teamInstanceName: string, teamDataName: string)
	if not teamInstanceName then return false end
	if not teamDataName then return false end

	local team = Teams:FindFirstChild(teamInstanceName) :: Team
	if not team then return false end

	local teamInfo = Teams_Data[teamDataName]
	if not teamInfo then return false end

	local maxPlayers = teamInfo.MaxPlayers
	if not maxPlayers then return true end

	local playersInTeam = team:GetPlayers()
	local amountOfPlayers = #playersInTeam

	if amountOfPlayers >= maxPlayers then
		return false
	end

	return true
end

local function SetTeamTools(player: Player)
	if not player then return false end

	local team = player.Team :: Team
	if not team then return false end

	local character = player.Character or player.CharacterAdded:Wait()
	if not character then return end
	local backpack = player:FindFirstChildOfClass("Backpack") or player:WaitForChild("Backpack", 5)
	local starterGear = player:FindFirstChildOfClass("StarterGear")
	if not backpack then return end

	for _, item in team:GetChildren() do
		if not item:IsA("Tool") then continue end
		local toolName = item.Name
		if (backpack and backpack:FindFirstChild(toolName)) then continue end
		if (character and character:FindFirstChild(toolName)) then continue end
		if (starterGear and starterGear:FindFirstChild(toolName)) then continue end
		local clone = item:Clone()
		clone.Parent = backpack
	end

	return true
end

local function GiveSign(player: Player)
	local backpack = player:WaitForChild("Backpack", 10)
	if not backpack then return end
	if backpack:FindFirstChild("Sign") then return end

	local character = player.Character
	if character and character:FindFirstChild("Sign") then return end

	SignTool:Clone().Parent = backpack
end

function TeamService.ChangeTeam(player: Player, teamName: string?)
	if not teamName then return false end

	local resolvedTeamName = ResolveTeamInstanceName(teamName)
	if not resolvedTeamName then return false end

	local Team = Teams:FindFirstChild(resolvedTeamName)
	if not Team then return false end


	player:SetAttribute("Revision", nil)

	player.Team = Team
	task.delay(.5, function()

		player.CharacterAdded:Once(function()
			LoadoutService:ApplyLoadout(player)
		end)

		player:LoadCharacterAsync()
		warn("character loaded")
	end)

	return true
end

function TeamService.Init()
	Players.PlayerAdded:Connect(function(player: Player)
		if not player then return end

		player.CharacterAdded:Connect(function(character: Instance)
			if not character then return end
			SetTeamTools(player)
			GiveSign(player)
			LoadoutService:ApplyLoadout(player)
		end)
	end)

end

function TeamService.CheckTeam(player: Player, teamName: string)
	if not player then return end
	if (not player.Parent) == Players then return end

	local resolvedTeamName = ResolveTeamInstanceName(teamName)
	local Team = resolvedTeamName and Teams:FindFirstChild(resolvedTeamName)

	if not Team then
		warn("Team not found")
		return 
	end

	local teamDataName = ResolveTeamDataName(teamName)
	local teamInfo = teamDataName and Teams_Data[teamDataName]
	if not teamInfo then
		warn("Team info not found")
		return
	end

	if not IsTeamJoinAllowed(Team.Name, teamDataName) then return end

	local gamepassName = teamInfo.GamepassID
	local gamepassId = gamepassName and Passes_Data[gamepassName]
	if gamepassId then
		local ownsPass = MarketService.OwnsPass(player, gamepassName)
		if ownsPass == nil then
			return
		end

		if ownsPass then
			TeamService.ChangeTeam(player, Team.Name)
		else
			MarketplaceService:PromptGamePassPurchase(player, gamepassId)
			--SendMainNotification:FireClient(player, string.format("You don't own this Gamepass: <font color=\"rgb(255, 193, 0)\">%s</font>", teamName), "Error")

		end
	else
		if player.Team ~= Team then
			TeamService.ChangeTeam(player, Team.Name)
		end
	end
end

ChangeTeamRE.OnServerEvent:Connect(TeamService.CheckTeam)

return TeamService
