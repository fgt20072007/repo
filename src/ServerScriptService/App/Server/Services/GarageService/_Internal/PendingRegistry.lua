--!strict

export type Registry = {
	Has: (self: Registry, player: Player) -> boolean,
	Set: (self: Registry, player: Player, garageModel: Model) -> (),
	Consume: (self: Registry, player: Player) -> Model?,
	Clear: (self: Registry, player: Player) -> (),
	Destroy: (self: Registry) -> (),

	_modelsByPlayer: { [Player]: Model },
}

local PendingRegistry = {}
PendingRegistry.__index = PendingRegistry

function PendingRegistry.New(): Registry
	local self = setmetatable({
		_modelsByPlayer = {},
	}, PendingRegistry)

	return (self :: any) :: Registry
end

function PendingRegistry:Has(player: Player): boolean
	return self._modelsByPlayer[player] ~= nil
end

function PendingRegistry:Set(player: Player, garageModel: Model)
	self._modelsByPlayer[player] = garageModel
end

function PendingRegistry:Consume(player: Player): Model?
	local garageModel = self._modelsByPlayer[player]
	self._modelsByPlayer[player] = nil

	return garageModel
end

function PendingRegistry:Clear(player: Player)
	self._modelsByPlayer[player] = nil
end

function PendingRegistry:Destroy()
	table.clear(self._modelsByPlayer)
end

return table.freeze({
	New = PendingRegistry.New,
})