local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Charm = require(ReplicatedStorage.Shared.Packages.Charm)
local CharmSync = require(ReplicatedStorage.Shared.Packages.CharmSync)
local Sift = require(ReplicatedStorage.Shared.Packages.Sift)

return Sift.Dictionary.flatten({
	["DataStore"] = Charm.atom({}),
})
