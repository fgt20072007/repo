local DataStoreService = game:GetService("DataStoreService")
local MemoryStoreService = game:GetService("MemoryStoreService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local DataService = require(ReplicatedStorage.Utilities.DataService)

local CollectedODS = DataStoreService:GetOrderedDataStore("CollectedLeaderboardV1")
local LeaderboardCache = MemoryStoreService:GetSortedMap("CollectedLeaderboardCache")

local ScrollingFrame = script.Parent
local Template = ScrollingFrame:WaitForChild("Template")
Template.Visible = false

-- ⭐ ASEGÚRATE de que exista un UIListLayout dentro del ScrollingFrame
local listLayout = ScrollingFrame:WaitForChild("UIListLayout")

-- ⭐ Ajusta el CanvasSize automáticamente (esto evita que se amontonen)
listLayout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
	ScrollingFrame.CanvasSize = UDim2.new(0, 0, 0, listLayout.AbsoluteContentSize.Y)
end)

local UPDATE_INTERVAL = 50
local CACHE_EXPIRATION = 300
local MAX_ENTRIES = 50

local LeaderboardHandler = {}
local PlayerCountCache = {}

local function getPlayerCollectedCount(player)
	local success, indexData = pcall(function()
		return DataService.server:get(player, "index")
	end)
	if not success or not indexData then
		return PlayerCountCache[player.UserId] or 0
	end

	local count = 0
	for _ in pairs(indexData) do
		count += 1
	end

	PlayerCountCache[player.UserId] = count
	return count
end

local function updatePlayerInDatastore(player)
	local userId = tostring(player.UserId)
	local count = getPlayerCollectedCount(player)

	if count > 0 then
		pcall(function()
			CollectedODS:SetAsync(userId, count)
		end)
	end
end

local function fetchLeaderboardData()
	local success, pages = pcall(function()
		return CollectedODS:GetSortedAsync(false, MAX_ENTRIES)
	end)
	if not success or not pages then return {} end

	local data = {}
	local currentPage = pages:GetCurrentPage()

	for rank, entry in ipairs(currentPage) do
		local userId = tonumber(entry.key)
		local playerName = "Unknown"

		local nameSuccess, name = pcall(function()
			return Players:GetNameFromUserIdAsync(userId)
		end)
		if nameSuccess then playerName = name end

		table.insert(data, {
			UserId = userId,
			Name = playerName,
			Value = entry.value,
			Rank = rank
		})
	end

	return data
end

local function cacheLeaderboardData(data)
	for _, entry in ipairs(data) do
		pcall(function()
			LeaderboardCache:SetAsync(tostring(entry.Rank), entry, CACHE_EXPIRATION)
		end)
	end
end

local function clearLeaderboardUI()
	for _, child in ipairs(ScrollingFrame:GetChildren()) do
		if child:IsA("Frame") and child ~= Template then
			child:Destroy()
		end
	end
end

local function displayLeaderboard(data)
	clearLeaderboardUI()

	for _, entry in ipairs(data) do
		local newEntry = Template:Clone()
		newEntry.Name = entry.Rank .. "_" .. entry.Name
		newEntry.LayoutOrder = entry.Rank
		newEntry.Visible = true

		local imagen = newEntry:FindFirstChild("Imagen")
		local nombre = newEntry:FindFirstChild("Nombre")
		local collected = newEntry:FindFirstChild("Collected")

		if nombre then
			nombre.Text = "#" .. entry.Rank .. " " .. entry.Name
		end
		if collected then
			collected.Text = tostring(entry.Value)
		end

		if imagen then
			task.spawn(function()
				local avatarSuccess, avatarContent = pcall(function()
					return Players:GetUserThumbnailAsync(
						entry.UserId,
						Enum.ThumbnailType.HeadShot,
						Enum.ThumbnailSize.Size420x420
					)
				end)
				if avatarSuccess and avatarContent then
					imagen.Image = avatarContent
				end
			end)
		end

		newEntry.Parent = ScrollingFrame
	end
end

local function refreshLeaderboard()
	for _, player in ipairs(Players:GetPlayers()) do
		updatePlayerInDatastore(player)
	end

	local data = fetchLeaderboardData()
	cacheLeaderboardData(data)
	displayLeaderboard(data)
end

local function onPlayerAdded(player)
	DataService.server:waitForData(player)
	updatePlayerInDatastore(player)

	DataService.server:getIndexChangedSignal(player, "index"):Connect(function()
		updatePlayerInDatastore(player)
	end)
end

local function onPlayerRemoving(player)
	updatePlayerInDatastore(player)
	PlayerCountCache[player.UserId] = nil
end

function LeaderboardHandler:Initialize()
	Players.PlayerAdded:Connect(onPlayerAdded)
	Players.PlayerRemoving:Connect(onPlayerRemoving)

	for _, player in ipairs(Players:GetPlayers()) do
		task.spawn(onPlayerAdded, player)
	end

	task.defer(refreshLeaderboard)

	task.spawn(function()
		while true do
			task.wait(UPDATE_INTERVAL)
			refreshLeaderboard()
		end
	end)
end

LeaderboardHandler:Initialize()
return LeaderboardHandler
