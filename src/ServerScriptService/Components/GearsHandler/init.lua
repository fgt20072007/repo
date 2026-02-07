-- Services
local ReplicatedStorage = game:GetService('ReplicatedStorage')
local Players = game:GetService('Players')

-- Variables

-- Dependencies
local DataService = require(ReplicatedStorage.Utilities.DataService)
local Gears = require(ReplicatedStorage.DataModules.Gears)

local GearsHandler = {}

-- Initialization function for the script
function GearsHandler.CreateNewGear(player, gearname)
	local informations = Gears[gearname]
	if informations then
		local module = script:FindFirstChild(informations.Type)
		if module then
			local newModule = require(module)
			local newtool: Tool = informations.Tool:Clone()
			newtool.Parent = player.Backpack
			
			if informations.GearImage then
				newtool.TextureId = informations.GearImage
			end
			
			newModule(newtool, informations.ExtraInformations)
		end
	end
end

return GearsHandler
