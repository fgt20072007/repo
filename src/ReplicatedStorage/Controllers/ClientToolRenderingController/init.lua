
--> Services
local CollectionService = game:GetService("CollectionService")
local RunService = game:GetService("RunService")

local module = {}

local ToolControllers = {}
local TrackingTools = {}

local function UntrackTool(Tool:Tool)
	local ToolData = TrackingTools[Tool]
	if not ToolData then return end

	for _, RBXScriptConnection:RBXScriptConnection in ToolData.Connections do
		RBXScriptConnection:Disconnect()
	end
	TrackingTools[Tool] = nil
	
	local TrackingModule = ToolControllers[Tool.Name]
	if TrackingModule then
		ToolControllers[Tool.Name].InstanceRemoved(Tool)
	end

	return true
end

local function TrackTool(Tool:Tool, Init:boolean)
	if ToolControllers[Tool] then return end
	if not (Tool.Parent.Name == "Backpack" or game.Players:GetPlayerFromCharacter(Tool.Parent)) then return end
	
	local TrackingModule = ToolControllers[Tool.Name]
	
	local ToolData = {
		Connections = {}
	}
	
	for Tracking:string, TrackingFunction in TrackingModule.Signals do
		table.insert(ToolData.Connections, Tool:GetAttributeChangedSignal(Tracking):Connect(function()
			TrackingFunction(Tool)
		end))
		
		if Init then
			TrackingFunction(Tool)
		end
	end
	TrackingTools[Tool] = ToolData
	
	ToolControllers[Tool.Name].InstanceAdded(Tool)
	return ToolData
end

local Flashlights = {}

function module.Init()
	--> Prepare tool controllers
	
	print("INIT")
	for _, ToolControllerModule:ModuleScript in script:GetChildren() do
		if not ToolControllerModule:IsA("ModuleScript") then continue end
		
		local ControllerName = ToolControllerModule.Name
		ToolControllers[ControllerName] = require(ToolControllerModule)
		
		CollectionService:GetInstanceAddedSignal(ControllerName):Connect(function(Tool:Tool)
			TrackTool(Tool)
		end)

		CollectionService:GetInstanceRemovedSignal(ControllerName):Connect(function(Tool:Tool)
			UntrackTool(Tool)
		end)

		for _, Tool:Tool in CollectionService:GetTagged(ControllerName) do
			TrackTool(Tool, true)
		end
	end
end

return module
