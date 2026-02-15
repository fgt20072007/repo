local ServerStorage = game:GetService("ServerStorage")
local Players = game:GetService("Players")

local Packages = ServerStorage:WaitForChild('Packages')
local ProfileStore = require(Packages.ProfileStore)
local Replica = require(Packages.ReplicaServer)

local PROFILE_TEMPLATE = {
	TeamXP = {
		["Civilian"] = 0,
		["Border Patrol"] = 0,
		["State Trooper"] = 0,
		["HSI"] = 0,
	},
}

local PlayerStore = ProfileStore.New("PlayerStore", PROFILE_TEMPLATE)
local Profiles: {[Player]: typeof(PlayerStore:StartSessionAsync())} = {}

local PlayerProfileToken = Replica.Token("PlayerProfileData")

local ProfileReplicas = {}
local ReadyConnections = {}
local ProfilesService = {}

local function deepCopy(tbl)
	local result = {}
	for key, value in pairs(tbl) do
		result[key] = if typeof(value) == "table" then deepCopy(value) else value
	end
	return result
end

local function ensureTeamContainer(profile)
	local data = profile.Data
	local container = data.TeamXP
	if typeof(container) ~= "table" then
		container = {}
		data.TeamXP = container
	end
	for teamName, defaultValue in pairs(PROFILE_TEMPLATE.TeamXP) do
		if typeof(container[teamName]) ~= "number" then
			container[teamName] = defaultValue
		end
	end
	return container
end

local function destroyReplicaFor(player: Player)
	local readyConnection = ReadyConnections[player]
	if readyConnection then
		readyConnection:Disconnect()
		ReadyConnections[player] = nil
	end

	local replica = ProfileReplicas[player]
	if replica then
		replica:Destroy()
		ProfileReplicas[player] = nil
	end
end

local function cleanupPlayer(player: Player)
	destroyReplicaFor(player)
	Profiles[player] = nil
end

local function subscribeReplica(replica, player: Player)
	if Replica.ReadyPlayers[player] then
		replica:Subscribe(player)
		return
	end

	ReadyConnections[player] = Replica.NewReadyPlayer:Connect(function(readyPlayer)
		if readyPlayer ~= player then
			return
		end

		replica:Subscribe(player)
		local connection = ReadyConnections[player]
		if connection then
			connection:Disconnect()
			ReadyConnections[player] = nil
		end
	end)
end

local function createReplica(player: Player, profile)
	local replica = Replica.New({
		Token = PlayerProfileToken,
		Tags = {
			UserId = player.UserId,
		},
		Data = {
			UserId = player.UserId,
			DisplayName = player.DisplayName,
			TeamXP = deepCopy(profile.Data.TeamXP),
		},
	})

	subscribeReplica(replica, player)
	ProfileReplicas[player] = replica
	return replica
end

function ProfilesService.GetProfile(player: Player)
	return Profiles[player]
end

function ProfilesService.WaitForProfile(player: Player, timeoutSeconds: number?)
	local start = os.clock()
	while not Profiles[player] do
		if player.Parent ~= Players then
			break
		end
		if timeoutSeconds and os.clock() - start >= timeoutSeconds then
			break
		end
		task.wait()
	end
	return Profiles[player]
end

function ProfilesService.GetReplica(player: Player)
	return ProfileReplicas[player]
end

function ProfilesService.GetTeamXPTemplate()
	return deepCopy(PROFILE_TEMPLATE.TeamXP)
end

local function onPlayerAdded(player: Player)
	local profile = PlayerStore:StartSessionAsync(`{player.UserId}`, {
		Cancel = function()
			return player.Parent ~= Players
		end,
	})

	if profile == nil then
		player:Kick(`Profile load fail - Please rejoin`)
		return
	end

	profile:AddUserId(player.UserId)
	profile:Reconcile()
	ensureTeamContainer(profile)

	profile.OnSessionEnd:Connect(function()
		cleanupPlayer(player)
		if player.Parent == Players then
			player:Kick(`Profile session end - Please rejoin`)
		end
	end)

	if player.Parent ~= Players then
		profile:EndSession()
		return
	end

	Profiles[player] = profile
	createReplica(player, profile)
end

for _, player in Players:GetPlayers() do
	task.spawn(onPlayerAdded, player)
end

Players.PlayerAdded:Connect(onPlayerAdded)

Players.PlayerRemoving:Connect(function(player)
	local profile = Profiles[player]
	if profile ~= nil then
		profile:EndSession()
	else
		cleanupPlayer(player)
	end
end)

return ProfilesService