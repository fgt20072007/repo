--!strict
local Players = game:GetService('Players')
local ReplicatedStorage = game:GetService('ReplicatedStorage')
local MarketplaceService = game:GetService('MarketplaceService')

local Packages = ReplicatedStorage:WaitForChild('Packages')
local Trove = require(Packages.Trove)

local Controllers = ReplicatedStorage:WaitForChild('Controllers')
local ReplicaController = require(Controllers.ReplicaController)

local Data = ReplicatedStorage:WaitForChild('Data')
local Passes = require(Data.Passes)
local GamepassOwnership = require(ReplicatedStorage.Util.GamepassOwnership)

local Player = Players.LocalPlayer :: Player
local PlayerGui = Player:WaitForChild('PlayerGui') :: PlayerGui

local Main = PlayerGui:WaitForChild('Main') :: ScreenGui
local StarterPackRoot = Main:WaitForChild('StarterPack') :: Instance
local RightRoot = StarterPackRoot:WaitForChild('Right') :: Instance
local RightStarterPack = RightRoot:WaitForChild('StarterPack') :: Instance
local PanelRoot = StarterPackRoot:WaitForChild('Starterpack') :: Instance

local PlayerScripts = Player:WaitForChild('PlayerScripts') :: PlayerScripts
local PlayerData = PlayerScripts:WaitForChild('Data') :: Instance
local OnMobile = PlayerData:WaitForChild('OnMobile') :: BoolValue

local Starterpack = {}
Starterpack.__index = Starterpack

local function ResolveButton(root: Instance, name: string?): GuiButton?
	if not root then return end
	if name then
		local direct = root:FindFirstChild(name, true)
		if direct and direct:IsA('GuiButton') then return direct end
		if direct then
			local inner = direct:FindFirstChildWhichIsA('GuiButton', true)
			if inner then return inner end
		end
	end
	if root:IsA('GuiButton') then return root end
	return root:FindFirstChildWhichIsA('GuiButton', true)
end

local function ResolveGui(root: Instance): GuiObject?
	if not root then return end
	if root:IsA('GuiObject') then return root end
	return root:FindFirstChildWhichIsA('GuiObject', true)
end

local function ResolveGuiGroup(root: Instance): {GuiObject}
	if not root then return {} end
	if root:IsA('GuiObject') then return { root } end
	local group = {}
	for _, child in ipairs(root:GetChildren()) do
		if child:IsA('GuiObject') then
			table.insert(group, child)
		end
	end
	if #group > 0 then return group end
	for _, desc in ipairs(root:GetDescendants()) do
		if desc:IsA('GuiObject') then
			table.insert(group, desc)
		end
	end
	return group
end

local function SetVisibleGroup(group: {GuiObject}, visible: boolean)
	for _, gui in ipairs(group) do
		gui.Visible = visible
	end
end

function Starterpack.new()
	local self = setmetatable({}, Starterpack)
	self._trove = Trove.new()
	self._open = false
	self._owns = false
	self._isDriving = false
	self._ownershipResolved = false
	self:_init()
	return self
end

function Starterpack:_init()
	self._rightButton = ResolveButton(RightStarterPack)
	self._rightGui = ResolveGui(RightStarterPack)
	self._rightGuis = ResolveGuiGroup(RightStarterPack)
	self._closeButton = ResolveButton(PanelRoot, 'CloseButton')
	self._purchaseButton = ResolveButton(PanelRoot, 'PurchaseButton')
	self._panelGui = ResolveGui(PanelRoot)
	self._panelGuis = ResolveGuiGroup(PanelRoot)

	SetVisibleGroup(self._rightGuis, false)
	SetVisibleGroup(self._panelGuis, false)

	self:_bindButtons()
	self:_bindReplica()
	self:_bindDrivingState()
	self:_applyVisibility()
	self:_resolveOwnershipAsync()
end

function Starterpack:_bindButtons()
	if self._rightButton then
		self._trove:Connect(self._rightButton.MouseButton1Click, function()
			self:Toggle()
		end)
	end

	if self._closeButton then
		self._trove:Connect(self._closeButton.MouseButton1Click, function()
			self:SetOpen(false)
		end)
	end

	if self._purchaseButton then
		self._trove:Connect(self._purchaseButton.MouseButton1Click, function()
			if self._owns then return end
			local productId = tonumber(self._purchaseButton:GetAttribute('ProductId')) or Passes.Starterpack
			if not productId then return end
			MarketplaceService:PromptGamePassPurchase(Player, productId)
		end)
	end
end

function Starterpack:_bindDrivingState()
	local function bindCharacter(character: Model)
		local humanoid = character:FindFirstChildOfClass('Humanoid')
		if not humanoid then return end
		self._trove:Connect(humanoid.Seated, function(isSeated, seat)
			self._isDriving = isSeated and seat and seat:IsA('VehicleSeat') or false
			self:_applyVisibility()
		end)
	end

	if Player.Character then
		bindCharacter(Player.Character)
	end
	self._trove:Connect(Player.CharacterAdded, function(character)
		bindCharacter(character)
	end)
	self._trove:Connect(OnMobile.Changed, function()
		self:_applyVisibility()
	end)
end

function Starterpack:_bindReplica()
	task.spawn(function()
		local succ, replica = ReplicaController.GetReplicaAsync('PlayerData'):await()
		if not succ or not replica then return end

		self._trove:Add(replica:OnChange(function(_, path)
			if path[1] ~= 'GiftedPasses' then return end
			GamepassOwnership.Invalidate()
			self:_refreshOwnership()
			self:_applyVisibility()
		end))

		self:_refreshOwnership()
		self._ownershipResolved = true
		self:_applyVisibility()
	end)
end

function Starterpack:_resolveOwnershipAsync()
	task.spawn(function()
		self:_refreshOwnership()
		self._ownershipResolved = true
		self:_applyVisibility()
	end)
end

function Starterpack:_refreshOwnership()
	self._owns = GamepassOwnership.Owns('Starterpack')
end

function Starterpack:_applyVisibility()
	if not self._ownershipResolved then
		SetVisibleGroup(self._rightGuis, false)
		SetVisibleGroup(self._panelGuis, false)
		return
	end
	if self._owns then
		SetVisibleGroup(self._rightGuis, false)
		SetVisibleGroup(self._panelGuis, false)
		self._open = false
		return
	end

	local hideForDrivingMobile = OnMobile.Value == true and self._isDriving == true
	if hideForDrivingMobile then
		SetVisibleGroup(self._rightGuis, false)
		SetVisibleGroup(self._panelGuis, false)
		self._open = false
		return
	end

	SetVisibleGroup(self._rightGuis, true)
	SetVisibleGroup(self._panelGuis, self._open == true)
end

function Starterpack:SetOpen(state: boolean)
	if self._owns then return end
	self._open = state == true
	self:_applyVisibility()
end

function Starterpack:Toggle()
	if self._owns then return end
	self:SetOpen(not self._open)
end

return Starterpack.new()