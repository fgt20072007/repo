local Lighting = game:GetService("Lighting")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local SoundService = game:GetService("SoundService")

local Shared = ReplicatedStorage:WaitForChild("Shared")

local Spring = require(Shared.Packages:WaitForChild("Spr"))

local Player = game.Players.LocalPlayer
local PlayerGui = Player.PlayerGui

local Main = PlayerGui:WaitForChild("Main")

local BUTTON_DAMPING = 0.75
local BUTTON_FREQUENCY = 4.5
local FRAME_DAMPING = 0.8
local FRAME_FREQUENCY = 5

local ButtonActions = {
	QuickSell = function()
		local character = Player.Character
		if not character then return end

		local humanoid = character:FindFirstChildOfClass("Humanoid")
		local rootPart = character:FindFirstChild("HumanoidRootPart")
		if not humanoid or not rootPart then return end

		local lobbyZones = workspace:FindFirstChild("LobbyZones")
		if not lobbyZones then return end

		local sellZone = lobbyZones:FindFirstChild("SellZone")
		if not sellZone then return end

		local positionAttachment = sellZone:FindFirstChild("PositionAttachment")
		if not positionAttachment then return end

		local targetPos = positionAttachment.WorldPosition
		local _, yRot, _ = rootPart.CFrame:ToEulerAnglesYXZ()
		character:PivotTo(CFrame.new(targetPos.X, targetPos.Y + humanoid.HipHeight + rootPart.Size.Y / 2, targetPos.Z) * CFrame.Angles(0, yRot + math.pi, 0))
	end,
}

local Interface = {}

function Interface._Init(self: Interface)
	self.Hud = Main:WaitForChild("HUD")
	self.Frames = Main:WaitForChild("Frames")
	self.OpenFrame = nil
	self.FrameScales = {}
	self.ConnectedButtons = {}

	self:_SetupHudButtons()
	self:_SetupClosingButtons()
	self:_SetupAllButtonEffects()
end

function Interface._SetupHudButtons(self: Interface)
	for _, button in self.Hud:GetDescendants() do
		if not button:IsA("ImageButton") and not button:IsA("TextButton") then continue end

		local action = ButtonActions[button.Name]
		local targetFrame = self.Frames:FindFirstChild(button.Name)

		if not action and not targetFrame then continue end

		self.ConnectedButtons[button] = true

		if targetFrame then
			self:_SetupFrameScale(targetFrame)
		end

		button.MouseButton1Click:Connect(function()
			self:_PlaySound("OnClick")
			if action then action() end
			if targetFrame then self:_ToggleFrame(targetFrame) end
		end)
	end
end

function Interface._SetupClosingButtons(self: Interface)
	for _, frame in self.Frames:GetChildren() do
		if not frame:IsA("Frame") then continue end

		for _, descendant in frame:GetDescendants() do
			if not descendant:IsA("ImageButton") and not descendant:IsA("TextButton") then continue end
			if not descendant.Parent or descendant.Parent.Name ~= "Closing" then continue end

			self.ConnectedButtons[descendant] = true

			descendant.MouseButton1Click:Connect(function()
				self:_PlaySound("OnClick")
				self:_CloseFrame(frame)
			end)
		end
	end
end

function Interface._SetupAllButtonEffects(self: Interface)
	for _, button in Main:GetDescendants() do
		if not button:IsA("ImageButton") and not button:IsA("TextButton") then continue end
		self:AnimateButton(button)
	end
end

function Interface._SetupFrameScale(self: Interface, Frame: Frame)
	if self.FrameScales[Frame] then return end

	local scale = Frame:FindFirstChildWhichIsA("UIScale")
	if not scale then
		scale = Instance.new("UIScale")
		scale.Parent = Frame
	end

	self.FrameScales[Frame] = scale
	Frame.Visible = false
	scale.Scale = 0
end

function Interface._GetComponent(self: Interface, pathSplit: { string }): GuiObject
	local currentParent: Instance = Main

	if #pathSplit == 1 then return currentParent:WaitForChild(pathSplit[1]) :: GuiObject end
	if #pathSplit == 0 then return Main end

	for _, pathPart in pathSplit do
		currentParent = currentParent:FindFirstChild(pathPart)
		if not currentParent then return Main end
	end

	return currentParent :: GuiObject
end

