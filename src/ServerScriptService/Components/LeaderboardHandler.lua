-- Services
local ReplicatedStorage = game:GetService('ReplicatedStorage')
local Players = game:GetService('Players')
local DataStoreService = game:GetService('DataStoreService')
local RunService = game:GetService('RunService')

-- Variables

-- Dependencies
local DataService = require(ReplicatedStorage.Utilities.DataService)
local GlobalConfiguration = require(ReplicatedStorage.DataModules.GlobalConfiguration)
local SharedFunctions = require(ReplicatedStorage.DataModules.SharedFunctions)
local Mutations = require(ReplicatedStorage.DataModules.Mutations)
local leaderboardsVersion = GlobalConfiguration.CurrentDatastoreVersion

local LEADERBOARD_PAGE_SIZE = 100
local LEADERBOARD_REFRESH_INTERVAL = 180
local MAX_THUMBNAIL_FETCHES_PER_UPDATE = 12
local DEBUG_LEADERBOARD = true

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
		Datastore = DataStoreService:GetOrderedDataStore("CashPerSecondLeaderboard" .. leaderboardsVersion)
	},
}

local Format = require(ReplicatedStorage.Utilities.Format)

local LeaderboardsHandler = {}
local _isUpdating = false
local _updateCount = 0

local cachedNames: {[number]: string} = {}
local cachedHeadshots: {[number]: string} = {}
local cachedBodyshots: {[number]: string} = {}

type LeaderboardEntry = {
	key: string,
	value: number,
}

local function normalizeLeaderboardValue(value: number): number
	local safeValue = math.max(0, value)
	return math.floor(safeValue * 100 + 0.5) / 100
end

local function getRebirthMultiplierFromData(data): number
	local rebirths = if typeof(data) == "table" then tonumber(data.rebirth) or 0 else 0
	return rebirths * GlobalConfiguration.RebirthIncrements + 1
end

local function getIndexMultiplierFromData(data): number
	local indexData = if typeof(data) == "table" then data.index else nil
	if typeof(indexData) ~= "table" then
		return 0
	end

	local totalMultiplier = 0
	for mutationName, _ in Mutations do
		local unlockedEntries = indexData[mutationName]
		if typeof(unlockedEntries) == "table" and #unlockedEntries >= GlobalConfiguration.EntitiesForMulti then
			totalMultiplier += GlobalConfiguration.IndexMultiplier
		end
	end

	return totalMultiplier
end

local function getEarningsPerSecondFromData(data): number
	if typeof(data) ~= "table" then
		return 0
	end

	local stands = data.stands
	if typeof(stands) ~= "table" then
		return 0
	end

	local totalBaseEarnings = 0
	for _, standData in stands do
		if typeof(standData) ~= "table" then
			continue
		end

		local entityData = standData.entity
		if typeof(entityData) ~= "table" then
			continue
		end

		local entityName = entityData.name
		if typeof(entityName) ~= "string" then
			continue
		end

		local mutationName = if typeof(entityData.mutation) == "string" then entityData.mutation else "Normal"
		local upgradeLevel = tonumber(entityData.upgradeLevel) or 0
		local success, earnings = pcall(function()
			return SharedFunctions.GetEarningsPerSecond(entityName, mutationName, upgradeLevel, nil, entityData.traits)
		end)
		if success and typeof(earnings) == "number" then
			totalBaseEarnings += earnings
		end
	end

	local totalMultiplier = getRebirthMultiplierFromData(data) + getIndexMultiplierFromData(data)
	return normalizeLeaderboardValue(totalBaseEarnings * totalMultiplier)
end

local function debugLog(...)
	if not DEBUG_LEADERBOARD then
		return
	end
	--print("[LeaderboardDebug]", ...)
end

local function fetchPlayerName(userId: number): string?
	local cached = cachedNames[userId]
	if cached then
		return cached
	end

	local success, playerName = pcall(function()
		return Players:GetNameFromUserIdAsync(userId)
	end)
	if success and playerName then
		cachedNames[userId] = playerName
		return playerName
	end

	return nil
end

local function fetchPlayerThumbnails(userId: number): (string?, string?)
	local cachedHeadshot = cachedHeadshots[userId]
	local cachedBodyshot = cachedBodyshots[userId]
	if cachedHeadshot and cachedBodyshot then
		return cachedHeadshot, cachedBodyshot
	end

	local headshotSuccess, headshot = pcall(function()
		return Players:GetUserThumbnailAsync(userId, Enum.ThumbnailType.HeadShot, Enum.ThumbnailSize.Size100x100)
	end)
	if headshotSuccess and headshot then
		cachedHeadshots[userId] = headshot
	end

	local bodyShotSuccess, bodyShot = pcall(function()
		return Players:GetUserThumbnailAsync(userId, Enum.ThumbnailType.AvatarThumbnail, Enum.ThumbnailSize.Size180x180)
	end)
	if bodyShotSuccess and bodyShot then
		cachedBodyshots[userId] = bodyShot
	end

	return cachedHeadshots[userId], cachedBodyshots[userId]
end

