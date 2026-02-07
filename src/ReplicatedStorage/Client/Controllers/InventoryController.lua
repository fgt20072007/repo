local Players = game:GetService("Players")
local ContentProvider = game:GetService("ContentProvider")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Assets = ReplicatedStorage:WaitForChild("Assets")

local Module3D = require(Shared.Packages:WaitForChild("module3d"))
local Rarities = require(Shared.Data:WaitForChild("Rarities"))
local AllPets = require(Shared.Data.Eggs:WaitForChild("AllPets"))
local Client = require(ReplicatedStorage:WaitForChild("Client"))
local Interface = require(ReplicatedStorage:WaitForChild("Interface"))
local TweenPlus = require(ReplicatedStorage:WaitForChild("Tween+"))

local EquipPetRemote = require(Shared.Remotes:WaitForChild("EquipPet")):Client()
local UnequipPetRemote = require(Shared.Remotes:WaitForChild("UnequipPet")):Client()
local DeletePetsRemote = require(Shared.Remotes:WaitForChild("DeletePets")):Client()

local Player = Players.LocalPlayer

local PETS_PER_PAGE = 24
local MAX_AUTO_EQUIP = 3

local PetChanceByName = {}
for _, pet in ipairs(AllPets) do
	if type(pet) ~= "table" then continue end
	if type(pet.Name) ~= "string" then continue end
	if type(pet.Chance) ~= "number" then continue end
	PetChanceByName[pet.Name] = pet.Chance
end

local RarityRankByName = {}
for rarityIndex, rarityName in ipairs(Rarities.Order) do
	RarityRankByName[rarityName] = rarityIndex
end

local function IsTextObject(instance)
	if not instance then
		return false
	end

	return instance:IsA("TextLabel") or instance:IsA("TextButton") or instance:IsA("TextBox")
end

local function SetVisible(instance, visible)
	if not instance then
		return
	end

	pcall(function()
		instance.Visible = visible
	end)
end

local function FindTextTarget(scope, name)
	if not scope then
		return nil
	end

	local target = scope:FindFirstChild(name, true)
	if not target then
		return nil
	end

	if IsTextObject(target) then
		return target
	end

	return target:FindFirstChildWhichIsA("TextLabel", true)
		or target:FindFirstChildWhichIsA("TextButton", true)
		or target:FindFirstChildWhichIsA("TextBox", true)
end

local function FormatChance(chance: number): string
	if chance <= 0 then
		return "??"
	end

	if chance >= 1 then
		return string.format("1/%d", math.max(1, math.floor(1 / chance)))
	end

	return string.format("%.1f%%", chance * 100)
end

local function FormatCompactCount(value: number): string
	local integerValue = math.max(0, math.floor(tonumber(value) or 0))
	if integerValue < 1000 then
		return tostring(integerValue)
	end

	local suffixes = { "k", "m", "b", "t", "qa", "qi" }
	local scaled = integerValue
	local suffixIndex = 0

	while scaled >= 1000 and suffixIndex < #suffixes do
		scaled /= 1000
		suffixIndex += 1
	end

	local compact = ""
	if scaled >= 100 then
		compact = string.format("%.0f", scaled)
	elseif scaled >= 10 then
		compact = string.format("%.1f", scaled)
	else
		compact = string.format("%.2f", scaled)
	end

	compact = string.gsub(compact, "%.0+$", "")
	compact = string.gsub(compact, "(%.[1-9]*)0+$", "%1")

	local suffix = suffixes[suffixIndex]
	if suffix then
		return compact .. suffix
	end

	return tostring(integerValue)
end

local function NormalizeSearchText(value: string?): string
	if type(value) ~= "string" then
		return ""
	end

	value = string.gsub(value, "^%s+", "")
	value = string.gsub(value, "%s+$", "")

	return string.lower(value)
end

local InventoryController = {}

