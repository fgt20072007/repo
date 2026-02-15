

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local SoundService = game:GetService("SoundService")
local Assets = ReplicatedStorage.Assets
local RagdollController = require(script.RagdollController)

local function SetCharacterNetworkOwner(Character:Model, NetworkOwner:Instance?)
	for _, Bodypart in Character:GetDescendants() do
		if not (Bodypart:IsA("MeshPart") or Bodypart:IsA("Part")) then continue end
		Bodypart:SetNetworkOwner(NetworkOwner)
	end
end

local ElectrocutedRuntimes = {}
local RagdollService = {}

function RagdollService:RemoveElectrocute(Player:Player)
	local Character = Player.Character
	if ElectrocutedRuntimes[Player] then task.cancel(ElectrocutedRuntimes[Player]) ElectrocutedRuntimes[Player] = nil end

	Player:SetAttribute("Electrocuted", false)

	local HumanoidRootPart = Character:FindFirstChild("HumanoidRootPart")
	local ElectricParticles = HumanoidRootPart and HumanoidRootPart:FindFirstChild("Electric")
	local ElectricSFX = HumanoidRootPart and HumanoidRootPart:FindFirstChild("Taser")
	if ElectricParticles then ElectricParticles:Destroy() end

	if ElectricSFX then ElectricSFX:Destroy() end
end

local ElectrocutionTime = 3
function RagdollService:AddElectrocute(Player:Player)
	local Character = Player.Character	
	if ElectrocutedRuntimes[Player] then RagdollService:RemoveElectrocute(Player) end

	ElectrocutedRuntimes[Player] = task.spawn(function()
		local Effect = Assets.Particles.Electric:Clone()
		Effect.Parent = Character.HumanoidRootPart

		local SFX = SoundService.SFX.Tools.Taser:Clone()
		SFX.Parent = Character.HumanoidRootPart
		SFX:Play()

		local BodyParts = {}
		--> Setup
		for _, Part in Character:GetChildren() do
			if not (Part:IsA("BasePart") or Part:IsA("MeshPart")) then continue end
			BodyParts[Part] = {
				Side = math.random(1, 2)
			}
		end
		local StarterTime = tick()
		--[[while true do
			for Part, PartData in BodyParts do
				local PositionOffset = Vector3.new(Part.Size.X * (PartData.Side == 2 and -1 or 1), 0, 0)
				--Part:ApplyImpulseAtPosition(Part.CFrame.LookVector * Part:GetMass() * .005 * (math.random(1, 2) == 1 and -1 or 1), PositionOffset)
				PartData.Side = PartData.Side == 1 and 2 or 1
			end
			task.wait(.125)
		end]]
	end)

	task.spawn(function()
		task.wait(ElectrocutionTime)
		RagdollService:RemoveElectrocute(Player)
		task.wait(.3)
		Player:SetAttribute("Ragdoll", false)
	end)
end

local function SetupListeners()
	game.Players.PlayerAdded:Connect(function(Player)
		Player:SetAttribute("Ragdoll", false)
		Player:SetAttribute("Electrocuted", false)

		Player.CharacterAdded:Connect(function(Character)
			local controller = RagdollController.new(Character)
			local Humanoid:Humanoid = Character:FindFirstChild("Humanoid")

			Humanoid:SetStateEnabled(Enum.HumanoidStateType.FallingDown, false)

			local RagdollAttributeChanged = Player:GetAttributeChangedSignal("Ragdoll"):Connect(function()
				local RagdollAttribute = Player:GetAttribute("Ragdoll")
				local Character = Player.Character
				local Humanoid:Humanoid = Character and Character:FindFirstChild("Humanoid")
				if RagdollAttribute then					
					controller:Enable()
				else
					controller:Disable()
				end
			end)

			local ElectrocutedAttributeChanged = Player:GetAttributeChangedSignal("Electrocuted"):Connect(function()
				local ElectrocutedAttribute = Player:GetAttribute("Electrocuted")
				if ElectrocutedAttribute then
					--> Add
					RagdollService:AddElectrocute(Player)
				else
					--> Remove
					RagdollService:RemoveElectrocute(Player)
				end
			end)

			Humanoid.Died:Once(function()
				controller:Enable()

				RagdollAttributeChanged:Disconnect()
				ElectrocutedAttributeChanged:Disconnect()

				--SetCharacterNetworkOwner(Character, Player)
			end)


			for _, Bodypart in Character:GetDescendants() do
				if not (Bodypart:IsA("MeshPart") or Bodypart:IsA("Part")) then continue end
			end
		end)
	end)
end


function RagdollService.Init()
	SetupListeners()
end

return RagdollService