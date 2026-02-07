-- model  by CatLeoYT XD --

local Tool = script.Parent
local speedforsmoke = 10

local CoilSound = Tool.Handle:WaitForChild("CoilSound")

function MakeSmoke(HRP, Human)
	smoke=Instance.new("Smoke")
	smoke.Enabled=HRP.Velocity.magnitude>speedforsmoke
	smoke.RiseVelocity=2
	smoke.Opacity=.25
	smoke.Size=.5
	smoke.Parent=HRP
	Human.Running:connect(function(speed)
		if smoke and smoke~=nil then
			smoke.Enabled=speed>speedforsmoke
		end
	end)
end

Tool.Equipped:connect(function()
	local Handle = Tool:WaitForChild("Handle")
	local HRP = Tool.Parent:FindFirstChild("HumanoidRootPart")
	local Human = Tool.Parent:FindFirstChild("Humanoid")
	CoilSound:Play()
	Human.WalkSpeed = Human.WalkSpeed * Tool.SpeedBoostScript.SpeedMultiplier.Value
	MakeSmoke(HRP, Human)
end)

Tool.Unequipped:connect(function()
	local plrChar = Tool.Parent.Parent.Character
	local HRP = plrChar.HumanoidRootPart
	if HRP:FindFirstChild("Smoke") then
		HRP.Smoke:Destroy()
	end
	plrChar.Humanoid.WalkSpeed = plrChar.Humanoid.WalkSpeed / Tool.SpeedBoostScript.SpeedMultiplier.Value
end)