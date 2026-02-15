local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")

local Packages = ReplicatedStorage:WaitForChild("Packages")
local Observers = require(Packages:WaitForChild("Observers"))

local Player = Players.LocalPlayer
local Character = Player.Character or Player.CharacterAdded:Wait()
local HumanoidRootPart = Character:WaitForChild("HumanoidRootPart") :: BasePart

local characterAttachment = HumanoidRootPart:FindFirstChild("RootAttachment") :: Attachment

local testAttachment = workspace.testPart.Attachment

local Civilian = {}
Civilian.__index = Civilian

function Civilian.new(controller: any)
	local self = setmetatable({}, Civilian)
	self._controller = controller
	self._IsFirstJoin = true
	self._Step = nil
		
	
	self:_startTutorial()
	return self
end

function Civilian:_startTutorial()
	if not self._IsFirstJoin then return end
	if not characterAttachment then return end
	
	
	
	self:_firstStep()
	
end

function Civilian:_firstStep()
	
	self._controller:displayMessage("Welcome! Since you are a new player im going to guide you")
	task.wait(2)
	self._controller:displayMessage("Lets go and spawn a car!")
	
	self._controller:applyBeam(characterAttachment, testAttachment)
	
end

return Civilian