local SortControllers = {}



local FilterInteractions = {}

for _, Module:ModuleScript in script:GetChildren() do
	SortControllers[Module.Name] = require(Module)
end

local module = {}
function module:CreateFilterInteraction(Frame:Frame, FilterOptions: {[string]: {string}})
	local SortType = Frame:GetAttribute("SortType")
	if not SortControllers[SortType] then return end
	
	FilterInteractions[Frame] = SortControllers[SortType]:Setup(Frame, FilterOptions)
	
	return FilterInteractions[Frame]
end

function module:RemoveFilterInteraction(Frame)
	local SortType = Frame:GetAttribute("SortType")
	if not SortControllers[SortType] then return end
	
	local FilterData = FilterInteractions[Frame]
	if not FilterData then return end
	
	SortControllers[SortType]:Clear(FilterData)
	
	for _, Connection:RBXScriptConnection in FilterData.Connections do
		Connection:Disconnect()
	end
	
	FilterInteractions[Frame] = nil
	
	return true
end

return module
