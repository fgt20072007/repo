local ReplicatedStorage = game:GetService('ReplicatedStorage')
local TextChatService = game:GetService('TextChatService')
local Players = game:GetService('Players')

local Packages = ReplicatedStorage:WaitForChild('Packages')
local Net = require(Packages.Net)
local Promise = require(Packages.Promise)

local CanChatRemote = Net:RemoteFunction('CanChatWith')

local RE_FETCH_AFTER = 5 * 60

type CanChatData = {
	Can: boolean,
	Fetched: number,
}

local SocialService = {
	ActiveCanChatQueries = {} :: {[number]: {[number]: any}},
	CachedCanChat = {} :: {[number]: {[number]: CanChatData}},
}

function SocialService._QueryCanChat(origin: number, target: number)
	local active = SocialService.ActiveCanChatQueries[origin]
	if active and active[target] then return active[target] end
	
	local new = Promise.new(function(resolve, reject, onCancel)
		local succ, res = pcall(function()
			return TextChatService:CanUsersChatAsync(origin, target)
		end)
		
		if succ then
			resolve(res)
		else
			reject(res)
		end
	end):finally(function()
		local updated = SocialService.ActiveCanChatQueries[origin]
		if not (updated and updated[target]) then return end
		
		updated[target] = nil
	end)
	
	local updated = SocialService.ActiveCanChatQueries[origin]
	if updated then
		updated[target] = new
	else
		SocialService.ActiveCanChatQueries[origin] = {[target] = new}
	end
	
	return new
end

function SocialService.OnCanChatRequest(player: Player, target: number): boolean?
	local origin = player.UserId
	
	local cachedList = SocialService.CachedCanChat[origin]
	local cachedData = cachedList and cachedList[target] or nil
	if cachedData and cachedData.Fetched + RE_FETCH_AFTER < os.time() then
		return cachedData.Can
	end
	
	local succ, res = SocialService._QueryCanChat(origin, target):await()
	if not succ then return nil end

	local fixed = {Can = res, Fetched = os.time()}
	local updated = SocialService.CachedCanChat[origin]
	
	if updated then
		updated[target] = fixed
	else
		SocialService.CachedCanChat[origin] = {[target] = fixed}
	end
	
	return res
end

function SocialService.OnPlayerRemoval(player: Player)
	local id = player.UserId
	
	if SocialService.CachedCanChat[id] then
		SocialService.CachedCanChat[id] = nil
	end
	
	if SocialService.ActiveCanChatQueries then
		SocialService.ActiveCanChatQueries[id] = nil
	end
	
	for _, list in SocialService.CachedCanChat do
		list[id] = nil
	end
end

function SocialService.Init()
	CanChatRemote.OnServerInvoke = SocialService.OnCanChatRequest;
	Players.PlayerRemoving:Connect(SocialService.OnPlayerRemoval)
end

return SocialService