local function getOrCreateRow(container: ScrollingFrame, template: GuiObject, rank: number): GuiObject
	local rowName = "Entry_" .. rank
	local row = container:FindFirstChild(rowName)
	if row and row:IsA("GuiObject") then
		return row
	end

	local newRow = template:Clone()
	newRow.Name = rowName
	newRow.Visible = true
	newRow.Parent = container
	return newRow
end

local function clearUnusedRows(container: ScrollingFrame, maxRank: number)
	for _, child in container:GetChildren() do
		if not child:IsA("GuiObject") then
			continue
		end
		if child.Name == "Template" then
			continue
		end

		local prefix = string.sub(child.Name, 1, 6)
		if prefix == "Entry_" then
			local rank = tonumber(string.sub(child.Name, 7))
			if not rank or rank > maxRank then
				child:Destroy()
			end
		end
	end
end

local function getRuntimeLeaderboardData(): {LeaderboardEntry}
	local runtimeData: {LeaderboardEntry} = {}

	for _, player in ipairs(Players:GetPlayers()) do
		local earningsPerSecond = 0
		local success, data = pcall(function()
			return DataService.server:get(player)
		end)
		if success then
			earningsPerSecond = getEarningsPerSecondFromData(data)
		end

		table.insert(runtimeData, {
			key = tostring(player.UserId),
			value = earningsPerSecond,
		})
	end

	table.sort(runtimeData, function(a, b)
		return a.value > b.value
	end)

	return runtimeData
end

local function mergeLeaderboardWithRuntime(storeData: {LeaderboardEntry}?): {LeaderboardEntry}
	local mergedByUserId: {[string]: number} = {}

	if storeData then
		for _, entry in ipairs(storeData) do
			local key = tostring(entry.key)
			local value = tonumber(entry.value) or 0
			mergedByUserId[key] = normalizeLeaderboardValue(value)
		end
	end

	for _, player in ipairs(Players:GetPlayers()) do
		local userIdKey = tostring(player.UserId)
		local success, data = pcall(function()
			return DataService.server:get(player)
		end)
		if success then
			local liveValue = getEarningsPerSecondFromData(data)
			mergedByUserId[userIdKey] = liveValue
			debugLog("Live EPS", player.Name, userIdKey, liveValue)
		else
			debugLog("Failed to read data for", player.Name)
		end
	end

	local mergedData: {LeaderboardEntry} = {}
	for key, value in pairs(mergedByUserId) do
		table.insert(mergedData, {
			key = key,
			value = value,
		})
	end

	table.sort(mergedData, function(a, b)
		return a.value > b.value
	end)

	return mergedData
end

