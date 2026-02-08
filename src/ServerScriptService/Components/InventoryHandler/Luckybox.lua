local ReplicatedStorage = game:GetService('ReplicatedStorage')

local Entities = require(ReplicatedStorage.DataModules.EntityCatalog)
local SharedFunctions = require(ReplicatedStorage.DataModules.SharedFunctions)
local SharedUtilities = require(ReplicatedStorage.Utilities.SharedUtilities)

local TemplateTool = ReplicatedStorage.Assets.TemplateTool
local EQUIPPED_ENTITY_OFFSET = CFrame.new(0, 0, 2)

local function setupHeldPart(part: BasePart)
	part.CanCollide = false
	part.Massless = true
end

return function(informations: {name: string, mutation: string, traits: {string}?}, guid)
	local newTool = TemplateTool:Clone()
	local handle = newTool:FindFirstChild("Handle")
	if handle and handle:IsA("BasePart") then
		setupHeldPart(handle)
	end

	local entityInformations = Entities[informations.name]
	if entityInformations then
		local model = select(1, SharedFunctions.GetEntityVariantModel(informations.name, informations.mutation))
		if model then
			local cloned = SharedFunctions.CreateEntity(informations.name, informations.mutation, true, informations.upgradeLevel, informations.traits)
			if not cloned then
				return
			end

			local root = cloned.PrimaryPart or cloned:FindFirstChild("HumanoidRootPart")
			if not root then
				return
			end

			for _, v in cloned:GetDescendants() do
				if v:IsA("BasePart") then
					setupHeldPart(v)
					v.Anchored = false
					v.CustomPhysicalProperties = PhysicalProperties.new(0.01, 0, 0, 0, 0)
				end
			end
			cloned:PivotTo(newTool.Handle.CFrame)

			newTool.Name = informations.name
			newTool:SetAttribute("Id", guid)
			newTool:SetAttribute("IsLuckyBox", true)

			SharedUtilities.createWeld(newTool.Handle, root, EQUIPPED_ENTITY_OFFSET)

			cloned.Parent = newTool
			return newTool
		end
	end
end
