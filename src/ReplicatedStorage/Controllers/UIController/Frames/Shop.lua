--//services
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local MarketplaceService = game:GetService("MarketplaceService")

--//Data
local Data = ReplicatedStorage:WaitForChild("Data")
local GamepassesData = require(Data:WaitForChild("Passes"))
local ProductsData = require(Data:WaitForChild('Products'))

--//packages
local Controllers = ReplicatedStorage:WaitForChild("Controllers")
local ReplicaController = require(Controllers.ReplicaController)
local UIController = require(Controllers.UIController)

local Packages = ReplicatedStorage:WaitForChild("Packages")
local Replica = require(Packages.ReplicaClient)
local Trove = require(Packages:WaitForChild("Trove"))
local Observers = require(Packages:WaitForChild("Observers"))

local ProductUtil = require(ReplicatedStorage.Util.Products)
local Format = require(ReplicatedStorage.Util.Format)
local GamepassOwnership = require(ReplicatedStorage.Util.GamepassOwnership)

local Net = require(Packages:WaitForChild("Net"))
local GiftPassEvent = Net:RemoteEvent("GiftPass")

--//player
local Player = Players.LocalPlayer :: Player
local PlayerGui = Player:WaitForChild("PlayerGui") :: PlayerGui


local uiManager = UIController.Managers.Notifications

--//ui
local Main = PlayerGui:WaitForChild("Main") :: ScreenGui
local HUD = PlayerGui:WaitForChild("HUD")

local frame = Main:WaitForChild("Shop") :: GuiObject
local LeftTabs = frame:WaitForChild("LeftTabs") :: Frame
local Header = frame:WaitForChild("Header") :: Frame
local CloseButton = Header:WaitForChild("CloseButton") :: GuiButton
local Holder = frame:WaitForChild("Holder") :: Frame	
local Container = Holder:WaitForChild("Container") :: Frame
local ScrollingFrame = Container:WaitForChild("ScrollingFrame") :: ScrollingFrame

local MoneyTab = HUD:WaitForChild("Money")

--//misc

local DEFAULT_TAB = LeftTabs:WaitForChild("Passes") :: ImageButton
local PassId_To_PassName = {}

local Shop = {}
Shop.__index = Shop


local GiftFrame = Main:WaitForChild("GiftFrame")
local GiftHolder = GiftFrame:WaitForChild("Holder")
local GiftPlayerList = GiftHolder:WaitForChild("PlayerList") :: GuiObject
local GiftPlayerTemplate = GiftPlayerList:WaitForChild("Player") :: Instance
local GiftCloseButton = GiftFrame:FindFirstChild("CloseButton", true) :: GuiButton?


local CurrentGiftProduct = nil

local function SetGiftVisibility(isOpen: boolean)
	GiftFrame.Visible = isOpen == true
	frame.Visible = not isOpen
	if not isOpen then CurrentGiftProduct = nil end
end

local function ResolveTextButton(root: Instance): TextButton?
	if root:IsA("TextButton") then return root end
	return root:FindFirstChildWhichIsA("TextButton", true)
end

local function ResolveTextLabel(root: Instance, name: string): TextLabel?
	local direct = root:FindFirstChild(name, true)
	if direct and direct:IsA("TextLabel") then return direct end
	return nil
end

local function ResolveImage(root: Instance, name: string): ImageLabel?
	local direct = root:FindFirstChild(name, true)
	if direct and direct:IsA("ImageLabel") then return direct end
	return nil
end

if GiftCloseButton then
	GiftCloseButton.MouseButton1Click:Connect(function()
		SetGiftVisibility(false)
	end)
end


local function changeButtonTransparency(buttonName: string, transparency: number)
	if not buttonName then return end

	local button = LeftTabs:FindFirstChild(buttonName) :: ImageButton
	if not button then return end

	local info = TweenInfo.new(0.1)
	TweenService:Create(button.IconImage, info, {ImageTransparency = transparency}):Play()
	TweenService:Create(button.StrokeImage, info, {ImageTransparency = transparency}):Play()
	TweenService:Create(button.NameLabel, info, {TextTransparency = transparency}):Play()
	TweenService:Create(button, info, {ImageTransparency = transparency}):Play()
end

