local RunService = game:GetService("RunService")
local IsClient = RunService:IsClient()

local VelocityManager = {}

function VelocityManager.ApplyLinearVelocity(Direction: Vector3, Force: number, Victim: Part | Model)
	local IsModel = Victim.ClassName == "Model"

	if IsModel and Victim.PrimaryPart then
		Victim = Victim.PrimaryPart
	elseif IsModel and not Victim.PrimaryPart then
		warn(`Primary part is not set on {Victim}.`)
		return
	end

	assert(Victim.ClassName == "Part", "Invalid victim supplied")

	Victim.AssemblyLinearVelocity = Direction * Force * Victim.AssemblyMass
end

function VelocityManager.Fling(Character: Model, Force: number)
	local primaryPart = Character.PrimaryPart

	if not primaryPart then
		warn(`No primary part set for {Character}`)
		return
	end

	local direction = (-primaryPart.CFrame.LookVector + Vector3.new(0, 0.5, 0))
	primaryPart.AssemblyLinearVelocity = direction * Force * primaryPart.AssemblyMass
end

return VelocityManager
