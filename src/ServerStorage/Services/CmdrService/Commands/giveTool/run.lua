local ServerStorage = game:GetService('ServerStorage')
local Path = ServerStorage.ServerAssets.Tools

return function(context, player: Player, id: string)
	local found = Path:FindFirstChild(id)
	if not found then return 'Failed to find asset' end
	
	local new = found:Clone()
		new.Parent = player.Backpack
	
	return `{player.Name} received {id} successfully`
end