-- Services
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

-- Variables
local PURCHASE_BIND_ATTRIBUTE = "StarterPackPurchaseBound"
local OVERLAY_BUTTON_NAME = "StarterPackPurchaseOverlay"

-- Dependencies
local DevProducts = require(ReplicatedStorage.DataModules.DevProducts)
local RemoteBank = require(ReplicatedStorage.RemoteBank)
local GuiController = require(script.Parent.GuiController)

local StarterPackPrompt = {}

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

local function bindPurchaseToButton(button: GuiButton)
	if button:GetAttribute(PURCHASE_BIND_ATTRIBUTE) then
		return
	end

	button:SetAttribute(PURCHASE_BIND_ATTRIBUTE, true)
	button.Activated:Connect(promptStarterPackPurchase)
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

local function bindStarterPackCard(mainGui: ScreenGui)
	local rightContainer = mainGui:FindFirstChild("Right")
	if not rightContainer then
		return
	end

	local starterPackCard = rightContainer:FindFirstChild("StarterPack")
	if not starterPackCard or not starterPackCard:IsA("GuiObject") then
		return
	end

	if starterPackCard:IsA("GuiButton") then
		bindPurchaseToButton(starterPackCard)
		return
	end

	local nestedButton = starterPackCard:FindFirstChildWhichIsA("GuiButton", true)
	if nestedButton then
		bindPurchaseToButton(nestedButton)
		return
	end

	local overlayButton = createOverlayButton(starterPackCard)
	GuiController.AddButton(overlayButton)
	bindPurchaseToButton(overlayButton)
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
		bindPurchaseToButton(purchaseButton)
		return
	end

	local nestedPurchaseButton = purchaseButton:FindFirstChildWhichIsA("GuiButton", true)
	if nestedPurchaseButton then
		bindPurchaseToButton(nestedPurchaseButton)
	end
end

-- Initialization function for the script
function StarterPackPrompt:Initialize()
	local playerGui = Players.LocalPlayer:WaitForChild("PlayerGui")
	local mainGui = playerGui:WaitForChild("MainGui") :: ScreenGui

	bindStarterPackCard(mainGui)
	bindStarterPackFramePurchase(mainGui)
end

return StarterPackPrompt