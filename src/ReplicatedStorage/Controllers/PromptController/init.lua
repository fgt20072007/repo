--!strict
local ProximityPromptService = game:GetService 'ProximityPromptService'

local Highlight = script.Highlight

-- Util
local function GetObjectValue(from: Instance): ObjectValue?
	local found = (from.Parent or from):QueryDescendants('ObjectValue #Highlight')
	return #found > 0 and found[1] :: any or nil
end

-- Manager
local Manager = {
	LockedBy = {} :: {string},
}

function Manager.LockFrom(id: string)
	if table.find(Manager.LockedBy, id) then return end

	table.insert(Manager.LockedBy, id)
	ProximityPromptService.Enabled = false
end

function Manager.UnlockFrom(id: string)
	local index = table.find(Manager.LockedBy, id)
	if not index then return end
	
	table.remove(Manager.LockedBy, index)
	ProximityPromptService.Enabled = #Manager.LockedBy <= 0
end

function Manager.OnShown(prompt: ProximityPrompt)
	local objValue = GetObjectValue(prompt)
	if not objValue then return end
	
	Highlight.OutlineColor = objValue:GetAttribute("OutlineColor") or Color3.new(1, 1, 1)
	Highlight.FillColor = objValue:GetAttribute("FillColor") or Color3.new(1, 1, 1)
	Highlight.FillTransparency = objValue:GetAttribute("FillTransparency") or 1
	
	Highlight.Adornee = objValue.Value
end

function Manager.OnHidden(prompt: ProximityPrompt)
	local objValue = GetObjectValue(prompt)
	if not objValue or objValue.Value ~= Highlight.Adornee then return end
	Highlight.Adornee = nil
end

function Manager.Init()
	ProximityPromptService.PromptShown:Connect(Manager.OnShown)
	ProximityPromptService.PromptHidden:Connect(Manager.OnHidden)
end

table.freeze(Manager)
return Manager