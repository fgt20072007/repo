local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local MarketplaceService = game:GetService("MarketplaceService")

local Packages = ReplicatedStorage:WaitForChild("Packages")
local Trove = require(Packages:WaitForChild("Trove"))
local Net = require(Packages:WaitForChild("Net"))

local Data = ReplicatedStorage:WaitForChild("Data")
local WithdrawConfig = require(Data:WaitForChild("ATMWithdraw"))

local Util = ReplicatedStorage:WaitForChild("Util")
local Format = require(Util:WaitForChild("Format"))
local ProductUtil = require(Util:WaitForChild("Products"))

local Player = Players.LocalPlayer :: Player
local PlayerGui = Player:WaitForChild("PlayerGui") :: PlayerGui

local MainGui = PlayerGui:WaitForChild("Main")
local frame = MainGui:WaitForChild("ATM")
local MainPanel = frame:WaitForChild("Main")
local UsersModal = frame:WaitForChild("Users")

local WelcomeRoot = MainPanel:WaitForChild("Welcome")
local WithdrawButtonRoot = MainPanel:WaitForChild("Withdraw")
local TransferButtonRoot = MainPanel:WaitForChild("Transfer")
local WithdrawFrame = MainPanel:WaitForChild("WithdrawFrame")
local TransferFrame = MainPanel:WaitForChild("TransferFrame")

local SelectUserRoot = TransferFrame:WaitForChild("SelectUserButton")
local UserSelectedRoot = TransferFrame:WaitForChild("UserSelected")
local AmountInputRoot = TransferFrame:WaitForChild("TextBox")
local ConfirmTransferRoot = TransferFrame:WaitForChild("ConfirmTransfer")
local UserList = UsersModal:WaitForChild("Holder"):WaitForChild("PlayerList")
local UserTemplate = UserList:WaitForChild("Player")

local TransferRemote = Net:RemoteFunction("ATMTransfer")

local MAX_TRANSFER = 5_000
local COLOR_DEFAULT = Color3.fromRGB(255, 255, 255)
local COLOR_VALID = Color3.fromRGB(74, 255, 122)
local COLOR_INVALID = Color3.fromRGB(255, 85, 85)

local ATM = {}
ATM.__index = ATM

local function ResolveTextBox(root: Instance?): TextBox?
	if not root then return nil end
	if root:IsA("TextBox") then return root end
	return root:FindFirstChildWhichIsA("TextBox", true)
end

local function ResolveTextLabel(root: Instance?, name: string): TextLabel?
	if not root then return nil end
	local direct = root:FindFirstChild(name, true)
	if direct and direct:IsA("TextLabel") then
		return direct
	end
	return nil
end

local function ResolveInteractable(root: Instance?): GuiObject?
	if not root then return nil end
	if root:IsA("GuiButton") then return root end

	local button = root:FindFirstChildWhichIsA("GuiButton", true)
	if button then return button end

	if root:IsA("GuiObject") then return root end
	return root:FindFirstChildWhichIsA("GuiObject", true)
end

local function ResolveImage(root: Instance?, name: string): ImageLabel?
	if not root then return nil end
	local direct = root:FindFirstChild(name, true)
	if direct and direct:IsA("ImageLabel") then
		return direct
	end
	return nil
end

local function SetVisible(instance: Instance?, visible: boolean)
	if not (instance and instance:IsA("GuiObject")) then return end
	instance.Visible = visible
end

local function ConnectActivated(trove: Trove.Trove, target: GuiObject?, callback: () -> ())
	if not target then return end
	if target:IsA("GuiButton") then
		trove:Connect(target.MouseButton1Click, callback)
		return
	end
	target.Active = true

	trove:Connect(target.InputBegan, function(input: InputObject)
		local inputType = input.UserInputType
		if inputType ~= Enum.UserInputType.MouseButton1 and inputType ~= Enum.UserInputType.Touch then
			return
		end
		callback()
	end)
end

