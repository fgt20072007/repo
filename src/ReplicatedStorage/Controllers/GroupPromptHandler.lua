local GroupService = game:GetService("GroupService")
local Players = game:GetService('Players')
local ReplicatedStorage = game:GetService('ReplicatedStorage')

local GlobalConfiguration = require(ReplicatedStorage.DataModules.GlobalConfiguration)
local PromptFunction = ReplicatedStorage.Communication.Functions.PromptJoinGroup

local GroupPromptHandler = {}

function GroupPromptHandler.GroupCheck()
	if Players.LocalPlayer:IsInGroupAsync(GlobalConfiguration.GroupId) then
		if not game.Workspace:FindFirstChild("GroupRewardCell") then return end
		game.Workspace.GroupRewardCell:Destroy()
	end
end

function GroupPromptHandler.PromptGroupJoinAsync()
	if not GlobalConfiguration.PromptGroupJoin then return end
	local success, errormsg = pcall(function()
		GroupService:PromptJoinAsync(GlobalConfiguration.GroupId)
	end)
end

function GroupPromptHandler.Initialize()
	PromptFunction.OnClientInvoke = function()
		GroupPromptHandler.PromptGroupJoinAsync()
	end
	GroupPromptHandler.GroupCheck()
	task.spawn(function()
		while task.wait(30) do
			GroupPromptHandler.GroupCheck()
		end
	end)
end

return GroupPromptHandler
