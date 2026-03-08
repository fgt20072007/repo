--!strict

local CollectionService = game:GetService("CollectionService")
local Players = game:GetService("Players")

local DENY_PREFIX = "DenyPrompt_"
local DESTROY_PREFIX = "DestroyPrompt_"

local localPlayer = Players.LocalPlayer :: Player

local PromptGate = {}
PromptGate.__index = PromptGate

local gate = setmetatable({
	_deniedTags = {} :: { [string]: true },
	_destroyedTags = {} :: { [string]: true },
	_tagListeners = {} :: { [string]: RBXScriptConnection },
}, PromptGate)

local function destroyPrompt(instance: Instance)
	if instance:IsA("ProximityPrompt") then
		instance:Destroy()
	end
end

local function setPromptEnabled(instance: Instance, enabled: boolean)
	if instance:IsA("ProximityPrompt") then
		(instance :: ProximityPrompt).Enabled = enabled
	end
end

function PromptGate:DestroyTag(tag: string)
	if self._destroyedTags[tag] then
		return
	end

	if self._deniedTags[tag] then
		self:AllowTag(tag)
	end

	self._destroyedTags[tag] = true

	for _, instance in CollectionService:GetTagged(tag) do
		destroyPrompt(instance)
	end

	self._tagListeners["destroy_" .. tag] = CollectionService:GetInstanceAddedSignal(tag):Connect(function(instance)
		destroyPrompt(instance)
	end)
end

function PromptGate:DenyTag(tag: string)
	if self._deniedTags[tag] or self._destroyedTags[tag] then
		return
	end

	self._deniedTags[tag] = true

	for _, instance in CollectionService:GetTagged(tag) do
		setPromptEnabled(instance, false)
	end

	self._tagListeners["deny_" .. tag] = CollectionService:GetInstanceAddedSignal(tag):Connect(function(instance)
		setPromptEnabled(instance, false)
	end)
end

function PromptGate:AllowTag(tag: string)
	if self._deniedTags[tag] ~= true then
		return
	end

	self._deniedTags[tag] = nil :: any

	local key = "deny_" .. tag
	local connection = self._tagListeners[key]
	if connection ~= nil then
		connection:Disconnect()
		self._tagListeners[key] = nil :: any
	end

	for _, instance in CollectionService:GetTagged(tag) do
		setPromptEnabled(instance, true)
	end
end

function PromptGate:IsTagDenied(tag: string): boolean
	return self._deniedTags[tag] == true
end

function PromptGate:IsTagDestroyed(tag: string): boolean
	return self._destroyedTags[tag] == true
end

local function extractPrefixedTag(attrName: string, prefix: string): string?
	if string.sub(attrName, 1, #prefix) ~= prefix then
		return nil
	end

	return string.sub(attrName, #prefix + 1)
end

function PromptGate:Init()
	local attributes = localPlayer:GetAttributes()

	for attrName, value in attributes do
		if value ~= true then
			continue
		end

		local destroyTag = extractPrefixedTag(attrName, DESTROY_PREFIX)
		if destroyTag ~= nil then
			self:DestroyTag(destroyTag)
			continue
		end

		local denyTag = extractPrefixedTag(attrName, DENY_PREFIX)
		if denyTag ~= nil then
			self:DenyTag(denyTag)
		end
	end

	localPlayer.AttributeChanged:Connect(function(attrName: string)
		local value = localPlayer:GetAttribute(attrName)

		local destroyTag = extractPrefixedTag(attrName, DESTROY_PREFIX)
		if destroyTag ~= nil then
			if value == true then
				self:DestroyTag(destroyTag)
			end
			return
		end

		local denyTag = extractPrefixedTag(attrName, DENY_PREFIX)
		if denyTag ~= nil then
			if value == true then
				self:DenyTag(denyTag)
			else
				self:AllowTag(denyTag)
			end
		end
	end)
end

return gate