function InventoryController._Init(self: InventoryController)
	self.PlayerGui = Player:WaitForChild("PlayerGui")

	local Main = self.PlayerGui:WaitForChild("Main")
	local Inventory = Main:WaitForChild("Frames"):WaitForChild("Inventory")
	local InventoryFrames = Inventory:WaitForChild("Frames")

	self.MainFrame = InventoryFrames:WaitForChild("MainFrame")
	self.Container = self.MainFrame:WaitForChild("Container")
	self.PetsTab = self.Container:WaitForChild("PetsTab")
	self.PetsContainer = self.PetsTab:WaitForChild("Pets")
	self.EquippedContainer = self.PetsTab:WaitForChild("EquippedPets")

	self.ModeButtons = self.Container:FindFirstChild("ModeButtons")
	self.TButtons = self.Container:FindFirstChild("TButtons")
	self.NButtons = self.Container:FindFirstChild("NButtons")

	self.PetModels = Assets:WaitForChild("Models"):WaitForChild("Pets")
	self.Pets = {}
	self.EquippedPets = {}
	self.SelectedToDelete = {}
	self.CurrentPage = 1
	self.TotalPages = 1
	self.DeleteMode = false
	self.Preloaded = false
	self.SearchInput = nil
	self.SearchQuery = ""

	local SearchFrame = self.MainFrame:FindFirstChild("Search")
	local SearchScope = SearchFrame
	if SearchFrame then
		SearchScope = SearchFrame:FindFirstChild("Input") or SearchFrame
	end

	self.SearchInput = self:_FindTextBox(SearchScope)
	if self.SearchInput then
		self.SearchQuery = NormalizeSearchText(self.SearchInput.Text)
	end

	local Templates = self.PlayerGui:FindFirstChild("Templates")
	self.PetTemplate = Templates and (Templates:FindFirstChild("PetTemp") or Templates:FindFirstChild("PetTempSecret"))

	if not self.PetTemplate then
		local ItemTemp = InventoryFrames:FindFirstChild("ItemTemp", true)
		if ItemTemp then
			self.PetTemplate = ItemTemp
		end
	end

	self:_BindButtons()
	self:_PreloadPetAssets()
	self:_SetDeleteMode(false)
end

function InventoryController.Spawn(self: InventoryController)
	local DataController = Client.Controllers.DataController
	if not DataController then return end

	local Profile = DataController:GetProfile(true)
	self.Pets = type(Profile.Pets) == "table" and Profile.Pets or {}
	self.EquippedPets = type(Profile.EquippedPets) == "table" and Profile.EquippedPets or {}

	self:_Render()

	DataController:OnChange("Pets", function(new)
		self.Pets = type(new) == "table" and new or {}

		for petId in self.SelectedToDelete do
			if not self.Pets[petId] then
				self.SelectedToDelete[petId] = nil
			end
		end

		self:_Render()
	end)

	DataController:OnChange("EquippedPets", function(new)
		self.EquippedPets = type(new) == "table" and new or {}
		self:_Render()
	end)
end

function InventoryController._BindButtons(self: InventoryController)
	local nextPageFrame = self.PetsTab:FindFirstChild("NextPage")
	local nextPageButton = self:_FindButton(nextPageFrame and nextPageFrame:FindFirstChild("NextPage"))
	local backPageButton = self:_FindButton(nextPageFrame and nextPageFrame:FindFirstChild("BackPage"))
	local massDeleteButton = self:_FindButton(self.TButtons and self.TButtons:FindFirstChild("MassDelete"))
	local confirmDeleteButton = self:_FindButton(self.ModeButtons and self.ModeButtons:FindFirstChild("Confirm"))
	local cancelDeleteButton = self:_FindButton(self.ModeButtons and self.ModeButtons:FindFirstChild("Cancel"))
	local equipBestButton = self:_FindButton(self.NButtons and self.NButtons:FindFirstChild("EquipBest"))
	local unequipAllButton = self:_FindButton(self.NButtons and self.NButtons:FindFirstChild("UnequipAll"))

	if nextPageButton then
		nextPageButton.MouseButton1Click:Connect(function()
			self.CurrentPage = math.min(self.CurrentPage + 1, self.TotalPages)
			self:_Render()
		end)
	end

	if backPageButton then
		backPageButton.MouseButton1Click:Connect(function()
			self.CurrentPage = math.max(self.CurrentPage - 1, 1)
			self:_Render()
		end)
	end

	if massDeleteButton then
		massDeleteButton.MouseButton1Click:Connect(function()
			self:_SetDeleteMode(true)
		end)
	end

	if confirmDeleteButton then
		confirmDeleteButton.MouseButton1Click:Connect(function()
			self:_ConfirmDelete()
		end)
	end

	if cancelDeleteButton then
		cancelDeleteButton.MouseButton1Click:Connect(function()
			self:_SetDeleteMode(false)
		end)
	end

	if equipBestButton then
		equipBestButton.MouseButton1Click:Connect(function()
			self:_EquipBest()
		end)
	end

	if unequipAllButton then
		unequipAllButton.MouseButton1Click:Connect(function()
			self:_UnequipAll()
		end)
	end

	if self.SearchInput then
		self.SearchInput:GetPropertyChangedSignal("Text"):Connect(function()
			local searchQuery = NormalizeSearchText(self.SearchInput.Text)
			if searchQuery == self.SearchQuery then
				return
			end

			self.SearchQuery = searchQuery
			self.CurrentPage = 1
			self:_Render()
		end)
	end
