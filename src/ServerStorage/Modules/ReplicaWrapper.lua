local ServerStorage = game:GetService('ServerStorage')
local ReplicatedStorage = game:GetService('ReplicatedStorage')

local TableUtil = require(ReplicatedStorage.Packages.TableUtil)
local ReplicaServer = require(ServerStorage.Packages.ReplicaServer)

local Util = {}

local function _getPointer(data: {[any]: any}, path: {string})
	local pointer = data
	for i = 1, #path do
		if pointer == nil then break end
		pointer = pointer[path[i]]
	end
	return pointer
end

function Util.Get(replica: ReplicaServer.Replica, path: {string}): any
	if not (replica and path) then return end
	return if #path > 0 then _getPointer(replica.Data, path) else replica.Data
end

function Util.Set(replica: ReplicaServer.Replica, path: {string}, value: any): boolean
	if not (replica and path) then return false end

	if #path == 0 then
		local currData = TableUtil.Copy(Util.Get(replica, {}), true)
		for id, _ in currData do
			if value[id]~=nil then continue end
			replica:Set({id}, nil)
		end
		
		for id, data in value do
			replica:Set({id}, data)
		end
	else
		replica:Set(path, value)
	end
	return true
end

function Util.SetValues(replica: ReplicaServer.Replica, path: {string}, values: {[string]: {any}}): boolean
	if not (replica and path and values) then return false end

	replica:SetValues(path, values)
	return true
end

function Util.Increase(replica: ReplicaServer.Replica, path: {string}, value: number, _forcePositive: boolean?): boolean
	if not (replica and path and value) then return false end

	local pointer = replica.Data
	for i = 1, #path do
		if pointer == nil then break end
		pointer = pointer[path[i]]
	end

	if pointer and ( typeof(pointer)~='number' or (_forcePositive and 0 > (pointer+value)) ) then return false end

	replica:Set(path, (pointer or 0) + value)
	return true
end

function Util.Insert(replica: ReplicaServer.Replica, path: {string}, value: any, index: number?, preventDuplicates: boolean?): number?
	if not (replica and path and value) then return end

	if preventDuplicates then
		local pointer = _getPointer(replica.Data, path)
		if pointer and typeof(pointer)=='table' and table.find(pointer, value) then return end
	end
	return replica:TableInsert(path, value, index)
end

function Util.Remove(replica: ReplicaServer.Replica, path: {string}, index: number?): boolean
	if not (replica and path and index) then return false end

	replica:TableRemove(path, index)
	return true
end

function Util.FetchRemove(replica: ReplicaServer.Replica, path: {string}, value: any): boolean
	if not (replica and path and value) then return false end

	local pointer = _getPointer(replica.Data, path)
	local index = (pointer and typeof(pointer)=='table') and table.find(pointer, value) or nil
	if not index then return false end

	replica:TableRemove(path, index)
	return true
end

return Util 