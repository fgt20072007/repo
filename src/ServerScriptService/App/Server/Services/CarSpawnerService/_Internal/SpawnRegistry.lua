--!strict

export type Record = {
	DisplayVehicles: { Model },
	ActiveDriveVehicle: Model?,
}

export type Registry = {
	Get: (self: Registry, player: Player) -> Record?,
	Set: (self: Registry, player: Player, record: Record) -> (),
	Clear: (self: Registry, player: Player) -> Record?,
	Destroy: (self: Registry) -> (),

	_recordsByPlayer: { [Player]: Record },
}

local SpawnRegistry = {}
SpawnRegistry.__index = SpawnRegistry

function SpawnRegistry.New(): Registry
	local self = setmetatable({
		_recordsByPlayer = {},
	}, SpawnRegistry)

	return (self :: any) :: Registry
end

function SpawnRegistry:Get(player: Player): Record?
	return self._recordsByPlayer[player]
end

function SpawnRegistry:Set(player: Player, record: Record)
	self._recordsByPlayer[player] = record
end

function SpawnRegistry:Clear(player: Player): Record?
	local record = self._recordsByPlayer[player]
	self._recordsByPlayer[player] = nil

	return record
end

function SpawnRegistry:Destroy()
	table.clear(self._recordsByPlayer)
end

return table.freeze({
	New = SpawnRegistry.New,
})