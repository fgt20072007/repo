--!strict
--!native
--!optimize 2

--// Services
local Players = game:GetService 'Players'
local RunService = game:GetService 'RunService'
local PhysicsService = game:GetService 'PhysicsService'
local ReplicatedStorage = game:GetService 'ReplicatedStorage'

--// Constants
local vector3_zero = Vector3.zero

local cframe_offset1 = CFrame.Angles(0, -math.pi, 0)

--// Structure
local Structure = {}

function Structure:Build(Chassis: Model)
	local Primary = Chassis.PrimaryPart
	if not Primary then return end

	local DataModule = Chassis:FindFirstChild 'Data' :: ModuleScript
	if not DataModule then return end

	local Data = require(DataModule) :: any

	local Wheels = Instance.new 'Folder'
	Wheels.Name = 'Wheels'

	for _, Child in Primary:GetChildren() do
		if Child:IsA 'Attachment' then
			local Wheel = ReplicatedStorage.Assets.Wheel:Clone()
			Wheel.Name = Child.Name

			if Wheel.PrimaryPart then
				Wheel.PrimaryPart.Anchored = false
			end

			for _, Descendant in Wheel:GetDescendants() do
				if Descendant:IsA 'BasePart' then
					Descendant.CanCollide = true
					Descendant.CollisionGroup = 'Vehicles'
				end
			end

			local Motor6D = Instance.new 'Motor6D'
			Motor6D.Part0 = Wheel.PrimaryPart
			Motor6D.Part1 = Primary

			local FreeLength = string.sub(Wheel.Name, 1, 1) == 'F' and Data.FrontFreeLength or Data.RearFreeLength

			if string.sub(Wheel.Name, 2, 2) == 'L' then
				Motor6D.C1 = Child.CFrame - Vector3.new(0, FreeLength, 0)
			else
				Motor6D.C1 = Child.CFrame*cframe_offset1 - Vector3.new(0, FreeLength, 0)
			end

			Motor6D.Parent = Wheel.PrimaryPart

			Wheel.Parent = Wheels
		end
	end

	Wheels.Parent = Chassis

	Primary:SetNetworkOwnershipAuto()
	Primary.CustomPhysicalProperties = PhysicalProperties.new(
		Data.Weight/(Primary.Size.X*Primary.Size.Y*Primary.Size.Z),
		0, 0, 0, 100
	)

	local Body = Chassis:WaitForChild 'Body'
	for _, Descendant in Body:GetDescendants() do
		if Descendant:IsA 'BasePart' then
			local Weld = Instance.new 'WeldConstraint'
			Weld.Part0 = Descendant
			Weld.Part1 = Primary
			Weld.Parent = Descendant

			Descendant.Anchored = false
			Descendant.Massless = false
		end
	end

	local Seats = Chassis:WaitForChild 'Seats'
	for _, Descendant in Seats:GetDescendants() do
		if Descendant:IsA 'BasePart' then
			local Weld = Instance.new 'WeldConstraint'
			Weld.Part0 = Descendant
			Weld.Part1 = Primary
			Weld.Parent = Descendant

			Descendant.Anchored = false
			Descendant.Massless = false
		end
	end

	local Collision = Chassis:WaitForChild 'Collision'
	for _, Descendant in Collision:GetDescendants() do
		if Descendant:IsA 'BasePart' then
			local Weld = Instance.new 'WeldConstraint'
			Weld.Part0 = Descendant
			Weld.Part1 = Primary
			Weld.Parent = Descendant

			Descendant.Anchored = false
			Descendant.Massless = false

			Descendant.CollisionGroup = 'Vehicles'
		end
	end

	Primary.Anchored = false

	local Attachment = Instance.new 'Attachment'
	Attachment.Name = 'Gravity'
	Attachment.Parent = Primary

	local Force = Instance.new 'VectorForce'
	Force.Attachment0 = Attachment
	Force.RelativeTo = Enum.ActuatorRelativeTo.World
	Force.Force = Vector3.new(0, Data.Gravity > 0 and Primary.AssemblyMass*(workspace.Gravity - Data.Gravity) or 0, 0)
	Force.Parent = Attachment

	local Drive = Seats:FindFirstChildOfClass 'VehicleSeat'
	if not Drive then return end

	local Ownership = nil
	Drive:GetPropertyChangedSignal 'Occupant':Connect(function()
		local Occupant = Drive.Occupant
		if Occupant then
			if Drive:GetAttribute 'Driven' then return end

			local Player = Players:GetPlayerFromCharacter(Occupant.Parent :: Model)
			if not Player then return end

			for _, Wheel in Wheels:GetChildren() do
				for _, Descendant in Wheel:GetDescendants() do
					if Descendant:IsA 'BasePart' then
						Descendant.CanCollide = false
					end
				end
			end

			Drive:SetAttribute('Driven', true)
			Chassis:AddTag(`VehicleStepper_{Player.UserId}`)

			Primary:SetNetworkOwner(Player)
			Ownership = Player
		else
			Drive:SetAttribute('Driven', nil)
			for _, Tag in Chassis:GetTags() do Chassis:RemoveTag(Tag) end

			for _, Wheel in Wheels:GetChildren() :: {any} do
				local Attachment = Primary:FindFirstChild(Wheel.Name) :: Attachment
				if Attachment then
					local Motor6D = Wheel.PrimaryPart:FindFirstChildOfClass 'Motor6D'
					if Motor6D then
						local FreeLength = string.sub(Wheel.Name, 1, 1) == 'F' and Data.FrontFreeLength or Data.RearFreeLength

						if string.sub(Wheel.Name, 2, 2) == 'L' then
							Motor6D.C1 = Attachment.CFrame - Vector3.new(0, FreeLength, 0)
						else
							Motor6D.C1 = Attachment.CFrame*cframe_offset1 - Vector3.new(0, FreeLength, 0)
						end
					end
				end

				for _, Descendant in Wheel:GetDescendants() do
					if Descendant:IsA 'BasePart' then
						Descendant.CanCollide = true
					end
				end
			end

			Primary:SetNetworkOwner(nil)
			Ownership = nil
		end
	end)

	task.spawn(function()
		while Primary:IsDescendantOf(workspace) do
			if Ownership then
				Primary:SetNetworkOwner(Ownership)
			else
				Primary:SetNetworkOwner(nil)
				Primary.AssemblyLinearVelocity = vector3_zero
				Primary.AssemblyAngularVelocity = vector3_zero
			end

			task.wait(0.5)
		end
	end)
end

return Structure