local trampoline = script.Parent
local BOOST = 120 -- fuerza del salto (sube si quieres más)

local debounce = {}

trampoline.Touched:Connect(function(hit)
	local character = hit.Parent
	local humanoid = character:FindFirstChildOfClass("Humanoid")
	local root = character:FindFirstChild("HumanoidRootPart")

	if not humanoid or not root then return end
	if debounce[character] then return end
	debounce[character] = true

	-- Crear LinearVelocity
	local attachment = Instance.new("Attachment")
	attachment.Parent = root

	local velocity = Instance.new("LinearVelocity")
	velocity.Attachment0 = attachment
	velocity.MaxForce = math.huge
	velocity.VectorVelocity = Vector3.new(0, BOOST, 0)
	velocity.RelativeTo = Enum.ActuatorRelativeTo.World
	velocity.Parent = root

	-- limpiar después
	task.delay(0.3, function()
		velocity:Destroy()
		attachment:Destroy()
	end)

	task.delay(0.8, function()
		debounce[character] = nil
	end)
end)
