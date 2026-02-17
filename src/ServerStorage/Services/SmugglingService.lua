--!strict
local ReplicatedStorage = game:GetService 'ReplicatedStorage'
local ServerStorage = game:GetService 'ServerStorage'
local Marketplaceservice = game:GetService 'MarketplaceService'

local Packages = ReplicatedStorage.Packages
local Net = require(Packages.Net)
local Observer = require(Packages.Observers)
local RateLimit = require(Packages.ReplicaShared.RateLimit)
local MarketService = require(script.Parent.MarketService)

local Data = ReplicatedStorage.Data
local ToolsData = require(Data.Tools)
local GeneralData = require(Data.General)
local GamepassData = require(Data.Passes)

local ToolsPath = ServerStorage.ServerAssets.Tools

local Assets = ReplicatedStorage.Assets.Tools
local PurchasePromptTemplate = Assets.General.BasePurchasePrompt
local SellPromptTemplate = Assets.General.SellSmugglePrompt
local LaundryPromptTemplate = Assets.General.LaundryPrompt

local Format = require(ReplicatedStorage.Util.Format)
local DataService = require(ServerStorage.Services.DataService)

local NotifyEvent = Net:RemoteEvent('Notification')

local SmuggleShopService = {
	PurchaseRateLimit = RateLimit.New(2),
}

local EL_PATRON_PASS = "El Patron"
local EL_PATRON_SELLABLE_BONUS = 3
local EL_PATRON_SELL_MULTIPLIER = 2

type EquippedPerClass = { Sellable: {Tool}, NonSellable: {Tool} }

local function GetCopiesOf(equipped: EquippedPerClass, id: string): number
	local count = 0

	for _, list: {Tool} in equipped :: any do
		for _, tool: Tool in list do
			if tool.Name ~= id then continue end
			count += 1
		end
	end

	return count
end

local function HasElPatron(player: Player): boolean
	return MarketService.OwnsPass(player, EL_PATRON_PASS) == true
end

function SmuggleShopService.GetEquippedPerClass(player: Player): EquippedPerClass
	local found = {Sellable = {}, NonSellable = {}}

	local function check(input: Instance)
		if not input:IsA('Tool') then return end

		local data = (ToolsData :: any)[input.Name]
		if not data then return end

		table.insert(
			data.SellPrice and found.Sellable or found.NonSellable,
			input
		)
	end

	for _, des in player.Backpack:GetChildren() do
		check(des)
	end

	if player.Character then
		for _, des in player.Character:GetChildren() do
			check(des)
		end
	end

	return found
end

function SmuggleShopService.OnPurchaseAttempt(player: Player, itemId: string): (boolean, string?)
	if not SmuggleShopService.PurchaseRateLimit:CheckRate(player) then return false, nil end

	local data: ToolsData.Data? = itemId and (ToolsData :: any)[itemId] or nil
	if not (data and data.Price) then return false, nil end

	if data.GamepassOnly and not MarketService.OwnsPass(player, data.GamepassOnly) then
		Marketplaceservice:PromptGamePassPurchase(player, GamepassData[data.GamepassOnly])
		return false, 'ItemPurchase/PassRequired'
	end

	if data.Illegal then
		local team = player.Team

		if not (team and not team:HasTag('Federal')) then
			return false, 'ItemPurchase/FedBlocked'
		end
	end

	local perClass = SmuggleShopService.GetEquippedPerClass(player)
	local index = data.SellPrice and 'Sellable' or 'NonSellable'
	local carryLimit = (GeneralData :: any)[`CarryMax{index}`]
	if index == "Sellable" and HasElPatron(player) then
		carryLimit += EL_PATRON_SELLABLE_BONUS
	end

	if carryLimit <= #(perClass :: any)[index] then
		return false, 'ItemPurchase/MaxxedClass'
	end

	if data.CarryMax then
		local copies = GetCopiesOf(perClass, itemId)
		if copies >= (data.CarryMax :: number) then return false, 'ItemPurchase/MaxxedItem' end
	end

	local cash = DataService.GetBalance(player)
	if not cash or cash < data.Price then
		return false, 'ItemPurchase/CantAfford'
	end

	local template = ToolsPath:FindFirstChild(itemId)
	if not template then return false, 'ItemPurchase/Unexpected' end

	local success = DataService.AdjustBalance(player, -data.Price)
	if success then
		local new = template:Clone()
		new.Parent = player.Backpack
	end

	return success, success and 'ItemPurchase/Success' or 'ItemPurchase/Unexpected'
end

