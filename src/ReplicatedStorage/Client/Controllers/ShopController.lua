--!nocheck

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Assets = ReplicatedStorage:WaitForChild("Assets")
local Shared = ReplicatedStorage:WaitForChild("Shared")

local Scythes = require(Shared.Data:WaitForChild("Scythes"))
local DNAData = require(Shared.Data:WaitForChild("DNA"))
local RankData = require(Shared.Data:WaitForChild("Ranks"))
local Interface = require(ReplicatedStorage:WaitForChild("Interface"))
local Module3D = require(Shared.Packages:WaitForChild("module3d"))
local Math = require(Shared.CustomPackages.Math)
local Client = require(ReplicatedStorage.Client)
local PurchaseItemRemote = require(Shared.Remotes.PurchaseItem):Client()
local BuyAllRemote = require(Shared.Remotes.BuyAll):Client()

local DisplayCFrame = CFrame.new(0, 0.25, 0)
local ShopController = {}

function ShopController._Init(self: ShopController)
	self.Container = Interface:_GetComponent({ "Frames", "Shop", "MainContainer" })
	self.TabSelection = self.Container:WaitForChild("TabSelection")
	self.LastOpenedContainer = self.Container:WaitForChild("ScythesContainer")
	local Closing = self.Container:WaitForChild("Closing")

	local openedTab

	for _, tabButton in self.TabSelection:GetChildren() do
		if not tabButton:IsA("GuiButton") then
			continue
		end

		tabButton.MouseButton1Click:Connect(function()
			local targetContainer = self.Container:FindFirstChild(tabButton.Name .. "Container")

			if not targetContainer then
				warn(`Shop tab container not found for {tabButton.Name}`)
				return
			end

			if openedTab then
				openedTab.IsOnPage.Enabled = false
			end

			if self.LastOpenedContainer and self.LastOpenedContainer ~= tabButton then
				self.LastOpenedContainer.Visible = false
			end

			tabButton.IsOnPage.Enabled = true
			targetContainer.Visible = true

			openedTab = tabButton
			self.LastOpenedContainer = targetContainer
		end)
	end

	Closing.Button.MouseButton1Click:Connect(function()
		Interface:_ToggleFrame("Shop")
	end)
end

function ShopController.Spawn(self: ShopController)
	self:_DisplayScythes()
	self:_DisplayDNA()
	self:_DisplayRanks()
end

