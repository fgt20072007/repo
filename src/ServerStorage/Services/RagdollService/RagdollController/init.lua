--[[
local PhysicsService = game:GetService("PhysicsService")

local noclipgrouptest = pcall(function() PhysicsService:GetCollisionGroupId("noclip") end)
if not noclipgrouptest then
	PhysicsService:CreateCollisionGroup("noclip")
	PhysicsService:CollisionGroupSetCollidable("Default","noclip",false)
end]]

--> Dependencies
local BodyParts = require(script.BodypartData)
local ConstraintProperties = require(script.ConstraintData)

function ApplyConstraintProperties(Constraint, ConstraintTypeName)
	--if true then return end
	for PropertyName, PropertyValue in ConstraintProperties[ConstraintTypeName] do
		if PropertyName == "ConstraintName" then continue end
		Constraint[PropertyName] = PropertyValue 
	end
end

function getAccessoryAttachment0(Character, AttachmentName)
	for _,v in pairs(Character:GetChildren()) do
		local attachment = v:FindFirstChild(AttachmentName)
		if attachment then return attachment end
	end
end



local module = {}
module.__index = module

function module.new(Character:Model)
	local self = setmetatable({}, module)
	
	local ConstraintsFolder = Character:FindFirstChild("RagdollConstraints")
	if not ConstraintsFolder then ConstraintsFolder = Instance.new("Folder", Character); ConstraintsFolder.Name = "RagdollConstraints" end
	
	local ForcesFolder = Character:FindFirstChild("RagdollForces")
	if not ForcesFolder then ForcesFolder = Instance.new("Folder", Character); ForcesFolder.Name = "RagdollForces" end

	local CollisionFolder = Character:FindFirstChild("CollisionConstraints")
	if not CollisionFolder then CollisionFolder = Instance.new("Folder", Character); CollisionFolder.Name = "CollisionConstraints" end
	
	
	self.Instances = {}
	self.Motors = {}
	self.Enabled = false
	
	--> Create Constraints
	for BodyPartName, BodypartData in BodyParts do
		local BodyPart = Character:FindFirstChild(BodyPartName)
		local Motor3D = BodypartData.Motor and BodyPart:FindFirstChild(BodypartData.Motor)
		if not Motor3D then continue end
		
		local start_i, end_i = string.find(BodypartData.Motor, "Right")
		if not start_i then
			start_i, end_i = string.find(BodypartData.Motor, "Left")
		end
		
		if not BodypartData.Motor then continue end
		local ConstraintTypeName = start_i and string.sub(BodypartData.Motor, end_i + 1, -1) or BodypartData.Motor
		
		local AttachmentName = BodypartData.Motor.."RigAttachment"

		local ConstraintType = ConstraintProperties[ConstraintTypeName]
		if not ConstraintType then continue end
		
		local Constraint = Instance.new(ConstraintType.ConstraintName)
		Constraint.Attachment0 = Character:FindFirstChild(BodypartData.Part0):FindFirstChild(AttachmentName)
		Constraint.Attachment1 = BodyPart:FindFirstChild(AttachmentName)
		Constraint.LimitsEnabled = true
		
		--TODO: Only enable the limits when ragdolled
		if Constraint.ClassName ~= "HingeConstraint" then
			Constraint.TwistLimitsEnabled = true
		end
		
		Constraint.Enabled = true
		ApplyConstraintProperties(Constraint, ConstraintTypeName)
		Constraint.Parent = ConstraintsFolder
		
		table.insert(self.Instances, Constraint)
		table.insert(self.Motors, Motor3D)
		
		--> Collision Filters
		--[[
		if not BodypartData.CollisionFilter then continue end
		for _, BodyPartName in BodypartData.CollisionFilter do
			local PartB = Character:FindFirstChild(BodyPartName)
			
			local constraint = Instance.new("NoCollisionConstraint", CollisionFolder)
			constraint.Name = BodyPartName.."<->"..PartB.Name
			constraint.Part0 = BodyPart
			constraint.Part1 = PartB
			constraint.Parent = BodyPart
			
			table.insert(self.Instances, constraint)
		end	]]
	end
	
	--> Weld Accessories
	for _,v in pairs(Character:GetChildren()) do
		if not v:IsA("Accessory") then continue end
		local handle = v:FindFirstChild("Handle")
		if not handle then continue end
		handle.CustomPhysicalProperties = PhysicalProperties.new(0.0001,0,0,0,0)
		local attachment1 = handle:FindFirstChildOfClass("Attachment")
		local attachment0 = getAccessoryAttachment0(Character, attachment1.Name)
		if attachment1 and attachment0 then
			local con = Instance.new("HingeConstraint")
			con.Name = "Accessory_"..v.Name
			con.Attachment0 = attachment0
			con.Attachment1 = attachment1
			con.LimitsEnabled = true
			con.UpperAngle = 0
			con.LowerAngle = 0
			con.Parent = ConstraintsFolder
			table.insert(self.Instances, con)
		end
	end
	
	local altrootmotor = Instance.new("Motor6D",Character.UpperTorso)
	altrootmotor.C0 = CFrame.new(0,(Character.LowerTorso.Size.Y)*0.7,0)
	altrootmotor.Part0 = Character.HumanoidRootPart
	altrootmotor.Part1 = Character.UpperTorso
	altrootmotor.Enabled = false
	
	self.altRootMotor = altrootmotor
	
	Character.Head.Size = Character.Head.Size
	Character.HumanoidRootPart.CanCollide = false
	
	self.ConstraintFolder = ConstraintsFolder
	self.CollisionFolder = CollisionFolder
	self.Character = Character
	
	return self