function SmuggleShopService.OnSellAttempt(player: Player): (boolean, string?)
	if not player.Character then return false, nil end

	local team = player.Team
	if team and team:HasTag('Federal') then return false, 'Smuggling/FedBlocked' end

	local perClass = SmuggleShopService.GetEquippedPerClass(player)
	if #perClass.Sellable <= 0 then return false, 'Smuggling/NoSellable' end

	local totalCash = 0
	local sellMultiplier = HasElPatron(player) and EL_PATRON_SELL_MULTIPLIER or 1
	for _, item in perClass.Sellable do
		local data = ToolsData[item.Name]
		if not (data and data.SellPrice) then continue end

		totalCash = math.floor(totalCash + data.SellPrice * sellMultiplier)
		item:Destroy()
	end

	if totalCash <= 0 then return false, 'Smuggling/NoSellable' end

	local foundBriefcase = player.Character:FindFirstChild('Briefcase')
		or player.Backpack:FindFirstChild('Briefcase')

	if foundBriefcase and foundBriefcase:IsA('Tool') then
		local prev = foundBriefcase:GetAttribute('Cash') or 0
		foundBriefcase:SetAttribute('Cash', math.floor(prev + totalCash))

		return true, 'Smuggling/SoldPrev'
	else
		local new = ToolsPath.Briefcase:Clone()
		new:SetAttribute('Cash', totalCash)
		new.Parent = player.Backpack :: any

		return true, 'Smuggling/SoldNoPrev'
	end
end

function SmuggleShopService.OnLaundryAttempt(player: Player): (boolean, string?)
	if not player.Character then return false, nil end

	local team = player.Team
	if team and team:HasTag('Federal') then return false, 'Laundering/FedBlocked' end

	local briefcase = player.Character:FindFirstChild('Briefcase')
		or player.Backpack:FindFirstChild('Briefcase')
	if not (briefcase and briefcase:IsA('Tool')) then return false, 'Laundering/NoBriefcase' end

	local cash = briefcase:GetAttribute('Cash') or 0
	local succ = DataService.AdjustBalance(player, math.abs(cash))
	if not succ then return false, nil end

	briefcase:Destroy()
	return true, 'Laundering/Sold'
end

function SmuggleShopService._BindPurchasable(item: Instance)
	if not item:IsA('Model') then return end

	local id = item.Name
	local itemData = ToolsData[id]
	if not itemData then return end

	local price = itemData.Price
	if not price then return end

	local main = item.PrimaryPart or item:FindFirstChild('Main') or item:FindFirstChildOfClass('BasePart')
	if not main then return end

	local rate = itemData.DetectionRate
	local fixedPrice = (price and price > 0) and `${Format.WithCommas(price)}` or 'FREE'

	local att = main:FindFirstChild('PromptAtt')
	local prompt = PurchasePromptTemplate:Clone()
	prompt.ActionText = `Buy {id}`
	prompt.ObjectText = `{fixedPrice}{rate and ` • Detection: {rate}%` or ''}`
	prompt.HoldDuration = 0.4
	prompt.UIOffset = att and Vector2.new(0, 5) or Vector2.zero
	prompt.Parent = (att or main) :: any

	prompt.Triggered:Connect(function(who: Player)
		local success, res = SmuggleShopService.OnPurchaseAttempt(who, id)
		if res ~= nil then NotifyEvent:FireClient(who, res) end
	end)
end

function SmuggleShopService._BindReseller(item: Instance)
	if not item:IsA('BasePart') then return end
	item.Transparency = 1

	local prompt = SellPromptTemplate:Clone()
	prompt.Parent = item :: any

	prompt.Triggered:Connect(function(who: Player)
		local success, res = SmuggleShopService.OnSellAttempt(who)
		if res ~= nil then NotifyEvent:FireClient(who, res) end
	end)
end

function SmuggleShopService._BindLaundry(item: Instance)
	if not item:IsA('BasePart') then return end
	item.Transparency = 1

	local prompt = LaundryPromptTemplate:Clone()
	prompt.Parent = item :: any

	prompt.Triggered:Connect(function(who: Player)
		local success, res = SmuggleShopService.OnLaundryAttempt(who)
		if res ~= nil then NotifyEvent:FireClient(who, res) end
	end)
end

function SmuggleShopService.Init()
	Observer.observeTag('Purchasable', SmuggleShopService._BindPurchasable)
	Observer.observeTag('SellSmuggle', SmuggleShopService._BindReseller)
	Observer.observeTag('LaundryCash', SmuggleShopService._BindLaundry)
end

return SmuggleShopService