end

function InventoryController._FindButton(self: InventoryController, scope): GuiButton?
	if not scope then
		return nil
	end

	if scope:IsA("GuiButton") then
		return scope
	end

	local button = scope:FindFirstChild("Button")
	if button then
		if button:IsA("GuiButton") then
			return button
		end

		local nestedButton = button:FindFirstChildWhichIsA("GuiButton", true)
		if nestedButton then
			return nestedButton
		end
	end

	return scope:FindFirstChildWhichIsA("GuiButton", true)
end

function InventoryController._FindTextBox(self: InventoryController, scope): TextBox?
	if not scope then
		return nil
	end

	if scope:IsA("TextBox") then
		return scope
	end

	local input = scope:FindFirstChild("Input")
	if input and input:IsA("TextBox") then
		return input
	end

	return scope:FindFirstChildWhichIsA("TextBox", true)
end

function InventoryController._SetText(self: InventoryController, scope, name: string, value: string)
	local target = FindTextTarget(scope, name)
	if not target then
		return
	end

	target.Text = value
end

function InventoryController._GetCardScale(self: InventoryController, card)
	local scale = card:FindFirstChildWhichIsA("UIScale")
	if scale then
		return scale
	end

	scale = Instance.new("UIScale")
	scale.Parent = card
	scale.Scale = 1

	return scale
end

function InventoryController._AnimateCardEnter(self: InventoryController, card)
	local scale = self:_GetCardScale(card)

	scale.Scale = 0.9

	TweenPlus(scale, { Scale = 1 }, {
		Time = 0.18,
		EasingStyle = "Back",
		EasingDirection = "Out",
	}):Start()
end

function InventoryController._AnimateCardPress(self: InventoryController, card, toSelectedState: boolean?)
	if not card then
		return
	end

	local scale = self:_GetCardScale(card)
	local punchScale = toSelectedState and 1.08 or 0.95

	TweenPlus(scale, { Scale = punchScale }, {
		Time = 0.08,
		EasingStyle = "Quad",
		EasingDirection = "Out",
	}):Start()

	task.delay(0.08, function()
		if not scale or not scale.Parent then return end

		TweenPlus(scale, { Scale = 1 }, {
			Time = 0.14,
			EasingStyle = "Back",
			EasingDirection = "Out",
		}):Start()
	end)
end

function InventoryController._CollectPetPreloadIds(self: InventoryController)
	if not self.PetModels then
		return {}
	end

	local targets = {}

	for _, instance in self.PetModels:GetDescendants() do
		if
			instance:IsA("MeshPart")
			or instance:IsA("SpecialMesh")
			or instance:IsA("SurfaceAppearance")
			or instance:IsA("Decal")
			or instance:IsA("Texture")
			or instance:IsA("ImageLabel")
			or instance:IsA("ImageButton")
		then
			table.insert(targets, instance)
		end
	end

	return targets
end

function InventoryController._PreloadPetAssets(self: InventoryController)
	if self.Preloaded then
		return
	end

	self.Preloaded = true

	task.spawn(function()
		local preloadTargets = self:_CollectPetPreloadIds()
		if #preloadTargets == 0 then return end

		pcall(function()
			ContentProvider:PreloadAsync(preloadTargets)
		end)
	end)
end

function InventoryController._SetCardSelectedVisual(self: InventoryController, card, isSelected: boolean)
	local selectedMarker = card:FindFirstChild("Selected ToDelete", true) or card:FindFirstChild("Selected", true)
	SetVisible(selectedMarker, self.DeleteMode and isSelected)
end

function InventoryController._UpdateSelectionVisuals(self: InventoryController, petId: string)
	local isSelected = self.SelectedToDelete[petId] == true

	for _, card in self.PetsContainer:GetChildren() do
		if card.Name ~= petId then continue end
		self:_SetCardSelectedVisual(card, isSelected)
	end

	for _, card in self.EquippedContainer:GetChildren() do
		if card.Name ~= petId then continue end
		self:_SetCardSelectedVisual(card, isSelected)
	end
end

function InventoryController._SetDeleteMode(self: InventoryController, enabled: boolean)
	self.DeleteMode = enabled == true

	if not self.DeleteMode then
		table.clear(self.SelectedToDelete)
	end

	SetVisible(self.ModeButtons, self.DeleteMode)
	SetVisible(self.NButtons, not self.DeleteMode)
	SetVisible(self.TButtons, not self.DeleteMode)

	self:_Render()
end

