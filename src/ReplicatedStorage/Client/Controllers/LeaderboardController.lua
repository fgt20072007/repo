local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage.Shared

local Math = require(Shared.CustomPackages.Math)
local Client = require(ReplicatedStorage.Client)
local GetLeaderboardRemote = require(Shared.Remotes.GetLeaderboard):Client()
local LeaderboardDataRemote = require(Shared.Remotes.LeaderboardData):Client()

local Player = Players.LocalPlayer

local LEADERBOARD_MAPPING = {
	Coins = "Coins",
	Shards = "Shards",
	Kills = "Kills",
	PlayTime = "PlayTime",
	KOTH = "KOTHTime",
	Robux = "RobuxSpent",
	BossWins = "BossWins",
}

local UPDATE_INTERVAL = 5

local LeaderboardController = {}

function LeaderboardController._Init(self: LeaderboardController)
	self.LeaderboardFrames = {}
	self.EntryTemplates = {}

	local function RegisterLeaderboard(leaderboard)
		if not leaderboard or self.LeaderboardFrames[leaderboard.Name] then return end

		local surfaceGuiPart = leaderboard:FindFirstChild("SurfaceGuiPart")
		if not surfaceGuiPart then return end

		local surfaceGui = surfaceGuiPart:FindFirstChild("SurfaceGui")
		if not surfaceGui then return end

		local scrollingFrame = surfaceGui:FindFirstChild("ScrollingFrame")
		local localPlayerStats = surfaceGui:FindFirstChild("LocalPlayerStats")
		if not scrollingFrame or not localPlayerStats then return end

		local template = scrollingFrame:FindFirstChild("1")
		if not template then return end

		self.LeaderboardFrames[leaderboard.Name] = {
			ScrollingFrame = scrollingFrame,
			LocalPlayerStats = localPlayerStats,
			Template = template,
		}

		self.EntryTemplates[leaderboard.Name] = template:Clone()
		template.Visible = false
	end

	local leaderboardsFolder = workspace:FindFirstChild("Code") and workspace.Code:FindFirstChild("Leaderboards")
	if leaderboardsFolder then
		for _, leaderboard in leaderboardsFolder:GetChildren() do
			RegisterLeaderboard(leaderboard)
		end
	end

	RegisterLeaderboard(workspace:FindFirstChild("KOTH"))

	LeaderboardDataRemote:On(function(LeaderboardName, Data)
		self:DisplayLeaderboard(LeaderboardName, Data)
	end)
end

function LeaderboardController.Spawn(self: LeaderboardController)
	local DataController = Client.Controllers.DataController
	DataController:GetProfile(true)

	self:UpdateLocalStats()
	self:RequestAllLeaderboards()

	task.spawn(function()
		while true do
			task.wait(UPDATE_INTERVAL)
			self:UpdateLocalStats()
			self:RequestAllLeaderboards()
		end
	end)
end

function LeaderboardController.UpdateLocalStats(self: LeaderboardController)
	local DataController = Client.Controllers.DataController
	local profile = DataController:GetProfile(false)
	if not profile then return end

	local success, headshot = pcall(function()
		return Players:GetUserThumbnailAsync(Player.UserId, Enum.ThumbnailType.HeadShot, Enum.ThumbnailSize.Size420x420)
	end)

	if not success then return end

	for leaderboardName, frameData in self.LeaderboardFrames do
		local localStats = frameData.LocalPlayerStats
		local statName = LEADERBOARD_MAPPING[leaderboardName]
		if not statName then continue end

		local value = profile[statName] or 0
		local displayValue = (statName == "PlayTime" or statName == "KOTHTime") and self:FormatPlayTime(value)
			or Math.FormatCurrency(value)

		local scoreLabel = localStats:FindFirstChild("ScoreLabel")
		local playerImage = localStats:FindFirstChild("PlayerImage")

		if scoreLabel then
			scoreLabel.Text = `Your Score: <font color="rgb(85, 255, 0)">{displayValue}</font>`
		end

		if playerImage then
			playerImage.Image = headshot
		end
	end
end

function LeaderboardController.RequestAllLeaderboards(self: LeaderboardController)
	for leaderboardName in self.LeaderboardFrames do
		GetLeaderboardRemote:Fire(leaderboardName)
	end
end

function LeaderboardController.DisplayLeaderboard(self: LeaderboardController, LeaderboardName: string, entries)
	local frameData = self.LeaderboardFrames[LeaderboardName]
	if not frameData or not entries then return end

	local scrollingFrame = frameData.ScrollingFrame
	local template = self.EntryTemplates[LeaderboardName]
	if not template then return end

	for _, child in scrollingFrame:GetChildren() do
		if child:IsA("Frame") then
			child:Destroy()
		end
	end

	local statName = LEADERBOARD_MAPPING[LeaderboardName]

	for _, entry in entries do
		local entryFrame = template:Clone()
		entryFrame.Name = tostring(entry.Rank)
		entryFrame.LayoutOrder = entry.Rank
		entryFrame.Visible = true

		local placeLabel = entryFrame:FindFirstChild("Place")
		local playerLabel = entryFrame:FindFirstChild("Player")
		local amountLabel = entryFrame:FindFirstChild("Amount")
		local playerImage = entryFrame:FindFirstChild("PlayerImage")

		if placeLabel then
			local textLabel = placeLabel:FindFirstChildWhichIsA("TextLabel") or placeLabel
			if textLabel:IsA("TextLabel") then
				textLabel.Text = "#" .. tostring(entry.Rank)
			end
		end

		if playerLabel then
			local textLabel = playerLabel:FindFirstChildWhichIsA("TextLabel") or playerLabel
			if textLabel:IsA("TextLabel") then
				local nameSuccess, name = pcall(function()
					return Players:GetNameFromUserIdAsync(entry.UserId)
				end)
				textLabel.Text = nameSuccess and name or "Unknown"
			end
		end

		if amountLabel then
			local textLabel = amountLabel:FindFirstChildWhichIsA("TextLabel") or amountLabel
			if textLabel:IsA("TextLabel") then
				local displayValue = (statName == "PlayTime" or statName == "KOTHTime") and self:FormatPlayTime(entry.Value)
					or Math.FormatCurrency(entry.Value)
				textLabel.Text = displayValue
			end
		end

		if playerImage then
			task.spawn(function()
				local thumbnailSuccess, thumbnail = pcall(function()
					return Players:GetUserThumbnailAsync(entry.UserId, Enum.ThumbnailType.HeadShot, Enum.ThumbnailSize.Size420x420)
				end)
				if thumbnailSuccess and playerImage then
					playerImage.Image = thumbnail
				end
			end)
		end

		entryFrame.Parent = scrollingFrame
	end
end

function LeaderboardController.FormatPlayTime(self: LeaderboardController, Seconds: number)
	local hours = math.floor(Seconds / 3600)
	local minutes = math.floor((Seconds % 3600) / 60)

	if hours > 0 then return string.format("%dh %dm", hours, minutes) end
	if minutes > 0 then return string.format("%dm", minutes) end
	return string.format("%ds", Seconds)
end

type LeaderboardController = typeof(LeaderboardController) & {
	LeaderboardFrames: { [string]: { ScrollingFrame: ScrollingFrame, LocalPlayerStats: Frame, Template: Frame } },
	EntryTemplates: { [string]: Frame },
}

return LeaderboardController