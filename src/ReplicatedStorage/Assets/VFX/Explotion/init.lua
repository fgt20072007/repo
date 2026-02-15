--!strict
local ReplicatedStorage = game:GetService "ReplicatedStorage"
local Sounds = require(ReplicatedStorage.Util.Sounds)

local Template = script.Template

local module = {}

function module.Run(position: Vector3)
	if not position then return end
	
	local new = Template:Clone()
		new.Name = `_{script.Name}`
		new.Position = position
		new.Parent = (workspace.CurrentCamera or workspace) :: any
	
	for _, child in new:GetChildren() do
		if not child:IsA("ParticleEmitter") then continue end
		child:Emit()
	end

	Sounds.PlayAt('SFX/Interactions/C4/Explosion', position)
	task.delay(2, new.Destroy, new)
end

return module
