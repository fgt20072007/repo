local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Shared = ReplicatedStorage.Shared

local Index = {}
Index.__index = Index

function Index.new(IndexFrame: Frame)
	local self = setmetatable({
		IndexFrame = IndexFrame,
	}, Index)

	return self
end

function Index:LoadPetsAsync()
	local AllPets = require(Shared.Data.Eggs.AllPets)

	local MainFrame = self.IndexFrame:WaitForChild("MainFrame")
	local PetsTab = MainFrame.Container:WaitForChild("PetsTab")
	local PetTemplate = PetsTab.Pets:WaitForChild("PetTemp")

	for _, pet in AllPets do
		local templateClone = PetTemplate:Clone()
		templateClone.Name = pet.Name
		templateClone.Visible = true
		templateClone.Parent = PetTemplate.Parent
	end
end

return Index