function ShopController._DisplayScythes(self: ShopController)
	local itemTemplate = self.Container.ScythesContainer.Page:WaitForChild("Template")

	local DataController = Client.Controllers.DataController
	local OwnedScythes = DataController:Get("Scythes")
	local EquippedScythe = DataController:Get("EquippedScythe")

	local DisplayFrame = self.Container.ScythesContainer.Scythe:WaitForChild("Display")
	local BuyScytheButton = self.Container.ScythesContainer.Scythe.Buy:WaitForChild("Buy")
	local BuyAllVip = self.Container.ScythesContainer.Scythe:FindFirstChild("BuyAll_Vip")
	local BuyAllButton = BuyAllVip and BuyAllVip:FindFirstChild("BuyAll") and BuyAllVip.BuyAll:FindFirstChild("Button")
	local Stats = self.Container.ScythesContainer.Scythe.Stats
	local displayedScythe
	local displayedModel

	local function RefreshPageClones()
		for _, clone in self.Container.ScythesContainer.Page:GetChildren() do
			if not clone:IsA("GuiButton") or clone.Name == "Template" then continue end
			local scytheData = Scythes.Sorted[clone.Name]
			if not scytheData then continue end

			local ownsIt = OwnedScythes[clone.Name] or false
			clone.IfLocked.Visible = not ownsIt

			if not ownsIt then
				local idx = table.find(Scythes.Raw, scytheData)
				if idx and idx > 1 then
					local prev = Scythes.Raw[idx - 1]
					if OwnedScythes[prev.name] then
						clone.IfLocked.Visible = false
					end
				end
			end
		end
	end

	local function ChangeScytheDisplay(scythe: Scythes.Scythe)
		if displayedModel then
			displayedModel:Destroy()
		end

		local displayModel = Assets.Scythes[scythe.type][scythe.name]:Clone()
		local Model3D = Module3D:Attach3D(DisplayFrame.Frame, displayModel)
		local ownsScythe = OwnedScythes[scythe.name] or false
		local isEquipped = EquippedScythe == scythe.name
		Model3D:SetDepthMultiplier(1.2)
		Model3D.CurrentCamera.FieldOfView = 5
		Model3D:SetCFrame(DisplayCFrame)
		Model3D.Visible = true

		Stats.Stats.Text = `1/{scythe.skullPerClick} swing`
		BuyScytheButton.Cost.Amount.Text = isEquipped and "Equipped" or (ownsScythe and "Equip" or Math.FormatCurrency(scythe.price))
		displayedScythe = scythe
		displayedModel = displayModel
		self.Container.ScythesContainer.Scythe.ScytheName.Text = scythe.displayName
	end

	BuyScytheButton.MouseButton1Click:Connect(function()
		if not displayedScythe then return end
		if EquippedScythe == displayedScythe.name then return end

		local profile = DataController:GetProfile()

		if OwnedScythes[displayedScythe.name] then
			PurchaseItemRemote:Fire("Scythes", displayedScythe.name)
			EquippedScythe = displayedScythe.name
			ChangeScytheDisplay(displayedScythe)
			return
		end

		if profile.Coins < displayedScythe.price then return end

		PurchaseItemRemote:Fire("Scythes", displayedScythe.name)
		OwnedScythes[displayedScythe.name] = true
		EquippedScythe = displayedScythe.name
		ChangeScytheDisplay(displayedScythe)

		local index = table.find(Scythes.Raw, displayedScythe)
		local nextItem = index and Scythes.Raw[index + 1]
		if nextItem then
			local nextClone = self.Container.ScythesContainer.Page:FindFirstChild(nextItem.name)
			if nextClone then nextClone.IfLocked.Visible = false end
		end
	end)

	if BuyAllButton then
		BuyAllButton.MouseButton1Click:Connect(function()
			local profile = DataController:GetProfile()
			local lastPurchased = nil
			local coins = profile.Coins

			for _, scythe in Scythes.Raw do
				if OwnedScythes[scythe.name] then
					lastPurchased = scythe
					continue
				end

				if coins < scythe.price then break end

				coins -= scythe.price
				profile.Coins = coins
				OwnedScythes[scythe.name] = true
				lastPurchased = scythe
			end

			if lastPurchased then
				EquippedScythe = lastPurchased.name
				ChangeScytheDisplay(lastPurchased)
				RefreshPageClones()
			end

			BuyAllRemote:Fire("Scythes")
		end)
	end

	DataController:OnChange("Scythes", function(new)
		OwnedScythes = new
		RefreshPageClones()
	end)

	DataController:OnChange("EquippedScythe", function(new)
		EquippedScythe = new
		local scytheData = Scythes.Sorted[new]
		if scytheData then
			ChangeScytheDisplay(scytheData)
		end
	end)

	for index, scythe in Scythes.Raw do
		local Clone = itemTemplate:Clone()
		local Model = Assets.Scythes[scythe.type]:FindFirstChild(scythe.name)

		if not Model then continue end

		Model = Model:Clone()

		local Model3D = Module3D:Attach3D(Clone, Model)
		local playerOwnsScythe = OwnedScythes[scythe.name] or false
		Model3D:SetDepthMultiplier(1.2)
		Model3D.CurrentCamera.FieldOfView = 5
		Model3D.Interactable = false
		Model3D.Visible = true
		Model3D:SetCFrame(DisplayCFrame)

		Clone.ScytheName.Text = scythe.displayName
		Clone.LayoutOrder = index
		Clone.IfLocked.Visible = not playerOwnsScythe

		if index > 1 and not playerOwnsScythe then
			local previousScythe = Scythes.Raw[index - 1]
			if OwnedScythes[previousScythe.name] then
				Clone.IfLocked.Visible = false
			end
		end

		Clone.Name = scythe.name
		Clone.Parent = self.Container.ScythesContainer.Page
		Clone.Visible = true

		Clone.MouseButton1Click:Connect(function()
			if Clone.IfLocked.Visible then return end
			ChangeScytheDisplay(scythe)
		end)

		Interface:AnimateButton(Clone)
	end

	ChangeScytheDisplay(Scythes.Sorted[EquippedScythe])
end