local function ParseAmount(rawText: string): number?
	local normalized = string.gsub(rawText, "[,%$%s]", "")
	if normalized == "" then return nil end
	if not string.match(normalized, "^%d+$") then return nil end

	local amount = tonumber(normalized)
	if not amount then return nil end

	return math.floor(amount)
end

local function SetButtonText(root: Instance?, text: string)
	if not root then return end

	if root:IsA("TextButton") then
		root.Text = text
		return
	end

	local textLabel = ResolveTextLabel(root, "TextLabel")
		or ResolveTextLabel(root, "Label")
		or ResolveTextLabel(root, "Username")
	if textLabel then
		textLabel.Text = text
	end
end

local function ResolveWithdrawGroup(frameRoot: Instance, index: number): Instance?
	local groupNames = if index <= 3
		then {"First", "1"}
		elseif index <= 6
		then {"Second", "2"}
		else {"Third", "3"}

	for _, name in groupNames do
		local group = frameRoot:FindFirstChild(name)
		if group then
			return group
		end
	end

	return nil
end

local function ResolveWithdrawSlot(withdrawFrame: Instance, index: number): Instance?
	local root = withdrawFrame:FindFirstChild("Frame")
	if not root then
		return nil
	end

	local group = ResolveWithdrawGroup(root, index)
	if not group then
		return nil
	end

	return group:FindFirstChild(tostring(index))
end

function ATM.new(controller: any)
	local self = setmetatable({
		_name = "ATM",
		_uiController = controller,
		_notifications = controller and controller.Managers and controller.Managers.Notifications or nil,
		_trove = Trove.new(),
		_playerListTrove = Trove.new(),
		_connectionsReady = false,
		_requestPending = false,
		_selectedTarget = nil :: Player?,
	}, ATM)

	self:_init()
	return self
end

function ATM:_notify(id: string, args: {[string]: any}?)
	if not self._notifications then return end
	self._notifications.Add(id, args)
end

function ATM:_setHomeView()
	SetVisible(WelcomeRoot, true)
	SetVisible(WithdrawButtonRoot, true)
	SetVisible(TransferButtonRoot, true)

	SetVisible(WithdrawFrame, false)
	SetVisible(TransferFrame, false)
	SetVisible(UsersModal, false)
end

function ATM:_isSubViewOpen(): boolean
	return (WithdrawFrame:IsA("GuiObject") and WithdrawFrame.Visible)
		or (TransferFrame:IsA("GuiObject") and TransferFrame.Visible)
		or (UsersModal:IsA("GuiObject") and UsersModal.Visible)
end

function ATM:_setWithdrawView()
	SetVisible(WelcomeRoot, false)
	SetVisible(WithdrawButtonRoot, false)
	SetVisible(TransferButtonRoot, false)

	SetVisible(WithdrawFrame, true)
	SetVisible(TransferFrame, false)
	SetVisible(UsersModal, false)
end

function ATM:_setTransferView()
	SetVisible(WelcomeRoot, false)
	SetVisible(WithdrawButtonRoot, false)
	SetVisible(TransferButtonRoot, false)

	SetVisible(WithdrawFrame, false)
	SetVisible(TransferFrame, true)
	SetVisible(UsersModal, false)
end

function ATM:_setSelectedTarget(target: Player?)
	self._selectedTarget = target

	local text = if target then target.DisplayName else "Select User"
	if UserSelectedRoot:IsA("TextLabel") then
		UserSelectedRoot.Text = text
	else
		local selectedLabel = ResolveTextLabel(UserSelectedRoot, "TextLabel")
		if selectedLabel then
			selectedLabel.Text = text
		end
	end

	SetButtonText(SelectUserRoot, text)
end

function ATM:_updateWelcome()
	local welcomeLabel = ResolveTextLabel(WelcomeRoot, "TextLabel")
	if not welcomeLabel then return end

	welcomeLabel.Text = `Welcome back, {Player.DisplayName}.`
