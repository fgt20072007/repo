local ReplicatedStorage = game:GetService('ReplicatedStorage')
local ServerStorage = game:GetService('ServerStorage')
local Players = game:GetService('Players')

local Packages = ReplicatedStorage.Packages
local Signal = require(Packages.Signal)

local ServerData = ServerStorage.Data
local ProfileStoreData = require(ServerData.ProfileStoreData)

local ServerModules = ServerStorage.Modules
local ProfileManager = require(ServerModules.ProfileManager)

local ServerPackages = ServerStorage.Packages
local ReplicaServer = require(ServerPackages.ReplicaServer)

local DataService = {
	PlayerLoaded = Signal.new() :: Signal.Signal<Player>,
	Managers = {} :: {[string]: ProfileManager.Class<any>}
}

-- PLAYER BALANCE
function DataService.GetBalance(player: Player): number?
	local dataManager = DataService.GetManager('PlayerData')
	return dataManager and dataManager:Get(player, {'Cash'}) or nil
end

function DataService.AdjustBalance(player: Player, amount: number): boolean
	local dataManager = DataService.GetManager('PlayerData')
	return dataManager and dataManager:Increase(player, {'Cash'}, amount, true) or false
end

-- PLAYER SETTINGS
function DataService.UpdateSetting(player: Player, id: string, value: boolean): boolean
	local dataManager = DataService.GetManager('PlayerData')
	return dataManager and dataManager:Set(player, {'Settings', id}, value) or nil
end

-- PLAYER XP
function DataService.GetInstitutionXP(player: Player, id: string): number?
	local dataManager = DataService.GetManager('PlayerData')
	return dataManager and dataManager:Get(player, {'XP', id}) or nil
end

function DataService._AdjustInstitutionXP(player: Player, id: string, amount: number): boolean
	-- ⚠️ should only be called from RankingService
	local dataManager = DataService.GetManager('PlayerData')
	return dataManager and dataManager:Increase(player, {'XP', id}, amount, true) or false
end

-- PLAYER VEHICLES
function DataService.InsertVehicle(player: Player, vehicleId: string): boolean
	local dataManager = DataService.GetManager('PlayerData')
	return dataManager and dataManager:Insert(player, {'Vehicles'}, vehicleId) or false
end

function DataService.RemoveVehicle(player:Player, vehicleNumberId:number): boolean
	local dataManager = DataService.GetManager('PlayerData')
	
	return dataManager and dataManager:Remove(player, {'Vehicles'}, vehicleNumberId) or false
end

-- GAMEPASSES
function DataService.InsertPass(player: Player, passId: string): boolean
	--TODO: Quizá hacer check que el gamepass esté en el database...
	local dataManager = DataService.GetManager('PlayerData')
	return dataManager and dataManager:Insert(player, {'GiftedPasses'}, passId) or false
end

function DataService.RemovePass(player: Player, PassName: string): boolean
	--TODO: Quizá hacer check que el gamepass esté en el database...
	local dataManager = DataService.GetManager('PlayerData')
	local GiftedPasses = dataManager:Get(player, {`GiftedPasses`})
	if not GiftedPasses then return false end
	
	local GamepassDataIndex = table.find(GiftedPasses, PassName)
	return dataManager and dataManager:Remove(player, {'GiftedPasses'}, GamepassDataIndex) or false
end


-- Main
function DataService.GetManager(id: string): ProfileManager.Class<any>?
	return DataService.Managers[id]
end

function DataService.GetLoaded(): {Player}
	local loaded = {}
	for _, player in Players:GetPlayers() do
		if not player:GetAttribute('LoadedData') then continue end
		table.insert(loaded, player)
	end
	return loaded
end

function DataService.OnPlayerLoaded(player: Player)
	for id, manager: ProfileManager.Class<any> in pairs(DataService.Managers) do
		local res = manager:LoadPlayerAsync(player)
		if not res then return end
	end 
	
	DataService.PlayerLoaded:Fire(player)
	player:SetAttribute('LoadedData', true)
	player:SetAttribute('JoinedAt', os.time())
end

function DataService.OnPlayerRemoving(player: Player)
	for id, manager: ProfileManager.Class<any> in DataService.Managers do
		local profile = manager:GetProfileFor(player)
		if not (profile and profile.Profile) then continue end
		
		profile.Profile:EndSession()
	end
end

function DataService.Init()
	for key, _ in ProfileStoreData do
		local new = ProfileManager.new(key)
		DataService.Managers[key] = new
	end
	
	do
		for player, available in ReplicaServer.ReadyPlayers do
			if not available then continue end
			task.spawn(DataService.OnPlayerLoaded, player)
		end
	end
	
	ReplicaServer.NewReadyPlayer:Connect(function(...)
		DataService.OnPlayerLoaded(...)
	end)
	Players.PlayerRemoving:Connect(function(...)
		DataService.OnPlayerRemoving(...)	
	end)
end

return DataService
