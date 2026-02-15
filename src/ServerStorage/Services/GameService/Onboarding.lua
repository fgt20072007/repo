local ReplicatedStorage = game:GetService 'ReplicatedStorage'
local ServerStorage = game:GetService 'ServerStorage'

local Data = ReplicatedStorage.Data
local GeneralData = require(Data.General)
local OnboardingData = require(Data.Onboarding)

local Net = require(ReplicatedStorage.Packages.Net)
local DataService = require(ServerStorage.Services.DataService)

local NotifyEvent = Net:RemoteEvent('Notification')

local SkipEvent = Net:RemoteEvent('SkippedOnboarding')
local CompleteEvent = Net:RemoteEvent('CompletedOnboarding')

local Manager = {}

function Manager._ShouldProceed(player: Player): boolean
	local team = player.Team
	if not (team and OnboardingData[team.Name]) then return false end
	
	local dataManager = DataService.GetManager('PlayerData')
	if not dataManager then return false end
	
	local curr = dataManager:Get(player, {'Onboarded', team.Name})
	if curr == true then return false end
	
	return dataManager:Set(player, {'Onboarded', team.Name}, true)
end

function Manager._OnSkipAttempt(player: Player)
	Manager._ShouldProceed(player)
end

function Manager._OnCompleteAttempt(player: Player)
	if not Manager._ShouldProceed(player) then return end

	local succ = DataService.AdjustBalance(player, GeneralData.OnboardingReward)
	if not succ then return end
	
	NotifyEvent:FireClient(player, 'Rewards/Onboarding')
end

function Manager.Init()
	SkipEvent.OnServerEvent:Connect(Manager._OnSkipAttempt)
	CompleteEvent.OnServerEvent:Connect(Manager._OnCompleteAttempt)
end

table.freeze(Manager)
return Manager
