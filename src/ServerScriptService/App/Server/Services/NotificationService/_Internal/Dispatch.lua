--!strict

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local shared = ReplicatedStorage:WaitForChild("App"):WaitForChild("Shared")
local Net = require(shared:WaitForChild("Net")) :: any
local NotificationUtil = require(shared:WaitForChild("Util"):WaitForChild("NotificationUtil"))

type Payload = NotificationUtil.Payload
export type PlayerSet = { [Player]: boolean }

local Dispatch = {}

local function fireToPlayer(player: Player, payload: Payload)
	Net.NotificationPushed.Fire(player, payload.Type, payload.Message, payload.Category, payload.Key, payload.Timestamp)
end

function Dispatch.ToPlayer(player: Player, payload: Payload): boolean
	if player.Parent ~= Players then
		return false
	end

	fireToPlayer(player, payload)
	return true
end

function Dispatch.ToAll(payload: Payload): number
	local playerCount = #Players:GetPlayers()
	if playerCount == 0 then
		return 0
	end

	Net.NotificationPushed.FireAll(payload.Type, payload.Message, payload.Category, payload.Key, payload.Timestamp)

	return playerCount
end

function Dispatch.ToAllExcept(exceptPlayer: Player, payload: Payload): number
	local playerCount = #Players:GetPlayers()
	if playerCount == 0 then
		return 0
	end

	local recipients = if exceptPlayer.Parent == Players then playerCount - 1 else playerCount

	if recipients == 0 then
		return 0
	end

	Net.NotificationPushed.FireExcept(
		exceptPlayer,
		payload.Type,
		payload.Message,
		payload.Category,
		payload.Key,
		payload.Timestamp
	)

	return recipients
end

function Dispatch.ToList(players: { Player }, payload: Payload): number
	local validPlayers = table.create(#players)
	local seenPlayers: { [Player]: true } = {}

	for _, player in ipairs(players) do
		if seenPlayers[player] == nil and player.Parent == Players then
			seenPlayers[player] = true
			table.insert(validPlayers, player)
		end
	end

	if #validPlayers == 0 then
		return 0
	end

	Net.NotificationPushed.FireList(
		validPlayers,
		payload.Type,
		payload.Message,
		payload.Category,
		payload.Key,
		payload.Timestamp
	)

	return #validPlayers
end

function Dispatch.ToSet(playerSet: PlayerSet, payload: Payload): number
	local validPlayers: PlayerSet = {}
	local recipients = 0

	for player, included in pairs(playerSet) do
		if included == true and player.Parent == Players then
			validPlayers[player] = true
			recipients += 1
		end
	end

	if recipients == 0 then
		return 0
	end

	Net.NotificationPushed.FireSet(
		validPlayers,
		payload.Type,
		payload.Message,
		payload.Category,
		payload.Key,
		payload.Timestamp
	)

	return recipients
end

return table.freeze(Dispatch)