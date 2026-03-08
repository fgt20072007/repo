--!strict
--!native
--!optimize 2

--// Services
local RunService = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

--// Dependencies
local Maid = require(
	ReplicatedStorage:WaitForChild("App"):WaitForChild("Shared"):WaitForChild("Util"):WaitForChild("Maid")
)

--// Types
type Entry = {
	Name: string,
	Callback: (dt: number) -> (),
}

type Channel = {
	Entries: { Entry },
	Connection: RBXScriptConnection?,
}

--// Signal map (server-valid channels only)
local SIGNALS: { [string]: RBXScriptSignal } = {
	Heartbeat = RunService.Heartbeat,
	PostSimulation = RunService.PostSimulation,
	PreSimulation = RunService.PreSimulation,
	PreAnimation = RunService.PreAnimation,
	Stepped = RunService.Stepped,
}

--// RunLoop (Singleton)
local RunLoop = {}
RunLoop.__index = RunLoop

local instance: typeof(setmetatable({} :: {
	_channels: { [string]: Channel },
	_maid: any,
}, RunLoop))? = nil

function RunLoop._new()
	local self = setmetatable({
		_channels = {} :: { [string]: Channel },
		_maid = Maid.New(),
	}, RunLoop)

	return self
end

function RunLoop:_ensureChannel(channelName: string): Channel
	local channel = self._channels[channelName]
	if channel then
		return channel
	end

	local signal = SIGNALS[channelName]
	if not signal then
		error(`RunLoop: unknown channel "{channelName}"`)
	end

	channel = {
		Entries = {},
		Connection = nil,
	} :: Channel

	self._channels[channelName] = channel

	local entries = channel.Entries
	local connection = signal:Connect(function(dt: number)
		for _, entry in entries do
			debug.profilebegin(entry.Name)
			entry.Callback(dt)
			debug.profileend()
		end
	end)

	channel.Connection = connection
	self._maid:Add(connection)

	return channel
end

function RunLoop:Bind(channelName: string, name: string, callback: (dt: number) -> ()): () -> ()
	local channel = self:_ensureChannel(channelName)
	local entries = channel.Entries

	local entry: Entry = {
		Name = name,
		Callback = callback,
	}

	table.insert(entries, entry)

	local removed = false
	return function()
		if removed then
			return
		end
		removed = true

		local idx = table.find(entries, entry)
		if idx then
			local last = #entries
			entries[idx] = entries[last]
			entries[last] = nil
		end
	end
end

function RunLoop.Get()
	if instance == nil then
		instance = RunLoop._new()
	end

	return instance :: any
end

return table.freeze(RunLoop)