function ShopController._DisplayDNA(self: ShopController)
	local itemTemplate = self.Container.DNAContainer.Page:WaitForChild("Template")

	local DataController = Client.Controllers.DataController
	local OwnedDNA = DataController:Get("DNA")
	local EquippedDNA = DataController:Get("EquippedDNA")

	local BuyDNAButton = self.Container.DNAContainer.DNADisplay.Buy:WaitForChild("Buy")
	local BuyAllInf = self.Container.DNAContainer.DNADisplay:FindFirstChild("BuyAll_Inf")
	local BuyAllButton = BuyAllInf and BuyAllInf:FindFirstChild("BuyAll") and BuyAllInf.BuyAll:FindFirstChild("Button")
	local DisplayFrame = self.Container.DNAContainer.DNADisplay:WaitForChild("Display")
	local Stats = self.Container.DNAContainer.DNADisplay.Stats
	local displayedDna

	local function RefreshPageClones()
		for _, clone in self.Container.DNAContainer.Page:GetChildren() do
			if not clone:IsA("GuiButton") or clone.Name == "Template" then continue end
			local dnaData = DNAData.Sorted[clone.Name]
			if not dnaData then continue end

			local ownsIt = OwnedDNA[clone.Name] or false
			clone.IfLocked.Visible = not ownsIt

			if not ownsIt then
				local idx = table.find(DNAData.Raw, dnaData)
				if idx and idx > 1 then
					local prev = DNAData.Raw[idx - 1]
					if OwnedDNA[prev.name] then
						clone.IfLocked.Visible = false
					end
				end
			end
		end
	end

	local function ChangeDNADisplay(dna: DNAData.Dna)
		local ownsDna = OwnedDNA[dna.name] or false
		local isEquipped = EquippedDNA == dna.name

		Stats.Stats.Text = `+{dna.StorageSpace} Space`
		BuyDNAButton.Cost.Amount.Text = isEquipped and "Equipped" or (ownsDna and "Equip" or Math.FormatCurrency(dna.Price))
		DisplayFrame.Frame.DnaIcon.Image = dna.ImageId
		DisplayFrame.Frame.DnaIcon.Visible = true
		displayedDna = dna

		self.Container.DNAContainer.DNADisplay.DnaName.Text = dna.displayName
	end

	ChangeDNADisplay(DNAData.Sorted[EquippedDNA])

	for index, DNA in DNAData.Raw do
		local Clone = itemTemplate:Clone()

		local playerOwnsDna = OwnedDNA[DNA.name] or false

		Clone.ScytheName.Text = DNA.displayName
		Clone.LayoutOrder = index
		Clone.IfLocked.Visible = not playerOwnsDna
		Clone.Frame.Icon.Image = DNA.ImageId
		Clone.Frame.Icon.Visible = true

		if index > 1 and not playerOwnsDna then
			local previousDna = DNAData.Raw[index - 1]
			if OwnedDNA[previousDna.name] then
				Clone.IfLocked.Visible = false
			end
		end

		Clone.Name = DNA.name
		Clone.Parent = self.Container.DNAContainer.Page
		Clone.Visible = true

		Clone.MouseButton1Click:Connect(function()
			if Clone.IfLocked.Visible then return end
			ChangeDNADisplay(DNA)
		end)

		Interface:AnimateButton(Clone)
	end

	BuyDNAButton.MouseButton1Click:Connect(function()
		if not displayedDna then return end
		if EquippedDNA == displayedDna.name then return end

		local profile = DataController:GetProfile()

		if OwnedDNA[displayedDna.name] then
			PurchaseItemRemote:Fire("DNA", displayedDna.name)
			EquippedDNA = displayedDna.name
			ChangeDNADisplay(displayedDna)
			return
		end

		if profile.Coins < displayedDna.Price then return end

		PurchaseItemRemote:Fire("DNA", displayedDna.name)
		OwnedDNA[displayedDna.name] = true
		EquippedDNA = displayedDna.name
		ChangeDNADisplay(displayedDna)

		local index = table.find(DNAData.Raw, displayedDna)
		local nextItem = index and DNAData.Raw[index + 1]
		if nextItem then
			local nextClone = self.Container.DNAContainer.Page:FindFirstChild(nextItem.name)
			if nextClone then nextClone.IfLocked.Visible = false end
		end
	end)

	if BuyAllButton then
		BuyAllButton.MouseButton1Click:Connect(function()
			local profile = DataController:GetProfile()
			local lastPurchased = nil
			local coins = profile.Coins

			for _, dna in DNAData.Raw do
				if OwnedDNA[dna.name] then
					lastPurchased = dna
					continue
				end

				if coins < dna.Price then break end

				coins -= dna.Price
				profile.Coins = coins
				OwnedDNA[dna.name] = true
				lastPurchased = dna
			end

			if lastPurchased then
				EquippedDNA = lastPurchased.name
				ChangeDNADisplay(lastPurchased)
				RefreshPageClones()
			end

			BuyAllRemote:Fire("DNA")
		end)
	end

	DataController:OnChange("DNA", function(new)
		OwnedDNA = new
		RefreshPageClones()
	end)

	DataController:OnChange("EquippedDNA", function(new)
		EquippedDNA = new
		local dnaData = DNAData.Sorted[new]
		if dnaData then
			ChangeDNADisplay(dnaData)
		end
	end)
