local ReplicatedStorage = game:GetService('ReplicatedStorage')
local Players = game:GetService('Players')

local Client = Players.LocalPlayer
local PlayerGui = Client:WaitForChild('PlayerGui')

local Packages = ReplicatedStorage:WaitForChild('Packages')
local Trove = require(Packages.Trove)
local Net = require(Packages.Net)

local Main = PlayerGui:WaitForChild('Main')
local SignStructure = Main:WaitForChild('SignStructure')
local ChangeSignButton = SignStructure:WaitForChild('ChangeSign')
local Frame = SignStructure:WaitForChild('Frame')
local CloseButton = Frame:WaitForChild('CloseButton')
local TextBox = Frame:WaitForChild('TextBox')

local SignRemote = Net:RemoteEvent('Sign_SetText')

local MAX_CHARACTERS = 50
local COOLDOWN_SECONDS = 60
local DEFAULT_BUTTON_TEXT = "Change Text"

local ActiveTool = nil
local UIConnections = {}
local CooldownEndsAt = 0
local CooldownVersion = 0

local Manager = { Loaded = {} }

local Class = {}
Class.__index = Class

function Class.new(tool)
	local self = setmetatable({ Tool = tool, Trove = Trove.new() }, Class)
	task.defer(self._Init, self)
	return self
end

function Class:_Init()
	self.Trove:Add(self.Tool.AncestryChanged:Connect(function()
		if self.Tool.Parent then return end
		self:Destroy()
	end))

	self.Trove:Add(self.Tool.Equipped:Connect(function()
		Manager.OnEquipped(self.Tool)
	end))

	self.Trove:Add(self.Tool.Unequipped:Connect(function()
		Manager.OnUnequipped()
	end))
end

function Class:Destroy()
	Manager.OnUnequipped()
	self.Trove:Destroy()
	Manager.Loaded[self.Tool] = nil
end

local function ClearUIConnections()
	for _, conn in UIConnections do
		conn:Disconnect()
	end
	table.clear(UIConnections)
end

local function CloseFrame()
	Frame.Visible = false
end

local function SetChangeButtonText(text: string)
	local textLabel = ChangeSignButton:FindFirstChild("TextLabel")
	if textLabel and textLabel:IsA("TextLabel") then
		textLabel.Text = text
		return
	end

	if ChangeSignButton:IsA("TextButton") then
		ChangeSignButton.Text = text
	end
end

local function GetRemainingCooldown(): number
	return math.max(0, math.ceil(CooldownEndsAt - os.clock()))
end

local function UpdateCooldownState()
	local remaining = GetRemainingCooldown()
	local onCooldown = remaining > 0

	ChangeSignButton.Active = not onCooldown
	if ChangeSignButton:IsA("TextButton") then
		ChangeSignButton.AutoButtonColor = not onCooldown
	end

	if onCooldown then
		SetChangeButtonText(tostring(remaining))
	else
		SetChangeButtonText(DEFAULT_BUTTON_TEXT)
	end
end

local function StartCooldown()
	CooldownEndsAt = os.clock() + COOLDOWN_SECONDS
	CooldownVersion += 1
	local version = CooldownVersion

	UpdateCooldownState()
	CloseFrame()

	task.spawn(function()
		while version == CooldownVersion do
			if GetRemainingCooldown() <= 0 then
				break
			end

			task.wait(1)
			if version ~= CooldownVersion then return end
			UpdateCooldownState()
		end

		if version ~= CooldownVersion then return end
		CooldownEndsAt = 0
		UpdateCooldownState()
	end)
end

local function OpenFrame()
	if GetRemainingCooldown() > 0 then return end
	Frame.Visible = true
	TextBox.Text = ""
	TextBox:CaptureFocus()
end

local function SubmitText()
	local tool = ActiveTool
	if not tool then return end
	if GetRemainingCooldown() > 0 then return end

	local text = TextBox.Text
	if text == "" then return end
	if #text > MAX_CHARACTERS then text = string.sub(text, 1, MAX_CHARACTERS) end

	SignRemote:FireServer(tool, text)
	StartCooldown()
	CloseFrame()
end

function Manager.OnEquipped(tool)
	ActiveTool = tool
	ChangeSignButton.Visible = true
	UpdateCooldownState()

	table.insert(UIConnections, ChangeSignButton.MouseButton1Click:Connect(OpenFrame))
	table.insert(UIConnections, CloseButton.MouseButton1Click:Connect(CloseFrame))

	table.insert(UIConnections, TextBox.FocusLost:Connect(function(enterPressed)
		if enterPressed then SubmitText() end
	end))

	table.insert(UIConnections, TextBox:GetPropertyChangedSignal("Text"):Connect(function()
		if #TextBox.Text > MAX_CHARACTERS then
			TextBox.Text = string.sub(TextBox.Text, 1, MAX_CHARACTERS)
		end
	end))
end

function Manager.OnUnequipped()
	ActiveTool = nil
	ChangeSignButton.Visible = false
	CloseFrame()
	ClearUIConnections()
end

function Manager.Load(tool)
	if Manager.Loaded[tool] then return end
	Manager.Loaded[tool] = Class.new(tool)
end

return Manager
