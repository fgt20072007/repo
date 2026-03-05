--!strict

local ServiceRegistry = {}
ServiceRegistry.__index = ServiceRegistry

local function isService(service: any): boolean
	return type(service) == "table"
		and type(service.Name) == "string"
		and type(service.Dependencies) == "table"
		and type(service._RunInit) == "function"
		and type(service._RunStart) == "function"
end

function ServiceRegistry.New()
	local self = setmetatable({
		_servicesByName = {},
		_registrationOrder = {},
		_sortedOrder = nil,
		_isInitialized = false,
		_isStarted = false,
	}, ServiceRegistry)

	return self
end

function ServiceRegistry:Register(service: any)
	if self._isInitialized == true then
		error("Cannot register new services after InitAll")
	end
	if isService(service) ~= true then
		error("Invalid service object")
	end
	if self._servicesByName[service.Name] ~= nil then
		error(`Duplicate service "{service.Name}"`)
	end

	self._servicesByName[service.Name] = service
	table.insert(self._registrationOrder, service)
end

function ServiceRegistry:Get(serviceName: string)
	local service = self._servicesByName[serviceName]
	if service == nil then
		error(`Service "{serviceName}" is not registered`)
	end
	return service
end

local function buildTopologicalOrder(self)
	local servicesByName = self._servicesByName
	local order = {}
	local visitState = {} -- [serviceName] = 0 (unvisited) | 1 (visiting) | 2 (visited)

	local function dfs(serviceName: string, stack: { string })
		local state = visitState[serviceName]
		if state == 2 then
			return
		end
		if state == 1 then
			local cycle = table.concat(stack, " -> ")
			error(`Circular dependency detected: {cycle} -> {serviceName}`)
		end

		local service = servicesByName[serviceName]
		if service == nil then
			error(`Missing dependency service "{serviceName}"`)
		end

		visitState[serviceName] = 1
		table.insert(stack, serviceName)

		for _, dependencyName in ipairs(service.Dependencies) do
			if servicesByName[dependencyName] == nil then
				error(`Service "{serviceName}" requires missing dependency "{dependencyName}"`)
			end
			dfs(dependencyName, stack)
		end

		table.remove(stack)
		visitState[serviceName] = 2
		table.insert(order, service)
	end

	for _, service in ipairs(self._registrationOrder) do
		dfs(service.Name, {})
	end

	return order
end

function ServiceRegistry:InitAll()
	if self._isInitialized == true then
		return
	end

	self._sortedOrder = buildTopologicalOrder(self)
	for _, service in ipairs(self._sortedOrder) do
		service:_RunInit(self)
	end

	self._isInitialized = true
end

function ServiceRegistry:StartAll()
	if self._isStarted == true then
		return
	end
	if self._isInitialized ~= true then
		self:InitAll()
	end

	for _, service in ipairs(self._sortedOrder) do
		service:_RunStart(self)
	end

	self._isStarted = true
end

function ServiceRegistry:GetAll()
	if self._sortedOrder == nil then
		return {}
	end

	local copy = table.create(#self._sortedOrder)
	for index, service in ipairs(self._sortedOrder) do
		copy[index] = service
	end

	return copy
end

return ServiceRegistry
