--!strict

export type Record = {
	GarageModel: Model,
	GarageKey: string,
	SlotIndex: number,
}

export type Registry = {
	Get: (self: Registry, player: Player) -> Record?,
	Set: (self: Registry, player: Player, record: Record) -> (),
	Clear: (self: Registry, player: Player) -> Record?,
	Destroy: (self: Registry) -> (),

	_recordsByPlayer: { [Player]: Record },
}

local ActiveRegistry = {}
ActiveRegistry.__index = ActiveRegistry

function ActiveRegistry.New(): Registry
	local self = setmetatable({
		_recordsByPlayer = {},
	}, ActiveRegistry)

	return (self :: any) :: Registry
end

function ActiveRegistry:Get(player: Player): Record?
	return self._recordsByPlayer[player]
end

function ActiveRegistry:Set(player: Player, record: Record)
	self._recordsByPlayer[player] = record
end

function ActiveRegistry:Clear(player: Player): Record?
	local record = self._recordsByPlayer[player]
	self._recordsByPlayer[player] = nil

	return record
end

function ActiveRegistry:Destroy()
	table.clear(self._recordsByPlayer)
end

return table.freeze({
	New = ActiveRegistry.New,
})