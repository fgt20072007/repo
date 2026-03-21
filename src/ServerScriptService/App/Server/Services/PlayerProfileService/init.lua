--!strict

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")

local appServer = ServerScriptService:WaitForChild("App"):WaitForChild("Server")
local libs = appServer:WaitForChild("Libs")
local system = appServer:WaitForChild("System")

local BaseService = require(system:WaitForChild("BaseService"))
local Maid =
	require(ReplicatedStorage:WaitForChild("App"):WaitForChild("Shared"):WaitForChild("Util"):WaitForChild("Maid"))
local Signal =
	require(ReplicatedStorage:WaitForChild("App"):WaitForChild("Shared"):WaitForChild("Util"):WaitForChild("Signal"))
local ProfileStore = require(libs:WaitForChild("ProfileStore"))
local ReplicaServer = require(libs:WaitForChild("ReplicaServer"))

local ProfileDataModel = require(script:WaitForChild("_Internal"):WaitForChild("ProfileDataModel"))

type PlayerRecord = {
	Profile: any,
	Replica: any,
	Maid: any,
	LastSessionEndReason: "Manual" | "External" | "Shutdown" | nil,
}

type ProfileData = {
	XP: number,
}

type EconomyData = {
	Money: number,
}

type StatsData = {
	StudsDriven: number,
	DriveSeconds: number,
	CarsSold: number,
	Kills: number,
}

type GarageData = {
	CurrentGarage: string,
	Vehicles: { [any]: any },
}

local SERVICE_NAME = "PlayerProfileService"
local LOAD_FAILURE_KICK_REASON = "No se pudo cargar tu perfil. Vuelve a entrar."
local SESSION_LOST_KICK_REASON = "Tu sesion se abrio en otro servidor."

local PlayerProfileService = BaseService.New(SERVICE_NAME)
PlayerProfileService.ProfileLoaded = Signal.New()
PlayerProfileService.ProfileReleased = Signal.New()

local baseProfileStore = ProfileStore.New(ProfileDataModel.StoreName, ProfileDataModel.BuildTemplate())
local profileStore = if ProfileDataModel.UseMock == true then baseProfileStore.Mock else baseProfileStore
local profileReplicaToken = ReplicaServer.Token(ProfileDataModel.ReplicaToken)

local recordsByPlayer: { [Player]: PlayerRecord } = {}
local loadingPlayers: { [Player]: boolean } = {}

local function isFiniteNumber(value: any): boolean
	return type(value) == "number" and value == value and value ~= math.huge and value ~= -math.huge
end

local function getProfileKey(userId: number): string
	return `Player_{userId}`
end

local function getRecord(player: Player): PlayerRecord?
	local record = recordsByPlayer[player]
	if record == nil then
		return nil
	end

	if record.Profile:IsActive() ~= true then
		return nil
	end

	return record
end

local function pushReplicaField(record: PlayerRecord, fieldName: string, value: any)
	if ProfileDataModel.IsReplicatedField(fieldName) ~= true then
		return
	end

	if record.Replica ~= nil and record.Replica:IsActive() == true then
		record.Replica:Set({ fieldName }, ProfileDataModel.CloneValue(value))
	end
end

local function subscribeReplicaForPlayer(player: Player, record: PlayerRecord)
	local function trySubscribe()
		if recordsByPlayer[player] ~= record then
			return
		end
		if ReplicaServer.ReadyPlayers[player] ~= true then
			return
		end
		if record.Replica:IsActive() ~= true then
			return
		end

		record.Replica:Subscribe(player)
	end

	if ReplicaServer.ReadyPlayers[player] == true then
		trySubscribe()
		return
	end

	local readyConnection
	readyConnection = ReplicaServer.NewReadyPlayer:Connect(function(readyPlayer: Player)
		if readyPlayer ~= player then
			return
		end

		trySubscribe()

		if readyConnection ~= nil then
			readyConnection:Disconnect()
		end
	end)

	record.Maid:Add(readyConnection)
	trySubscribe()
end

