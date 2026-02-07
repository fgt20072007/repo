-- Services
local ReplicatedStorage = game:GetService('ReplicatedStorage')
local Players = game:GetService('Players')
local CollectionService = game:GetService('CollectionService')

-- Variables

-- Dependencies
local DataService = require(ReplicatedStorage.Utilities.DataService)

local KillbrickHandler = {}
local killbirckDebounces = {}

local function bindKillbirck(v)
	v.Touched:Connect(function(hit: BasePart)
		local char = hit.Parent
		if char then
			local Player = Players:GetPlayerFromCharacter(char)
			if Player then
				if killbirckDebounces[Player] then return end
				killbirckDebounces[Player] = true
				local humanoid = Player.Character:FindFirstChildOfClass("Humanoid")
				if humanoid.Health > 0 then
					humanoid.Health = 0
				end
				task.delay(0.5, function()
					killbirckDebounces[Player] = nil
				end)
			end
		end
	end)
end

-- Initialization function for the script
function KillbrickHandler:Initialize()
	workspace.DescendantAdded:Connect(function(v)
		if v:IsA("BasePart") and v:HasTag("KillBrick") then
			bindKillbirck(v)
		end
	end)
	
	for i, v in CollectionService:GetTagged("KillBrick") do
		bindKillbirck(v)
	end
end

return KillbrickHandler
