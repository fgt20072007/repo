local CollectionService = game:GetService('CollectionService')

for _, v in CollectionService:GetTagged("Sine") do
	local angle = 0
	local starterPivot = v:GetPivot()
	game:GetService("RunService").RenderStepped:Connect(function(dt)
		angle += dt 
		v:PivotTo(starterPivot * CFrame.new(0, math.sin(angle), 0) * CFrame.Angles(0, math.rad(math.cos(angle) * 10), math.rad(math.sin(angle) * 15)))
	end)
end

for _, v in CollectionService:GetTagged("Rotating") do
	local angle = 0
	local starterPivot = v:GetPivot()
	game:GetService("RunService").RenderStepped:Connect(function(dt)
		angle += dt 
		v:PivotTo(starterPivot * CFrame.new(0, math.sin(angle), 0) * CFrame.Angles(0, math.rad(angle * 12), 0))
	end)
end

