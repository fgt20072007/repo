return function(viewportFrame: ViewportFrame)
	local worldModel = Instance.new("WorldModel")
	worldModel.Parent = viewportFrame

	local camera = Instance.new("Camera")
	camera.Parent = viewportFrame
	viewportFrame.CurrentCamera = camera
	
	camera.CFrame = CFrame.lookAt(Vector3.new(0, 0, -12), Vector3.new(0,0,0))
	
	return viewportFrame
end