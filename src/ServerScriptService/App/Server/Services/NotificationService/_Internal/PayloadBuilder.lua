--!strict

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local shared = ReplicatedStorage:WaitForChild("App"):WaitForChild("Shared")
local NotificationUtil = require(shared:WaitForChild("Util"):WaitForChild("NotificationUtil"))

export type Payload = NotificationUtil.Payload
export type RawPayload = NotificationUtil.RawPayload
export type Tokens = NotificationUtil.Tokens

local PayloadBuilder = {}

function PayloadBuilder.FromRaw(rawPayload: RawPayload): Payload?
	return NotificationUtil.NormalizePayload(rawPayload)
end

function PayloadBuilder.FromCatalog(category: string, key: string, tokens: Tokens?, randomizer: Random?): Payload?
	return NotificationUtil.BuildPayload(category, key, tokens, nil, randomizer)
end

return table.freeze(PayloadBuilder)