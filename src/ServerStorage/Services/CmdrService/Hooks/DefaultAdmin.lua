local Players = game:GetService('Players')

return function(registry)
	registry:RegisterHook('BeforeRun', function(context)
		if context.Group == 'DefaultAdmin' then
			local userId = context.Executor.UserId
			local player = userId and Players:GetPlayerByUserId(userId)
			if not player then return 'Error finding player' end

			if not player:GetAttribute('IsProtected') then
				return `You don't have permissions to run this command`
			end
		end
	end)
end
