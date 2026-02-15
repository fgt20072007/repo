		--!strict
local ReplicatedStorage = game:GetService 'ReplicatedStorage'
local TableUtil = require(ReplicatedStorage.Packages.TableUtil)

return TableUtil.Lock {
	CarryMaxSellable = 10,
	CarryMaxNonSellable = 10,
	
	ArrestXP = 10,
	FedKillXP = 5,
	CriminalKillXP = 5,
	
	PlaytimeXP = 15,
	PlaytimeEvery = 4*60,
	
	OnboardingReward = 5_000,
	JanitorReward = 25,
	
	DynamicWaypointsEnabled = false,
}