function Interface._ToggleFrame(self: Interface, Frame: Frame | string)
	if typeof(Frame) == "string" then
		Frame = self.Frames:FindFirstChild(Frame)
	end

	if not Frame then return end

	if self.OpenFrame == Frame then
		self:_CloseFrame(Frame)
		return
	end

	if self.OpenFrame then
		self:_CloseFrame(self.OpenFrame)
	end

	self:_OpenFrame(Frame)
end

function Interface._OpenFrame(self: Interface, Frame: Frame)
	local scale = self.FrameScales[Frame]
	if not scale then
		self:_SetupFrameScale(Frame)
		scale = self.FrameScales[Frame]
	end

	self.OpenFrame = Frame
	Frame.Visible = true
	scale.Scale = 0

	Spring.target(Lighting.Blur, 1, 3, { Size = 15 })
	Spring.target(scale, FRAME_DAMPING, FRAME_FREQUENCY, { Scale = 1.05 })

	task.delay(0.1, function()
		Spring.target(scale, FRAME_DAMPING, FRAME_FREQUENCY, { Scale = 1 })
	end)
end

function Interface._CloseFrame(self: Interface, Frame: Frame)
	local scale = self.FrameScales[Frame]
	if not scale then return end

	if self.OpenFrame == Frame then
		self.OpenFrame = nil
	end

	Spring.target(Lighting.Blur, 1, 3, { Size = 0 })
	Spring.target(scale, FRAME_DAMPING, FRAME_FREQUENCY, { Scale = 1.05 })

	task.delay(0.08, function()
		Spring.target(scale, FRAME_DAMPING, 8, { Scale = 0 })

		task.delay(0.15, function()
			if scale.Scale < 0.1 then
				Frame.Visible = false
			end
		end)
	end)
end

function Interface._PlaySound(self: Interface, SoundName: string)
	local sfxFolder = SoundService:FindFirstChild("SFX")
	if not sfxFolder then return end

	local sound = sfxFolder:FindFirstChild(SoundName)
	if not sound or not sound:IsA("Sound") then return end

	SoundService:PlayLocalSound(sound)
end

function Interface._Notify(self: Interface, Text: string, Warning: boolean?)
	local Clone = self.Hud.Notifications.Message:Clone()
	Clone.text.Text = Text
	Clone.text.TextColor3 = Warning and Color3.fromRGB(255, 0, 0) or Color3.fromRGB(0, 255, 0)
	Clone.Visible = true
	Clone.Parent = self.Hud.Notifications

	task.delay(1.5, function()
		Clone:Destroy()
	end)
end

function Interface.AnimateButton(self: Interface, Button: GuiButton)
	local scale = Button:FindFirstChildWhichIsA("UIScale") or Instance.new("UIScale")
	scale.Parent = Button

	local defaultScale = scale.Scale
	local isHovering = false
	local isPressed = false

	Button.MouseEnter:Connect(function()
		isHovering = true
		self:_PlaySound("Hover")
		Spring.target(scale, 0.7, 6, { Scale = defaultScale * 1.08 })
	end)

	Button.MouseLeave:Connect(function()
		isHovering = false
		if isPressed then return end
		Spring.target(scale, 0.8, 5, { Scale = defaultScale })
	end)

	Button.MouseButton1Down:Connect(function()
		isPressed = true
		self:_PlaySound("OnClick")
		Spring.target(scale, 0.5, 8, { Scale = defaultScale * 0.92 })
	end)

	Button.MouseButton1Up:Connect(function()
		isPressed = false
		local targetScale = isHovering and defaultScale * 1.08 or defaultScale
		Spring.target(scale, 0.6, 7, { Scale = defaultScale * 1.12 })
		task.delay(0.08, function()
			Spring.target(scale, 0.7, 5, { Scale = targetScale })
		end)
	end)
end

function Interface.IsFrameOpen(self: Interface, FrameName: string)
	local frame = self.Frames:FindFirstChild(FrameName)
	return self.OpenFrame == frame
end

function Interface.ForceClose(self: Interface)
	if not self.OpenFrame then return end
	self:_CloseFrame(self.OpenFrame)
end

type Interface = typeof(Interface) & {
	Hud: Folder,
	Frames: Frame,
	OpenFrame: Frame?,
	FrameScales: { [Frame]: UIScale },
	ConnectedButtons: { [GuiButton]: boolean },
}

return Interface