end

function ATM:_refreshAmountState(): (boolean, number?)
	local input = ResolveTextBox(AmountInputRoot)
	if not input then
		return false, nil
	end

	local amount = ParseAmount(input.Text)
	local valid = amount ~= nil and amount > 0 and amount <= MAX_TRANSFER

	if input.Text == "" then
		input.TextColor3 = COLOR_DEFAULT
	elseif valid then
		input.TextColor3 = COLOR_VALID
	else
		input.TextColor3 = COLOR_INVALID
	end

	return valid, amount
end

function ATM:_applyPlayerEntry(entry: Instance, target: Player)
	local displayLabel = ResolveTextLabel(entry, "DisplayName")
	if displayLabel then
		displayLabel.Text = target.DisplayName
	end

	local usernameLabel = ResolveTextLabel(entry, "Username")
	if usernameLabel then
		usernameLabel.Text = `@{target.Name}`
	end

	local image = ResolveImage(entry, "PlayerImage")
	if image then
		local icon = Players:GetUserThumbnailAsync(target.UserId, Enum.ThumbnailType.HeadShot, Enum.ThumbnailSize.Size150x150)
		image.Image = icon
	end

	local selectButton = ResolveInteractable(entry:FindFirstChild("Transfer", true))
		or ResolveInteractable(entry)
	ConnectActivated(self._playerListTrove, selectButton, function()
		self:_setSelectedTarget(target)
		SetVisible(UsersModal, false)
	end)
end

function ATM:_rebuildPlayerList()
	if self._playerListTrove then
		self._playerListTrove:Clean()
	end

	if UserTemplate:IsA("GuiObject") then
		UserTemplate.Visible = false
	end

	for _, child in UserList:GetChildren() do
		if child == UserTemplate then continue end
		if child:IsA("UIListLayout") or child:IsA("UIPadding") then continue end
		child:Destroy()
	end

	local hasEntries = false
	for _, target in Players:GetPlayers() do
		if target == Player then continue end

		hasEntries = true
		local entry = UserTemplate:Clone()
		entry.Name = target.Name
		if entry:IsA("GuiObject") then
			entry.Visible = true
		end
		self:_applyPlayerEntry(entry, target)
		entry.Parent = UserList
	end

	if not hasEntries then
		self:_notify("ATM/NoPlayers")
	end
end

function ATM:_requestTransfer()
	if self._requestPending then return end

	local target = self._selectedTarget
	if not target then
		self:_notify("ATM/NeedSelectPlayer")
		return
	end

	if not target:IsDescendantOf(Players) then
		self:_setSelectedTarget(nil)
		self:_notify("ATM/TargetNotFound")
		return
	end

	local input = ResolveTextBox(AmountInputRoot)
	local parsedAmount = input and ParseAmount(input.Text) or nil
	local valid, amount = self:_refreshAmountState()
	if not valid or not amount then
		if parsedAmount and parsedAmount > MAX_TRANSFER then
			self:_notify("ATM/AmountTooHigh")
		else
			self:_notify("ATM/InvalidAmount")
		end
		return
	end

	self._requestPending = true
	local ok, success = pcall(function()
		return TransferRemote:InvokeServer(target.UserId, amount)
	end)
	self._requestPending = false

	if not ok then
		self:_notify("ATM/TransferFailed")
		return
	end

	if success and input then
		input.Text = ""
		self:_refreshAmountState()
	end
end

