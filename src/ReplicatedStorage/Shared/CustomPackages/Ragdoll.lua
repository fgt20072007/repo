local RunService = game:GetService("RunService")
local RunContext = RunService:IsServer()
local RagdollHinges = require(script.Parent.RagdollHinges)

local noCollisionMap = {
	R15 = {
		Head = { "LeftUpperArm", "LeftUpperLeg", "LowerTorso", "RightUpperArm", "RightUpperLeg" },
		LeftFoot = { "LowerTorso", "UpperTorso" },
		LeftHand = { "LowerTorso", "UpperTorso" },
		RightFoot = { "LowerTorso", "UpperTorso" },
		RightHand = { "LowerTorso", "UpperTorso" },
		LeftLowerArm = { "LowerTorso", "UpperTorso" },
		LeftLowerLeg = { "LowerTorso", "UpperTorso" },
		LeftUpperArm = { "LeftUpperLeg", "LowerTorso", "UpperTorso", "RightUpperArm", "RightUpperLeg" },
		LeftUpperLeg = { "LowerTorso", "UpperTorso", "RightUpperLeg" },
		RightLowerArm = { "LowerTorso", "UpperTorso" },
		RightLowerLeg = { "LowerTorso", "UpperTorso" },
		RightUpperArm = { "RightUpperLeg", "LowerTorso", "UpperTorso", "LeftUpperLeg" },
		RightUpperLeg = { "LowerTorso", "UpperTorso" },
	},

	R6 = {
		Head = { "Left Arm", "Left Leg", "Torso", "Right Arm", "Right Leg" },
	},
}

local function getMotors(character): { Motor6D }
	local t: { Motor6D } = {}

	for _, part in character:GetChildren() do
		for _, descendant in part:GetChildren() do
			if descendant:IsA("Motor6D") then
				t[#t + 1] = descendant
			end
		end
	end

	return t
end

-- create NoCollisionConstraints so the character doesn't fling
local function createNoCollisionConstraints(character, rigTypeName)
	for i, subMap in noCollisionMap[rigTypeName] do
		for _, x in subMap do
			local noCollision = Instance.new("NoCollisionConstraint")
			noCollision.Name = "RagdollNoCollide"
			noCollision.Part0 = character[i]
			noCollision.Part1 = character[x]
			noCollision.Parent = character
		end
	end
end

local RagdollService = {
	CharacterMotors = {},
}

local function createJoints(character)
	if not character:IsA("Model") or not character:FindFirstChildOfClass("Humanoid") then
		return
	end

	local rigType = character.Humanoid.RigType
	local motors = getMotors(character)

	createNoCollisionConstraints(character, rigType.Name)

	for _, motor in motors do
		local a0, a1 = Instance.new("Attachment"), Instance.new("Attachment")
		a0.Name, a1.Name = "RagdollConstraint", "RagdollConstraint"
		a0.CFrame = motor.C0
		a1.CFrame = motor.C1
		a0.Parent = motor.Part0
		a1.Parent = motor.Part1

		local name = motor.Name:gsub("Right", "")
		name = name:gsub("Left", "")
		name = name:gsub("Joint", "")
		name = name:gsub(" ", "")

		local b = (RagdollHinges[rigType.Name]:FindFirstChild(name) or RagdollHinges[rigType.Name].Default):Clone()
		b.Name = "RagdollConstraint"

		b.Attachment0 = a0
		b.Attachment1 = a1
		b.Parent = motor.Part1
	end

	RagdollService.CharacterMotors[character] = motors

	return motors
end

local function destroyJoints(character)
	for _, descendant: Instance in character:GetDescendants() do
		-- Remove BallSockets and NoCollides, leave the additional Attachments
		if
			(descendant:IsA("Constraint") or descendant:IsA("WeldConstraint") or descendant:IsA("Attachment"))
				and descendant.Name == "RagdollConstraint"
			or descendant:IsA("NoCollisionConstraint") and descendant.Name == "RagdollNoCollide"
		then
			descendant:Destroy()
		end
	end
end

local function setMotorsEnabled(motors: { Motor6D }, enabled: boolean)
	if not motors then
		return
	end

	for _, motor in motors do
		motor.Enabled = enabled
	end
end

function RagdollService.Ragdoll(character)
	local rootPart: BasePart = character.PrimaryPart
	local humanoid: Humanoid = character:FindFirstChild("Humanoid")

	if not rootPart or not humanoid then
		return
	end

	local motors = createJoints(character)

	setMotorsEnabled(motors, false)

	humanoid.AutoRotate = false
	rootPart.CanCollide = false
	character.Head.CanCollide = true

	if RunContext and character.PrimaryPart:GetNetworkOwner() then
		return
	end

	if humanoid.Health > 0 and humanoid:GetState() ~= Enum.HumanoidStateType.Physics then
		humanoid:ChangeState(Enum.HumanoidStateType.Physics)
	end
end

function RagdollService.CancelRagdoll(character)
	destroyJoints(character)

	setMotorsEnabled(RagdollService.CharacterMotors[character], true)

	local humanoid = character:FindFirstChild("Humanoid")

	if not humanoid then
		return
	end

	if humanoid.Health > 0 then
		humanoid.AutoRotate = true
		character.PrimaryPart.CanCollide = true
		character.Head.CanCollide = false

		if RunContext and character.PrimaryPart:GetNetworkOwner() then
			return
		end

		if humanoid:GetState() ~= Enum.HumanoidStateType.GettingUp then
			humanoid:ChangeState(Enum.HumanoidStateType.GettingUp)
		end
	end
end

return RagdollService
