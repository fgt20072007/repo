local CameraUtils = require(script.CameraUtils)

local function isValidAnimationId(animationId)
	return typeof(animationId) == "string" and string.match(animationId, "^rbxassetid://%d+$") ~= nil
end

return function(Model, ViewportFrame, Animation)
	ViewportFrame:ClearAllChildren()
	if not Model or not Model:IsA("Model") then
		return ViewportFrame
	end

	local WolrdModel = Instance.new("WorldModel")
	WolrdModel.Parent = ViewportFrame

	local ModelClone = Model:Clone()
	ModelClone:PivotTo(CFrame.new(0,0,0))
	ModelClone.Parent = WolrdModel

	local Camera = Instance.new("Camera")
	Camera:PivotTo(CFrame.lookAt(CameraUtils:GetCameraPositionForModel(ModelClone, 70), Vector3.zero))
	Camera.Parent = ViewportFrame
	ViewportFrame.CurrentCamera = Camera

	if isValidAnimationId(Animation) then
		local animationInstance = Instance.new("Animation")
		animationInstance.AnimationId = Animation
		local Humanoid = ModelClone:FindFirstChildWhichIsA("Humanoid") or ModelClone:FindFirstChildWhichIsA("AnimationController")
		if Humanoid then
			local Animator = Humanoid:FindFirstChildWhichIsA("Animator")
			if Animator then
				local AnimationTrack = Animator:LoadAnimation(animationInstance)
				AnimationTrack:Play()
			end
		end
	end

	return ViewportFrame
end