function LeaderboardsHandler:UpdateLeaderboards()
	if _isUpdating then
		debugLog("Update skipped because another update is running")
		return
	end
	_isUpdating = true
	_updateCount += 1
	debugLog("Update start", _updateCount, "Players:", #Players:GetPlayers(), "CanUseDataStoreApis:", CanUseDataStoreApis)

	local updateSuccess, updateError = pcall(function()
		local leaderboardsContainer = workspace.Leaderboards
		if not leaderboardsContainer then
			debugLog("workspace.Leaderboards not found")
			return
		end
		for leaderboardName, leaderboardInfo in pairs(Informations) do
			local leaderboard = leaderboardsContainer:FindFirstChild(leaderboardName)
			if leaderboard then
				debugLog("Rendering leaderboard", leaderboardName)
				local containerPart = leaderboard:FindFirstChild("Container")
				if not containerPart then
					debugLog("Missing Container in", leaderboard:GetFullName())
					continue
				end

				local surfaceGui = containerPart:FindFirstChild("SurfaceGui")
				if not surfaceGui or not surfaceGui:IsA("SurfaceGui") then
					debugLog("Missing/invalid SurfaceGui in", containerPart:GetFullName(), "Class:", surfaceGui and surfaceGui.ClassName)
					continue
				end

				local scrollingFrame = surfaceGui:FindFirstChild("ScrollingFrame")
				if not scrollingFrame or not scrollingFrame:IsA("ScrollingFrame") then
					debugLog("Missing/invalid ScrollingFrame in", surfaceGui:GetFullName(), "Class:", scrollingFrame and scrollingFrame.ClassName)
					continue
				end

				local Template = scrollingFrame:FindFirstChild("Template")
				if not Template then
					debugLog("Missing Template in", scrollingFrame:GetFullName())
					continue
				end
				if not Template:IsA("GuiObject") then
					debugLog("Template is not a GuiObject:", Template.ClassName, Template:GetFullName())
					continue
				end

				local isAscending = false
				local pageSize = LEADERBOARD_PAGE_SIZE

				local playersData = nil
				if CanUseDataStoreApis then
					local pagesSuccess, pages = pcall(function()
						return leaderboardInfo.Datastore:GetSortedAsync(isAscending, pageSize)
					end)
					if not pagesSuccess then
						debugLog("GetSortedAsync failed for", leaderboardName)
					end
					if pagesSuccess and pages then
						local currentPageSuccess, pageData = pcall(function()
							return pages:GetCurrentPage()
						end)
						if not currentPageSuccess then
							debugLog("GetCurrentPage failed for", leaderboardName)
						end
						if currentPageSuccess and pageData then
							playersData = pageData
						end
					end
				end

				playersData = mergeLeaderboardWithRuntime(playersData)
				if #playersData == 0 then
					playersData = getRuntimeLeaderboardData()
					debugLog("Using runtime fallback for", leaderboardName, "entries:", #playersData)
				else
					debugLog("Using merged datastore/runtime data for", leaderboardName, "entries:", #playersData)
				end

				local rowsCreated = 0
				local thumbnailFetchesStarted = 0
				for rank, data in ipairs(playersData) do
					if rank > LEADERBOARD_PAGE_SIZE then
						break
					end

					local playerId = tonumber(data.key)
					if not playerId or playerId <= 0 then
						continue
					end

					rowsCreated = rank

					local newTemplate = getOrCreateRow(scrollingFrame, Template, rank)
					newTemplate:SetAttribute("UserId", playerId)

					local rankLabel = newTemplate:FindFirstChild("RankLabel", true)
					if rankLabel and rankLabel:IsA("TextLabel") then
						rankLabel.Text = "#" .. rank
					else
						debugLog("Missing RankLabel in row", rank, newTemplate:GetFullName())
					end

					local nameLabel = newTemplate:FindFirstChild("NameLabel", true)
					if nameLabel and nameLabel:IsA("TextLabel") then
						nameLabel.Text = fetchPlayerName(playerId) or ("User " .. playerId)
					else
						debugLog("Missing NameLabel in row", rank, newTemplate:GetFullName())
					end

					local amountLabel = newTemplate:FindFirstChild("AmountLabel", true)
					if amountLabel and amountLabel:IsA("TextLabel") then
						amountLabel.Text = Format.abbreviateCash(data.value) .. "/s"
					else
						debugLog("Missing AmountLabel in row", rank, newTemplate:GetFullName())
					end
					newTemplate.Visible = true

					local headshot = cachedHeadshots[playerId]
					local bodyShot = cachedBodyshots[playerId]

					local headshotImage = newTemplate:FindFirstChild("PlayerHeadshot", true)
					if headshotImage and headshotImage:IsA("ImageLabel") then
						if headshot then
							headshotImage.Image = headshot
						end
					else
						debugLog("Missing PlayerHeadshot ImageLabel in row", rank, newTemplate:GetFullName())
					end

					local extraContainer = newTemplate:FindFirstChild("Extra", true)
					local bodyshotImage = if extraContainer then extraContainer:FindFirstChild("ImageLabel", true) else nil
					if bodyshotImage and bodyshotImage:IsA("ImageLabel") then
						if bodyShot then
							bodyshotImage.Image = bodyShot
						end
					else
						debugLog("Missing Extra.ImageLabel in row", rank, newTemplate:GetFullName())
					end

					if thumbnailFetchesStarted < MAX_THUMBNAIL_FETCHES_PER_UPDATE and (not headshot or not bodyShot) then
						thumbnailFetchesStarted += 1
						task.spawn(function()
							local fetchedHeadshot, fetchedBodyshot = fetchPlayerThumbnails(playerId)
							if not newTemplate.Parent then
								return
							end
							if newTemplate:GetAttribute("UserId") ~= playerId then
								return
							end
							if fetchedHeadshot and headshotImage and headshotImage:IsA("ImageLabel") then
								headshotImage.Image = fetchedHeadshot
							end
							if fetchedBodyshot and bodyshotImage and bodyshotImage:IsA("ImageLabel") then
								bodyshotImage.Image = fetchedBodyshot
							end
						end)
					end

					if rank % 20 == 0 then
						task.wait()
					end
				end

				clearUnusedRows(scrollingFrame, rowsCreated)
				debugLog("Rendered rows for", leaderboardName, "rowsCreated:", rowsCreated)
			end
		end
	end)

	if not updateSuccess then
		warn(`[LeaderboardsHandler] Failed to update leaderboards: {updateError}`)
	else
		debugLog("Update finished", _updateCount)
	end

	_isUpdating = false
end

-- Initialization function for the script
function LeaderboardsHandler:Initialize()
	debugLog("Initialize called")
	self:UpdateLeaderboards()

	Players.PlayerAdded:Connect(function(player)
		debugLog("PlayerAdded received, refreshing leaderboard")
		task.defer(function()
			local waitSuccess = pcall(function()
				DataService.server:waitForData(player)
			end)
			if not waitSuccess then
				debugLog("waitForData failed on PlayerAdded")
			end
			self:UpdateLeaderboards()
		end)
	end)
	Players.PlayerRemoving:Connect(function()
		debugLog("PlayerRemoving received, refreshing leaderboard")
		task.defer(function()
			self:UpdateLeaderboards()
		end)
	end)

	task.spawn(function()
		while true do
			self:UpdateLeaderboards()
			task.wait(LEADERBOARD_REFRESH_INTERVAL)
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

		local statValue = getEarningsPerSecondFromData(data)
		for _, v in Informations do
			pcall(function()
				v.Datastore:SetAsync(player.UserId, statValue)
			end)
		end
	end
end

return LeaderboardsHandler
