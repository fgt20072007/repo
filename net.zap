opt server_output = "src/ReplicatedStorage/App/Shared/Net/Server.lua"
opt client_output = "src/ReplicatedStorage/App/Shared/Net/Client.lua"
opt types_output = "src/ReplicatedStorage/App/Shared/Net/Types.lua"
opt remote_folder = "AppNet"
opt remote_scope = "APP"
opt casing = "PascalCase"
opt write_checks = true

funct GetServerTime = {
	call: Async,
	rets: f64,
}

event DrivingXPReward = {
	from: Server,
	type: Reliable,
	call: ManyAsync,
	data: (xpDelta: f64)
}

event DrivingMoneyReward = {
	from: Server,
	type: Reliable,
	call: ManyAsync,
	data: (moneyDelta: f64)
}

event PlayTimeMoneyReward = {
	from: Server,
	type: Reliable,
	call: ManyAsync,
	data: (moneyDelta: f64)
}
