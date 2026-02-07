local HttpService = game:GetService("HttpService")

local followingCache = {}

local API = {}

function API.GetFollowingListAsync(Player: Player)
	if followingCache[Player] and followingCache[Player] ~= {} then
		return followingCache[Player]
	end

	local result
	local success, err = pcall(function()
		result = HttpService:GetAsync("https://friends.roproxy.com/v1/users/" .. Player.UserId .. "/followings")
	end)

	if not success or not result then
		warn(err)
		return {}
	end

	local jsonDecoded = HttpService:JSONDecode(result)

	followingCache[Player] = jsonDecoded
	return jsonDecoded
end

return API
