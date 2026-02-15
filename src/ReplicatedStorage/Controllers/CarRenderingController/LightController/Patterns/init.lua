local Patterns = {}

--> Startup
for _, Module in script:GetChildren() do
	if Patterns[Module.Name] then continue end
	Patterns[Module.Name] = require(Module)
end

return Patterns