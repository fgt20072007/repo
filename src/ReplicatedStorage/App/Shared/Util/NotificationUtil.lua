--!strict

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local sharedData = ReplicatedStorage:WaitForChild("App"):WaitForChild("Shared"):WaitForChild("Data")
local catalogFolder = sharedData:WaitForChild("Notifications")

local NotificationCatalog = require(catalogFolder:WaitForChild("Catalog"))

export type NotificationType = NotificationCatalog.NotificationType
export type CatalogItem = NotificationCatalog.Item
export type TokenValue = string | number | boolean
export type Tokens = { [string]: TokenValue }
export type RawPayload = {
	Type: NotificationType,
	Message: string,
	Category: string?,
	Key: string?,
	Timestamp: number?,
}
export type Payload = {
	Type: NotificationType,
	Message: string,
	Category: string,
	Key: string,
	Timestamp: number,
}

local NotificationUtil = {}

local notificationTypeSet: { [NotificationType]: true } = {
	Warning = true,
	Error = true,
	Info = true,
	Success = true,
}

local function isFiniteNumber(value: any): boolean
	return type(value) == "number" and value == value and value ~= math.huge and value ~= -math.huge
end

local function stringifyTokenValue(value: TokenValue): string
	if type(value) == "string" then
		return value
	end

	return tostring(value)
end

local function replaceToken(tokens: Tokens?, tokenKey: string, placeholder: string): string
	if tokens == nil then
		return placeholder
	end

	local tokenValue = tokens[tokenKey]
	if tokenValue == nil then
		return placeholder
	end

	return stringifyTokenValue(tokenValue)
end

local function buildTimestamp(timestamp: number?): number
	if isFiniteNumber(timestamp) == true then
		return timestamp :: number
	end

	return DateTime.now().UnixTimestampMillis / 1000
end

local function freezePayload(payload: Payload): Payload
	return table.freeze(payload)
end

function NotificationUtil.IsValidType(value: any): boolean
	return notificationTypeSet[value :: NotificationType] == true
end

function NotificationUtil.GetItem(category: string, key: string): CatalogItem?
	local group = NotificationCatalog[category]
	if group == nil then
		return nil
	end

	return group[key]
end

function NotificationUtil.FormatMessage(message: string, tokens: Tokens?): string
	local formatted = string.gsub(message, "%$%{([%w_]+)%}", function(tokenKey: string)
		return replaceToken(tokens, tokenKey, "${" .. tokenKey .. "}")
	end)

	formatted = string.gsub(formatted, "{([%w_]+)}", function(tokenKey: string)
		return replaceToken(tokens, tokenKey, "{" .. tokenKey .. "}")
	end)

	return formatted
end

function NotificationUtil.ChooseMessage(item: CatalogItem, randomizer: Random?): string
	local messages = item.Messages
	local messageCount = #messages

	if messageCount <= 1 then
		return messages[1]
	end

	local picker = randomizer or Random.new()
	local selectedIndex = picker:NextInteger(1, messageCount)

	return messages[selectedIndex]
end

function NotificationUtil.BuildPayload(
	category: string,
	key: string,
	tokens: Tokens?,
	timestamp: number?,
	randomizer: Random?
): Payload?
	local item = NotificationUtil.GetItem(category, key)
	if item == nil then
		return nil
	end

	local message = NotificationUtil.FormatMessage(NotificationUtil.ChooseMessage(item, randomizer), tokens)

	return freezePayload({
		Type = item.Type,
		Message = message,
		Category = category,
		Key = key,
		Timestamp = buildTimestamp(timestamp),
	})
end

function NotificationUtil.NormalizePayload(rawPayload: RawPayload): Payload?
	if NotificationUtil.IsValidType(rawPayload.Type) ~= true then
		return nil
	end
	if type(rawPayload.Message) ~= "string" or rawPayload.Message == "" then
		return nil
	end

	local category = rawPayload.Category
	if type(category) ~= "string" or category == "" then
		category = "Direct"
	end

	local key = rawPayload.Key
	if type(key) ~= "string" or key == "" then
		key = "Message"
	end

	return freezePayload({
		Type = rawPayload.Type,
		Message = rawPayload.Message,
		Category = category,
		Key = key,
		Timestamp = buildTimestamp(rawPayload.Timestamp),
	})
end

return table.freeze(NotificationUtil)