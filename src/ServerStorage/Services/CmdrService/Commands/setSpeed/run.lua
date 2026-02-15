return function(context, player: Player, amount: number)
	local char = player.Character
	if not char then return `Player doesn't have a character` end
	
	local hum = char:FindFirstChildOfClass('Humanoid')
	if not hum then return `Wrong character setup` end
	
	hum.WalkSpeed = amount
	return 'Success!'
end