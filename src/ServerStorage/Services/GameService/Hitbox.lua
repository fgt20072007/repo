local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")

local Packages = ReplicatedStorage.Packages
local Observers = require(Packages.Observers)

local BLACKLIST_REVISION = table.freeze {
	'Wanted', 'Hostile'
}
local WHITELIST_REVISION = table.freeze {
	'Approved', 'Secondary'
}

local Characters = {}
local SpatialQuery = {}

local function IsApproved(player: Player): boolean
	if player.Team and player.Team:HasTag("Federal") then return true end
	return player:GetAttribute("Revision") == 'Approved'
end

local function HasAnyCheck(player: Player): boolean
	if player.Team and player.Team:HasTag("Federal") then
		return true
	end

	local state = player:GetAttribute("Revision")
	return table.find(WHITELIST_REVISION, state)~= nil
end

local function Verify(part: BasePart, func: (Player) -> boolean): (boolean, Player?)
	if not part then return false, nil end

	if not (part.Name == "HumanoidRootPart") then return false, nil end

	local player = Players:GetPlayerFromCharacter(part.Parent)
	if not player then return false, nil end

	if table.find(BLACKLIST_REVISION, player:GetAttribute("Revision")) then
		return false, nil
	end

	if func(player) then return false, nil end
	return true, player
end

function SpatialQuery:SetupHitboxes()
	Observers.observeTag("StrongBorderHitbox", function(part: BasePart)
		if not part then return end
		part.Transparency = 1

		part.Touched:Connect(function(part: BasePart)
			local succ, player = Verify(part, IsApproved)
			if not succ then return end

			player:SetAttribute("Revision", "Wanted")
		end)
	end)

	Observers.observeTag("MidBorderHitbox", function(part: BasePart)
		if not part then return end
		part.Transparency = 1

		part.Touched:Connect(function(part: BasePart)
			local succ, player = Verify(part, HasAnyCheck)
			if not succ then return end

			player:SetAttribute("Revision", "Wanted")
		end)
	end)
end

function SpatialQuery:SetupListeners()
	Players.PlayerAdded:Connect(function(player: Player)
		if player.Character then 
			table.insert(Characters, player.Character)
		end

		player.CharacterAdded:Connect(function(character: Model)
			table.insert(Characters, character)
		end)

		player.CharacterRemoving:Connect(function(character: Model)
			local index = table.find(Characters, character)
			if not index then return end
			table.remove(Characters, index)
		end)
	end)

	Players.PlayerRemoving:Connect(function(player: Player)
		local index = player.Character and table.find(Characters, player.Character) or nil
		if not index then return end
		table.remove(Characters, index)
	end)
end

function SpatialQuery.Init()
	SpatialQuery:SetupHitboxes()
	SpatialQuery:SetupListeners()
end

return SpatialQuery