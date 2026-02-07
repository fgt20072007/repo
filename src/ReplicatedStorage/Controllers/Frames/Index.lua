-- Index Handler Script
-- Handles displaying, sorting, and searching entities in the UI

local IndexHandler = {}

-- Services
local ReplicatedStorage = game:GetService('ReplicatedStorage')
local Players = game:GetService('Players')

local Player = Players.LocalPlayer
local Gui = Player.PlayerGui
local Main = Gui:WaitForChild("MainGui")

local IndexFrame = Main.Frames.Index
local Container = IndexFrame.Backdrop.ScrollingFrame
local Banner = IndexFrame.Backdrop.IndexContainer

-- Banner elements
local BannerImageContainer = Banner.ImageContainer
local BannerImageLabel = BannerImageContainer.ImageLabel
local BetterHintButton = Banner.BetterHintButton
local BannerNameLabel = Banner.NameLabel
local BannerDescriptionLabel = Banner.DescriptionLabel

local ModeButton = IndexFrame.Backdrop.ChangeType
local SearchBox = IndexFrame.Backdrop.SearchBar.TextBox
local Template = Container.Template

-- Constants
local SORT_MODES = {
	OWNED_ASC = "Owned Ascending",
	OWNED_DESC = "Owned Descending",
	RARITY_ASC = "Rarity Ascending",
	RARITY_DESC = "Rarity Descending"
}

-- Variables
local currentMode = SORT_MODES.OWNED_DESC
local searchQuery = ""

-- Hide template
Template.Visible = false

-- Get modules
local Rarities = require(ReplicatedStorage.DataModules.Rarities)
local Entities = require(ReplicatedStorage.DataModules.EntityData)
local DataService = require(ReplicatedStorage.Utilities.DataService)

local CurrentEntity = nil

-- Helper function to check if entity is owned
local function isEntityOwned(entityName)
	local indexData = DataService.client:get("index")
	if indexData and indexData[entityName] then
		return true
	end
	return false
end

-- Update banner with entity information
local function updateBanner(entityName, entityData, isOwned)
	CurrentEntity = entityName
	
	if BannerImageLabel then
		BannerImageLabel.Image = entityData.Image
	end

	if BannerNameLabel then
		BannerNameLabel.Text = entityName
	end
	
	local ownsBetterHint = DataService.client:get("betterHintsOwned")[entityName] or false

	if BannerDescriptionLabel then
		if entityData.Spawnable then
			BannerDescriptionLabel.Text = "You can obtain this entity trough the conveyor belt"
		else
			BannerDescriptionLabel.Text = (ownsBetterHint and entityData.BetterHint or entityData.NormalHint) or "Hint was not given." 
		end
	end

	if BetterHintButton then
		if not isOwned then
			BetterHintButton.Visible = true
			local buttonTextLabel = BetterHintButton:FindFirstChild("TextLabel")
			
			if ownsBetterHint then
				BetterHintButton.Visible = false
				return
			end
			
			if buttonTextLabel then
				if entityData.Spawnable then
					buttonTextLabel.Text = "More luck"
				else
					buttonTextLabel.Text = "Better Hin"
				end
			end
		else
			BetterHintButton.Visible = false
		end
	end
end

-- Handle BetterHintButton click
local function onBetterHintButtonClicked()
	if not CurrentEntity then return end
	ReplicatedStorage.Communication.Functions.PurchaseBetterHint:InvokeServer(CurrentEntity)
end

-- Sort entities based on current mode
local function sortEntities(entitiesTable)
	local sortedList = {}

	-- Convert to array
	for name, data in pairs(entitiesTable) do
		table.insert(sortedList, {
			Name = name,
			Data = data,
			Owned = isEntityOwned(name),
			RarityWeight = Rarities[data.Rarity].Weight
		})
	end

	-- Sort based on mode
	if currentMode == SORT_MODES.OWNED_ASC then
		table.sort(sortedList, function(a, b)
			if a.Owned == b.Owned then
				if a.RarityWeight == b.RarityWeight then
					return a.Name < b.Name
				end
				return a.RarityWeight < b.RarityWeight
			end
			return not a.Owned and b.Owned 
		end)
	elseif currentMode == SORT_MODES.OWNED_DESC then
		table.sort(sortedList, function(a, b)
			if a.Owned == b.Owned then
				if a.RarityWeight == b.RarityWeight then
					return a.Name < b.Name
				end
				return a.RarityWeight < b.RarityWeight
			end
			return a.Owned and not b.Owned 
		end)
	elseif currentMode == SORT_MODES.RARITY_ASC then
		table.sort(sortedList, function(a, b)
			if a.RarityWeight == b.RarityWeight then
				return a.Name < b.Name
			end
			return a.RarityWeight < b.RarityWeight 
		end)
	elseif currentMode == SORT_MODES.RARITY_DESC then
		table.sort(sortedList, function(a, b)
			if a.RarityWeight == b.RarityWeight then
				return a.Name < b.Name
			end
			return a.RarityWeight > b.RarityWeight 
		end)
	end

	return sortedList