local function OwnsPass(productId: number)
	productId = tonumber(productId)
	if not productId then return false end
	return GamepassOwnership.Owns(productId)
end


function Shop.new(controller: any)
	local self = setmetatable({}, Shop)

	self._name = "Shop"
	self._uiController = controller
	self._Trove = Trove.new()
	self._subTrove = self._Trove:Extend()
	self._giftTrove = self._Trove:Extend()
	self._giftListTrove = self._Trove:Extend()
	self._openedTab = nil
	self._openedBefore = false
	self._UI = frame

	self:_init()

	return self
end


function Shop:_changeTab(tab: string)
	if not tab then print("NOT TAB", tab) return end
	--if self._subTrove then self._subTrove:Clean() end

	if self._openedTab then -- if there is a tab selected, then we make it transparent
		changeButtonTransparency(self._openedTab, 0.5)
	end

	changeButtonTransparency(tab, 0)
	self:_changePage(tab)
end

function Shop:_changePage(pageName: string)
	if not pageName then return end

	local page = ScrollingFrame:FindFirstChild(pageName) :: Folder
	if not page then return end

	--> Close Previous Tab
	if self._openedTab then
		local OpenedFrame = ScrollingFrame:FindFirstChild(self._openedTab)
		for _, frame in OpenedFrame:GetChildren() do
			if not frame:IsA("GuiObject") then continue end
			frame.Visible = false
		end
	end

	for _, frame in page:GetChildren() do
		if not frame:IsA("GuiObject") then continue end

		if frame:HasTag("Gamepass") then
			frame:AddTag("GamepassButton")
		end
		--clone.Parent = ScrollingFrame
		frame.Visible = true
	end

	self._openedTab = pageName
end



function Shop:_setupPurchaseFrame(frame: GuiObject)
	if not frame:IsA("GuiObject") then return end

	local button = frame:FindFirstChild("PurchaseButton") :: GuiButton
	if not button then return end

	return true 
end

local function UpdateButton(button, productId)
	local priceLabel = button:WaitForChild("PriceLabel") :: TextLabel
	if not priceLabel then return end
	if OwnsPass(productId) then
		priceLabel.Text = "OWNED"
		return
	else
		local succ, info = pcall(function()
			return MarketplaceService:GetProductInfoAsync(productId, Enum.InfoType.GamePass)
		end)
		if not (succ and info) then return end
		priceLabel.Text = `{info.PriceInRobux}`
	end
end

function Shop:_setupConnections()

	--TAB BUTTONS
	for _, button in LeftTabs:GetChildren() do --// setup tabs
		if not button:IsA("GuiButton") then continue end

		self._Trove:Connect(button.MouseButton1Click, function()
			self:_changeTab(button.Name)
		end)
	end

	self._Trove:Connect(CloseButton.MouseButton1Click, function()
		self._uiController:Close(self._name)
	end)


	self._Trove:Add( Observers.observeTag("GamepassButton", function(frame: GuiObject)
		if not frame then return end

		local productId = frame:GetAttribute("ProductId") :: number
		if not productId then return end

		local button = frame:FindFirstChild("PurchaseButton") :: GuiButton
		if not button then return end

		UpdateButton(button, productId)

		self._subTrove:Connect(button.MouseButton1Click, function()
			if button.Name == "Gift" then
				self:_openGiftWindow(productId)
				return
			end

			if OwnsPass(productId) then
				UpdateButton(button, productId)
				return
			end
			MarketplaceService:PromptGamePassPurchase(Player, productId)
		end)
	end) )

	self._Trove:Add( Observers.observeTag("ProductButton", function(button: GuiObject)
		if not button then return end

		local productId = button:GetAttribute("ProductId") :: number
		if not productId then return end

		local label = button:FindFirstChild('PriceLabel') :: TextLabel?
		if label then
			local info = ProductUtil.GetProductInfo(productId, Enum.InfoType.Product)
			local price: number? = info and info.PriceInRobux or nil

			label.Text = price and `{Format.RobuxUTF}{Format.WithCommas(price)}` or 'PURCHASE!'
		end

		self._subTrove:Connect(button.MouseButton1Click, function()
			if button.Name == "Gift" then
				self:_openGiftWindow(productId)
				return
			end

			if OwnsPass(productId) then return end
			MarketplaceService:PromptProductPurchase(Player, productId)
		end)
	end) )

	self._giftTrove:Connect(Players.PlayerAdded, function()
		if GiftFrame.Visible then
			self:_rebuildGiftPlayerList()
		end
	end)

	self._giftTrove:Connect(Players.PlayerRemoving, function()
		if GiftFrame.Visible then
			self:_rebuildGiftPlayerList()
		end
	end)
