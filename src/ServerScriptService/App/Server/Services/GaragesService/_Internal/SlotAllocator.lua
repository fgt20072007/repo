--!strict

export type Allocator = {
	Acquire: (self: Allocator, player: Player) -> number,
	Get: (self: Allocator, player: Player) -> number?,
	Release: (self: Allocator, player: Player) -> (),
	Destroy: (self: Allocator) -> (),

	_nextSlotIndex: number,
	_freeSlotIndices: { number },
	_slotIndexByPlayer: { [Player]: number },
}

local SlotAllocator = {}
SlotAllocator.__index = SlotAllocator

function SlotAllocator.New(): Allocator
	local self = setmetatable({
		_nextSlotIndex = 1,
		_freeSlotIndices = {},
		_slotIndexByPlayer = {},
	}, SlotAllocator)

	return (self :: any) :: Allocator
end

function SlotAllocator:Acquire(player: Player): number
	local existingSlotIndex = self._slotIndexByPlayer[player]
	if existingSlotIndex ~= nil then
		return existingSlotIndex
	end

	local freeSlotCount = #self._freeSlotIndices
	local slotIndex: number
	if freeSlotCount > 0 then
		slotIndex = self._freeSlotIndices[freeSlotCount]
		self._freeSlotIndices[freeSlotCount] = nil
	else
		slotIndex = self._nextSlotIndex
		self._nextSlotIndex += 1
	end

	self._slotIndexByPlayer[player] = slotIndex
	return slotIndex
end

function SlotAllocator:Get(player: Player): number?
	return self._slotIndexByPlayer[player]
end

function SlotAllocator:Release(player: Player)
	local slotIndex = self._slotIndexByPlayer[player]
	if slotIndex == nil then
		return
	end

	self._slotIndexByPlayer[player] = nil
	table.insert(self._freeSlotIndices, slotIndex)
end

function SlotAllocator:Destroy()
	table.clear(self._slotIndexByPlayer)
	table.clear(self._freeSlotIndices)
	self._nextSlotIndex = 1
end

return table.freeze({
	New = SlotAllocator.New,
})