end

function ShopController._DisplayRanks(self: ShopController)
	local itemTemplate = self.Container.RanksContainer.Page:WaitForChild("Template")

	local DataController = Client.Controllers.DataController
	local OwnedRanks = DataController:Get("Ranks")
	local EquippedRank = DataController:Get("EquippedRank")

	local BuyRankButton = self.Container.RanksContainer.RankDisplay.Buy:WaitForChild("Buy")
	local DisplayFrame = self.Container.RanksContainer.RankDisplay:WaitForChild("Display")
	local Stats = self.Container.RanksContainer.RankDisplay.Stats
	local displayedRank

	local function RefreshPageClones()
		for _, clone in self.Container.RanksContainer.Page:GetChildren() do
			if not clone:IsA("GuiButton") or clone.Name == "Template" then continue end
			local rankData = RankData.Sorted[clone.Name]
			if not rankData then continue end

			local ownsIt = OwnedRanks[clone.Name] or false
			clone.IfLocked.Visible = not ownsIt

			if not ownsIt then
				local idx = table.find(RankData.Raw, rankData)
				if idx and idx > 1 then
					local prev = RankData.Raw[idx - 1]
					if OwnedRanks[prev.name] then
						clone.IfLocked.Visible = false
					end
				end
			end
		end
	end

	local function ChangeRankDisplay(rank: RankData.Rank)
		local ownsRank = OwnedRanks[rank.name] or false
		local isEquipped = EquippedRank == rank.name

		Stats.Coins.Stats.Text = `+{rank.Boosts.Coins}x Coins`
		Stats.Shards.Stats.Text = `+{rank.Boosts.Shards}x Shards`
		Stats.Skulls.Stats.Text = `+{rank.Boosts.Skulls}x Skulls`
		DisplayFrame.Frame.RankIcon.Image = rank.imageId
		DisplayFrame.Frame.RankIcon.Visible = true
		displayedRank = rank

		BuyRankButton.Cost.Amount.Text = isEquipped and "Equipped" or (ownsRank and "Equip" or Math.FormatCurrency(rank.Price))
		self.Container.RanksContainer.RankDisplay.RankName.Text = rank.displayName
	end

	ChangeRankDisplay(RankData.Sorted[EquippedRank])

	for index, Rank in RankData.Raw do
		local Clone = itemTemplate:Clone()

		local playerOwnsRank = OwnedRanks[Rank.name] or false

		Clone.ScytheName.Text = Rank.displayName
		Clone.LayoutOrder = index
		Clone.IfLocked.Visible = not playerOwnsRank
		Clone.Frame.Icon.Image = Rank.imageId
		Clone.Frame.Icon.Visible = true

		if index > 1 and not playerOwnsRank then
			local previousRank = RankData.Raw[index - 1]
			if OwnedRanks[previousRank.name] then
				Clone.IfLocked.Visible = false
			end
		end

		Clone.Name = Rank.name
		Clone.Parent = self.Container.RanksContainer.Page
		Clone.Visible = true

		Clone.MouseButton1Click:Connect(function()
			if Clone.IfLocked.Visible then return end
			ChangeRankDisplay(Rank)
		end)

		Interface:AnimateButton(Clone)
	end

	BuyRankButton.MouseButton1Click:Connect(function()
		if not displayedRank then return end
		if EquippedRank == displayedRank.name then return end

		local profile = DataController:GetProfile()

		if OwnedRanks[displayedRank.name] then
			PurchaseItemRemote:Fire("Rank", displayedRank.name)
			EquippedRank = displayedRank.name
			ChangeRankDisplay(displayedRank)
			return
		end

		if profile.Coins < displayedRank.Price then return end

		PurchaseItemRemote:Fire("Rank", displayedRank.name)
		OwnedRanks[displayedRank.name] = true
		EquippedRank = displayedRank.name
		ChangeRankDisplay(displayedRank)

		local index = table.find(RankData.Raw, displayedRank)
		local nextItem = index and RankData.Raw[index + 1]
		if nextItem then
			local nextClone = self.Container.RanksContainer.Page:FindFirstChild(nextItem.name)
			if nextClone then nextClone.IfLocked.Visible = false end
		end
	end)

	DataController:OnChange("Ranks", function(new)
		OwnedRanks = new
		RefreshPageClones()
	end)

	DataController:OnChange("EquippedRank", function(new)
		EquippedRank = new
		local rankData = RankData.Sorted[new]
		if rankData then
			ChangeRankDisplay(rankData)
		end
	end)
end

type ShopController = typeof(ShopController) & {
	LastOpenedContainer: Frame,
}

return ShopController