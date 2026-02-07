local ReplicatedStorage = game:GetService('ReplicatedStorage')

local Entities = require(ReplicatedStorage.DataModules.Entities)
local SharedFunctions = require(ReplicatedStorage.DataModules.SharedFunctions)
local SharedUtilities = require(ReplicatedStorage.Utilities.SharedUtilities)
local DataService = require(ReplicatedStorage.Utilities.DataService)

local TemplateTool = ReplicatedStorage.Assets.TemplateTool

return function(informations: {name: string, mutation: string, traits: {string}?}, guid)
	local NewTool = TemplateTool:Clone()
	local EntityInformations = Entities[informations.name]
	if EntityInformations then
		local Model = EntityInformations.Model:FindFirstChild(informations.mutation)
		if Model then
			local Cloned: Model = SharedFunctions.CreateEntity(informations.name, informations.mutation, true, informations.upgradeLevel, informations.traits)
			local root = Cloned.PrimaryPart or Cloned:FindFirstChild("HumanoidRootPart")
			if not root then warn("No root was found in entity") return end
			
			for _, v in Cloned:GetDescendants() do if v:IsA("BasePart") then v.CanCollide = false v.Anchored = false v.Massless = true v.CustomPhysicalProperties = PhysicalProperties.new(0.01, 0, 0, 0, 0) end end
			Cloned:PivotTo(NewTool.Handle.CFrame)
			
			NewTool.Name = informations.mutation .. " " .. informations.name
			NewTool:SetAttribute("Id", guid)
			
			local newWeld = SharedUtilities.createWeld(NewTool.Handle, root)
			
			Cloned.Parent = NewTool
			return NewTool
		end
	end
end