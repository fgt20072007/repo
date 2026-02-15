local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerStorage = game:GetService 'ServerStorage'

local Data = ReplicatedStorage.Data
local SettingsData = require(Data.Settings)

local Services = ServerStorage.Services
local DataService = require(Services.DataService)

local Packages = ReplicatedStorage.Packages
local Net = require(Packages.Net)
local RateLimit = require(Packages.ReplicaShared.RateLimit)

local UpdateRemote = Net:RemoteEvent('UpdateSetting')
local NotifyRemote = Net:RemoteEvent('Notification')

local UpdateRateLimit = RateLimit.New(2)

local SettingsService = {}

function SettingsService.OnUpdateAttempt(player: Player, id: string, newValue: boolean): boolean
	if typeof(id)~='string'
		or typeof(newValue)~='boolean'
		or not SettingsData[id]
	then return false end
	
	return DataService.UpdateSetting(player, id, newValue)
end

function SettingsService.Init()
	UpdateRemote.OnServerEvent:Connect(function(player: Player, id: string, newValue: boolean)
		if not UpdateRateLimit:CheckRate(player) then return end
		
		local succ = SettingsService.OnUpdateAttempt(player, id, newValue)
		NotifyRemote:FireClient(player, `Settings/{succ and 'Success' or 'Failed'}`)
	end)
end

return SettingsService