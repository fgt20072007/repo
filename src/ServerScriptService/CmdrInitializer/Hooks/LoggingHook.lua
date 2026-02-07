local ReplicatedStorage = game:GetService('ReplicatedStorage')
local GlobalConfiguration = require(ReplicatedStorage.DataModules.GlobalConfiguration)

return function (registry)
	registry:RegisterHook("BeforeRun", function(context)
		local player: Player = context.Executor
		print(player:GetRankInGroupAsync(GlobalConfiguration.GroupID))
		if player:GetRankInGroupAsync(GlobalConfiguration.GroupID) < 5 then
			return "You don't have permission to run this command"
		end
	end)
end