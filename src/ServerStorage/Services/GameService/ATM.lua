--!strict
local DataStoreService = game:GetService("DataStoreService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerStorage = game:GetService("ServerStorage")

local Packages = ReplicatedStorage.Packages
local Net = require(Packages.Net)
local RateLimit = require(Packages.ReplicaShared.RateLimit)

local Services = ServerStorage.Services
local DataService = require(Services.DataService)

local NotifyEvent = Net:RemoteEvent("Notification")
local TransferRemote = Net:RemoteFunction("ATMTransfer")

local MAX_TRANSFER_AMOUNT = 5_000
local MIN_ACCOUNT_AGE_DAYS = 7
local TRANSFER_COOLDOWN_SECONDS = 5 * 60
local TRANSFER_TAX_RATE = 0.30

local CooldownStore = DataStoreService:GetDataStore("ATMTransferCooldown_v1.0.0")
local RequestRateLimit = RateLimit.New(2)

local TransferInProgress: {[Player]: boolean} = {}

local Service = {}

local function Notify(player: Player?, id: string, args: {[string]: any}?)
	if not player then return end
	NotifyEvent:FireClient(player, id, args)
end

local function FormatDuration(seconds: number): string
	local fixed = math.max(0, math.floor(seconds))
	local minutes = math.floor(fixed / 60)
	local remainingSeconds = fixed % 60
	return string.format("%02d:%02d", minutes, remainingSeconds)
end

local function ResolveTarget(targetArg: any): Player?
	if typeof(targetArg) == "number" then
		return Players:GetPlayerByUserId(targetArg)
	end

	if typeof(targetArg) == "string" then
		local lowered = string.lower(targetArg)
		for _, target in Players:GetPlayers() do
			if string.lower(target.Name) == lowered then
				return target
			end
		end
	end

	return nil
end

local function NormalizeAmount(rawAmount: any): number?
	if typeof(rawAmount) == "number" then
		if rawAmount ~= rawAmount then return nil end
		return math.floor(rawAmount)
	end

	if typeof(rawAmount) == "string" then
		local normalized = string.gsub(rawAmount, "[,%$%s]", "")
		if normalized == "" then return nil end
		if not string.match(normalized, "^%d+$") then return nil end

		local numeric = tonumber(normalized)
		if not numeric then return nil end
		return math.floor(numeric)
	end

	return nil
end

local function ReserveGlobalCooldown(userId: number): (boolean, number?)
	local now = os.time()
	local granted = false
	local reservedUntil: number? = nil

	local success = pcall(function()
		CooldownStore:UpdateAsync(tostring(userId), function(current)
			local currentUntil = if typeof(current) == "number" then current else 0
			if currentUntil > now then
				reservedUntil = currentUntil
				return currentUntil
			end

			local nextAllowedAt = now + TRANSFER_COOLDOWN_SECONDS
			reservedUntil = nextAllowedAt
			granted = true
			return nextAllowedAt
		end)
	end)

	if not success then
		return false, nil
	end

	return granted, reservedUntil
end

local function ReleaseReservedCooldown(userId: number, expectedUntil: number?)
	if not expectedUntil then return end

	pcall(function()
		CooldownStore:UpdateAsync(tostring(userId), function(current)
			if typeof(current) == "number" and current == expectedUntil then
				return nil
			end
			return current
		end)
	end)
end

local function ProcessTransfer(player: Player, targetArg: any, amountArg: any): boolean
	local accountAge = tonumber(player.AccountAge) or 0
	if accountAge < MIN_ACCOUNT_AGE_DAYS then
		Notify(player, "ATM/AccountTooYoung", {
			minDays = MIN_ACCOUNT_AGE_DAYS,
			remaining = math.max(1, MIN_ACCOUNT_AGE_DAYS - accountAge),
		})
		return false
	end

	if not RequestRateLimit:CheckRate(player) then
		Notify(player, "ATM/RateLimited")
		return false
	end

	if TransferInProgress[player] then
		Notify(player, "ATM/RateLimited")
		return false
	end

	TransferInProgress[player] = true

	local amount = NormalizeAmount(amountArg)
	if not amount or amount <= 0 then
		TransferInProgress[player] = nil
		Notify(player, "ATM/InvalidAmount")
		return false
	end

	if amount > MAX_TRANSFER_AMOUNT then
		TransferInProgress[player] = nil
		Notify(player, "ATM/AmountTooHigh", {
			max = MAX_TRANSFER_AMOUNT,
		})
		return false
	end

	local target = ResolveTarget(targetArg)
	if not target or not target:IsDescendantOf(Players) then
		TransferInProgress[player] = nil
		Notify(player, "ATM/TargetNotFound")
		return false
	end

	if target == player then
		TransferInProgress[player] = nil
		Notify(player, "ATM/SelfTransfer")
		return false
	end

	local balance = DataService.GetBalance(player) or 0
	if balance < amount then
		TransferInProgress[player] = nil
		Notify(player, "ATM/InsufficientFunds", {
			needed = math.max(1, amount - balance),
		})
		return false
	end

	local hasCooldown, cooldownUntil = ReserveGlobalCooldown(player.UserId)
	if not hasCooldown then
		TransferInProgress[player] = nil

		if cooldownUntil then
			Notify(player, "ATM/CooldownActive", {
				time = FormatDuration(math.max(0, cooldownUntil - os.time())),
			})
		else
			Notify(player, "ATM/Unavailable")
		end

		return false
	end

	local debited = DataService.AdjustBalance(player, -amount)
	if not debited then
		ReleaseReservedCooldown(player.UserId, cooldownUntil)
		TransferInProgress[player] = nil

		local refreshedBalance = DataService.GetBalance(player) or 0
		Notify(player, "ATM/InsufficientFunds", {
			needed = math.max(1, amount - refreshedBalance),
		})
		return false
	end

	local receivedAmount = math.floor(amount * (1 - TRANSFER_TAX_RATE))
	local taxAmount = amount - receivedAmount
	if receivedAmount <= 0 then
		DataService.AdjustBalance(player, amount)
		ReleaseReservedCooldown(player.UserId, cooldownUntil)
		TransferInProgress[player] = nil
		Notify(player, "ATM/InvalidAmount")
		return false
	end

	local credited = DataService.AdjustBalance(target, receivedAmount)
	if not credited then
		DataService.AdjustBalance(player, amount)
		ReleaseReservedCooldown(player.UserId, cooldownUntil)
		TransferInProgress[player] = nil
		Notify(player, "ATM/TransferFailed")
		return false
	end

	TransferInProgress[player] = nil

	Notify(player, "ATM/TransferSuccess", {
		target = target.DisplayName,
		sent = amount,
		received = receivedAmount,
		tax = taxAmount,
	})
	Notify(target, "ATM/TransferReceived", {
		sender = player.DisplayName,
		amount = receivedAmount,
	})

	return true
end

function Service.Init()
	TransferRemote.OnServerInvoke = function(player: Player, targetArg: any, amountArg: any)
		return ProcessTransfer(player, targetArg, amountArg)
	end

	Players.PlayerRemoving:Connect(function(player: Player)
		TransferInProgress[player] = nil
		RequestRateLimit:CleanSource(player)
	end)
end

return Service