function ATM:_setupConnections()
	if self._connectionsReady then return end
	self._connectionsReady = true

	local withdrawButton = ResolveInteractable(WithdrawButtonRoot)
	ConnectActivated(self._trove, withdrawButton, function()
		self:_setWithdrawView()
	end)

	local transferButton = ResolveInteractable(TransferButtonRoot)
	ConnectActivated(self._trove, transferButton, function()
		self:_setTransferView()
	end)

	local withdrawBack = ResolveInteractable(WithdrawFrame:FindFirstChild("Back", true))
	ConnectActivated(self._trove, withdrawBack, function()
		self:_setHomeView()
	end)

	local transferBack = ResolveInteractable(TransferFrame:FindFirstChild("Back", true))
	ConnectActivated(self._trove, transferBack, function()
		self:_setHomeView()
	end)

	local selectUserButton = ResolveInteractable(SelectUserRoot)
	ConnectActivated(self._trove, selectUserButton, function()
		SetVisible(UsersModal, true)
		self:_rebuildPlayerList()
	end)

	local usersClose = ResolveInteractable(UsersModal:FindFirstChild("CloseButton", true))
	ConnectActivated(self._trove, usersClose, function()
		SetVisible(UsersModal, false)
	end)

	local mainClose = ResolveInteractable(MainPanel:FindFirstChild("CloseButton", true))
	ConnectActivated(self._trove, mainClose, function()
		if not self._uiController then return end
		if self:_isSubViewOpen() then
			self:_setHomeView()
			return
		end
		self._uiController:Close(self._name)
	end)

	local transferSubmit = ResolveInteractable(ConfirmTransferRoot)
		or ResolveInteractable(TransferFrame:FindFirstChild("Transfer", true))
		or ResolveInteractable(TransferFrame:FindFirstChild("Send", true))
	ConnectActivated(self._trove, transferSubmit, function()
		self:_requestTransfer()
	end)

	local amountInput = ResolveTextBox(AmountInputRoot)
	if amountInput then
		self._trove:Connect(amountInput:GetPropertyChangedSignal("Text"), function()
			self:_refreshAmountState()
		end)
	end

	self._trove:Connect(Players.PlayerAdded, function()
		if UsersModal:IsA("GuiObject") and UsersModal.Visible then
			self:_rebuildPlayerList()
		end
	end)

	self._trove:Connect(Players.PlayerRemoving, function(removedPlayer: Player)
		if self._selectedTarget == removedPlayer then
			self:_setSelectedTarget(nil)
		end

		if UsersModal:IsA("GuiObject") and UsersModal.Visible then
			self:_rebuildPlayerList()
		end
	end)
end

function ATM:_setupWithdrawEntries()
	for index = 1, 7 do
		local entryData = WithdrawConfig[index]
		if typeof(entryData) ~= "table" then
			continue
		end

		local slot = ResolveWithdrawSlot(WithdrawFrame, index)
		if not slot then
			continue
		end

		local money = math.max(0, math.floor(entryData.Money or 0))
		local productId = tonumber(entryData.ProductId)
		if not productId then
			continue
		end

		local nameLabel = ResolveTextLabel(slot, "NameLabel")
		if nameLabel then
			nameLabel.Text = `${
			Format.WithCommas(money)
			}`
		end

		local priceLabel = ResolveTextLabel(slot, "PriceLabel")
		if priceLabel then
			task.spawn(function()
				local productInfo = ProductUtil.GetProductInfo(productId, Enum.InfoType.Product)
				local price = productInfo and productInfo.PriceInRobux or nil
				if price == nil then
					priceLabel.Text = "N/A"
					return
				end

				priceLabel.Text = `{Format.RobuxUTF}{Format.WithCommas(price)}`
			end)
		end

		local button = ResolveInteractable(slot)
		ConnectActivated(self._trove, button, function()
			MarketplaceService:PromptProductPurchase(Player, productId)
		end)
	end
end

function ATM:_init()
	if UserTemplate:IsA("GuiObject") then
		UserTemplate.Visible = false
	end

	self:_setSelectedTarget(nil)
	self:_setHomeView()
	self:_updateWelcome()
	self:_refreshAmountState()
	self:_setupConnections()
	self:_setupWithdrawEntries()
end

function ATM:OnOpen()
	self:_updateWelcome()
	self:_setHomeView()
	self:_refreshAmountState()
end

function ATM:OnClose()
	self:_setHomeView()
end

return ATM