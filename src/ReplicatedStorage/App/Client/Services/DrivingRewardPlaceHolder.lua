--!strict

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local app = ReplicatedStorage:WaitForChild("App")
local shared = app:WaitForChild("Shared")

local Net = require(shared:WaitForChild("Net")) :: any

--// Service
local DrivingRewardService = {}

function DrivingRewardService:Init()
	Net.DrivingReward.On(function(moneyDelta: number, xpDelta: number)
		warn("f: DrivingReward: Money:", moneyDelta, "XP:", xpDelta)
	end)
end

return DrivingRewardService
