local ServerScriptService = game:GetService("ServerScriptService")

local Services = ServerScriptService:WaitForChild("Services")
local ProfilesService = require(Services.Profiles)

local XpService = {}

local function sanitizeXP(value: number): number
	local numberValue = tonumber(value) or 0
	if numberValue ~= numberValue then
		numberValue = 0
	end
	return math.max(0, math.floor(numberValue + 0.5))
end

local function deepCopy(dict)
	local copy = {}
	for key, value in pairs(dict) do
		copy[key] = value
	end
	return copy
end

local function ensureTeamContainer(profile)
	local data = profile.Data
	local container = data.TeamXP
	if typeof(container) ~= "table" then
		container = {}
		data.TeamXP = container
	end

	local defaults = ProfilesService.GetTeamXPTemplate()
	for teamName, defaultValue in pairs(defaults) do
		if typeof(container[teamName]) ~= "number" then
			container[teamName] = defaultValue
		end
	end

	return container
end

local function resolveTeamName(player: Player, _profile, overrideTeam: string?)
	if typeof(overrideTeam) == "string" and overrideTeam ~= "" then
		return overrideTeam
	end
	local team = player.Team
	if team then
		return team.Name
	end
	return nil
end

local function applyTeamXP(player: Player, profile, teamName: string, amount: number)
	local container = ensureTeamContainer(profile)
	if typeof(container[teamName]) ~= "number" then
		return nil, "UnknownTeam"
	end
	container[teamName] = sanitizeXP(amount)

	local replica = ProfilesService.GetReplica(player)
	if replica then
		replica:Set({"TeamXP", teamName}, container[teamName])
	end

	return container[teamName]
end

function XpService.GetAllTeamXP(player: Player)
	local profile = ProfilesService.GetProfile(player)
	if not profile then
		return nil
	end
	local container = ensureTeamContainer(profile)
	return deepCopy(container)
end

function XpService.GetTeamXP(player: Player, teamName: string?)
	local profile = ProfilesService.GetProfile(player)
	if not profile then
		return nil
	end
	local resolvedTeam = resolveTeamName(player, profile, teamName)
	if not resolvedTeam then
		return nil
	end
	local container = ensureTeamContainer(profile)
	if typeof(container[resolvedTeam]) ~= "number" then
		return nil
	end
	return container[resolvedTeam]
end

function XpService.SetTeamXP(player: Player, value: number, teamName: string?)
	local profile = ProfilesService.GetProfile(player)
	if not profile then
		return nil, "ProfileMissing"
	end
	local resolvedTeam = resolveTeamName(player, profile, teamName)
	if not resolvedTeam then
		return nil, "NoTeam"
	end
	local newValue, err = applyTeamXP(player, profile, resolvedTeam, value)
	if not newValue then
		return nil, err
	end
	return newValue
end

function XpService.AddTeamXP(player: Player, delta: number, teamName: string?)
	local profile = ProfilesService.GetProfile(player)
	if not profile then
		return nil, "ProfileMissing"
	end
	local resolvedTeam = resolveTeamName(player, profile, teamName)
	if not resolvedTeam then
		return nil, "NoTeam"
	end
	local container = ensureTeamContainer(profile)
	if typeof(container[resolvedTeam]) ~= "number" then
		return nil, "UnknownTeam"
	end
	local current = container[resolvedTeam]
	local newValue, err = applyTeamXP(player, profile, resolvedTeam, current + (tonumber(delta) or 0))
	if not newValue then
		return nil, err
	end
	return newValue
end

function XpService.RemoveTeamXP(player: Player, amount: number, teamName: string?)
	amount = tonumber(amount) or 0
	return XpService.AddTeamXP(player, -math.abs(amount), teamName)
end

return XpService
