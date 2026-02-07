local ReplicatedStorage = game:GetService('ReplicatedStorage')
local Players = game:GetService('Players')

local GlobalConfiguration = require(ReplicatedStorage.DataModules.GlobalConfiguration)
local QueryAuth = require(ReplicatedStorage.Utilities.QueryAuth)

local PromptJoinGroup = ReplicatedStorage.Communication.Functions.PromptJoinGroup

local GroupRewardHandler = {}
local isInGroupQuery = QueryAuth.Group(GlobalConfiguration.GroupId)

function GroupRewardHandler.CheckForGroup(player)
	local isInGroup = isInGroupQuery(player)
	if not isInGroup and GlobalConfiguration.PromptGroupJoin then
		PromptJoinGroup:InvokeClient(player)
	elseif isInGroup then
		--TODO: Give player the reward and open the cage
	end
end

function GroupRewardHandler.Initialize()
	Players.PlayerAdded:Connect(function(player)
		task.delay(GlobalConfiguration.GroupPromptTimeAfterJoin, function()
			GroupRewardHandler.CheckForGroup(player)
		end)
	end)
end

return GroupRewardHandler