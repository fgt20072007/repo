local Entities = require(script.Parent.Entities)
local Brainrots = require(script.Parent.Brainrots)

local Catalog = {}

for entityName, entityData in Entities do
	Catalog[entityName] = entityData
end

for brainrotName, brainrotData in Brainrots do
	if not Catalog[brainrotName] then
		Catalog[brainrotName] = brainrotData
	end
end

return Catalog