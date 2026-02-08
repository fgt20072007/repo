local MarketplaceService = game:GetService("MarketplaceService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local StarterPlayer = game:GetService("StarterPlayer")
local RunService = game:GetService("RunService")

local DataService = require(ReplicatedStorage.Utilities.DataService)
local SharedUtilities = require(ReplicatedStorage.Utilities.SharedUtilities)
local RemoteBank = require(ReplicatedStorage.RemoteBank)
local Gamepasses = require(ReplicatedStorage.DataModules.Gamepasses)

local GamepassHandler = {}
local DEBUG_GAMEPASSES = true

local DEFAULT_DOUBLE_MONEY_ID = 1704637573
local DEFAULT_VIP_ID = 1704599571
local DEFAULT_DOUBLE_MONEY_MULTIPLIER = 2
local DEFAULT_VIP_MULTIPLIER = 1.5
local DEFAULT_VIP_FIRST_JOIN_REWARD = 500_000

local DoubleMoneyConfig = Gamepasses.DoubleMoney or Gamepasses["2x Money"] or Gamepasses[DEFAULT_DOUBLE_MONEY_ID] or {}
local VipConfig = Gamepasses.VIP or Gamepasses.Vip or Gamepasses[DEFAULT_VIP_ID] or {}

local DOUBLE_MONEY_ID = tonumber(DoubleMoneyConfig.Id) or DEFAULT_DOUBLE_MONEY_ID
local VIP_ID = tonumber(VipConfig.Id) or DEFAULT_VIP_ID
local DOUBLE_MONEY_MULTIPLIER = tonumber(DoubleMoneyConfig.IncomeMultiplier) or DEFAULT_DOUBLE_MONEY_MULTIPLIER
local VIP_MULTIPLIER = tonumber(VipConfig.IncomeMultiplier) or DEFAULT_VIP_MULTIPLIER
local VIP_FIRST_JOIN_REWARD = tonumber(VipConfig.FirstJoinCashReward) or DEFAULT_VIP_FIRST_JOIN_REWARD

local VIP_REWARD_CLAIM_KEY = "VipFirstJoinRewardClaimed"
local PLAYER_MULTIPLIER_ATTRIBUTE = "MoneyPerSecondMultiplier"
local PLAYER_DOUBLE_MONEY_ATTRIBUTE = "HasDoubleMoneyGamepass"
local PLAYER_VIP_ATTRIBUTE = "HasVIPGamepass"
local NEGATIVE_CACHE_SECONDS = 20
local POSITIVE_CACHE_SECONDS = 180

local VIP_TOOLS = {
	{
		Name = "Speed Coil",
		IconTextureId = "rbxassetid://99170547",
		MeshTextureId = "rbxassetid://99170547",
		SpeedBonus = 8,
		JumpBonus = 0,
	},
	{
		Name = "Fusion Coil",
		IconTextureId = "rbxassetid://16606141",
		MeshTextureId = "rbxassetid://16606141",
		SpeedBonus = 16,
		JumpBonus = 20,
		VertexColor = Vector3.new(1, 0, 1),
	},
}

type OwnershipEntry = {
	owns: boolean,
	checkedAt: number,
}

local OwnershipCache = {} :: {[Player]: {[number]: OwnershipEntry}}

local function debugLog(player: Player?, message: string)
	if not DEBUG_GAMEPASSES then
		return
	end

	if player then
		print(string.format("[GamepassDebug] %s (%d) | %s", player.Name, player.UserId, message))
	else
		print(string.format("[GamepassDebug] %s", message))
	end
end

local function logGamepassMetadata(gamepassId: number, label: string)
	if gamepassId <= 0 then
		return
	end

	local success, info = pcall(function()
		return MarketplaceService:GetProductInfo(gamepassId, Enum.InfoType.GamePass)
	end)
	if not success then
		debugLog(nil, string.format("Gamepass metadata failed | %s | id=%d | error=%s", label, gamepassId, tostring(info)))
		return
	end

	local creator = info and info.Creator
	local creatorName = if creator then creator.Name else "Unknown"
	local creatorType = if creator then tostring(creator.CreatorType) else "Unknown"
	local creatorId = if creator then tostring(creator.CreatorTargetId) else "Unknown"
	local passName = if info and info.Name then info.Name else "Unknown"
	debugLog(
		nil,
		string.format(
			"Gamepass metadata | %s | id=%d | name=%s | creator=%s (%s:%s)",
			label,
			gamepassId,
			passName,
			creatorName,
			creatorType,
			creatorId
		)
	)
end

local function getCacheForPlayer(player: Player): {[number]: OwnershipEntry}
	local cache = OwnershipCache[player]
	if not cache then
		cache = {}
		OwnershipCache[player] = cache
	end

	return cache
end

local function safeOwnsGamepass(player: Player, gamepassId: number): boolean
	if gamepassId <= 0 then
		return false
	end

	local success, owns = pcall(function()
		return MarketplaceService:UserOwnsGamePassAsync(player.UserId, gamepassId)
	end)
	if not success then
		warn(string.format("[GamepassHandler] Failed to check ownership for %s (%d): %s", player.Name, gamepassId, tostring(owns)))
		return false
	end

	debugLog(player, string.format("Ownership checked | gamepassId=%d | owns=%s", gamepassId, tostring(owns == true)))
	return owns == true
end

local function getOwnership(player: Player, gamepassId: number, forceRefresh: boolean?): boolean
	local cache = getCacheForPlayer(player)
	local entry = cache[gamepassId]
	local now = os.clock()
	local shouldRefresh = forceRefresh == true

	if not shouldRefresh then
		if not entry then
			shouldRefresh = true
		else
			local age = now - entry.checkedAt
			local ttl = if entry.owns then POSITIVE_CACHE_SECONDS else NEGATIVE_CACHE_SECONDS
			shouldRefresh = age >= ttl
		end
	end

	if shouldRefresh then
		local ownsNow = safeOwnsGamepass(player, gamepassId)
		cache[gamepassId] = {
			owns = ownsNow,
			checkedAt = now,
		}
		debugLog(
			player,
			string.format(
				"Ownership cache updated | gamepassId=%d | owns=%s | forceRefresh=%s",
				gamepassId,
				tostring(ownsNow),
				tostring(forceRefresh == true)
			)
		)
		return ownsNow
	end

	return entry and entry.owns == true or false
end

local function setOwnership(player: Player, gamepassId: number, owns: boolean)
	local cache = getCacheForPlayer(player)
	cache[gamepassId] = {
		owns = owns == true,
		checkedAt = os.clock(),
	}
	debugLog(player, string.format("Ownership cache set | gamepassId=%d | owns=%s", gamepassId, tostring(cache[gamepassId].owns)))
end

local function getCurrentMultiplier(player: Player): number
	local multiplier = 1

	if DOUBLE_MONEY_ID > 0 and getOwnership(player, DOUBLE_MONEY_ID) then
		multiplier *= DOUBLE_MONEY_MULTIPLIER
	end

	if VIP_ID > 0 and getOwnership(player, VIP_ID) then
		multiplier *= VIP_MULTIPLIER
	end

	return multiplier
end

local function syncPlayerAttributes(player: Player)
	if not player or not player.Parent then
		return
	end

	local hasDoubleMoney = if DOUBLE_MONEY_ID > 0 then getOwnership(player, DOUBLE_MONEY_ID) else false
	local hasVip = if VIP_ID > 0 then getOwnership(player, VIP_ID) else false

	local multiplier = 1
	if hasDoubleMoney then
		multiplier *= DOUBLE_MONEY_MULTIPLIER
	end
	if hasVip then
		multiplier *= VIP_MULTIPLIER
	end

	player:SetAttribute(PLAYER_DOUBLE_MONEY_ATTRIBUTE, hasDoubleMoney)
	player:SetAttribute(PLAYER_VIP_ATTRIBUTE, hasVip)
	player:SetAttribute(PLAYER_MULTIPLIER_ATTRIBUTE, multiplier)
	debugLog(player, string.format("Attributes synced | has2x=%s | hasVIP=%s | totalMultiplier=%.2f", tostring(hasDoubleMoney), tostring(hasVip), multiplier))
end

local function applyCoilBehavior(tool: Tool, speedBonus: number, jumpBonus: number)
	local previousHumanoid: Humanoid? = nil
	local previousWalkSpeed: number? = nil
	local previousJumpPower: number? = nil

	local function restoreHumanoid()
		if not previousHumanoid or not previousHumanoid.Parent then
			previousHumanoid = nil
			previousWalkSpeed = nil
			previousJumpPower = nil
			return
		end

		if previousWalkSpeed then
			previousHumanoid.WalkSpeed = previousWalkSpeed
		end

		if jumpBonus > 0 and previousJumpPower and previousHumanoid.UseJumpPower then
			previousHumanoid.JumpPower = previousJumpPower
		end

		previousHumanoid = nil
		previousWalkSpeed = nil
		previousJumpPower = nil
	end

	tool.Equipped:Connect(function()
		local character = tool.Parent
		if not character or not character:IsA("Model") then
			return
		end

		local humanoid = character:FindFirstChildOfClass("Humanoid")
		if not humanoid then
			return
		end

		previousHumanoid = humanoid
		previousWalkSpeed = humanoid.WalkSpeed
		previousJumpPower = humanoid.JumpPower

		local boostedSpeed = StarterPlayer.CharacterWalkSpeed + speedBonus
		humanoid.WalkSpeed = math.max(humanoid.WalkSpeed, boostedSpeed)

		if jumpBonus > 0 and humanoid.UseJumpPower then
			local boostedJumpPower = StarterPlayer.CharacterJumpPower + jumpBonus
			humanoid.JumpPower = math.max(humanoid.JumpPower, boostedJumpPower)
		end
	end)

	tool.Unequipped:Connect(restoreHumanoid)
	tool.Destroying:Connect(restoreHumanoid)
end

local function createVipTool(toolConfig: {Name: string, IconTextureId: string?, MeshTextureId: string?, SpeedBonus: number, JumpBonus: number, VertexColor: Vector3?}): Tool
	local tool = Instance.new("Tool")
	tool.Name = toolConfig.Name
	tool.RequiresHandle = true
	tool.CanBeDropped = false
	tool.TextureId = toolConfig.IconTextureId or ""

	local handle = Instance.new("Part")
	handle.Name = "Handle"
	handle.Size = Vector3.new(1, 1, 1)
	handle.Transparency = 1
	handle.CanCollide = false
	handle.Massless = true
	handle.Parent = tool

	local mesh = Instance.new("SpecialMesh")
	mesh.Name = "Mesh"
	mesh.MeshType = Enum.MeshType.FileMesh
	mesh.MeshId = "rbxassetid://16606212"
	mesh.TextureId = toolConfig.MeshTextureId or ""
	mesh.Scale = Vector3.new(0.7, 0.7, 0.7)
	if toolConfig.VertexColor then
		mesh.VertexColor = toolConfig.VertexColor
	end
	mesh.Parent = handle

	local rightGripAttachment = Instance.new("Attachment")
	rightGripAttachment.Name = "RightGripAttachment"
	rightGripAttachment.CFrame = CFrame.new(0, 0, -1) * CFrame.Angles(0, 0, math.rad(135))
	rightGripAttachment.Parent = handle

	applyCoilBehavior(tool, toolConfig.SpeedBonus, toolConfig.JumpBonus)
	return tool
end

local function hasTool(player: Player, toolName: string): boolean
	for _, instance in SharedUtilities.getToolsForBackpackAndEquipped(player) do
		if instance:IsA("Tool") and instance.Name == toolName then
			return true
		end
	end

	return false
end

local function giveVipTool(player: Player, toolConfig: {Name: string, IconTextureId: string?, MeshTextureId: string?, SpeedBonus: number, JumpBonus: number, VertexColor: Vector3?})
	if not player or not player.Parent then
		return
	end

	if hasTool(player, toolConfig.Name) then
		debugLog(player, string.format("VIP tool already owned in session | tool=%s", toolConfig.Name))
		return
	end

	local backpack = player:FindFirstChildOfClass("Backpack")
	if not backpack then
		debugLog(player, string.format("Could not grant VIP tool (no backpack yet) | tool=%s", toolConfig.Name))
		return
	end

	local createdTool = createVipTool(toolConfig)
	createdTool.Parent = backpack
	debugLog(player, string.format("Granted VIP tool | tool=%s", toolConfig.Name))
end

function GamepassHandler.RefreshPlayerOwnership(player: Player, forceRefresh: boolean?): number
	if not player then
		return 1
	end

	if DOUBLE_MONEY_ID > 0 then
		getOwnership(player, DOUBLE_MONEY_ID, forceRefresh)
	end
	if VIP_ID > 0 then
		getOwnership(player, VIP_ID, forceRefresh)
	end

	syncPlayerAttributes(player)
	local currentMultiplier = getCurrentMultiplier(player)
	debugLog(player, string.format("RefreshPlayerOwnership done | multiplier=%.2f", currentMultiplier))
	return currentMultiplier
end

function GamepassHandler.GetMoneyPerSecondMultiplier(player: Player): number
	if not player then
		return 1
	end

	local multiplier = player:GetAttribute(PLAYER_MULTIPLIER_ATTRIBUTE)
	if typeof(multiplier) == "number" and multiplier > 0 then
		return multiplier
	end

	return GamepassHandler.RefreshPlayerOwnership(player)
end

function GamepassHandler.PlayerOwnsVip(player: Player, forceRefresh: boolean?): boolean
	if not player or VIP_ID <= 0 then
		return false
	end

	return getOwnership(player, VIP_ID, forceRefresh)
end

function GamepassHandler.TryGrantVipFirstJoinReward(player: Player): boolean
	if not player or not player.Parent then
		return false
	end

	if not GamepassHandler.PlayerOwnsVip(player) then
		-- Force one refresh before skipping in case ownership propagated recently.
		if not GamepassHandler.PlayerOwnsVip(player, true) then
			debugLog(player, "VIP first-join reward skipped (player does not own VIP)")
			return false
		end
	end

	if DataService.server:get(player, VIP_REWARD_CLAIM_KEY) then
		debugLog(player, "VIP first-join reward skipped (already claimed)")
		return false
	end

	DataService.server:update(player, "cash", function(old)
		local currentCash = if typeof(old) == "number" then old else 0
		return currentCash + VIP_FIRST_JOIN_REWARD
	end)
	DataService.server:set(player, VIP_REWARD_CLAIM_KEY, true)

	RemoteBank.SendNotification:FireClient(player, ("VIP bonus +$%d"):format(VIP_FIRST_JOIN_REWARD), Color3.new(1, 0.886275, 0.14902))
	debugLog(player, string.format("VIP first-join reward granted | cashAdded=%d", VIP_FIRST_JOIN_REWARD))
	return true
end

function GamepassHandler.AddVipTools(player: Player)
	if not player or not player.Parent then
		return
	end

	if not GamepassHandler.PlayerOwnsVip(player) then
		if not GamepassHandler.PlayerOwnsVip(player, true) then
			debugLog(player, "VIP tools skipped (player does not own VIP)")
			return
		end
	end

	debugLog(player, "Adding VIP tools to backpack")
	for _, toolConfig in ipairs(VIP_TOOLS) do
		giveVipTool(player, toolConfig)
	end
end

function GamepassHandler.HandleGamepassPurchaseFinished(player: Player, gamepassId: number, wasPurchased: boolean)
	if not player or not player.Parent or not gamepassId then
		return
	end

	debugLog(player, string.format("PromptGamePassPurchaseFinished | gamepassId=%d | purchased=%s", gamepassId, tostring(wasPurchased)))
	if wasPurchased then
		setOwnership(player, gamepassId, true)
	else
		setOwnership(player, gamepassId, safeOwnsGamepass(player, gamepassId))
	end

	if gamepassId == DOUBLE_MONEY_ID or gamepassId == VIP_ID then
		syncPlayerAttributes(player)
	end

	if wasPurchased and gamepassId == VIP_ID then
		task.spawn(function()
			DataService.server:waitForData(player)
			GamepassHandler.TryGrantVipFirstJoinReward(player)
		end)
	end
end

local function schedulePostJoinRefresh(player: Player, delaySeconds: number)
	task.delay(delaySeconds, function()
		if not player or not player.Parent then
			return
		end

		debugLog(player, string.format("Delayed ownership refresh fired | after=%.1fs", delaySeconds))
		GamepassHandler.RefreshPlayerOwnership(player, true)
		GamepassHandler.TryGrantVipFirstJoinReward(player)
		GamepassHandler.AddVipTools(player)
	end)
end

local function onPlayerAdded(player: Player)
	debugLog(player, "PlayerAdded received, checking gamepasses")
	debugLog(
		player,
		string.format(
			"Active config | doubleMoneyId=%d | vipId=%d | x2=%.2f | vip=%.2f | vipReward=%d",
			DOUBLE_MONEY_ID,
			VIP_ID,
			DOUBLE_MONEY_MULTIPLIER,
			VIP_MULTIPLIER,
			VIP_FIRST_JOIN_REWARD
		)
	)
	task.spawn(function()
		GamepassHandler.RefreshPlayerOwnership(player, true)
		GamepassHandler.AddVipTools(player)
	end)

	task.spawn(function()
		DataService.server:waitForData(player)
		GamepassHandler.TryGrantVipFirstJoinReward(player)
	end)

	-- Extra refreshes help when ownership propagation is delayed after a web purchase.
	schedulePostJoinRefresh(player, 8)
	schedulePostJoinRefresh(player, 25)
end

function GamepassHandler:Initialize()
	debugLog(nil, string.format("Initialize | DoubleMoneyId=%d | VIPId=%d | vipReward=%d", DOUBLE_MONEY_ID, VIP_ID, VIP_FIRST_JOIN_REWARD))
	debugLog(nil, string.format("Environment | placeId=%d | gameId=%d | isStudio=%s", game.PlaceId, game.GameId, tostring(RunService:IsStudio())))
	logGamepassMetadata(DOUBLE_MONEY_ID, "2x Money")
	logGamepassMetadata(VIP_ID, "VIP")
	for _, player in Players:GetPlayers() do
		onPlayerAdded(player)
	end

	Players.PlayerAdded:Connect(onPlayerAdded)
	Players.PlayerRemoving:Connect(function(player)
		OwnershipCache[player] = nil
	end)
end

return GamepassHandler