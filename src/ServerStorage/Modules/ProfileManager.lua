-- no strict mode isnce it breaks lol
local Players = game:GetService('Players')
local RunService = game:GetService('RunService')
local ServerStorage = game:GetService('ServerStorage')

local Packages = ServerStorage.Packages
local ReplicaServer = require(Packages.ReplicaServer)
local ProfileStore = require(Packages.ProfileStore)

local Modules = ServerStorage.Modules
local LeaderstatsUtil = require(Modules.Leaderstats)
local ReplicaUtil = require(Modules.ReplicaWrapper)
local ProfileSettings = require(ServerStorage.Data.ProfileStoreData)

local Manager = {}
Manager.__index = Manager

export type UserData<T> = {
	Profile: ProfileStore.Profile<T>,
	Replica: ReplicaServer.Replica,
}

export type Class<T> = typeof(setmetatable({} :: {
	Store: ProfileStore.ProfileStore<T>,
	ReplicaToken: ReplicaServer.ReplicaToken,
	ActiveProfiles: {[Player]: UserData<T>},
	Config: ProfileSettings.DataSettings<T>,
}, Manager))

function Manager.new(id: string): Class<any>
	local config = ProfileSettings[id]
	assert(config, '[Unexpected error]: Each ProfileStore should have a settings dictionary!')

	local dbName = (RunService:IsStudio() and config.DevEnvName) or (config.OverrideName or id)

	return setmetatable({
		ActiveProfiles = {},
		Config = config,
		Store = ProfileStore.New(dbName, config.Template),
		ReplicaToken = ReplicaServer.Token(config.ReplicaToken),
	}, Manager)
end

-- Private
local function _getPointer(data: {[any]: any}, path: {string})
	local pointer = data
	for i = 1, #path do
		if pointer == nil then break end
		pointer = pointer[path[i]]
	end
	return pointer
end

local function _areEqual(t1: {[any]: any}, t2: {[any]: any}): boolean
	for key, value in pairs(t1) do
		if t2[key] == value then continue end
		return false
	end
	return true
end

-- Internal
function Manager._removePlayer(self: Class<{any}>, player: Player)
	local profile = player and self:GetProfileFor(player)
	if not profile then return end

	profile.Replica:Destroy()
	self.ActiveProfiles[player] = nil
end

function Manager._updateShared(self: Class<{any}>, player: Player, data: ProfileSettings.ShareData): boolean
	if not (player and data) then return false end

	local replica = self:GetReplicaFor(player)
	if not replica then return false end

	local pointer = _getPointer(replica.Data, data.Path)
	if pointer == nil then return false end

	local newVal = if data.Format then data.Format(pointer) else pointer
	LeaderstatsUtil.SetValue(player, data.Name, newVal, data.Priority)
	return true
end

function Manager._onUpdate(self: Class<{any}>, player: Player, path: {string})
	if not self.Config.Share then return end

	task.spawn(function()
		for _, data in pairs(self.Config.Share) do
			if not (#path <= 0) and not _areEqual(data.Path, path) then continue end
			self:_updateShared(player, data)
		end
	end)
end

function Manager._shareAllFor(self: Class<{any}>, player: Player)
	if not self.Config.Share then return end
	for _, data in pairs(self.Config.Share) do self:_updateShared(player, data) end
end

-- Public
function Manager.LoadPlayerAsync(self: Class<{any}>, player: Player): boolean|nil
	if not player or self:GetProfileFor(player) then return end

	local profile = self.Store:StartSessionAsync(
		self.Config.KeyFormat and string.format(self.Config.KeyFormat, player.UserId) or tostring(player.UserId),
		{ Cancel = function() return not player:IsDescendantOf(Players) end }
	)

	if not profile then
		player:Kick(`Unable to load player's data. Please rejoin!`)
		return nil
	end

	profile:AddUserId(player.UserId)
	profile:Reconcile()

	profile.OnSessionEnd:Connect(function()
		self:_removePlayer(player)
		player:Kick(`Session was ended. Please rejoin!`)
	end)

	if player:IsDescendantOf(Players) then
		local replica = ReplicaServer.New({
			Token = self.ReplicaToken,
			Tags = {UserId = player.UserId},
			Data = profile.Data
		})

		self.ActiveProfiles[player] = {
			Profile = profile,
			Replica = replica,
		}

		replica:Subscribe(player)
		self:_shareAllFor(player)

		return true
	else
		profile:EndSession()
	end
	return nil
end

function Manager.GetProfileFor<T>(self: Class<T>, player: Player): UserData<T>?
	return player and self.ActiveProfiles[player]
end

function Manager.GetReplicaFor(self: Class<{any}>, player: Player): ReplicaServer.Replica?
	local profile = player and self:GetProfileFor(player)
	return profile and profile.Replica or nil
end

function Manager.GetDataFor<T>(self: Class<T>, player: Player): T?
	local profile = player and self:GetProfileFor(player)
	return profile and profile.Profile.Data or nil
end

function Manager.Reset(self: Class<{any}>, player: Player): boolean
	return self:Set(player, {}, self.Config.Template)
end

function Manager.Get(self: Class<{any}>, player: Player, path: {string}): any
	local replica = self:GetReplicaFor(player)
	return if (replica and replica.Data) then _getPointer(replica.Data, path) else nil
end

function Manager.Set(self: Class<{any}>, player: Player, path: {string}, value: any): boolean
	local success = ReplicaUtil.Set(self:GetReplicaFor(player), path, value)
	if success then self:_onUpdate(player, path) end
	return success
end

function Manager.SetValues(self: Class<{any}>, player: Player, path: {string}, values: {[string]: {any}}): boolean
	local success = ReplicaUtil.SetValues(self:GetReplicaFor(player), path, values)
	if success then self:_onUpdate(player, path) end
	return success
end

function Manager.Increase(self: Class<{any}>, player: Player, path: {string}, value: number, _forcePositive: boolean?): boolean
	local success = ReplicaUtil.Increase(self:GetReplicaFor(player), path, value, _forcePositive)
	if success then self:_onUpdate(player, path) end
	return success
end

function Manager.Insert(self: Class<{any}>, player: Player, path: {string}, value: any, index: number?, preventDuplicates: boolean?): number?
	local success = ReplicaUtil.Insert(self:GetReplicaFor(player), path, value, index, preventDuplicates)
	if success then self:_onUpdate(player, path) end
	return success
end

function Manager.Remove(self: Class<{any}>, player: Player, path: {string}, index: number?): boolean
	local success = ReplicaUtil.Remove(self:GetReplicaFor(player), path, index)
	if success then self:_onUpdate(player, path) end
	return success
end

function Manager.FetchRemove(self: Class<{any}>, player: Player, path: {string}, value: any): boolean
	local success = ReplicaUtil.FetchRemove(self:GetReplicaFor(player), path, value)
	if success then self:_onUpdate(player, path) end
	return success
end

return Manager