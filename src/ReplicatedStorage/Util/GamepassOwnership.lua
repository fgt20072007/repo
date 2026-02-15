--!strict
local Players = game:GetService("Players")
local MarketplaceService = game:GetService("MarketplaceService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Controllers = ReplicatedStorage:WaitForChild("Controllers")
local ReplicaController = require(Controllers:WaitForChild("ReplicaController"))

local Data = ReplicatedStorage:WaitForChild("Data")
local Passes = require(Data:WaitForChild("Passes"))

local Player = Players.LocalPlayer :: Player

local PassIdToName: {[number]: string} = {}
for passName, passId in Passes do
	PassIdToName[passId] = passName
end

local OwnershipCache: {[string]: boolean} = {}

local function ResolvePass(passRef: string | number): (string?, number?)
	if typeof(passRef) == "string" then
		local passName = passRef :: string
		return passName, Passes[passName]
	end

	local passId = passRef :: number
	return PassIdToName[passId], passId
end

local function IsGiftProduct(passName: string): boolean
	return string.sub(passName, 1, 5) == "Gift "
end

local function OwnsGiftedPass(passName: string): boolean
	local replica = ReplicaController.GetReplica("PlayerData")
	local giftedPasses = replica and replica.Data and replica.Data.GiftedPasses or nil
	return giftedPasses and table.find(giftedPasses, passName) ~= nil or false
end

local function QueryMarketplaceOwnership(passId: number): boolean?
	local ok, owns = pcall(MarketplaceService.UserOwnsGamePassAsync, MarketplaceService, Player.UserId, passId)
	if not ok then return nil end
	return owns == true
end

local GamepassOwnership = {}

function GamepassOwnership.Owns(passRef: string | number): boolean
	local passName, passId = ResolvePass(passRef)
	if not passName then return false end

	if OwnsGiftedPass(passName) then
		return true
	end

	local cached = OwnershipCache[passName]
	if cached ~= nil then
		return cached
	end

	if not passId or IsGiftProduct(passName) then
		OwnershipCache[passName] = false
		return false
	end

	local owns = QueryMarketplaceOwnership(passId)
	if owns == nil then
		return false
	end

	OwnershipCache[passName] = owns
	return owns
end

function GamepassOwnership.Invalidate(passRef: string | number?)
	if passRef == nil then
		for passName, _ in OwnershipCache do
			OwnershipCache[passName] = nil
		end
		return
	end

	local passName = ResolvePass(passRef)
	if not passName then return end

	OwnershipCache[passName] = nil
end

return table.freeze(GamepassOwnership)