function PlayerProfileService:_DestroyRecord(player: Player, releaseProfile: boolean)
	local record = recordsByPlayer[player]
	if record == nil then
		return
	end

	recordsByPlayer[player] = nil
	record.Maid:Cleanup()

	if record.Replica ~= nil and record.Replica:IsActive() == true then
		record.Replica:Destroy()
	end

	if releaseProfile == true and record.Profile:IsActive() == true then
		record.Profile:EndSession()
	end

	self.ProfileReleased:Fire(player)
end

function PlayerProfileService:_OnSessionEnded(player: Player)
	local record = recordsByPlayer[player]
	if record == nil then
		return
	end

	local sessionEndReason = record.LastSessionEndReason
	self:_DestroyRecord(player, false)

	if sessionEndReason ~= "Manual" and sessionEndReason ~= "Shutdown" and player.Parent == Players then
		player:Kick(SESSION_LOST_KICK_REASON)
	end
end

function PlayerProfileService:_LoadPlayer(player: Player)
	if loadingPlayers[player] == true or recordsByPlayer[player] ~= nil then
		return
	end

	loadingPlayers[player] = true

	local profile = profileStore:StartSessionAsync(getProfileKey(player.UserId), {
		Cancel = function()
			return player.Parent ~= Players
		end,
	})

	loadingPlayers[player] = nil

	if profile == nil then
		if player.Parent == Players then
			player:Kick(LOAD_FAILURE_KICK_REASON)
		end
		return
	end

	profile:AddUserId(player.UserId)
	profile:Reconcile()
	ProfileDataModel.SanitizeData(profile.Data)

	if player.Parent ~= Players then
		profile:EndSession()
		return
	end

	local replica = ReplicaServer.New({
		Token = profileReplicaToken,
		Tags = {
			PlayerUserId = player.UserId,
		},
		Data = ProfileDataModel.BuildReplicaData(profile.Data),
	})

	local recordMaid = Maid.New()
	local record: PlayerRecord = {
		Profile = profile,
		Replica = replica,
		Maid = recordMaid,
		LastSessionEndReason = nil,
	}

	recordsByPlayer[player] = record

	recordMaid:Add(profile.OnLastSave:Connect(function(reason: "Manual" | "External" | "Shutdown")
		record.LastSessionEndReason = reason
	end))

	recordMaid:Add(profile.OnSessionEnd:Connect(function()
		self:_OnSessionEnded(player)
	end))

	subscribeReplicaForPlayer(player, record)
	self.ProfileLoaded:Fire(player)
end

function PlayerProfileService:Init(_registry)
	-- No dependencies for now.
end

function PlayerProfileService:Start(_registry)
	self.Maid:Add(Players.PlayerAdded:Connect(function(player)
		task.spawn(function()
			self:_LoadPlayer(player)
		end)
	end))

	self.Maid:Add(Players.PlayerRemoving:Connect(function(player)
		loadingPlayers[player] = nil
		self:_DestroyRecord(player, true)
	end))

	for _, player in ipairs(Players:GetPlayers()) do
		task.spawn(function()
			self:_LoadPlayer(player)
		end)
	end
end

function PlayerProfileService:GetSnapshot(player: Player)
	local record = getRecord(player)
	if record == nil then
		return nil
	end

	return ProfileDataModel.BuildReplicaData(record.Profile.Data)
end

function PlayerProfileService:IsLoaded(player: Player): boolean
	return getRecord(player) ~= nil
end

function PlayerProfileService:GetCurrentGarage(player: Player): string?
	local record = getRecord(player)
	if record == nil then
		return nil
	end

	local garageData = (record.Profile.Data.Garage :: any) :: GarageData
	return garageData.CurrentGarage
end

function PlayerProfileService:GetGarageVehicles(player: Player): { [any]: any }?
	local record = getRecord(player)
	if record == nil then
		return nil
	end

	local garageData = (record.Profile.Data.Garage :: any) :: GarageData
	return ProfileDataModel.CloneValue(garageData.Vehicles)
end

function PlayerProfileService:GetValue(player: Player, fieldName: string)
	if ProfileDataModel.GetRule(fieldName) == nil then
		return nil
	end

	local record = getRecord(player)
	if record == nil then
		return nil
	end

	return ProfileDataModel.CloneValue(record.Profile.Data[fieldName])
