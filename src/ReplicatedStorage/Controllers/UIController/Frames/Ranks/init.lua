local ReplicatedStorage = game:GetService "ReplicatedStorage"
local Players = game:GetService 'Players'

local Client = Players.LocalPlayer :: Player
local PlayerGui = Client:WaitForChild('PlayerGui') :: PlayerGui

-- UI
local ScreenGui = PlayerGui:WaitForChild("Main") :: ScreenGui
local MenuObj = ScreenGui:WaitForChild("Ranks") :: Frame

local CloseButton = MenuObj:WaitForChild('CloseButton') :: GuiButton
local List = MenuObj:WaitForChild('Holder') :: ScrollingFrame
local XPFrame = List:WaitForChild('XP') :: Frame

-- Other
local Packages = ReplicatedStorage.Packages
local Trove = require(Packages.Trove)
local TopbarPlus = require(Packages.TopbarPlus)
local Net = require(Packages.Net)

local Data = ReplicatedStorage.Data
local RanksData = require(Data.Ranks)
local Products = require(Data.Products)

local Util = ReplicatedStorage.Util
local Format = require(Util.Format)
local ProductUtil = require(Util.Products)

local Assets = ReplicatedStorage.Assets.UI
local XPTemplate = Assets.BuyXP

local Controllers = ReplicatedStorage.Controllers
local ReplicaController = require(Controllers.ReplicaController)

--
local RankItem = require(script.RankItem)
local PurchaseEvent = Net:RemoteEvent('PurchaseXP')

-- Util
local function BuildPurchase(id: number, data: Products.XPItem): GuiButton
	local new = XPTemplate:Clone()
		new.Name = id
		new.LayoutOrder = id
		
	local amount = new:FindFirstChild('Amount')
	if amount then
		amount.Text = `+{Format.WithCommas(data.Reward)} XP`
	end
	
	local price = new:FindFirstChild('Price')
	if price then
		local info = ProductUtil.GetProductInfo(data.ProductId, Enum.InfoType.Product)
		price.Text = if info then
			`{Format.RobuxUTF}{Format.WithCommas(info.PriceInRobux :: number)}`
			else ''
	end
	
	new.Parent = XPFrame
	return new
end

-- Class
local Menu = {}
Menu.__index = Menu

export type Class = typeof(setmetatable({} :: {
	_UIController: any,
	
	XPId: string?,
	Built: {[string]: RankItem.Class},
	
	Icon: TopbarPlus.Icon,
	Trove: Trove.Trove,
}, Menu))

function Menu.new(controller: any): Class
	local icon = TopbarPlus.new()
		:align('Left')
		:setLabel('Ranks')
		:setImage('rbxassetid://5741308044')
		:autoDeselect(false)
	
	local self = setmetatable({
		_UIController = controller,
		
		XPId = nil :: any,
		Built = {},
		
		Icon = icon,
		Trove = Trove.new(),
	}, Menu)
	
	self:Init()
	return self
end

function Menu.Init(self: Class)
	for id, data in RanksData do
		local new = RankItem.new(id, List, self)
		self.Built[id] = new
	end
	
	for index, data in Products.XP do
		local new = BuildPurchase(index, data)

		new.MouseButton1Up:Connect(function()
			self:PromptXP(index)
		end)
	end
	
	self.Icon:bindEvent('toggled', function(_, selected, fromSource)
		if not fromSource then return end
		
		if selected then
			self._UIController:Open('Ranks')
		else
			self._UIController:Close('Ranks')
		end
	end)
	
	task.spawn(function()
		local succ, res: ReplicaController.Replica =
			ReplicaController.GetReplicaAsync('PlayerData'):await()
		if not succ then return end
		
		res:OnChange(function(_, path)
			if path[1] ~= 'XP' then return end
			
			local id = path[2]
			if not (id and typeof(id) == 'string') then return end
			
			local class = self.Built[id]
			if not class then return end
			
			local newXP = res.Data.XP[id]
			class:Update(newXP or 0)
		end)
		
		self:UpdateAll()
	end)
end

function Menu.UpdateAll(self: Class)
	local replica = ReplicaController.GetReplica('PlayerData')
	if not (replica and replica.Data and replica.Data.XP) then return end
	
	for id, class in self.Built do
		local currXP = (replica.Data.XP :: any)[id] or 0
		class:Update(currXP)
	end
end

function Menu.PromptXP(self: Class, tier: number)
	if not (self.XPId and tier) then return end
	PurchaseEvent:FireServer(self.XPId, tier)
end

function Menu._BindAll(self: Class)
	self.Trove:Connect(CloseButton.MouseButton1Click, function()
		self._UIController:Close('Ranks')
	end)
end

function Menu.OpenXPAt(self: Class, id: string)
	local data = RanksData[id]
	if not data then return end
	
	self.XPId = id
	
	XPFrame.Visible = true
	XPFrame.LayoutOrder = data.DisplayOrder * 2 + 1
end

function Menu.HideXP(self: Class)
	self.XPId = nil
	XPFrame.Visible = false
end

function Menu.OnOpen(self: Class)
	if self.Trove then
		self.Trove:Clean()
	end

	self.Icon:select()
	self:_BindAll()
end

function Menu.OnClose(self: Class)
	if self.Trove then
		self.Trove:Clean()
	end
	
	self.Icon:deselect()
	self:HideXP()
end

return Menu