function InventoryController._ConfirmDelete(self: InventoryController)
	local ids = {}

	for petId in self.SelectedToDelete do
		if self.Pets[petId] then
			table.insert(ids, petId)
		end
	end

	if #ids > 0 then
		DeletePetsRemote:Fire(ids)
	end

	self:_SetDeleteMode(false)
end

function InventoryController._BuildPetRecords(self: InventoryController)
	local records = {}

	for petId, petData in self.Pets do
		if type(petId) ~= "string" then continue end
		if type(petData) ~= "table" then continue end

		local petName = petData.Name
		if type(petName) ~= "string" then continue end

		local chance = tonumber(petData.Chance) or PetChanceByName[petName] or 0
		local obtainedAt = tonumber(petData.ObtainedAt) or 0
		local rarityName = Rarities.GetFromChance(chance).Name
		local rarityRank = RarityRankByName[rarityName] or 0

		table.insert(records, {
			Id = petId,
			Name = petName,
			Chance = chance,
			RarityRank = rarityRank,
			ObtainedAt = obtainedAt,
			IsEquipped = self.EquippedPets[petId] == true,
		})
	end

	table.sort(records, function(a, b)
		if a.IsEquipped ~= b.IsEquipped then
			return a.IsEquipped
		end

		if a.RarityRank ~= b.RarityRank then
			return a.RarityRank > b.RarityRank
		end

		if a.Chance ~= b.Chance then
			return a.Chance < b.Chance
		end

		if a.Name ~= b.Name then
			return a.Name < b.Name
		end

		return a.Id < b.Id
	end)

	return records
end

function InventoryController._ClearCards(self: InventoryController, container)
	if not container then
		return
	end

	for _, child in container:GetChildren() do
		if child:IsA("UIGridLayout") or child:IsA("UIListLayout") or child:IsA("UIPadding") then
			continue
		end

		child:Destroy()
	end
end

function InventoryController._ApplyPetVisuals(self: InventoryController, card, pet)
	local rarity = Rarities.GetFromChance(pet.Chance)
	local chanceText = FormatChance(pet.Chance)

	self:_SetText(card, "PetName", pet.Name)
	self:_SetText(card, "Name", pet.Name)
	self:_SetText(card, "Level", pet.Name)
	self:_SetText(card, "Lvl", pet.Name)
	self:_SetText(card, "StackAmount", chanceText)
	self:_SetText(card, "Stack", chanceText)
	self:_SetText(card, "Serial", `#{string.sub(pet.Id, 1, 6)}`)
	self:_SetText(card, "Secret", rarity.Name)
	self:_SetText(card, "Rarity", rarity.Name)

	local rarityGradient = card:FindFirstChild("RarityGradient", true)
	if rarityGradient and rarityGradient:IsA("UIGradient") then
		rarityGradient.Color = ColorSequence.new(rarity.Color, rarity.Color:Lerp(Color3.fromRGB(255, 255, 255), 0.2))
	end

	self:_SetCardSelectedVisual(card, self.SelectedToDelete[pet.Id] == true)

	local imageHolder = card:FindFirstChild("PetImage", true) or card:FindFirstChild("Image", true) or card:FindFirstChild(
		"ItemImage",
		true
	)
	local model = self.PetModels and self.PetModels:FindFirstChild(pet.Name)

	if not model then
		return
	end

	if imageHolder and not imageHolder:IsA("GuiObject") then
		imageHolder = imageHolder:FindFirstChildWhichIsA("GuiObject", true)
	end

	if not imageHolder or not imageHolder:IsA("GuiObject") then
		return
	end

	if imageHolder:IsA("ImageLabel") or imageHolder:IsA("ImageButton") then
		imageHolder.Image = ""
		imageHolder.ImageTransparency = 1
	end

	for _, child in imageHolder:GetChildren() do
		if child:IsA("ViewportFrame") then
			child:Destroy()
		elseif child:IsA("ImageLabel") or child:IsA("ImageButton") then
			child.Image = ""
			child.ImageTransparency = 1
		end
	end

	local modelClone = model:Clone()
	local success, model3d = pcall(function()
		return Module3D:Attach3D(imageHolder, modelClone)
	end)

	if not success or not model3d then
		modelClone:Destroy()
		return
	end

	model3d:SetDepthMultiplier(1.2)
	model3d.CurrentCamera.FieldOfView = 5
	model3d.Interactable = false
	model3d.Visible = true
	model3d:SetCFrame(CFrame.new(0, 0, 0) * CFrame.fromOrientation(0, math.rad(90), 0))
end

