local ReplicatedStorage = game:GetService('ReplicatedStorage')

local Entities = require(ReplicatedStorage.DataModules.EntityCatalog)
local SharedFunctions = require(ReplicatedStorage.DataModules.SharedFunctions)
local SharedUtilities = require(ReplicatedStorage.Utilities.SharedUtilities)
local DataService = require(ReplicatedStorage.Utilities.DataService)

local TemplateTool = ReplicatedStorage.Assets.TemplateTool
local EQUIPPED_ENTITY_OFFSET = CFrame.new(0, 0, 2)

local function setupHeldPart(part: BasePart)
	part.CanCollide = false
	part.Massless = true
end

return function(informations: {name: string, mutation: string, traits: {string}?}, guid)
	local NewTool = TemplateTool:Clone()
	local Handle = NewTool:FindFirstChild("Handle")
	if Handle and Handle:IsA("BasePart") then
		setupHeldPart(Handle)
	end

	local EntityInformations = Entities[informations.name]
	if EntityInformations then
		local Model = select(1, SharedFunctions.GetEntityVariantModel(informations.name, informations.mutation))
		if Model then
			local Cloned: Model = SharedFunctions.CreateEntity(informations.name, informations.mutation, true, informations.upgradeLevel, informations.traits)
			if not Cloned then
				return
			end

			local root = Cloned.PrimaryPart or Cloned:FindFirstChild("HumanoidRootPart")
			if not root then
				return
			end

			for _, v in Cloned:GetDescendants() do
				if v:IsA("BasePart") then
					setupHeldPart(v)
					v.Anchored = false
					v.CustomPhysicalProperties = PhysicalProperties.new(0.01, 0, 0, 0, 0)
				end
			end
			Cloned:PivotTo(NewTool.Handle.CFrame)

			NewTool.Name = informations.mutation .. " " .. informations.name
			NewTool:SetAttribute("Id", guid)

			SharedUtilities.createWeld(NewTool.Handle, root, EQUIPPED_ENTITY_OFFSET)

			Cloned.Parent = NewTool
			return NewTool
		end
	end
end