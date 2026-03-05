--!strict

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Maid = require(ReplicatedStorage:WaitForChild("App"):WaitForChild("Shared"):WaitForChild("Util"):WaitForChild("Maid"))

export type Service = {
	Name: string,
	Dependencies: { string },
	Maid: any,
	Init: (self: Service, registry: any) -> (),
	Start: (self: Service, registry: any) -> (),
	Destroy: (self: Service) -> (),
	_RunInit: (self: Service, registry: any) -> (),
	_RunStart: (self: Service, registry: any) -> (),

	_isInitializing: boolean,
	_isInitialized: boolean,
	_isStarting: boolean,
	_isStarted: boolean,
}

local BaseService = {}
BaseService.__index = BaseService

local function cloneDependencies(dependencies: { string }?): { string }
	if dependencies == nil then
		return {}
	end

	local copy = table.create(#dependencies)
	for index, dependency in ipairs(dependencies) do
		if type(dependency) ~= "string" then
			error(`Dependencies must contain strings only (index {index})`)
		end
		copy[index] = dependency
	end

	return copy
end

function BaseService.New(name: string, dependencies: { string }?): Service
	if type(name) ~= "string" or name == "" then
		error("Service name must be a non-empty string")
	end

	local self = setmetatable({
		Name = name,
		Dependencies = cloneDependencies(dependencies),
		Maid = Maid.New(),
		_isInitializing = false,
		_isInitialized = false,
		_isStarting = false,
		_isStarted = false,
	}, BaseService)

	return (self :: any) :: Service
end

function BaseService:Init(_registry: any)
	-- Overridden by services.
end

function BaseService:Start(_registry: any)
	-- Overridden by services.
end

function BaseService:_RunInit(registry: any)
	if self._isInitialized == true then
		return
	end
	if self._isInitializing == true then
		return
	end

	self._isInitializing = true
	local ok, err = pcall(self.Init, self, registry)
	self._isInitializing = false

	if ok ~= true then
		error(`Init failed for service "{self.Name}":\n{err}`)
	end

	self._isInitialized = true
end

function BaseService:_RunStart(registry: any)
	if self._isStarted == true then
		return
	end
	if self._isStarting == true then
		return
	end
	if self._isInitialized ~= true then
		error(`Service "{self.Name}" tried to start before initialization`)
	end

	self._isStarting = true
	local ok, err = pcall(self.Start, self, registry)
	self._isStarting = false

	if ok ~= true then
		error(`Start failed for service "{self.Name}":\n{err}`)
	end

	self._isStarted = true
end

function BaseService:Destroy()
	if self.Maid ~= nil then
		self.Maid:Cleanup()
	end
end

return BaseService
