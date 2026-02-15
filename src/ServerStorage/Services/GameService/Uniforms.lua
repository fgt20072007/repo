local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerStorage = game:GetService("ServerStorage")

local Packages = ReplicatedStorage.Packages
local Observers = require(Packages.Observers)

local Uniforms = {}

local function DeleteClothes(character: Model)
	for _, v in character:GetChildren() do
		if v:IsA("Shirt") or v:IsA("Pants") then
			v:Destroy()
		end
	end
end


function Uniforms.Init() 
	Observers.observeTag("UniformClick", function(uniform: Model)
		if not uniform then
			return
		end
		
		local clickDetector = uniform:FindFirstChildOfClass("ClickDetector")
		if not clickDetector then
			return
		end
		
		local Shirt = uniform:FindFirstChild("Shirt")
		local Pants = uniform:FindFirstChild("Pants")
		if not Shirt or not Pants then
			return
		end		
		local Team = uniform:GetAttribute("Team")
		local Faction = uniform:GetAttribute("Faction")
		
		
		clickDetector.MouseClick:Connect(function(player: Player)
			if Team and Team ~= player.Team.Name then
				return
			end
			
			if Faction and not player.Team:HasTag(Faction) then
				return
			end
		
			if not player then
				return
			end
			
			local character = player.Character
			if not character then
				return
			end
			
			DeleteClothes(character)
			
			local ShirtClone = Shirt:Clone()
			local PantsClone = Pants:Clone()
			
			ShirtClone.Parent = character
			PantsClone.Parent = character
			
			
		end)
		
		
	end)
end

return Uniforms