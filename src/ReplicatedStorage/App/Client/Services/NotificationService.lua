--!strict

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local app = ReplicatedStorage:WaitForChild("App")
local shared = app:WaitForChild("Shared")

local Net = require(shared:WaitForChild("Net")) :: any
local Signal = require(shared:WaitForChild("Util"):WaitForChild("Signal"))
local NotificationUtil = require(shared:WaitForChild("Util"):WaitForChild("NotificationUtil"))

type Payload = NotificationUtil.Payload
type RawPayload = NotificationUtil.RawPayload
type Tokens = NotificationUtil.Tokens

local MAX_HISTORY = 50

local NotificationService = {
	_isInitialized = false,
	_history = {} :: { Payload },
	NotificationReceived = Signal.New(),
}

local function emitNotification(self, payload: Payload)
	local history = self._history

	if #history >= MAX_HISTORY then
		table.remove(history, 1)
	end

	table.insert(history, payload)
	self.NotificationReceived:Fire(payload)
	warn(`Notification:[{payload.Type}][{payload.Category}.{payload.Key}] {payload.Message}`)
end

function NotificationService:Init()
	if self._isInitialized == true then
		return
	end

	self._isInitialized = true

	Net.NotificationPushed.On(
		function(
			notificationType: NotificationUtil.NotificationType,
			message: string,
			category: string,
			key: string,
			timestamp: number
		)
			local payload = NotificationUtil.NormalizePayload({
				Type = notificationType,
				Message = message,
				Category = category,
				Key = key,
				Timestamp = timestamp,
			})
			if payload == nil then
				return
			end

			emitNotification(self, payload)
		end
	)
end

function NotificationService:GetHistory(): { Payload }
	local copy = table.create(#self._history)

	for index, payload in ipairs(self._history) do
		copy[index] = payload
	end

	return copy
end

function NotificationService:Push(rawPayload: RawPayload): boolean
	local payload = NotificationUtil.NormalizePayload(rawPayload)
	if payload == nil then
		return false
	end

	emitNotification(self, payload)
	return true
end

function NotificationService:PushFromCatalog(category: string, key: string, tokens: Tokens?): boolean
	local payload = NotificationUtil.BuildPayload(category, key, tokens)
	if payload == nil then
		return false
	end

	emitNotification(self, payload)
	return true
end

return NotificationService