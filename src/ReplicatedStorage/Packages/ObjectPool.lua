local ObjectPool = {}
ObjectPool.__index = ObjectPool

type ObjectPoolCallback = (object: Instance) -> ()
type CreateFunction = () -> Instance

local function empty() end

function ObjectPool.new(create: CreateFunction, size: number, onGet: ObjectPoolCallback, onFree: ObjectPoolCallback)
	local self = setmetatable({}, ObjectPool)
	
	self._objects = {}
	self._create = create
	self._onGet = onGet or empty
	self._onFree = onFree or empty
	
	for i = 1, size do
		table.insert(self._objects, create())
	end
	
	return self
end

function ObjectPool:get()
	if #self._objects == 0 then
		local new = self._create()
		self._onGet(new)
		return new
	end
	
	local object = table.remove(self._objects)
	self._onGet(object)
	return object
end

function ObjectPool:free(object: Instance)
	self._onFree(object)
	table.insert(self._objects, object)
end

function ObjectPool:clear()
	for _, object in ipairs(self._objects) do
		object:Destroy()
	end
	self._objects = {}
end

return ObjectPool