end

function Shop:_openGiftWindow(productId: number)
	SetGiftVisibility(true)
	CurrentGiftProduct = productId
	self:_rebuildGiftPlayerList()
end

function Shop:_applyGiftEntry(entry: Instance, target: Player)
	local displayLabel = ResolveTextLabel(entry, "DisplayName")
	if displayLabel then displayLabel.Text = target.DisplayName end

	local usernameLabel = ResolveTextLabel(entry, "Username")
	if usernameLabel then usernameLabel.Text = `@{target.Name}` end

	local image = ResolveImage(entry, "PlayerImage")
	if image then
		local content = Players:GetUserThumbnailAsync(target.UserId, Enum.ThumbnailType.HeadShot, Enum.ThumbnailSize.Size150x150)
		image.Image = content
	end

	local giftButton = ResolveTextButton(entry)
	if giftButton then
		self._giftListTrove:Connect(giftButton.MouseButton1Click, function()
			if not CurrentGiftProduct then return end
			GiftPassEvent:FireServer(CurrentGiftProduct, target.Name)
		end)
	end
end

function Shop:_rebuildGiftPlayerList()
	if not (GiftPlayerList and GiftPlayerTemplate) then return end
	if self._giftListTrove then self._giftListTrove:Clean() end

	for _, child in GiftPlayerList:GetChildren() do
		if child == GiftPlayerTemplate then continue end
		if child:IsA("UIListLayout") or child:IsA("UIPadding") then continue end
		child:Destroy()
	end

	for _, target in Players:GetPlayers() do
		if target == Player then continue end
		local entry = GiftPlayerTemplate:Clone()
		entry.Name = target.Name
		if entry:IsA("GuiObject") then entry.Visible = true end
		self:_applyGiftEntry(entry, target)
		entry.Parent = GiftPlayerList
	end
end

function Shop:_init()
	self._UI.Visible = false
	GiftFrame.Visible = false
	if GiftPlayerTemplate:IsA("GuiObject") then
		GiftPlayerTemplate.Visible = false
	end

	for PassName, PassId in GamepassesData do
		PassId_To_PassName[PassId] = PassName
	end

	MoneyTab.MoneyButton.MouseButton1Click:Connect(function()
		self._uiController:Open(self._name)
		self:_changeTab("Cash")
	end)

	local cashHolder = ScrollingFrame:FindFirstChild('Cash')
	if cashHolder then
		for _, label: TextLabel in cashHolder:QueryDescendants('TextLabel#NameLabel') do
			local parentId = tonumber(label.Parent.Name)
			if not parentId then continue end

			local prodData = ProductsData.Cash[parentId]
			if not prodData then return end

			label.Text = `${Format.WithCommas(prodData.Reward)}`
		end
	end

	local succ, res: ReplicaController.Replica = ReplicaController.GetReplicaAsync("PlayerData"):await()
	if not succ then return end
	res:OnChange(function(listener, path)
		if path[1] ~= "GiftedPasses" then return end
		GamepassOwnership.Invalidate()

		for _, Button in game:GetService("CollectionService"):GetTagged("GamepassButton") do
			local productId = Button:GetAttribute("ProductId")
			if not productId then continue end
			UpdateButton(Button.PurchaseButton, productId)
		end


		uiManager.Add(`GamepassShop/{listener =="TableInsert" and "GamepassPurchased" or "GamepassRemoved"}`)
	end)

	return true
end


function Shop:OnOpen() --//esta funcion corre cuando abres la UI
	if not self._openedBefore then
		print("Setting up connections")
		self._openedBefore = true
		self:_setupConnections()

		self:_changeTab(DEFAULT_TAB.Name)
	end
end

function Shop:OnClose()
	print("Close")
	self._openedBefore = false
	self._subTrove:Clean()
	self._giftListTrove:Clean()
	--self.Trove:Clean()
end


return Shop
