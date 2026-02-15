local module = {}
module._TrackingTools = {}


local function ToggleFlashlight(Tool:TOol, Activated:boolean)
	local ToolModel = Tool:FindFirstChild("ToolModel")
	local LightPart = ToolModel:FindFirstChild("Light")
	
	LightPart.Start.Attachment.BillboardGui.Enabled = Activated
	LightPart.SurfaceLight.Enabled = Activated
	LightPart.Beam.Enabled = Activated
	
	LightPart.Color = Activated and Color3.new(1, 1, 1) or Color3.new(0, 0, 0)
end


module.Signals = {
	["Activated"] = function(Tool:Tool)
		local Activated = Tool:GetAttribute("Activated")
		ToggleFlashlight(Tool, Activated)
	end,
}


module.InstanceAdded = function(Tool:Tool)
	--print("Tool Added")
end

module.InstanceRemoved = function(Tool:Tool)
	--print("Tool Removed")
end

return module
