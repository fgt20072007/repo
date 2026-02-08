local ReplicatedStorage = game:GetService('ReplicatedStorage')

local Entities = require(ReplicatedStorage.DataModules.EntityCatalog)
local SharedFunctions = require(ReplicatedStorage.DataModules.SharedFunctions)
local LuckyBoxes = require(ReplicatedStorage.DataModules.LuckyBoxes)
local SharedUtilities = require(ReplicatedStorage.Utilities.SharedUtilities)
local DataService = require(ReplicatedStorage.Utilities.DataService)

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
local SharedFunctionsModule = ReplicatedStorage.DataModules:FindFirstChild("SharedFunctions")
local EntityBillboardTemplate = if SharedFunctionsModule then SharedFunctionsModule:FindFirstChild("EntityBillboardTemplate") else nil
local SpaceTemplate = if EntityBillboardTemplate then EntityBillboardTemplate:FindFirstChild("Space") else nil
local EQUIPPED_ENTITY_OFFSET = CFrame.new(0, 0, 2)

local function setupHeldPart(part: BasePart)
	part.CanCollide = false
	part.Massless = true
end

local function setupToolBillboard(entityModel: Model, shouldHideLabels: boolean)
	local billboard = entityModel:FindFirstChildWhichIsA("BillboardGui", true)
	if not billboard then
		return
	end

	if not shouldHideLabels then
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

local function expandBillboardOnEquip(tool: Tool, entityModel: Model)
	tool.Equipped:Connect(function()
		local billboard = entityModel:FindFirstChildWhichIsA("BillboardGui", true)
		if not billboard or billboard:GetAttribute("EquippedSpaceExpanded") then
			return
		end

		local sourceSpace = SpaceTemplate
		if not sourceSpace then
			sourceSpace = billboard:FindFirstChild("Space")
		end
		if not sourceSpace then
			return
		end

		for _ = 1, 2 do
			local clonedSpace = sourceSpace:Clone()
			clonedSpace.Parent = billboard
		end

		billboard:SetAttribute("EquippedSpaceExpanded", true)
	end)
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

			local isLuckyBlockEntity = LuckyBoxes.IsLuckyBox(informations.name)
			setupToolBillboard(Cloned, isLuckyBlockEntity)

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
			local textureId = ToolTextureIds[informations.name]
			if textureId then
				NewTool.TextureId = textureId
			end
			expandBillboardOnEquip(NewTool, Cloned)

			SharedUtilities.createWeld(NewTool.Handle, root, EQUIPPED_ENTITY_OFFSET)

			Cloned.Parent = NewTool
			return NewTool
		end
	end
end