function InventoryController._CreatePetCard(self: InventoryController, pet, parent)
	if not self.PetTemplate then
		return
	end

	local card = self.PetTemplate:Clone()
	card.Name = pet.Id
	card.Parent = parent
	SetVisible(card, true)
	self:_AnimateCardEnter(card)

	self:_ApplyPetVisuals(card, pet)

	local button = self:_FindButton(card)
	if button then
		Interface:AnimateButton(button)
		button.MouseButton1Click:Connect(function()
			self:_OnPetPressed(pet.Id, card)
		end)
	end
end

function InventoryController._OnPetPressed(self: InventoryController, petId: string, card)
	if self.DeleteMode then
		local isNowSelected = false

		if self.SelectedToDelete[petId] then
			self.SelectedToDelete[petId] = nil
		else
			self.SelectedToDelete[petId] = true
			isNowSelected = true
		end

		self:_AnimateCardPress(card, isNowSelected)
		self:_UpdateSelectionVisuals(petId)
		return
	end

	if self.EquippedPets[petId] then
		self:_AnimateCardPress(card, false)
		UnequipPetRemote:Fire(petId)
		return
	end

	self:_AnimateCardPress(card, true)
	EquipPetRemote:Fire(petId)
end

function InventoryController._EquipBest(self: InventoryController)
	local records = self:_BuildPetRecords()
	local equippedCount = 0

	for _, pet in records do
		if pet.IsEquipped then
			equippedCount += 1
		end
	end

	if equippedCount >= MAX_AUTO_EQUIP then
		return
	end

	for _, pet in records do
		if pet.IsEquipped then
			continue
		end

		EquipPetRemote:Fire(pet.Id)
		equippedCount += 1

		if equippedCount >= MAX_AUTO_EQUIP then
			break
		end
	end
end

function InventoryController._UnequipAll(self: InventoryController)
	for petId in self.EquippedPets do
		UnequipPetRemote:Fire(petId)
	end
end

function InventoryController._UpdateSummary(self: InventoryController, ownedCount: number, equippedCount: number)
	self:_SetText(self.PetsTab, "HowMuchOwned", string.format("%s / ∞", FormatCompactCount(ownedCount)))
	self:_SetText(self.PetsTab, "HowMuchEquipped", string.format("%d / %d", equippedCount, MAX_AUTO_EQUIP))
	self:_SetText(self.PetsTab, "Page", `{self.CurrentPage}/{self.TotalPages}`)
	self:_SetText(self.PetsTab, "WhatPage", `{self.CurrentPage}/{self.TotalPages}`)
end

function InventoryController._Render(self: InventoryController)
	if not self.PetTemplate then
		return
	end

	local records = self:_BuildPetRecords()
	local filteredRecords = {}
	local equippedRecords = {}
	local equippedCount = 0
	local searchQuery = self.SearchQuery

	for _, pet in records do
		if pet.IsEquipped then
			equippedCount += 1
			table.insert(equippedRecords, pet)
			continue
		end

		local matchesSearch = true
		if searchQuery ~= "" then
			matchesSearch = string.find(string.lower(pet.Name), searchQuery, 1, true) ~= nil
		end

		if matchesSearch then
			table.insert(filteredRecords, pet)
		end
	end

	self.TotalPages = math.max(1, math.ceil(#filteredRecords / PETS_PER_PAGE))
	self.CurrentPage = math.clamp(self.CurrentPage, 1, self.TotalPages)

	self:_ClearCards(self.PetsContainer)
	self:_ClearCards(self.EquippedContainer)

	local firstIndex = ((self.CurrentPage - 1) * PETS_PER_PAGE) + 1
	local lastIndex = math.min(#filteredRecords, firstIndex + PETS_PER_PAGE - 1)

	for index = firstIndex, lastIndex do
		self:_CreatePetCard(filteredRecords[index], self.PetsContainer)
	end

	for _, pet in equippedRecords do
		self:_CreatePetCard(pet, self.EquippedContainer)
	end

	self:_UpdateSummary(#records, equippedCount)
end

type InventoryController = typeof(InventoryController) & {
	PlayerGui: Instance,
	MainFrame: Instance,
	Container: Instance,
	PetsTab: Instance,
	PetsContainer: Instance,
	EquippedContainer: Instance,
	ModeButtons: Instance?,
	TButtons: Instance?,
	NButtons: Instance?,
	PetModels: Instance?,
	PetTemplate: Instance?,
	Pets: { [string]: any },
	EquippedPets: { [string]: boolean },
	SelectedToDelete: { [string]: boolean },
	CurrentPage: number,
	TotalPages: number,
	DeleteMode: boolean,
	Preloaded: boolean,
	SearchInput: TextBox?,
	SearchQuery: string,
}

return InventoryController
