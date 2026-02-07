-- Services
local ReplicatedStorage = game:GetService('ReplicatedStorage')
local Players = game:GetService('Players')

-- Variables
local SelectionBox = script.SelectionBox

-- Dependencies
local DataService = require(ReplicatedStorage.Utilities.DataService)

local HighlightClientController = {}
local BoundingCache = {}

function HighlightClientController.HighlightElement(Basepart: BasePart)
	local newHighlight = SelectionBox:Clone()
	newHighlight.Parent = Basepart
	newHighlight.Adornee = Basepart
	
	table.insert(BoundingCache, newHighlight)
end

function HighlightClientController.RemoveHighlights()
	for _, v in BoundingCache do
		v:Destroy()
	end
end

return HighlightClientController
