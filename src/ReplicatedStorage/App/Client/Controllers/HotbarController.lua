local Players = game:GetService("Players")
local StarterGui = game:GetService("StarterGui")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local app = ReplicatedStorage:WaitForChild("App")
local shared = app:WaitForChild("Shared")

local netRoot = shared:WaitForChild("Net")
local Net = require(netRoot:WaitForChild("Client"))
local Maid = require(shared:WaitForChild("Util"):WaitForChild("Maid"))

local HotbarController = {}
HotbarController.__index = HotbarController

local EQUIPPED_SIZE_SCALE = 1.15
local PULSE_SIZE_SCALE = 1.28
local PULSE_UP_INFO = TweenInfo.new(0.11, Enum.EasingStyle.Back, Enum.EasingDirection.Out)
local PULSE_DOWN_INFO = TweenInfo.new(0.16, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
local RESET_INFO = TweenInfo.new(0.12, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)

local function resolveNetEvent(container, pascalName)
	if type(container) ~= "table" then
		return nil
	end

	local eventObject = container[pascalName]
	if eventObject ~= nil then
		return eventObject
	end

	local camelName = string.lower(string.sub(pascalName, 1, 1)) .. string.sub(pascalName, 2)
	eventObject = container[camelName]
	if eventObject ~= nil then
		return eventObject
	end

	local eventsContainer = container.Events or container.events
	if type(eventsContainer) == "table" then
		eventObject = eventsContainer[pascalName]
		if eventObject ~= nil then
			return eventObject
		end

		return eventsContainer[camelName]
	end

	return nil
end

local KEY_TO_SLOT = {
	[Enum.KeyCode.One] = 1,
	[Enum.KeyCode.Two] = 2,
	[Enum.KeyCode.Three] = 3,
	[Enum.KeyCode.Four] = 4,
	[Enum.KeyCode.Five] = 5,
	[Enum.KeyCode.Six] = 6,
	[Enum.KeyCode.Seven] = 7,
	[Enum.KeyCode.Eight] = 8,
	[Enum.KeyCode.Nine] = 9,
	[Enum.KeyCode.KeypadOne] = 1,
	[Enum.KeyCode.KeypadTwo] = 2,
	[Enum.KeyCode.KeypadThree] = 3,
	[Enum.KeyCode.KeypadFour] = 4,
	[Enum.KeyCode.KeypadFive] = 5,
	[Enum.KeyCode.KeypadSix] = 6,
	[Enum.KeyCode.KeypadSeven] = 7,
	[Enum.KeyCode.KeypadEight] = 8,
	[Enum.KeyCode.KeypadNine] = 9,
}

function HotbarController.new()
	local self = setmetatable({}, HotbarController)

	self._initialized = false
	self._started = false
	self._maid = Maid.New()
	self._slots = {}
	self._container = nil
	self._template = nil

	return self
end

function HotbarController:_findHotbarContainer()
	local localPlayer = Players.LocalPlayer
	if not localPlayer then
		return nil
	end

	local playerGui = localPlayer:WaitForChild("PlayerGui")
	local hotbarGui = playerGui:FindFirstChild("Hotbar UI")
	if not hotbarGui then
		hotbarGui = playerGui:FindFirstChild("HotbarUI")
	end
	if not hotbarGui then
		return nil
	end

	local canvas = hotbarGui:FindFirstChild("Canvas")
	if not canvas then
		return nil
	end

	local container = canvas:FindFirstChild("Container")
	return container
end

function HotbarController:_setTemplateVisible(template, isVisible)
	if template:IsA("GuiObject") then
		template.Visible = isVisible
	end
end

function HotbarController:_ensureUI()
	if self._container and self._template then
		return true
	end

	local container = self:_findHotbarContainer()
	if not container then
		return false
	end

	local template = container:FindFirstChild("Template")
	if not template then
		return false
	end

	self._container = container
	self._template = template
	self:_setTemplateVisible(template, false)

	return true
end

function HotbarController:_setSlotVisualEquipped(root, isEquipped)
	root:SetAttribute("IsEquipped", isEquipped)

	if root:IsA("GuiObject") then
		root.Selectable = isEquipped
	end

	local stroke = root:FindFirstChildWhichIsA("UIStroke", true)
	if stroke then
		stroke.Enabled = isEquipped
	end
end

function HotbarController:_scaledSize(size, multiplier)
	return UDim2.new(
		size.X.Scale * multiplier,
		math.floor(size.X.Offset * multiplier + 0.5),
		size.Y.Scale * multiplier,
		math.floor(size.Y.Offset * multiplier + 0.5)
	)
end

function HotbarController:_cancelSlotTween(slotView)
	if slotView.activeTween then
		slotView.activeTween:Cancel()
		slotView.activeTween = nil
	end
end

function HotbarController:_playTween(slotView, tweenInfo, targetSize, onCompleted)
	self:_cancelSlotTween(slotView)

	local tween = TweenService:Create(slotView.root, tweenInfo, {
		Size = targetSize,
	})
	slotView.activeTween = tween

	tween:Play()

	tween.Completed:Once(function(playbackState)
		if slotView.activeTween == tween then
			slotView.activeTween = nil
		end

		if playbackState == Enum.PlaybackState.Completed and onCompleted then
			onCompleted()
		end
	end)
end

function HotbarController:_applySlotSizeState(slotView, isEquipped)
	if not slotView.root:IsA("GuiObject") then
		return
	end

	local baseSize = slotView.baseSize
	if not baseSize then
		baseSize = slotView.root.Size
		slotView.baseSize = baseSize
	end

	if not isEquipped then
		self:_playTween(slotView, RESET_INFO, baseSize)
		return
	end

	local pulseSize = self:_scaledSize(baseSize, PULSE_SIZE_SCALE)
	local equippedSize = self:_scaledSize(baseSize, EQUIPPED_SIZE_SCALE)

	self:_playTween(slotView, PULSE_UP_INFO, pulseSize, function()
		self:_playTween(slotView, PULSE_DOWN_INFO, equippedSize)
	end)
end

function HotbarController:_getOrCreateSlot(slot)
	if self._slots[slot] then
		return self._slots[slot]
	end

	if not self:_ensureUI() then
		return nil
	end

	local cloned = self._template:Clone()
	cloned.Name = "Slot_" .. tostring(slot)

	if cloned:IsA("GuiObject") then
		cloned.LayoutOrder = slot
		cloned.Visible = true
	end

	cloned.Parent = self._container

	local slotView = {
		uid = "",
		root = cloned,
		isEquipped = false,
		baseSize = cloned:IsA("GuiObject") and cloned.Size or nil,
		activeTween = nil,
		inputConnection = nil,
	}

	self:_bindSlotInput(slot, slotView)

	self._slots[slot] = slotView
	return slotView
end

function HotbarController:_bindSlotInput(slot, slotView)
	local root = slotView.root

	local function requestToggle()
		if self._slots[slot] ~= slotView then
			return
		end

		self:_fireRequestToggle(slot)
	end

	if root:IsA("GuiButton") then
		slotView.inputConnection = root.Activated:Connect(function()
			requestToggle()
		end)
		return
	end

	if root:IsA("GuiObject") then
		local nestedButton = root:FindFirstChildWhichIsA("GuiButton", true)
		if nestedButton then
			slotView.inputConnection = nestedButton.Activated:Connect(function()
				requestToggle()
			end)
			return
		end

		root.Active = true
		slotView.inputConnection = root.InputEnded:Connect(function(inputObject)
			local userInputType = inputObject.UserInputType
			if userInputType ~= Enum.UserInputType.Touch and userInputType ~= Enum.UserInputType.MouseButton1 then
				return
			end

			requestToggle()
		end)
	end
end

function HotbarController:_applySlotData(slot, uid, toolName, textureId)
	local slotView = self:_getOrCreateSlot(slot)
	if not slotView then
		return
	end

	slotView.uid = uid

	local root = slotView.root
	local nameLabel = root:FindFirstChild("TemplateName", true)
	if nameLabel and nameLabel:IsA("TextLabel") then
		nameLabel.Text = toolName
	end

	local numberLabel = root:FindFirstChild("TemplateNumber", true)
	if numberLabel and numberLabel:IsA("TextLabel") then
		numberLabel.Text = tostring(slot)
	end

	local imageLabel = root:FindFirstChild("TemplateImage", true)
	if imageLabel and imageLabel:IsA("ImageLabel") then
		imageLabel.Image = textureId
	elseif imageLabel and imageLabel:IsA("ImageButton") then
		imageLabel.Image = textureId
	end

	self:_setSlotVisualEquipped(root, slotView.isEquipped)
	self:_applySlotSizeState(slotView, slotView.isEquipped)
end

function HotbarController:_clearSlot(slot)
	local slotView = self._slots[slot]
	if not slotView then
		return
	end

	if slotView.inputConnection then
		slotView.inputConnection:Disconnect()
		slotView.inputConnection = nil
	end

	self:_cancelSlotTween(slotView)

	slotView.root:Destroy()
	self._slots[slot] = nil
end

function HotbarController:_setEquipped(slot, isEquipped)
	local slotView = self._slots[slot]
	if not slotView then
		return
	end

	slotView.isEquipped = isEquipped
	self:_setSlotVisualEquipped(slotView.root, isEquipped)
	self:_applySlotSizeState(slotView, isEquipped)
end

function HotbarController:Init()
	if self._initialized then
		return
	end
	self._initialized = true
end

function HotbarController:_disableDefaultBackpack()
	for _ = 1, 10 do
		local ok = pcall(function()
			StarterGui:SetCoreGuiEnabled(Enum.CoreGuiType.Backpack, false)
		end)

		if ok then
			return
		end

		task.wait(0.2)
	end
end

function HotbarController:_bindNetEvent(eventName, handler)
	local eventObject = resolveNetEvent(Net, eventName)
	if type(eventObject) ~= "table" then
		return
	end

	local onListener = eventObject.On
	if type(onListener) ~= "function" then
		return
	end

	self._maid:Add(onListener(handler))
end

function HotbarController:_fireRequestToggle(slot)
	local eventObject = resolveNetEvent(Net, "HotbarRequestToggle")
	if type(eventObject) ~= "table" then
		return
	end

	local fire = eventObject.Fire
	if type(fire) ~= "function" then
		return
	end

	fire(slot)
end

function HotbarController:Start()
	if self._started then
		return
	end
	self._started = true

	self:_disableDefaultBackpack()

	local localPlayer = Players.LocalPlayer
	if localPlayer then
		self._maid:Add(localPlayer.CharacterAdded:Connect(function()
			self:_disableDefaultBackpack()
		end))
	end

	self:_ensureUI()

	self:_bindNetEvent("HotbarSetSlot", function(slot, uid, toolName, textureId)
		self:_applySlotData(slot, uid, toolName, textureId)
	end)

	self:_bindNetEvent("HotbarClearSlot", function(slot)
		self:_clearSlot(slot)
	end)

	self:_bindNetEvent("HotbarSetEquipped", function(slot, isEquipped)
		self:_setEquipped(slot, isEquipped)
	end)

	self._maid:Add(UserInputService.InputBegan:Connect(function(inputObject, gameProcessedEvent)
		if gameProcessedEvent then
			return
		end

		if inputObject.UserInputType ~= Enum.UserInputType.Keyboard then
			return
		end

		local slot = KEY_TO_SLOT[inputObject.KeyCode]
		if not slot then
			return
		end

		if self._slots[slot] == nil then
			return
		end

		self:_fireRequestToggle(slot)
	end))
end

local singleton = HotbarController.new()

return table.freeze({
	Init = function()
		singleton:Init()
	end,
	Start = function()
		singleton:Start()
	end,
})