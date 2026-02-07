local RunService = game:GetService("RunService")
local Players = game:GetService("Players")

local IsClient = RunService:IsClient()

local random = Random.new(tick())

local Friends = {
	friendCache = {},
}

function Friends.GetFriendsAsync(Player: Player)
	Player = IsClient and game.Players.LocalPlayer or Player

	if Friends.friendCache[Player] then
		return Friends.friendCache[Player]
	end

	local friends = Players:GetFriendsAsync(Player.UserId)
	Friends.friendCache[Player] = friends

	return friends
end

function Friends.GetFriendsOnlineAsync(Player: Player)
	Player = IsClient and game.Players.LocalPlayer or Player

	return Player:GetFriendsOnlineAsync()
end

function Friends.GetRandomFriend(Player: Player)
	Player = IsClient and game.Players.LocalPlayer or Player

	local friends = Friends.GetFriendsAsync(Player)

	return friends[random:NextInteger(1, #friends)]
end

function Friends.GetRandomFriendOnline(Player: Player?)
	Player = IsClient and game.Players.LocalPlayer or Player

	local friends = Friends.GetFriendsOnlineAsync(Player)

	return friends[random:NextInteger(1, #friends)]
end

return Friends
