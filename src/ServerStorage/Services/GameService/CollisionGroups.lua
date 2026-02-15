local ReplicatedStorage = game:GetService("ReplicatedStorage")
local PhysicsService = game:GetService("PhysicsService")

local Packages = ReplicatedStorage.Packages
local Observers = require(Packages.Observers)

local Groups = {
	Car = {"Car", "Prop"},
	Prop = {"Prop"},
	Character = {"Wheels"},
	Wheels = {"Wheels"}
}

local RegisteredGroups = {}

local CollisionGroups = {}

function CollisionGroups.Init()
	CollisionGroups:_setupObserver()
	CollisionGroups:_registerCollisionGroups()
end

function CollisionGroups:_setupObserver()
	Observers.observeCharacter(function(player: Player, character: Model)
		if not player or not character then return end

		for _, part in character:QueryDescendants("BasePart") do
			part.CollisionGroup = "Character"
		end

		local conn = character.DescendantAdded:Connect(function(descendant: Instance)
			if not descendant:IsA("BasePart") then return end
			descendant.CollisionGroup = "Character"
		end)

		return function()
			conn:Disconnect()
		end
	end)
end

function CollisionGroups:_registerCollisionGroups()
	for index in Groups do
		if RegisteredGroups[index] then continue end
		PhysicsService:RegisterCollisionGroup(index)
		table.insert(RegisteredGroups, index)
	end

	CollisionGroups:_setCollidables()
end

function CollisionGroups:_setCollidables()
	PhysicsService:CollisionGroupSetCollidable("Car", "Prop", false)
	PhysicsService:CollisionGroupSetCollidable("Car", "Character", false)
	PhysicsService:CollisionGroupSetCollidable("Wheels", "Car", false)
	PhysicsService:CollisionGroupSetCollidable("Character", "Character", false)
end

return CollisionGroups