end

-- Filter entities based on search query
local function filterEntities(entitiesTable)
	if searchQuery == "" then
		return entitiesTable
	end

	local filtered = {}
	local lowerQuery = string.lower(searchQuery)

	for name, data in pairs(entitiesTable) do
		if string.find(string.lower(name), lowerQuery) then
			filtered[name] = data
		end
	end

	return filtered
end

-- Clear all templates from container
local function clearContainer()
	for _, child in ipairs(Container:GetChildren()) do
		if child:IsA("GuiObject") and child ~= Template then
			child:Destroy()
		end
	end
end

-- Create a template for an entity
local function createTemplate(entityName, entityData, isOwned)
	local newTemplate = Template:Clone()
	newTemplate.Name = entityName
	newTemplate.Visible = true

	local renderingImage = newTemplate:FindFirstChild("RenderingImage")
	local nameLabel = newTemplate:FindFirstChild("NameLabel")
	local rarityLabel = newTemplate:FindFirstChild("RarityLabel")

	if renderingImage then
		renderingImage.Image = entityData.Image

		if not isOwned then
			renderingImage.ImageColor3 = Color3.new(0, 0, 0)

			local overlay = Instance.new("Frame")
			overlay.Name = "LockedOverlay"
			overlay.Size = UDim2.new(1, 0, 1, 0)
			overlay.Position = UDim2.new(0, 0, 0, 0)
			overlay.BackgroundColor3 = Color3.new(0, 0, 0)
			overlay.BackgroundTransparency = 0.5
			overlay.BorderSizePixel = 0
			overlay.ZIndex = renderingImage.ZIndex + 1
			overlay.Parent = renderingImage.Parent
		else
			renderingImage.ImageColor3 = Color3.new(1, 1, 1)
		end
	end

	if nameLabel then
		nameLabel.Text = entityName
	end

	if rarityLabel then
		rarityLabel.Text = entityData.Rarity

		local rarityInfo = Rarities[entityData.Rarity]
		if rarityInfo then

			if rarityInfo.Gradient then
				local gradient = rarityInfo.Gradient:Clone()
				gradient.Parent = rarityLabel
			end

			local gradientStroke = rarityInfo.Gradient:FindFirstChildOfClass("UIStroke")
			if gradientStroke then
				local stroke = gradientStroke:Clone()
				stroke.Parent = rarityLabel
			end
		end
	end

	newTemplate.MouseButton1Click:Connect(function()
		onTemplateClicked(entityName, entityData, isOwned)
	end)

	newTemplate.Parent = Container
end

-- Refresh the display
local function refreshDisplay()
	clearContainer()

	local filtered = filterEntities(Entities)
	local sorted = sortEntities(filtered)

	for _, entityInfo in ipairs(sorted) do
		createTemplate(entityInfo.Name, entityInfo.Data, entityInfo.Owned)
	end
end

-- Handle template click
function onTemplateClicked(entityName, entityData, isOwned)
	updateBanner(entityName, entityData, isOwned)
end

-- Cycle through sort modes
local function cycleModes()
	if currentMode == SORT_MODES.OWNED_ASC then
		currentMode = SORT_MODES.OWNED_DESC
	elseif currentMode == SORT_MODES.OWNED_DESC then
		currentMode = SORT_MODES.RARITY_ASC
	elseif currentMode == SORT_MODES.RARITY_ASC then
		currentMode = SORT_MODES.RARITY_DESC
	elseif currentMode == SORT_MODES.RARITY_DESC then
		currentMode = SORT_MODES.OWNED_ASC
	end

	ModeButton.NameLabel.Text = "Mode: " .. currentMode
	refreshDisplay()
end

-- Set up event connections
local function setupConnections()
	ModeButton.MouseButton1Click:Connect(cycleModes)
	ModeButton.NameLabel.Text = "Mode: " .. currentMode

	SearchBox:GetPropertyChangedSignal("Text"):Connect(function()
		searchQuery = SearchBox.Text
		refreshDisplay()
	end)

	DataService.client:getIndexChangedSignal("index"):Connect(function()
		refreshDisplay()
	end)

	BetterHintButton.Activated:Connect(onBetterHintButtonClicked)
	
	ReplicatedStorage.Communication.Remotes.OnBetterHintPurchased.OnClientEvent:Connect(function(EntityChanged)
		if EntityChanged == CurrentEntity then
			updateBanner(EntityChanged, Entities[EntityChanged], DataService.client:get({"index", EntityChanged}))
		end
	end)
end

-- Initialize the index handler
function IndexHandler.Initialize()
	setupConnections()
	refreshDisplay()
end

-- Public function to refresh display manually
function IndexHandler.Refresh()
	refreshDisplay()
end

return IndexHandler