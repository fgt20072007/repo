local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")

local Packages = ReplicatedStorage:WaitForChild("Packages")
local Debug = require(Packages:WaitForChild("Debug"))
local Observers = require(Packages:WaitForChild("Observers"))

local Util = ReplicatedStorage:WaitForChild("Util")
local Utility = require(Util.Utility)

local Player = Players.LocalPlayer
local PlayerGui = Player:WaitForChild("PlayerGui")

local Character = Player.Character or Player.CharacterAdded:Wait()
local Humanoid = Character:WaitForChild("Humanoid") :: Humanoid

local HUD = PlayerGui:WaitForChild("HUD") :: ScreenGui
local Main = PlayerGui:WaitForChild("Main") :: ScreenGui

local tweenInfo = TweenInfo.new(0.3, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)

local UIController = {
	Managers = {},
	_registry = {},
	_currentOpen = nil,
}

function UIController.Init()
	for _, des in script.Managers:GetChildren() do
		if not des:IsA('ModuleScript') then continue end
		
		local result = Utility:Require(des) 
		if not result then continue end
		
		if result.Init and des:HasTag('Init') then
			result.Init(UIController)
		end
		
		UIController.Managers[des.Name] = result
	end
		
	Observers.observeTag("UIController/Init", function(frame: GuiObject) --//initialize all uis
		if not frame:IsA("GuiObject") then return end
		UIController:_setupFrame(frame)
	end, {PlayerGui})
	
	--// ProximityPrompt Open UI
	Observers.observeTag("InterfacePrompt", function(ProximityPrompt: ProximityPrompt)
		ProximityPrompt.Triggered:Connect(function(player:Player)
			print("Triggered")
			if Player ~=  Player then return end
			
			local Interface = ProximityPrompt:GetAttribute("Interface")
			if not Interface then return end
			
			print("Oksss")
			UIController:Open(Interface)	
		end)
	end, {workspace})
end

function UIController:_setupFrame(frame: GuiObject)
	if not frame:IsA("GuiObject") then return end
	
	if self._registry[frame.Name] then return end
		
	local module = script.Frames:FindFirstChild(frame.Name)
	if not module then return end
	
	local result = Utility:Require(module)
	if not result then return end
	
	local object = result.new(self)
	if not object then return end
	
	local canRegister = self:_registerFrame(frame, object)
	if not canRegister then return end
end

function UIController:_registerFrame(frame, object)
	if not frame
		or not object
		or self._registry[frame.Name]
	then return false end
	
	self._registry[frame.Name] = {
		Frame = frame,
		Object = object
	}
	
	return true
end

function UIController:Open(frameName: string)
	if not frameName then return false end

	
	local entry = self._registry[frameName]
	if not entry then return false end
	if self._currentOpen and self._currentOpen == entry then return false end
	if self._currentOpen then self:Close(self._currentOpen.Frame.Name) end
	
	self._currentOpen = entry
	entry.Frame.Visible = true
	
	entry.Object:OnOpen()	
	return true
end

function UIController:Close(frameName: string)
	if not frameName then return false end

	local entry = self._registry[frameName]
	if not entry then return false end

	entry.Frame.Visible = false
	entry.Object:OnClose()

	if self._currentOpen == entry then
		self._currentOpen = nil
	end

	return true
end

function UIController:Toggle(frameName: string)
	if not frameName then return false end
	
	local entry = self._registry[frameName]
	if not entry then return false end
	
	if entry.Frame.Visible then
		self:Close(frameName)
		return true
	else
		self:Open(entry.Frame.Name)
		return true
	end
end

function UIController:GetClass(id: string)
	local entry = self._registry[id]
	return entry and entry.Object or nil
end

return UIController