local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Red = require(ReplicatedStorage.Shared.Packages.Red)
local guard = require(ReplicatedStorage.Shared.Packages.Guard)

return Red.Event("SyncAtoms", function(...)
	return guard.Any(...)
end)
