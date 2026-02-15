--!strict
local ReplicatedStorage = game:GetService('ReplicatedStorage')
local ContextActionService = game:GetService('ContextActionService')
local RunService = game:GetService('RunService')
local Players = game:GetService('Players')

local Client = Players.LocalPlayer :: Player
local Beam = script.Beam

local Packages = ReplicatedStorage:WaitForChild('Packages')
local Trove = require(Packages.Trove)
local Observers = require(Packages.Observers)

local Controllers = ReplicatedStorage:WaitForChild('Controllers')
local UIController = require(Controllers.UIController)

-- Def
local Manager = {
	Loaded = {} :: {[Tool]: Class},
	Trove = Trove.new(),
}

local Class = {}
Class.__index = Class

export type Class = typeof(setmetatable({} :: {
	Tool: Tool,
	Trove: Trove.Trove,
}, Class))

-- Class
function Class.new(tool: Tool): Class
	local self: Class = setmetatable({
		Tool = tool,
		Trove = Trove.new(),
	}, Class)
	
	task.defer(self._Init, self)
	return self
end

function Class._Init(self: Class)
	-- Clean-up
	self.Trove:Add(self.Tool.AncestryChanged:Connect(function()
		if self.Tool.Parent then return end
		self:Destroy()
	end))
	
	self.Trove:Add(self.Tool.Destroying:Connect(function()
		self:Destroy()
	end))
	
	-- Cash
	self.Trove:Add(self.Tool:GetAttributeChangedSignal('Cash'):Connect(function()
		if not (
			Client.Character
			and self.Tool:IsDescendantOf(Client.Character)
			and UIController.Managers.DirtyCash
		) then return end
		
		UIController.Managers.DirtyCash.UpdateCount(self.Tool:GetAttribute('Cash'))
		Manager.DisplayGuide()
	end))
	
	-- Equipped
	self.Trove:Add(self.Tool.Equipped:Connect(function()
		if not UIController.Managers.DirtyCash then return end
		
		UIController.Managers.DirtyCash.Display(self.Tool:GetAttribute('Cash') or 0)
		Manager.DisplayGuide()
	end))
	
	-- Unequipped
	self.Trove:Add(self.Tool.Unequipped:Connect(function()
		if not UIController.Managers.DirtyCash then return end
		
		UIController.Managers.DirtyCash.Hide()
		Manager.HideGuide()
	end))
end

function Class.Destroy(self: Class)
	self.Trove:Destroy()
	
	UIController.Managers.DirtyCash.Hide()
	Manager.HideGuide()
	
	Manager.Loaded[self.Tool] = nil
	table.clear(self :: any)
end

-- Manager
function Manager.DisplayGuide()
	Beam.Enabled = true
end

function Manager.HideGuide()
	Beam.Enabled = false
end

function Manager.Load(tool: Tool)
	if Manager.Loaded[tool] then return end
	
	local new = Class.new(tool)
	Manager.Loaded[tool] = new
end

function Manager.Init()
	Beam.Enabled = false
	
	local waypoints = workspace:WaitForChild('_MapWaypoints_')
	local laundryWaypoint = waypoints:WaitForChild('Laundry')
	
	local att = Instance.new('Attachment')
		att.Name = '_Briefcase_Attachment'
		att.Parent = laundryWaypoint
	
	Beam.Attachment0 = att
	
	Observers.observeCharacter(function(player: Player, character: Model)
		if player ~= Client then return end
		
		local thread = task.spawn(function()
			local root = character.PrimaryPart
				or character:FindFirstChild('HumanoidRootPart')
			if not root then return end

			local att = root:FindFirstChild('RootAttachment')
			if not att then return end

			Beam.Parent = att :: any
			Beam.Attachment1 = att :: any
		end)
		
		return function()
			pcall(task.cancel, thread)
			Beam.Parent = script
		end :: any
	end)
end

task.spawn(Manager.Init)
return Manager