end

function module:Enable()
	if self.Enabled then return end
	local Character = self.Character
	
	for _, Motor3D in self.Motors do
		Motor3D.Enabled = false
	end
	for BodyPartName, BodypartData in BodyParts do
		local BodyPart = Character:FindFirstChild(BodyPartName)
		local Motor3D = BodyPart and BodypartData.Motor and BodyPart:FindFirstChild(BodypartData.Motor)
		if not Motor3D then continue end
		
		Motor3D.Enabled = false
		--BodyPart.CanCollide = true
	end
	self.altRootMotor.Enabled = true
	
	--local GravityCounterForces
	
	
	local Humanoid:Humanoid = Character:FindFirstChild("Humanoid")
	if Humanoid then
		Humanoid:ChangeState(Enum.HumanoidStateType.Physics)
		Humanoid:UnequipTools()
		
		if Humanoid.SeatPart then
			Humanoid.Jump = true
			if Humanoid.SeatPart:FindFirstChild("SeatWeld") then
				Humanoid.SeatPart.SeatWeld:Destroy()
			end
		end
	end
	
	local ConstraintsFolder = Character:FindFirstChild("RagdollConstraints")
	local ForcesFolder = Character:FindFirstChild("RagdollForces")
	
	for _, Bodypart:MeshPart in Character:GetDescendants() do
		--print(Bodypart)
		if not (Bodypart:IsA("MeshPart") or Bodypart:IsA("Part")) then continue end

		local Attachment = Instance.new("Attachment")
		Attachment.Name = "GravityForce"
		Attachment.Parent = Bodypart

		--[[
		local VectorForce = Instance.new("VectorForce")
		--VectorForce.ApplyAtCenterOfMass = true
		VectorForce.RelativeTo = Enum.ActuatorRelativeTo.World
		VectorForce.Force = ( Vector3.yAxis * workspace.Gravity * Bodypart:GetMass() * .85) -- (Bodypart.AssemblyLinearVelocity.Y * Vector3.yAxis)
		VectorForce.Attachment0 = Attachment
		VectorForce.Enabled = true
		VectorForce.Visible = true
		VectorForce.Parent = ForcesFolder
		]]
		
		pcall(function()
			Bodypart:SetNetworkOwner(nil)
		end)
	end
	
	self.Enabled = true
end

function module:Disable()
	if not self.Enabled then return end
	
	local Character = self.Character
	local Humanoid:Humanoid = Character:FindFirstChild("Humanoid")
	if Humanoid then
		Humanoid:ChangeState(Enum.HumanoidStateType.GettingUp)
	end
	
	local Player = game.Players:GetPlayerFromCharacter(Character)
	
	Character:PivotTo(Character:GetPivot()+ Vector3.new(0, 1.5, 0))
	
	for BodyPartName, BodypartData in BodyParts do
		local BodyPart:Part = Character:FindFirstChild(BodyPartName)
		local Motor3D = BodypartData.Motor and BodyPart:FindFirstChild(BodypartData.Motor)
		if not Motor3D then continue end

		Motor3D.Enabled = true
		--BodyPart.CanCollide = false
		
		pcall(function()
			BodyPart:SetNetworkOwner(Player)
		end)
	end
	self.altRootMotor.Enabled = false
	
	local ForcesFolder:Folder = Character:FindFirstChild("RagdollForces")
	if ForcesFolder then
		ForcesFolder:ClearAllChildren()
	end
	
	self.Enabled = false
end

function module:Destroy()
	setmetatable(self, nil)
	table.clear(self)
	table.freeze(self)
end

return module