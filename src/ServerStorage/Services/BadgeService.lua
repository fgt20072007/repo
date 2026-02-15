local Players = game:GetService("Players")
local RobloxBadgeService = game:GetService("BadgeService")

local Registry: {[string]: number} = {}
local OnJoinBadges: {[number]: true} = {}
local Started = false

local BadgeService = {}

local function resolveBadgeId(badgeKeyOrId: number | string): number?
	if typeof(badgeKeyOrId) == "number" then
		return badgeKeyOrId
	end

	if typeof(badgeKeyOrId) == "string" then
		return Registry[badgeKeyOrId]
	end

	return nil
end

function BadgeService.Register(key: string, badgeId: number): boolean
	if key == "" then return false end
	if badgeId <= 0 then return false end
	Registry[key] = badgeId
	
	return true
end

function BadgeService.GetBadgeId(badgeKeyOrId: number | string): number?
	return resolveBadgeId(badgeKeyOrId)
end

function BadgeService.Has(player: Player, badgeKeyOrId: number | string): boolean
	local badgeId = resolveBadgeId(badgeKeyOrId)
	if not badgeId then return false end

	local success, ownsBadge = pcall(
		RobloxBadgeService.UserHasBadgeAsync,
		RobloxBadgeService,
		player.UserId,
		badgeId
	)

	if not success then return false end

	return ownsBadge == true
end

function BadgeService.Award(player: Player, badgeKeyOrId: number | string): boolean
	local badgeId = resolveBadgeId(badgeKeyOrId)
	if not badgeId then return false end

	if not player.Parent then return false end

	if BadgeService.Has(player, badgeId) then return true end

	local success, result = pcall(
		RobloxBadgeService.AwardBadge,
		RobloxBadgeService,
		player.UserId,
		badgeId
	)

	if not success then return false end

	return result == true
end

function BadgeService.AwardOnJoin(badgeKeyOrId: number | string): boolean
	local badgeId = resolveBadgeId(badgeKeyOrId)
	if not badgeId then return false end

	OnJoinBadges[badgeId] = true

	if Started then
		for _, player in Players:GetPlayers() do
			task.spawn(BadgeService.Award, player, badgeId)
		end
	end

	return true
end

function BadgeService._HandlePlayerAdded(player: Player)
	for badgeId in OnJoinBadges do
		task.spawn(BadgeService.Award, player, badgeId)
	end
end

function BadgeService.Init()
	if Started then return end

	Started = true

	Players.PlayerAdded:Connect(BadgeService._HandlePlayerAdded)
	for _, player in Players:GetPlayers() do
		task.spawn(BadgeService._HandlePlayerAdded, player)
	end
end

return BadgeService