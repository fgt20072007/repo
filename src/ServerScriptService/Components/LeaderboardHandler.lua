-- Services
local ReplicatedStorage = game:GetService('ReplicatedStorage')
local Players = game:GetService('Players')
local DataStoreService = game:GetService('DataStoreService')
local RunService = game:GetService('RunService')

-- Variables

-- Dependencies
local DataService = require(ReplicatedStorage.Utilities.DataService)
local GlobalConfiguration = require(ReplicatedStorage.DataModules.GlobalConfiguration)
local leaderboardsVersion = GlobalConfiguration.CurrentDatastoreVersion

local function canUseDataStoreApis()
	if not RunService:IsStudio() then
		return true
	end

	local success, allowed = pcall(function()
		return game:GetService("StudioService").ApiAccessAllowed
	end)
	return success and allowed == true
end

local CanUseDataStoreApis = canUseDataStoreApis()

local Informations = {
	CashLeaderboard = {
		StatsName = "cash",
		Datastore = DataStoreService:GetOrderedDataStore("CashLeaderboard" .. leaderboardsVersion)
	},
}

local Format = require(ReplicatedStorage.Utilities.Format)

local LeaderboardsHandler = {}

function LeaderboardsHandler:UpdateLeaderboards()
	if not CanUseDataStoreApis then
		return
	end

	local leaderboardsContainer = workspace.Leaderboards
	for leaderboardName, leaderboardInfo in pairs(Informations) do
		local leaderboard = leaderboardsContainer:FindFirstChild(leaderboardName)
		if leaderboard then
			local SurfaceGui = leaderboard:FindFirstChild("SurfaceGui", true)
			if not SurfaceGui then
				continue
			end

			local Container: ScrollingFrame = SurfaceGui.ScrollingFrame
			if not Container then
				continue
			end

			local Template: Frame = Container:FindFirstChild("Template")
			if not Template then
				continue
			end

			for _, v in pairs(Container:GetChildren()) do
				if v == Template then continue end
				if v:IsA("GuiObject") then
					v:Destroy()
				end
			end

			local isAscending = false
			local pageSize = 100

			local pagesSuccess, pages = pcall(function()
				return leaderboardInfo.Datastore:GetSortedAsync(isAscending, pageSize)
			end)
			if not pagesSuccess or not pages then
				continue
			end

			local currentPageSuccess, playersData = pcall(function()
				return pages:GetCurrentPage()
			end)
			if not currentPageSuccess or not playersData then
				continue
			end

			for rank, data in playersData do
				local playerId = tonumber(data.key)
				if not playerId or playerId <= 0 then
					continue
				end

				local playerNameSuccess, playerName = pcall(function()
					return Players:GetNameFromUserIdAsync(playerId)
				end)
				if not playerNameSuccess or not playerName then
					continue
				end

				local newTemplate = Template:Clone()

				newTemplate.RankLabel.Text = "#" .. rank
				newTemplate.NameLabel.Text = playerName
				newTemplate.AmountLabel.Text = Format.abbreviateCash(data.value)

				newTemplate.Parent = Container

				newTemplate.Visible = true

				task.spawn(function()
					local headshotSuccess, Headshot = pcall(function()
						return Players:GetUserThumbnailAsync(playerId, Enum.ThumbnailType.HeadShot, Enum.ThumbnailSize.Size100x100)
					end)
					local bodyShotSuccess, BodyShot = pcall(function()
						return Players:GetUserThumbnailAsync(playerId, Enum.ThumbnailType.AvatarThumbnail, Enum.ThumbnailSize.Size180x180)
					end)

					if headshotSuccess and Headshot then
						newTemplate.PlayerHeadshot.Image = Headshot
					end
					if bodyShotSuccess and BodyShot then
						newTemplate.Extra.ImageLabel.Image = BodyShot
					end
				end)
			end
		end
	end
end

-- Initialization function for the script
function LeaderboardsHandler:Initialize()
	task.spawn(function()
		while true do
			self:UpdateLeaderboards()
			task.wait(180)
		end
	end)

	DataService.server.onPlayerRemoving = function(_, player, data)
		if not CanUseDataStoreApis then
			return
		end

		local stands = if typeof(data) == "table" then data.stands else nil
		if typeof(stands) == "table" then
			for _, v in stands do
				if v.entity then
					v.lastOnlineTime = os.time()
				end
			end
		end

		for _, v in Informations do
			pcall(function()
				local statValue = if typeof(data) == "table" then tonumber(data[v.StatsName]) or 0 else 0
				v.Datastore:SetAsync(player.UserId, math.floor(statValue))
			end)
		end
	end
end

return LeaderboardsHandler