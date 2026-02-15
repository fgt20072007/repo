
local ReplicatedStorage = game:GetService('ReplicatedStorage')
local Players = game:GetService('Players')

local Client = Players.LocalPlayer :: Player

local Util = ReplicatedStorage:WaitForChild('Util')
local Utility = require(Util.Utility)
local CoreGui = game:GetService("StarterGui")


local Packages = ReplicatedStorage:WaitForChild("Packages")
local Satchel = require(Packages:WaitForChild("Satchel"))

local CharConnection: RBXScriptConnection?

local ToolController = {
	Managers = {} :: {[string]: GenericManager},

	BackpackDisabledCases = {
		PlayerDetained = false,
		PlayerRagdoll = false,
		PlayerReloading = false
	}
}

type GenericManager = {
	Load: (tool: Tool) -> any,
}

function ToolController.OnToolAdded(tool: Tool)
	local manager = ToolController.Managers[tool.Name]
	if not manager then return end

	manager.Load(tool)
end

function ToolController._OnAdded(inst: Instance)
	if not inst:IsA('Tool') then return end
	ToolController.OnToolAdded(inst)
end

function ToolController._BindCharacter(character: Model)	
	for _, inst in character:GetChildren() do
		ToolController._OnAdded(inst)
	end

	CharConnection = character.ChildAdded:Connect(ToolController._OnAdded)
end

function ToolController._UnBindCharacter()
	if CharConnection then
		CharConnection:Disconnect()
		CharConnection = nil
	end
end



function ToolController:CompareDisableCases()
	local Disabled = false
	local ShouldUnequip = false

	for caseName, case in ToolController.BackpackDisabledCases do
		if case then
			Disabled = true
			if caseName ~= "PlayerReloading" then ShouldUnequip = true end
		end
	end

	if ShouldUnequip then
		local Character = Client.Character
		local Humanoid = Character and Character:FindFirstChildOfClass("Humanoid")
		if Humanoid then
			Humanoid:UnequipTools()
		end
	end

	Satchel:SetBackpackEnabled(not Disabled)
end


function ToolController.Init()
	for _, des in script:GetChildren() do
		if not des:IsA('ModuleScript') then continue end

		local safeRequire = Utility:Require(des)
		if not safeRequire then continue end

		ToolController.Managers[des.Name] = safeRequire
	end

	do
		local current = Client.Backpack:GetChildren()
		Client.Backpack.ChildAdded:Connect(ToolController._OnAdded)

		for _, inst in current do
			ToolController._OnAdded(inst)
		end
	end

	local hasChar = Client.Character
	if hasChar then
		ToolController._BindCharacter(hasChar)
	end

	Client.CharacterAdded:Connect(ToolController._BindCharacter)
	Client.CharacterRemoving:Connect(ToolController._UnBindCharacter)

	local function RagdollAttributeChanged()
		local Attribute = Client:GetAttribute("Ragdoll")
		ToolController.BackpackDisabledCases["PlayerRagdoll"] = Attribute
		ToolController:CompareDisableCases()
	end
	Client:GetAttributeChangedSignal("Ragdoll"):Connect(RagdollAttributeChanged)
	RagdollAttributeChanged()

	local function ArrestAttributeChanged()
		local Attribute = Client:GetAttribute("Detained")
		ToolController.BackpackDisabledCases["PlayerDetained"] = (Attribute == "Detained" or Attribute == "Arrested") and true or false
		ToolController:CompareDisableCases()
	end
	Client:GetAttributeChangedSignal("Detained"):Connect(ArrestAttributeChanged)
	ArrestAttributeChanged()

end

return ToolController