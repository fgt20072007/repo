--!strict
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local MarketplaceService = game:GetService("MarketplaceService")

local Packages = ReplicatedStorage:WaitForChild("Packages")
local Trove = require(Packages:WaitForChild("Trove"))
local Observers = require(Packages:WaitForChild("Observers"))
local Net = require(Packages:WaitForChild('Net'))

local Data = ReplicatedStorage:WaitForChild("Data") 
local SettingsData = require(Data:WaitForChild("Settings"))

local Util = ReplicatedStorage:WaitForChild('Util')
local Sounds = require(Util.Sounds)

local Controllers = ReplicatedStorage:WaitForChild('Controllers')
local ReplicaController = require(Controllers.ReplicaController)

local Assets = ReplicatedStorage:WaitForChild('Assets')
local Template = Assets.UI:WaitForChild("Setting") :: Frame

-- UI
local Player = Players.LocalPlayer :: Player
local PlayerGui = Player:WaitForChild("PlayerGui") :: PlayerGui

local Main = PlayerGui:WaitForChild("Main") :: ScreenGui
local frame = Main:WaitForChild("Settings") :: GuiObject

local Holder = frame:WaitForChild("Holder") :: ScrollingFrame
local CloseButton = frame:WaitForChild("CloseButton") :: GuiButton

-- Comm
local UpdateRemote = Net:RemoteEvent('UpdateSetting')

-- Util
local function getSettingFrame(id: string): GuiObject?
	local currentFrame = Holder:FindFirstChild(`Frame_{id}`)
	if currentFrame and currentFrame:IsA("GuiObject") then
		return currentFrame
	end

	local directFrame = Holder:FindFirstChild(id)
	if directFrame and directFrame:IsA("GuiObject") then
		return directFrame
	end

	return nil
end

local function getSwitchContainer(container: Instance): Instance?
	local directToggle = container:FindFirstChild("TOGGLE")
	if directToggle then return directToggle end

	local directSwitch = container:FindFirstChild("Switch")
	if directSwitch then return directSwitch end

	local deepToggle = container:FindFirstChild("TOGGLE", true)
	if deepToggle then return deepToggle end

	local deepSwitch = container:FindFirstChild("Switch", true)
	if deepSwitch then return deepSwitch end

	return nil
end

local function getSwitchButton(switchContainer: Instance): GuiButton?
	if switchContainer:IsA("GuiButton") then
		return switchContainer
	end

	local trigger = switchContainer:FindFirstChild("Trigger")
	if trigger and trigger:IsA("GuiButton") then
		return trigger
	end

	local deepTrigger = switchContainer:FindFirstChild("Trigger", true)
	if deepTrigger and deepTrigger:IsA("GuiButton") then
		return deepTrigger
	end

	local firstButton = switchContainer:FindFirstChildWhichIsA("GuiButton", true)
	if firstButton then
		return firstButton
	end

	return nil
end

local function changeSwitchState(switchContainer: Instance, on: boolean)
	local buttonText = switchContainer:FindFirstChild("STATE")
	if not (buttonText and buttonText:IsA("TextLabel")) then
		buttonText = switchContainer:FindFirstChild("TextLabel")
	end
	if buttonText and buttonText:IsA("TextLabel") then
		buttonText.Text = on and "ON" or "OFF"
	end

	for _, obj in switchContainer:GetDescendants() do
		if not (
			obj:IsA('UIGradient')
				or obj:IsA('UIStroke')
		) then continue end

		if obj.Name == "On" or obj.Name == "OnGradient" then
			obj.Enabled = on
		elseif obj.Name == "Off" or obj.Name == "OffGradient" then
			obj.Enabled = not on
		end
	end
end

-- Class
local Settings = {}
Settings.__index = Settings

export type Class = typeof(setmetatable({} :: {
	_Name: string,
	_UIController: any,
	_Trove: Trove.Trove,
	_UI: Frame
}, Settings))

function Settings.new(controller: any): Class
	local self = setmetatable({}, Settings)
	
	local self = setmetatable({
		_Name = "Settings",
		_UIController = controller,
		_Trove = Trove.new(),
		_UI = frame :: any,
	}, Settings)

	task.spawn(self.Init, self)
	return self
end

function Settings.Init(self: Class)
	self._UI.Visible = false
	Template.Visible = false

	return true
end

function Settings.UpdateSetting(self: Class, id: string, to: boolean)
	local frame = getSettingFrame(id)
	if not frame then return end
	
	local switchContainer = getSwitchContainer(frame)
	if not switchContainer then return end
	
	changeSwitchState(switchContainer, to)
end

function Settings.ToggleSetting(self: Class, id: string)
	local settingData = SettingsData[id]
	if not settingData then return end

	local replica: ReplicaController.Replica = ReplicaController.GetReplica('PlayerData')
	local data = (replica and replica.Data) and replica.Data.Settings or nil
	
	local currValue = if data then data[id] else nil
	local fixedValue = if currValue~=nil then currValue else settingData.Default

	UpdateRemote:FireServer(id, not fixedValue)
end

function Settings._renderSettings(self: Class)
	local replica: ReplicaController.Replica = ReplicaController.GetReplica('PlayerData')
	local current = (replica and replica.Data) and replica.Data.Settings or nil

	for id, data in SettingsData do
		local settingFrame = getSettingFrame(id)
		if not settingFrame then
			local clone = self._Trove:Clone(Template) :: Frame
			clone.Name = `Frame_{id}`
			clone.Parent = Holder
			settingFrame = clone
		end

		settingFrame.LayoutOrder = data.Order or 0
		
		local nameLabel = settingFrame:FindFirstChild('SettingName')
		if nameLabel and nameLabel:IsA('TextLabel') then
			nameLabel.Text = id
		end
		
		local descLabel = settingFrame:FindFirstChild('SettingDescription')
		if descLabel and descLabel:IsA('TextLabel') then
			descLabel.Text = data.Description
		end
		
		local switchContainer = getSwitchContainer(settingFrame)
		if switchContainer then
			local value = if current then current[id] else nil
			changeSwitchState(switchContainer, if value~=nil then value else data.Default)

			local switchButton = getSwitchButton(switchContainer)
			if switchButton then
				self._Trove:Connect(switchButton.MouseButton1Click, function()
					task.spawn(Sounds.Play :: any, 'SFX/Interface/Switch')
					self:ToggleSetting(id)
				end)
			end
		end
		
		settingFrame.Visible = true
		settingFrame.Parent = Holder
	end
end

function Settings._setupConnections(self: Class)
	self._Trove:Connect(CloseButton.MouseButton1Click, function()
		self._UIController:Close(self._Name)
	end)
end

function Settings.OnOpen(self: Class)
	if self._Trove then
		self._Trove:Clean()
	end
	
	self:_renderSettings()
	self:_setupConnections()
end

function Settings.OnClose(self: Class)
	if self._Trove then
		self._Trove:Clean()
	end
end

return Settings
