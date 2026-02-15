local RS = game:GetService("RunService")
local Camera = workspace.CurrentCamera

local DistFunctions = {
	[Enum.FieldOfViewMode.Vertical.Name] = function()
		return Camera.ViewportSize.Y, Camera.FieldOfView
	end,
	
	[Enum.FieldOfViewMode.Diagonal.Name] = function()
		return Camera.ViewportSize.Magnitude, Camera.DiagonalFieldOfView
	end,
	
	[Enum.FieldOfViewMode.MaxAxis.Name] = function()
		local vp = Camera.ViewportSize
		return math.max(vp.X, vp.Y), Camera.MaxAxisFieldOfView
	end,
}

local EstimatedThreads = 0

local module = {}

module.New = function(Bullet, Color, Width, Life, LightEmit, FullTracer, Texture)
	EstimatedThreads += 1
	
	local Att1 = Instance.new("Attachment")
	Att1.Name = "Att1"
	Att1.Position = Vector3.new(Width, 0, 0)

	local Att2  = Instance.new("Attachment")
	Att2.Name = "Att2"
	Att2.Position = Vector3.new(-Width, 0, 0)
	
	local Trail = Instance.new("Trail")
	
		Trail.Transparency = NumberSequence.new({
			NumberSequenceKeypoint.new(0, 0);
			NumberSequenceKeypoint.new(1, 0);
		})
	Trail.WidthScale = NumberSequence.new({
		NumberSequenceKeypoint.new(0, 0);
		NumberSequenceKeypoint.new(0.25, .35);
		NumberSequenceKeypoint.new(0.25, .35);
		NumberSequenceKeypoint.new(1, 0.5);
		})
	

	Trail.Texture = Texture or "rbxassetid://232918622" --"rbxassetid://4107607856"
	Trail.TextureMode = Enum.TextureMode.Stretch
	Trail.Color = Color

	Trail.FaceCamera = true
	Trail.LightEmission = LightEmit
	
	Trail.Lifetime = .04
	Trail.Attachment0 = Att1
	Trail.Attachment1 = Att2
	
	Att1.Parent = Bullet
	Att2.Parent = Bullet
	Trail.Parent = Bullet
	
end

module.GetThreads = function()
	return EstimatedThreads
end

return module
