-- Services
local ReplicatedStorage = game:GetService('ReplicatedStorage')
local Players = game:GetService('Players')
local DataStoreService = game:GetService('DataStoreService')

-- Variables

-- Dependencies
local DataService = require(ReplicatedStorage.Utilities.DataService)
local GlobalConfiguration = require(ReplicatedStorage.DataModules.GlobalConfiguration)
local leaderboardsVersion = GlobalConfiguration.CurrentDatastoreVersion
local Informations = {
	CashLeaderboard = {
		StatsName = "cash",
		Datastore = DataStoreService:GetOrderedDataStore("CashLeaderboard" .. leaderboardsVersion)
	},
}

local Format = require(ReplicatedStorage.Utilities.Format)

local LeaderboardsHandler = {}

function LeaderboardsHandler:UpdateLeaderboards()
	local leaderboardsContainer = workspace.Leaderboards
	for leaderboardName, leaderboardInfo in pairs(Informations) do
		local leaderboard = leaderboardsContainer:FindFirstChild(leaderboardName)
		if leaderboard then
			local SurfaceGui = leaderboard:FindFirstChild("SurfaceGui", true)
			local Container: ScrollingFrame = SurfaceGui.ScrollingFrame
			local Template: Frame = Container:FindFirstChild("Template")
			
			for _, v in pairs(Container:GetChildren()) do
				if v == Template then continue end
				if v:IsA("GuiObject") then
					v:Destroy()
				end
			end
			
			local isAscending = false
			local pageSize = 100
			local pages = leaderboardInfo.Datastore:GetSortedAsync(isAscending, pageSize)
			local playersData = pages:GetCurrentPage()
			for rank, data in playersData do
				local playerId = data.key
				if tonumber(playerId) < 0 then continue end
				local playerName = Players:GetNameFromUserIdAsync(playerId)
				local newTemplate = Template:Clone()
				
				newTemplate.RankLabel.Text = "#" .. rank
				newTemplate.NameLabel.Text = playerName
				newTemplate.AmountLabel.Text = Format.abbreviateCash(data.value)
				
				newTemplate.Parent = Container
				
				newTemplate.Visible = true
				
				task.spawn(function()
					local Headshot = Players:GetUserThumbnailAsync(playerId, Enum.ThumbnailType.HeadShot, Enum.ThumbnailSize.Size100x100)
					local BodyShot = Players:GetUserThumbnailAsync(playerId, Enum.ThumbnailType.AvatarThumbnail, Enum.ThumbnailSize.Size180x180)
					
					newTemplate.Extra.ImageLabel.Image = BodyShot
					newTemplate.PlayerHeadshot.Image = Headshot
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
		for _, v in data.stands do
			if v.entity then
				v.lastOnlineTime = os.time()
			end
		end	

		for _, v in Informations do
			v.Datastore:SetAsync(player.UserId, math.floor(data[v.StatsName]))
		end
	end
end

return LeaderboardsHandler