local walking = false
local walkanimcf = CFrame.new()

game.Players.LocalPlayer.Character.Humanoid.Running:Connect(function(speed)
	if speed >= 6 then
		walking = true
	else
		walking = false		
	end	
end)

game:GetService("RunService"):BindToRenderStep('camera woosh',1999,function() --haha bite of 87 xdd x3
	if walking then	
		local speed = game.Players.LocalPlayer.Character.Humanoid.WalkSpeed / 3
		walkanimcf = walkanimcf:lerp(CFrame.new(0.03 * math.sin(tick() * (2 * speed)), 0.01 * -math.cos(tick() * (4 * speed)), 0) * CFrame.Angles(0, 0, -.01 * math.sin(tick() * (2 * speed))), .2)
	else
		walkanimcf = walkanimcf:lerp(CFrame.new(), .05)
	end		
	workspace.CurrentCamera.CFrame = workspace.CurrentCamera.CFrame * walkanimcf	
end)