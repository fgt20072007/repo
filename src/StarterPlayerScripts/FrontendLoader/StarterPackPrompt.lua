-- Services
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local MarketplaceService = game:GetService("MarketplaceService")

-- Variables
local PURCHASE_BIND_ATTRIBUTE = "StarterPackPurchaseBound"
local OVERLAY_BUTTON_NAME = "StarterPackPurchaseOverlay"
local PLAYER = Players.LocalPlayer

-- Dependencies
local DevProducts = require(ReplicatedStorage.DataModules.DevProducts)
local RemoteBank = require(ReplicatedStorage.RemoteBank)
local GuiController = require(script.Parent.GuiController)
local Gamepasses = require(ReplicatedStorage.DataModules.Gamepasses)

local StarterPackPrompt = {}

local FALLBACK_GAMEPASS_IDS = {
	VIP = 1704599571,
	["2x Money"] = 1704637573,
}

local gamepassCardsById = {}

local function resolveGamepassId(cardName: string): number?
	local direct = Gamepasses[cardName]
	if typeof(direct) == "number" then
		return direct
	end
	if typeof(direct) == "table" and typeof(direct.Id) == "number" then
		return direct.Id
	end

	if cardName == "VIP" then
		local vipEntry = Gamepasses.VIP or Gamepasses.Vip
		if typeof(vipEntry) == "table" and typeof(vipEntry.Id) == "number" then
			return vipEntry.Id
		end
	end

	if cardName == "2x Money" then
		local twoXEntry = Gamepasses["2x Money"] or Gamepasses.DoubleMoney or Gamepasses["2x"] or Gamepasses["2xMoney"]
		if typeof(twoXEntry) == "table" and typeof(twoXEntry.Id) == "number" then
			return twoXEntry.Id
		end
	end

	return FALLBACK_GAMEPASS_IDS[cardName]
end

local function promptStarterPackPurchase()
	local starterPackData = DevProducts.StarterPack
	if typeof(starterPackData) ~= "table" then
		warn("StarterPack is missing from DevProducts module")
		return
	end

	local productId = tonumber(starterPackData.Id)
	if not productId then
		warn("StarterPack Dev Product Id is invalid")
		return
	end

	RemoteBank.Purchase:InvokeServer(false, productId)
end

local function promptGamepassPurchase(gamepassId: number)
	RemoteBank.Purchase:InvokeServer(true, gamepassId)
end

local function bindPurchaseToButton(button: GuiButton, callback: () -> ())
	if button:GetAttribute(PURCHASE_BIND_ATTRIBUTE) then
		return
	end

	button:SetAttribute(PURCHASE_BIND_ATTRIBUTE, true)
	button.Activated:Connect(callback)
end

local function createOverlayButton(target: GuiObject): GuiButton
	local existingOverlay = target:FindFirstChild(OVERLAY_BUTTON_NAME)
	if existingOverlay and existingOverlay:IsA("GuiButton") then
		return existingOverlay
	end

	local overlayButton = Instance.new("TextButton")
	overlayButton.Name = OVERLAY_BUTTON_NAME
	overlayButton.Size = UDim2.fromScale(1, 1)
	overlayButton.Position = UDim2.fromScale(0, 0)
	overlayButton.BackgroundTransparency = 1
	overlayButton.Text = ""
	overlayButton.AutoButtonColor = false
	overlayButton.ZIndex = target.ZIndex + 1
	overlayButton.Parent = target

	return overlayButton
end

local function resolveCardButton(card: GuiObject): GuiButton
	if card:IsA("GuiButton") then
		return card
	end

	local nestedButton = card:FindFirstChildWhichIsA("GuiButton", true)
	if nestedButton then
		return nestedButton
	end

	local overlayButton = createOverlayButton(card)
	GuiController.AddButton(overlayButton)
	return overlayButton
end

local function getGamepassOwnership(gamepassId: number): boolean
	local success, owns = pcall(function()
		return MarketplaceService:UserOwnsGamePassAsync(PLAYER.UserId, gamepassId)
	end)

	return success and owns == true
end

