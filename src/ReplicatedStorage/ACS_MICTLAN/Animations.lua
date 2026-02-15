local TS = game:GetService("TweenService")
local Anims = {

	FiremodeAnim = function(char,speed,objs)
		
		TS:Create(objs[2], TweenInfo.new(.12,Enum.EasingStyle.Sine), {C1 = (CFrame.new(-.7,0.05,.85) * CFrame.Angles(math.rad(110),math.rad(-15),math.rad(25))):inverse() }):Play()
		wait(0.16)
		TS:Create(objs[2], TweenInfo.new(.18,Enum.EasingStyle.Sine), {C1 = (CFrame.new(-.7,-0.05,.9) * CFrame.Angles(math.rad(110),math.rad(-15),math.rad(25))):inverse() }):Play()
		wait(0.2)
	end,
	
	ProneBeginAnim = function(char,speed,objs)
		TS:Create(objs[1],TweenInfo.new(1,Enum.EasingStyle.Back),{C1 = (CFrame.new(0.4,-0.5,1) * CFrame.Angles(math.rad(95), math.rad(0), math.rad(0))):inverse() }):Play()
		TS:Create(objs[2], TweenInfo.new(.4,Enum.EasingStyle.Sine), {C1 = (CFrame.new(-1.4,-0.6,0) * CFrame.Angles(math.rad(50),math.rad(5),math.rad(0))):inverse() }):Play()	
		wait(.5)
		TS:Create(objs[2], TweenInfo.new(.4,Enum.EasingStyle.Sine), {C1 = (CFrame.new(-1.2,-0.4,-0.3) * CFrame.Angles(math.rad(90),math.rad(5),math.rad(0))):inverse() }):Play()	
wait(0.3)
	end,
	
	ProneStandUpAnim = function(char,speed,objs)
		TS:Create(objs[1],TweenInfo.new(1,Enum.EasingStyle.Back),{C1 = (CFrame.new(0,-0.5,1) * CFrame.Angles(math.rad(95), math.rad(0), math.rad(0))):inverse() }):Play()
		TS:Create(objs[2], TweenInfo.new(.5,Enum.EasingStyle.Sine), {C1 = (CFrame.new(-2,-1,1) * CFrame.Angles(math.rad(50),math.rad(0),math.rad(0))):inverse() }):Play()	
		wait(.3)
	end,
}

return Anims
