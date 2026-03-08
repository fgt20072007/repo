--!strict

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local app = ReplicatedStorage:WaitForChild("App")
local shared = app:WaitForChild("Shared")

local Net = require(shared:WaitForChild("Net")) :: any

--// Service
local DrivingRewards = {}

function DrivingRewards:Init()
	Net.DrivingXPReward.On(function(xpDelta: number)
		warn("XP Reward:", xpDelta)
	end)

	Net.DrivingMoneyReward.On(function(moneyDelta: number)
		warn("Driving Money Reward:", moneyDelta)
	end)

	Net.PlayTimeMoneyReward.On(function(moneyDelta: number)
		warn("PlayTime Money Reward:", moneyDelta)
	end)
end

return DrivingRewards
