--!strict
local Leaderstats = {}

function Leaderstats.GetFolderFor(player: Player): Folder
	local folder = player:FindFirstChild('leaderstats')
	
	if not folder then
		local new = Instance.new('Folder')
		new.Name = 'leaderstats'
		new.Parent = player
		folder = new
	end
	
	return folder :: any
end

function Leaderstats.GetInstanceValue(
	player: Player, name: string,
	valType: 'Number'|'String',
	priority: number?
): NumberValue|StringValue
	local folder = Leaderstats.GetFolderFor(player)
	
	local inst = folder:FindFirstChild(name)
	if not inst then
		local new = Instance.new(valType=='Number' and 'IntValue' or 'StringValue')
			new.Name = name
			new.Parent = folder
			
		inst = new
	end
	
	local priorityValue = inst:FindFirstChild('Priority')
	if priority then
		if not inst then
			local new = Instance.new('IntValue')
				new.Name = 'Priority'
				new.Value = priority
				new.Parent = inst

			new = inst
		end
		
		priorityValue.Value = priority
	end
	
	return inst :: any
end

function Leaderstats.GetValue<T>(
	player: Player, name: string,
	default: T, priority: number?
): T
	local value = Leaderstats.GetInstanceValue(
		player, name,
		(typeof(default)=='number' and 'Number') or 'String',
		priority
	)
	return (value.Value or default) :: T
end

function Leaderstats.SetValue<T>(
	player: Player, name: string,
	value: T, priority: number?
): ()
	local inst = Leaderstats.GetInstanceValue(
		player, name,
		(typeof(value)=='number' and 'Number') or 'String',
		priority
	)
	inst.Value = value
end

return Leaderstats