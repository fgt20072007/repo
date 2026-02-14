local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local app = ReplicatedStorage:WaitForChild("App")
local shared = app:WaitForChild("Shared")

local netRoot = shared:WaitForChild("Net")
local Net = require(netRoot:WaitForChild("Server"))
local Maid = require(shared:WaitForChild("Util"):WaitForChild("Maid"))
local RateLimit = require(shared:WaitForChild("Util"):WaitForChild("RateLimit"))

local HotbarSession = require(script:WaitForChild("_Internal"):WaitForChild("HotbarSession"))

local HotbarService = {}
HotbarService.__index = HotbarService

local function resolveNetEvent(container, pascalName)
	if type(container) ~= "table" then
		return nil
	end

	local eventObject = container[pascalName]
	if eventObject ~= nil then
		return eventObject
	end

	local camelName = string.lower(string.sub(pascalName, 1, 1)) .. string.sub(pascalName, 2)
	eventObject = container[camelName]
	if eventObject ~= nil then
		return eventObject
	end

	local eventsContainer = container.Events or container.events
	if type(eventsContainer) == "table" then
		eventObject = eventsContainer[pascalName]
		if eventObject ~= nil then
			return eventObject
		end

		return eventsContainer[camelName]
	end

	return nil
end

function HotbarService.new()
	local self = setmetatable({}, HotbarService)

	self._initialized = false
	self._started = false
	self._maid = Maid.New()
	self._sessions = {}
	self._toggleRateLimit = RateLimit.New(10)
	self._netEvents = {
		HotbarSetSlot = resolveNetEvent(Net, "HotbarSetSlot"),
		HotbarSetEquipped = resolveNetEvent(Net, "HotbarSetEquipped"),
		HotbarRequestToggle = resolveNetEvent(Net, "HotbarRequestToggle"),
		HotbarClearSlot = resolveNetEvent(Net, "HotbarClearSlot"),
	}

	return self
end

function HotbarService:_createSession(player)
	if self._sessions[player] then
		return
	end

	local session = HotbarSession.new(player, self._netEvents, self._toggleRateLimit)
	session:Start()
	self._sessions[player] = session
end

function HotbarService:_destroySession(player)
	local session = self._sessions[player]
	if not session then
		return
	end

	session:Destroy()
	self._sessions[player] = nil
	self._toggleRateLimit:CleanSource(player)
end

function HotbarService:Init()
	if self._initialized then
		return
	end
	self._initialized = true

	local requestToggle = self._netEvents.HotbarRequestToggle
	if type(requestToggle) ~= "table" then
		return
	end

	local subscribe = requestToggle.On or requestToggle.SetCallback
	if type(subscribe) ~= "function" then
		return
	end

	self._maid:Add(subscribe(function(player, slot)
		local session = self._sessions[player]
		if not session then
			return
		end

		session:HandleToggleRequest(slot)
	end))
end

function HotbarService:Start()
	if self._started then
		return
	end
	self._started = true

	self._maid:Add(Players.PlayerAdded:Connect(function(player)
		self:_createSession(player)
	end))

	self._maid:Add(Players.PlayerRemoving:Connect(function(player)
		self:_destroySession(player)
	end))

	for _, player in Players:GetPlayers() do
		self:_createSession(player)
	end
end

local singleton = HotbarService.new()

return table.freeze({
	Init = function()
		singleton:Init()
	end,
	Start = function()
		singleton:Start()
	end,
})