local function updateGamepassCardVisibility(card: GuiObject, gamepassId: number)
	card.Visible = not getGamepassOwnership(gamepassId)
end

local function bindStarterPackCard(mainGui: ScreenGui)
	local rightContainer = mainGui:FindFirstChild("Right")
	if not rightContainer then
		return
	end

	local starterPackCard = rightContainer:FindFirstChild("StarterPack")
	if not starterPackCard or not starterPackCard:IsA("GuiObject") then
		return
	end

	local button = resolveCardButton(starterPackCard)
	bindPurchaseToButton(button, promptStarterPackPurchase)
end

local function bindGamepassCard(mainGui: ScreenGui, cardName: string)
	local rightContainer = mainGui:FindFirstChild("Right")
	if not rightContainer then
		return
	end

	local card = rightContainer:FindFirstChild(cardName)
	if not card or not card:IsA("GuiObject") then
		return
	end

	local gamepassId = resolveGamepassId(cardName)
	if not gamepassId then
		warn(("Gamepass id is missing for card '%s'"):format(cardName))
		return
	end

	gamepassCardsById[gamepassId] = card
	updateGamepassCardVisibility(card, gamepassId)

	local button = resolveCardButton(card)
	bindPurchaseToButton(button, function()
		promptGamepassPurchase(gamepassId)
	end)
end

local function bindStarterPackFramePurchase(mainGui: ScreenGui)
	local frames = mainGui:FindFirstChild("Frames")
	if not frames then
		return
	end

	local starterPackFrame = frames:FindFirstChild("Starterpack") or frames:FindFirstChild("StarterPack")
	if not starterPackFrame then
		return
	end

	local purchaseButton = starterPackFrame:FindFirstChild("PurchaseButton", true)
	if not purchaseButton then
		return
	end

	if purchaseButton:IsA("GuiButton") then
		bindPurchaseToButton(purchaseButton, promptStarterPackPurchase)
		return
	end

	local nestedPurchaseButton = purchaseButton:FindFirstChildWhichIsA("GuiButton", true)
	if nestedPurchaseButton then
		bindPurchaseToButton(nestedPurchaseButton, promptStarterPackPurchase)
	end
end

local function getGamepassPurchaseResult(...)
	local a, b, c = ...

	if typeof(a) == "number" then
		return a, b == true
	end

	if typeof(b) == "number" then
		return b, c == true
	end

	return nil, false
end

local function setupGamepassPurchaseListener()
	MarketplaceService.PromptGamePassPurchaseFinished:Connect(function(...)
		local gamepassId, wasPurchased = getGamepassPurchaseResult(...)
		if not gamepassId then
			return
		end

		local card = gamepassCardsById[gamepassId]
		if not card then
			return
		end

		if wasPurchased then
			card.Visible = false
		else
			-- Keep UI in sync even when purchase is cancelled.
			updateGamepassCardVisibility(card, gamepassId)
		end
	end)
end

local function bindRightOffers(mainGui: ScreenGui)
	bindStarterPackCard(mainGui)
	bindGamepassCard(mainGui, "VIP")
	bindGamepassCard(mainGui, "2x Money")

	local rightContainer = mainGui:FindFirstChild("Right")
	if rightContainer then
		rightContainer.ChildAdded:Connect(function(child)
			if child.Name == "StarterPack" and child:IsA("GuiObject") then
				bindStarterPackCard(mainGui)
				return
			end

			if child.Name == "VIP" and child:IsA("GuiObject") then
				bindGamepassCard(mainGui, "VIP")
				return
			end

			if child.Name == "2x Money" and child:IsA("GuiObject") then
				bindGamepassCard(mainGui, "2x Money")
				return
			end
		end)
	end
end

-- Initialization function for the script
function StarterPackPrompt:Initialize()
	local playerGui = PLAYER:WaitForChild("PlayerGui")
	local mainGui = playerGui:WaitForChild("MainGui") :: ScreenGui

	bindRightOffers(mainGui)
	bindStarterPackFramePurchase(mainGui)
	setupGamepassPurchaseListener()
end

return StarterPackPrompt
