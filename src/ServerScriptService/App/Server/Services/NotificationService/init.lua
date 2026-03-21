--!strict

local ServerScriptService = game:GetService("ServerScriptService")

local appServer = ServerScriptService:WaitForChild("App"):WaitForChild("Server")
local system = appServer:WaitForChild("System")

local BaseService = require(system:WaitForChild("BaseService"))

local internal = script:WaitForChild("_Internal")
local Dispatch = require(internal:WaitForChild("Dispatch"))
local PayloadBuilder = require(internal:WaitForChild("PayloadBuilder"))

type Payload = PayloadBuilder.Payload
type RawPayload = PayloadBuilder.RawPayload
type Tokens = PayloadBuilder.Tokens
type PlayerSet = Dispatch.PlayerSet

local Service = BaseService.New("NotificationService")

function Service:Init(_registry)
	self._random = Random.new()
end

function Service:Start(_registry)
	-- No runtime subscriptions yet.
end

function Service:CreatePayload(rawPayload: RawPayload): Payload?
	return PayloadBuilder.FromRaw(rawPayload)
end

function Service:CreatePayloadFromCatalog(category: string, key: string, tokens: Tokens?): Payload?
	return PayloadBuilder.FromCatalog(category, key, tokens, self._random)
end

function Service:Send(player: Player, rawPayload: RawPayload): boolean
	local payload = self:CreatePayload(rawPayload)
	if payload == nil then
		return false
	end

	return Dispatch.ToPlayer(player, payload)
end

function Service:SendFromCatalog(player: Player, category: string, key: string, tokens: Tokens?): boolean
	local payload = self:CreatePayloadFromCatalog(category, key, tokens)
	if payload == nil then
		return false
	end

	return Dispatch.ToPlayer(player, payload)
end

function Service:Broadcast(rawPayload: RawPayload): number
	local payload = self:CreatePayload(rawPayload)
	if payload == nil then
		return 0
	end

	return Dispatch.ToAll(payload)
end

function Service:BroadcastFromCatalog(category: string, key: string, tokens: Tokens?): number
	local payload = self:CreatePayloadFromCatalog(category, key, tokens)
	if payload == nil then
		return 0
	end

	return Dispatch.ToAll(payload)
end

function Service:BroadcastExcept(exceptPlayer: Player, rawPayload: RawPayload): number
	local payload = self:CreatePayload(rawPayload)
	if payload == nil then
		return 0
	end

	return Dispatch.ToAllExcept(exceptPlayer, payload)
end

function Service:BroadcastExceptFromCatalog(
	exceptPlayer: Player,
	category: string,
	key: string,
	tokens: Tokens?
): number
	local payload = self:CreatePayloadFromCatalog(category, key, tokens)
	if payload == nil then
		return 0
	end

	return Dispatch.ToAllExcept(exceptPlayer, payload)
end

function Service:SendList(players: { Player }, rawPayload: RawPayload): number
	local payload = self:CreatePayload(rawPayload)
	if payload == nil then
		return 0
	end

	return Dispatch.ToList(players, payload)
end

function Service:SendListFromCatalog(players: { Player }, category: string, key: string, tokens: Tokens?): number
	local payload = self:CreatePayloadFromCatalog(category, key, tokens)
	if payload == nil then
		return 0
	end

	return Dispatch.ToList(players, payload)
end

function Service:SendSet(playerSet: PlayerSet, rawPayload: RawPayload): number
	local payload = self:CreatePayload(rawPayload)
	if payload == nil then
		return 0
	end

	return Dispatch.ToSet(playerSet, payload)
end

function Service:SendSetFromCatalog(playerSet: PlayerSet, category: string, key: string, tokens: Tokens?): number
	local payload = self:CreatePayloadFromCatalog(category, key, tokens)
	if payload == nil then
		return 0
	end

	return Dispatch.ToSet(playerSet, payload)
end

return Service