end

function PlayerProfileService:SetValue(player: Player, fieldName: string, value: any): (boolean, any)
	local record = getRecord(player)
	if record == nil then
		return false, nil
	end

	local ok, normalized = ProfileDataModel.NormalizeValue(fieldName, value)
	if ok ~= true then
		return false, nil
	end

	local storedValue = ProfileDataModel.CloneValue(normalized)
	record.Profile.Data[fieldName] = storedValue
	pushReplicaField(record, fieldName, storedValue)

	return true, ProfileDataModel.CloneValue(storedValue)
end

function PlayerProfileService:UpdateValue(
	player: Player,
	fieldName: string,
	transform: (value: any) -> any
): (boolean, any)
	if type(transform) ~= "function" then
		return false, nil
	end
	if ProfileDataModel.GetRule(fieldName) == nil then
		return false, nil
	end

	local record = getRecord(player)
	if record == nil then
		return false, nil
	end

	local currentValue = ProfileDataModel.CloneValue(record.Profile.Data[fieldName])
	local ok, nextValue = pcall(transform, currentValue)
	if ok ~= true then
		return false, nil
	end

	local candidateValue = if nextValue == nil then currentValue else nextValue
	local normalizedOk, normalized = ProfileDataModel.NormalizeValue(fieldName, candidateValue)
	if normalizedOk ~= true then
		return false, nil
	end

	local storedValue = ProfileDataModel.CloneValue(normalized)
	record.Profile.Data[fieldName] = storedValue
	pushReplicaField(record, fieldName, storedValue)

	return true, ProfileDataModel.CloneValue(storedValue)
end

function PlayerProfileService:IncrementValue(player: Player, fieldName: string, delta: number): (boolean, number?)
	if isFiniteNumber(delta) ~= true then
		return false, nil
	end
	if ProfileDataModel.IsNumericField(fieldName) ~= true then
		return false, nil
	end

	local record = getRecord(player)
	if record == nil then
		return false, nil
	end

	local currentValue = record.Profile.Data[fieldName]
	if type(currentValue) ~= "number" then
		return false, nil
	end

	local ok, normalized = ProfileDataModel.NormalizeValue(fieldName, currentValue + delta)
	if ok ~= true then
		return false, nil
	end

	record.Profile.Data[fieldName] = normalized
	pushReplicaField(record, fieldName, normalized)

	return true, normalized
end

function PlayerProfileService:UpdateProfile(
	player: Player,
	transform: (profile: ProfileData) -> ProfileData
): (boolean, ProfileData?)
	local ok, value = self:UpdateValue(player, "Profile", function(profile)
		return transform((profile :: any) :: ProfileData)
	end)

	if ok ~= true or value == nil then
		return false, nil
	end

	return true, ((value :: any) :: ProfileData)
end

function PlayerProfileService:UpdateEconomy(
	player: Player,
	transform: (economy: EconomyData) -> EconomyData
): (boolean, EconomyData?)
	local ok, value = self:UpdateValue(player, "Economy", function(economy)
		return transform((economy :: any) :: EconomyData)
	end)

	if ok ~= true or value == nil then
		return false, nil
	end

	return true, ((value :: any) :: EconomyData)
end

function PlayerProfileService:UpdateStats(
	player: Player,
	transform: (stats: StatsData) -> StatsData
): (boolean, StatsData?)
	local ok, value = self:UpdateValue(player, "Stats", function(stats)
		return transform((stats :: any) :: StatsData)
	end)

	if ok ~= true or value == nil then
		return false, nil
	end

	return true, ((value :: any) :: StatsData)
end

function PlayerProfileService:SpendMoney(player: Player, amount: number): (boolean, number?)
	if isFiniteNumber(amount) ~= true or amount < 0 then
		return false, nil
	end

	local spent = false
	local ok, economy = self:UpdateEconomy(player, function(currentEconomy)
		if currentEconomy.Money < amount then
			return currentEconomy
		end

		currentEconomy.Money -= amount
		spent = true

		return currentEconomy
	end)

	if ok ~= true or spent ~= true or economy == nil then
		return false, nil
	end

	return true, economy.Money
end

return PlayerProfileService