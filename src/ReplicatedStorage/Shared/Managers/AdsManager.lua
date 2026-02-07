local PolicyService = game:GetService("PolicyService")
local RunService = game:GetService("RunService")

local cache = {}

local AdsManager = {}

function AdsManager.GetPolicyInfoAsync(Player: Player)
	if cache[Player] then
		return cache[Player]
	end

	Player = RunService:IsClient() and game.Players.LocalPlayer or Player

	if not Player then
		return
	end

	local info

	local success, err = pcall(function()
		info = PolicyService:GetPolicyInfoForPlayerAsync(Player)
	end)

	if not success then
		warn(err)
		return {}
	else
		cache[Player] = info
		return cache[Player]
	end
end

return AdsManager
