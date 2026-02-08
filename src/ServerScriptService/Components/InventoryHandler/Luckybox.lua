local ReplicatedStorage = game:GetService('ReplicatedStorage')

local Entities = require(ReplicatedStorage.DataModules.EntityCatalog)
local SharedFunctions = require(ReplicatedStorage.DataModules.SharedFunctions)
local SharedUtilities = require(ReplicatedStorage.Utilities.SharedUtilities)

local ToolTextureIds = {
	Common = "rbxassetid://112907692657841",
	Rare = "rbxassetid://121483848511026",
	Epic = "rbxassetid://77080096118745",
	Mythical = "rbxassetid://76552943471197",
	Legendary = "rbxassetid://125467504845882",
	Secret = "rbxassetid://138715737229887",
	Strawberry = "rbxassetid://81925461225579",
	SixSeven = "rbxassetid://94919913796612",
}

local TemplateTool = ReplicatedStorage.Assets.TemplateTool
local EQUIPPED_ENTITY_OFFSET = CFrame.new(0, 0, 2)

local function setupHeldPart(part: BasePart)
	part.CanCollide = false
	part.Massless = true
end

local function hideToolBillboard(entityModel: Model)
	local billboard = entityModel:FindFirstChildWhichIsA("BillboardGui", true)
	if not billboard then
		return
	end

	local cashLabel = billboard:FindFirstChild("CashLabel")
	if cashLabel and cashLabel:IsA("TextLabel") then
		cashLabel.Visible = false
		cashLabel.Text = ""
	end

	local nameLabel = billboard:FindFirstChild("NameLabel")
	if nameLabel and nameLabel:IsA("TextLabel") then
		nameLabel.Visible = false
	end
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

			hideToolBillboard(cloned)

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
			local textureId = ToolTextureIds[informations.name]
			if textureId then
				newTool.TextureId = textureId
			end

			SharedUtilities.createWeld(newTool.Handle, root, EQUIPPED_ENTITY_OFFSET)

			cloned.Parent = newTool
			return newTool
		end
	end
end
