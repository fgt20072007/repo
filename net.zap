opt server_output = "src/ReplicatedStorage/App/Shared/Net/Server.lua"
opt client_output = "src/ReplicatedStorage/App/Shared/Net/Client.lua"
opt types_output = "src/ReplicatedStorage/App/Shared/Net/Types.lua"
opt remote_folder = "AppNet"
opt remote_scope = "APP"
opt casing = "PascalCase"
opt write_checks = true

event HotbarSetSlot = {
	from: Server,
	type: Reliable,
	call: ManyAsync,
	data: (slot: u8, uid: string.utf8, toolName: string.utf8, textureId: string.utf8)
}

event HotbarSetEquipped = {
	from: Server,
	type: Reliable,
	call: ManyAsync,
	data: (slot: u8, isEquipped: boolean)
}

event HotbarRequestToggle = {
	from: Client,
	type: Reliable,
	call: ManyAsync,
	data: (slot: u8)
}

event HotbarClearSlot = {
	from: Server,
	type: Reliable,
	call: ManyAsync,
	data: (slot: u8)
}

event CombatRequestAttack = {
	from: Client,
	type: Reliable,
	call: ManyAsync,
	data: (comboIndex: u8)
}

event CombatRequestParry = {
	from: Client,
	type: Reliable,
	call: ManyAsync,
	data: ()
}

funct GetServerTime = {
	call: Async,
	rets: f64,
}

event CombatRequestParryEnd = {
	from: Client,
	type: Reliable,
	call: ManyAsync,
	data: ()
}
