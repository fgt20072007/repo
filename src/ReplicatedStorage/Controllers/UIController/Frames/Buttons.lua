local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")

local Packages = ReplicatedStorage:WaitForChild("Packages")
local Debug = require(Packages:WaitForChild("Debug"))
local Trove = require(Packages:WaitForChild("Trove"))
local Observers = require(Packages:WaitForChild("Observers"))

local Util = ReplicatedStorage:WaitForChild("Util")
local Utility = require(Util.Utility)

local Player = Players.LocalPlayer
local PlayerGui = Player:WaitForChild("PlayerGui")

local HUD = PlayerGui:WaitForChild("HUD") :: ScreenGui
local ButtonsUI = HUD:WaitForChild("Buttons") :: Frame
local Holder = ButtonsUI:WaitForChild("Holder") :: Frame

local Buttons = {}
Buttons.__index = Buttons

function Buttons.new(controller: any)
	local self = setmetatable({}, Buttons)
	
	self._registryButtons = {}
	self._Trove = Trove.new()
	self._uiController = controller
	
	task.defer(function()
		self:_init()
	end)
	
	return self
end

function Buttons:_init()
	
	Observers.observeTag("Buttons/Side", function(button: GuiButton)
		self:_setupButton(button)
	end, {PlayerGui})
	
end

function Buttons:_setupButton(button: GuiButton)
	if not button:IsA("GuiButton") then return end
	
	if self._registryButtons[button] then return end
	self._registryButtons[button] = button

	self._Trove:Connect(button.MouseButton1Click, function()
		self._uiController:Toggle(button.Name)
	end)
end

return Buttons