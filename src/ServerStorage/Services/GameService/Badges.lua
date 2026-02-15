local ServerStorage = game:GetService("ServerStorage")

local BadgeService = require(ServerStorage.Services.BadgeService)

local Manager = {}

local JOIN_BADGE_KEY = "JoinedGame"
local JOIN_BADGE_ID = 3288278993429895

function Manager.Init()
	BadgeService.Init()
	BadgeService.Register(JOIN_BADGE_KEY, JOIN_BADGE_ID)
	BadgeService.AwardOnJoin(JOIN_BADGE_KEY)
end

return Manager

--[[ API ]]

--[[

local BadgeService = require(game:GetService("ServerStorage").Services.BadgeService)

BadgeService.Register("MiBadge", 1234567890)
BadgeService.Award(player, "MiBadge") -- o BadgeService.Award(player, 1234567890)
BadgeService.Has(player, "MiBadge")
BadgeService.AwardOnJoin("MiBadge")

]]