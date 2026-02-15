local TS = game:GetService('TweenService')
local equipped = false
local self = {}

self.MainCFrame 	= CFrame.new(0.5,-0.8,-0.75)

self.GunModelFixed 	= true
self.GunCFrame 		= CFrame.new(0.15, -.2, .85) * CFrame.Angles(math.rad(90),math.rad(0),math.rad(0))
self.LArmCFrame 	= CFrame.new(-0.5,-0.45,-1) * CFrame.Angles(math.rad(110),math.rad(45),math.rad(30))
self.RArmCFrame 	= CFrame.new(0.1,-0.1,1) * CFrame.Angles(math.rad(90),math.rad(0),math.rad(0))

self.EquipAnim = function(objs)
	
	if equipped == true then
		TS:Create(objs[1], TweenInfo.new(.25,Enum.EasingStyle.Linear), {C1 = (CFrame.new(1,-1,1) * CFrame.Angles(math.rad(0),math.rad(0),math.rad(0))):inverse() }):Play()
		TS:Create(objs[2], TweenInfo.new(.25,Enum.EasingStyle.Linear), {C1 = (CFrame.new(-1,-1,1) * CFrame.Angles(math.rad(0),math.rad(0),math.rad(0))):inverse() }):Play()
		wait(.25)
		TS:Create(objs[1], TweenInfo.new(.35,Enum.EasingStyle.Sine), {C1 = self.RArmCFrame:Inverse()}):Play()
		TS:Create(objs[2], TweenInfo.new(.35,Enum.EasingStyle.Sine), {C1 = self.LArmCFrame:Inverse()}):Play()
		wait(.35)

	elseif equipped == false then
		TS:Create(objs[1], TweenInfo.new(0.3,Enum.EasingStyle.Linear), {C1 = (CFrame.new(1,-1,1) * CFrame.Angles(math.rad(0),math.rad(0),math.rad(0))):Inverse() }):Play()
		TS:Create(objs[2], TweenInfo.new(0.3,Enum.EasingStyle.Linear), {C1 = (CFrame.new(-1,-1,1) * CFrame.Angles(math.rad(0),math.rad(0),math.rad(0))):Inverse() }):Play()

		wait(0.3)
		objs[4].Handle.ShoulderEquip:Play()	
		TS:Create(objs[1], TweenInfo.new(.3,Enum.EasingStyle.Sine), {C1 = self.RArmCFrame:Inverse()}):Play()
		TS:Create(objs[2], TweenInfo.new(.3,Enum.EasingStyle.Sine), {C1 = self.LArmCFrame:Inverse()}):Play()
		wait(0.3)
		local Weld = Instance.new("WeldConstraint",objs[4])
		Weld.Part0 = objs[4].Handle
		Weld.Part1 = objs[5]["Left Arm"]

		objs[3].Part0 = nil
		TS:Create(objs[1],TweenInfo.new(.25,Enum.EasingStyle.Sine),{C1 = (CFrame.new(0.35,.2,0.25) * CFrame.Angles(math.rad(110),math.rad(0),math.rad(-15))):Inverse() }):Play()
		TS:Create(objs[2], TweenInfo.new(.3,Enum.EasingStyle.Sine),{C1 = (CFrame.new(-0.5,-0.4,-1) * CFrame.Angles(math.rad(120),math.rad(60),math.rad(30))):Inverse() }):Play()
		wait(0.3)	
		objs[6]:accelerate(Vector3.new(0,0,2))

		objs[4].Bolt.SlidePull:Play()
		TS:Create(objs[2], TweenInfo.new(.3,Enum.EasingStyle.Back),{C1 = (CFrame.new(-0.45,-0.4,-.85) * CFrame.Angles(math.rad(120),math.rad(60),math.rad(33))):Inverse() }):Play()
		TS:Create(objs[4].Handle.Slide, TweenInfo.new(.1,Enum.EasingStyle.Back), {C0 =  CFrame.new(0,0,-0.6):inverse() }):Play()
		TS:Create(objs[1],TweenInfo.new(.3,Enum.EasingStyle.Back),{C1 = (CFrame.new(0.4,0,.9) * CFrame.Angles(math.rad(110),math.rad(0),math.rad(-25))):Inverse() }):Play()
		wait(0.2)
		objs[6]:accelerate(Vector3.new(0,0,3))
		TS:Create(objs[1],TweenInfo.new(.4,Enum.EasingStyle.Back),{C1 = (CFrame.new(0.35,0,1.3) * CFrame.Angles(math.rad(110),math.rad(0),math.rad(-25))):Inverse() }):Play()
		TS:Create(objs[4].Handle.Slide, TweenInfo.new(.05,Enum.EasingStyle.Linear), {C0 =  CFrame.new():Inverse() }):Play()
		wait(0.15)

		objs[4].Bolt.SlideRelease:Play()
		TS:Create(objs[1], TweenInfo.new(.25,Enum.EasingStyle.Sine), {C1 = self.RArmCFrame:Inverse()}):Play()
		TS:Create(objs[2], TweenInfo.new(.3,Enum.EasingStyle.Sine), {C1 = self.LArmCFrame:Inverse()}):Play()
		wait(0.25)
		objs[3].Part0 = objs[5]["Right Arm"]
		Weld:Destroy()
		equipped = true
	end
end;
self.IdleAnim = function(objs)
	TS:Create(objs[1], TweenInfo.new(.3,Enum.EasingStyle.Sine), {C1 = self.RArmCFrame:Inverse()}):Play()
	TS:Create(objs[2], TweenInfo.new(.3,Enum.EasingStyle.Sine), {C1 = self.LArmCFrame:Inverse()}):Play()
end;

self.LowReady = function(objs)
	TS:Create(objs[1],TweenInfo.new(.25,Enum.EasingStyle.Sine),{C1 = (CFrame.new(0.05,-0.15,1) * CFrame.Angles(math.rad(65), math.rad(0), math.rad(0))):inverse() }):Play()
	TS:Create(objs[2],TweenInfo.new(.25,Enum.EasingStyle.Sine),{C1 = (CFrame.new(-.6,-0.75,-.25) * CFrame.Angles(math.rad(85),math.rad(15),math.rad(15))):inverse() }):Play()
	wait(0.25)	
end;

self.HighReady = function(objs)
	TS:Create(objs[1],TweenInfo.new(.25,Enum.EasingStyle.Sine),{C1 = (CFrame.new(0.35,-0.75,1) * CFrame.Angles(math.rad(135), math.rad(0), math.rad(0))):inverse() }):Play()
	TS:Create(objs[2],TweenInfo.new(.25,Enum.EasingStyle.Sine),{C1 = (CFrame.new(-.2,-0.15,0.25) * CFrame.Angles(math.rad(155),math.rad(35),math.rad(15))):inverse() }):Play()
	wait(0.25)	
end;

self.Patrol = function(objs)
	TS:Create(objs[1], TweenInfo.new(.25,Enum.EasingStyle.Sine), {C1 = (CFrame.new(.75,-0.15,0) * CFrame.Angles(math.rad(90),math.rad(20),math.rad(-75))):inverse() }):Play()
	TS:Create(objs[2], TweenInfo.new(.25,Enum.EasingStyle.Sine), {C1 = (CFrame.new(-1.15,-0.75,0.4) * CFrame.Angles(math.rad(90),math.rad(20),math.rad(25))):inverse() }):Play()	
	wait(.25)	
end;

self.SprintAnim = function(objs)                                    --all cframe    --up/down                    --less = tilt down
	TS:Create(objs[1], TweenInfo.new(.25,Enum.EasingStyle.Sine), {C1 = (CFrame.new(.44,-0.3,.7) * CFrame.Angles(math.rad(90),math.rad(20),math.rad(-25))):inverse() }):Play()
	TS:Create(objs[2], TweenInfo.new(.25,Enum.EasingStyle.Sine), {C1 = (CFrame.new(-.6,-0.80,-.68) * CFrame.Angles(math.rad(125),math.rad(45),math.rad(-25))):inverse() }):Play()	
	wait(.25)                                                              --left/right         --more = back                         --spin           --tilt angle / more = tilt to right
end;    

self.ReloadAnim = function(objs)
	TS:Create(objs[1],TweenInfo.new(.25,Enum.EasingStyle.Sine),{C1 = (CFrame.new(0.1,-0.1,1) * CFrame.Angles(math.rad(90), math.rad(-5), math.rad(0))):inverse() }):Play()
	TS:Create(objs[2],TweenInfo.new(.25,Enum.EasingStyle.Sine),{C1 = (CFrame.new(-0.4,-0.7,0.1) * CFrame.Angles(math.rad(110), math.rad(15), math.rad(15))):inverse() }):Play()
wait(.3)
	TS:Create(objs[4].Handle.Mag, TweenInfo.new(.15,Enum.EasingStyle.Sine), {C1 = (CFrame.new(0,0,-.2) * CFrame.Angles(math.rad(25),math.rad(0),math.rad(0))):Inverse() }):Play()
	objs[4].Handle.MagOut:Play() 
	TS:Create(objs[2],TweenInfo.new(.2,Enum.EasingStyle.Sine),{C1 = (CFrame.new(-0.4,-.95,-0.4) * CFrame.Angles(math.rad(125), math.rad(15), math.rad(15))):inverse() }):Play()
wait(.3)
	
	TS:Create(objs[4].Handle.Mag, TweenInfo.new(.3,Enum.EasingStyle.Sine), {C1 = (CFrame.new(-.5,-1,.3) * CFrame.Angles(math.rad(25),math.rad(0),math.rad(0))):Inverse() }):Play()
	TS:Create(objs[2],TweenInfo.new(.4,Enum.EasingStyle.Sine),{C1 = (CFrame.new(-1.3,-3,-.6) * CFrame.Angles(math.rad(140), math.rad(20), math.rad(15))):inverse() }):Play()
wait(.4)
	objs[4].Handle.MagPouch:Play()
	
	TS:Create(objs[1],TweenInfo.new(.25,Enum.EasingStyle.Sine),{C1 = (CFrame.new(0.1,-0.1,1) * CFrame.Angles(math.rad(90), math.rad(-9), math.rad(0))):inverse() }):Play()
wait(.8)
	
	TS:Create(objs[4].Handle.Mag, TweenInfo.new(.3,Enum.EasingStyle.Sine), {C1 = (CFrame.new(0,0,-.2) * CFrame.Angles(math.rad(25),math.rad(0),math.rad(0))):Inverse() }):Play()
	TS:Create(objs[1],TweenInfo.new(.4,Enum.EasingStyle.Sine),{C1 = (CFrame.new(0.1,-0.1,1) * CFrame.Angles(math.rad(90), math.rad(-6), math.rad(0))):inverse() }):Play()
	TS:Create(objs[2],TweenInfo.new(.3,Enum.EasingStyle.Sine),{C1 = (CFrame.new(-0.45,-0.9,-.5) * CFrame.Angles(math.rad(140), math.rad(0), math.rad(15))):inverse() }):Play()
wait(.5)
	objs[4].Handle.MagIn:Play()
	TS:Create(objs[4].Handle.Mag, TweenInfo.new(.1,Enum.EasingStyle.Sine), {C1 = (CFrame.new(0,0,0) * CFrame.Angles(math.rad(0),math.rad(0),math.rad(0))):Inverse() }):Play()
	
	TS:Create(objs[2],TweenInfo.new(.3,Enum.EasingStyle.Sine),{C1 = (CFrame.new(-0.45,-0.7,-0) * CFrame.Angles(math.rad(110), math.rad(5), math.rad(15))):inverse() }):Play()
	
wait(0.1)


end;

self.TacticalReloadAnim = function(objs)
	TS:Create(objs[1],TweenInfo.new(.8,Enum.EasingStyle.Exponential),{C1 = (CFrame.new(0.1,-0.1,.3) * CFrame.Angles(math.rad(110), math.rad(-15), math.rad(0))):inverse() }):Play()
	TS:Create(objs[2],TweenInfo.new(.45,Enum.EasingStyle.Sine),{C1 = (CFrame.new(-0.7,-0.7,2) * CFrame.Angles(math.rad(110), math.rad(15), math.rad(15))):inverse() }):Play()
	local fakeloadmag = objs[4].Mag:Clone()
	fakeloadmag.Name = "TemporaryMag"
	fakeloadmag.Parent = objs[4]
	fakeloadmag.Transparency = 0
	fakeloadmag.CanCollide = false
fakeloadmag.Transparency = 1
	local MagCW = Instance.new("Motor6D")
	MagCW.Part0 = fakeloadmag
	MagCW.Part1 = objs[3].Parent.Parent:WaitForChild("Left Arm")
	MagCW.Parent = fakeloadmag
	MagCW.C1 = fakeloadmag.CFrame:toObjectSpace(objs[4].Parent:WaitForChild("Left Arm").CFrame) * CFrame.new(0.1, -1, -0.15) * CFrame.Angles(math.rad(110),math.rad(0),math.rad(0)):Inverse()
	wait(0.5)
	TS:Create(objs[1],TweenInfo.new(.8,Enum.EasingStyle.Sine),{C1 = (CFrame.new(0.1,-0.1,.35) * CFrame.Angles(math.rad(110), math.rad(-17), math.rad(0))):inverse() }):Play()
	fakeloadmag.Transparency = 0
	TS:Create(objs[2],TweenInfo.new(.2,Enum.EasingStyle.Sine),{C1 = (CFrame.new(-0.7,-.5,0) * CFrame.Angles(math.rad(120), math.rad(-90), math.rad(-15))):inverse() }):Play()
	
wait(0.2)
	TS:Create(objs[4].Handle.Mag, TweenInfo.new(.5,Enum.EasingStyle.Exponential), {C1 = (CFrame.new(0,0,-.2) * CFrame.Angles(math.rad(25),math.rad(0),math.rad(0))):Inverse() }):Play()
	objs[4].Handle.MagOut:Play() 
	TS:Create(objs[1],TweenInfo.new(.8,Enum.EasingStyle.Sine),{C1 = (CFrame.new(0.1,-0.1,.4) * CFrame.Angles(math.rad(110), math.rad(-12), math.rad(0))):inverse() }):Play()
wait(0.1)
	TS:Create(objs[1],TweenInfo.new(.7,Enum.EasingStyle.Exponential),{C1 = (CFrame.new(0.1,-.3,.1) * CFrame.Angles(math.rad(120), math.rad(-12), math.rad(0))):inverse() }):Play()

	objs[4].Mag.Transparency = 1
	local FakeMag = objs[4].Mag:Clone()
	FakeMag:ClearAllChildren()
	FakeMag.Transparency = 0
	FakeMag.CanCollide = true
	FakeMag.Parent = objs[4]
	FakeMag.Anchored = false
	FakeMag.RotVelocity = Vector3.new(0,-10,0)
	FakeMag.Velocity = (FakeMag.CFrame.UpVector * -250)
	TS:Create(objs[2],TweenInfo.new(.5,Enum.EasingStyle.Exponential),{C1 = (CFrame.new(-1.4,-.4,-1.3) * CFrame.Angles(math.rad(90), math.rad(-70), math.rad(-25))):inverse() }):Play()
	wait(.1)
	TS:Create(objs[1],TweenInfo.new(1.3,Enum.EasingStyle.Exponential),{C1 = (CFrame.new(0.1,-0.1,.3) * CFrame.Angles(math.rad(110), math.rad(-15), math.rad(0))):inverse() }):Play()
wait(.2)
	TS:Create(objs[2],TweenInfo.new(.25,Enum.EasingStyle.Sine),{C1 = (CFrame.new(-0.35,-0.4,-1.3) * CFrame.Angles(math.rad(150), math.rad(-15), math.rad(0))):inverse() }):Play()
	wait(.2)
	fakeloadmag:Remove()
	objs[4].Mag.Transparency = 0
	objs[4].Handle.AimUp:Play()
	objs[4].Handle.MagIn:Play()

wait(0.2)
	TS:Create(objs[4].Handle.Mag, TweenInfo.new(.5,Enum.EasingStyle.Exponential), {C1 = (CFrame.new(0,0,0) * CFrame.Angles(math.rad(0),math.rad(0),math.rad(0))):Inverse() }):Play()
	TS:Create(objs[2],TweenInfo.new(.25,Enum.EasingStyle.Sine),{C1 = (CFrame.new(-0.35,-0.6,-1.1) * CFrame.Angles(math.rad(155), math.rad(-15), math.rad(0))):inverse() }):Play()
wait(.4)
	TS:Create(objs[1],TweenInfo.new(0.35,Enum.EasingStyle.Sine),{C1 = (CFrame.new(0.05,-0.15,1) * CFrame.Angles(math.rad(90),math.rad(-7.5),math.rad(0))):inverse() }):Play()
	TS:Create(objs[2],TweenInfo.new(0.35,Enum.EasingStyle.Sine,Enum.EasingDirection.Out),{C1 = CFrame.new(.6,-0.53,-0.22) * CFrame.Angles(math.rad(-180),math.rad(90),math.rad(0)) }):Play()
	wait(.3)    
	objs[4].Bolt.SlidePull:Play()
	TS:Create(objs[1],TweenInfo.new(0.3,Enum.EasingStyle.Back),{C1 = (CFrame.new(0.05,-0.2,1.3) * CFrame.Angles(math.rad(93),math.rad(-7.75),math.rad(-3))):inverse() }):Play()
	TS:Create(objs[2],TweenInfo.new(0.3,Enum.EasingStyle.Quart),{C1 = CFrame.new(-.05,-0.53,-0.22) * CFrame.Angles(math.rad(-180),math.rad(100),math.rad(10)) }):Play()
	TS:Create(objs[4].Handle.Slide, TweenInfo.new(.2,Enum.EasingStyle.Sine), {C0 =  CFrame.new(0,0,-0.6):inverse() }):Play()
	TS:Create(objs[4].Handle.Bolt, TweenInfo.new(.2,Enum.EasingStyle.Sine), {C0 =  CFrame.new(0,0,-0.6):inverse() }):Play()
	wait(0.25)

	objs[4].Bolt.SlideRelease:Play()
	TS:Create(objs[4].Handle.Slide, TweenInfo.new(.2,Enum.EasingStyle.Linear), {C0 =  CFrame.new():inverse() }):Play()
	TS:Create(objs[4].Handle.Bolt, TweenInfo.new(.2,Enum.EasingStyle.Linear), {C0 =  CFrame.new():inverse() }):Play()

end;

self.PumpAnim = function(objs)

end;

self.FiremodeAnim = function(objs)
	local Weld = Instance.new("WeldConstraint",objs[4])
	Weld.Part0 = objs[4].Handle
	Weld.Part1 = objs[5]["Left Arm"]

	objs[3].Part0 = nil

	TS:Create(objs[1], TweenInfo.new(.2,Enum.EasingStyle.Sine), {C1 = (CFrame.new(0.25,-0.2,.8) * CFrame.Angles(math.rad(110),math.rad(0),math.rad(0))):inverse() }):Play()
	wait(0.15)
	objs[4].Handle.SafetyClick:Play()
	TS:Create(objs[1], TweenInfo.new(.25,Enum.EasingStyle.Sine), {C1 = (CFrame.new(0.25,-0.5,0.8) * CFrame.Angles(math.rad(120),math.rad(0),math.rad(0))):inverse() }):Play()
	wait(.2)
	TS:Create(objs[1], TweenInfo.new(.3,Enum.EasingStyle.Sine), {C1 = self.RArmCFrame:Inverse()}):Play()
	wait(.3)

	objs[3].Part0 = objs[5]["Right Arm"]
	Weld:Destroy()
end
self.MagCheck = function(objs)
	objs[4].Handle.AimUp:Play()
	TS:Create(objs[1], TweenInfo.new(.25,Enum.EasingStyle.Sine), {C1 = (CFrame.new(0.5,-0.15,0) * CFrame.Angles(math.rad(100),math.rad(0),math.rad(-45))):inverse() }):Play()
	TS:Create(objs[2], TweenInfo.new(.25,Enum.EasingStyle.Linear), {C1 = (CFrame.new(-1,-1,1) * CFrame.Angles(math.rad(0),math.rad(0),math.rad(0))):inverse() }):Play()
	wait(2.5)
	objs[4].Handle.AimDown:Play()
	TS:Create(objs[1], TweenInfo.new(.25,Enum.EasingStyle.Sine), {C1 = (CFrame.new(0.5,-0.15,0) * CFrame.Angles(math.rad(160),math.rad(60),math.rad(-45))):inverse() }):Play()
	TS:Create(objs[2], TweenInfo.new(.25,Enum.EasingStyle.Linear), {C1 = (CFrame.new(-1,-1,1) * CFrame.Angles(math.rad(0),math.rad(0),math.rad(0))):inverse() }):Play()
	wait(2.5)
	objs[4].Handle.AimUp:Play()
end;

self.meleeAttack = function(objs)

end;

self.GrenadeReady = function(objs)

end;

self.GrenadeThrow = function(objs)

end;

----------------------------------------------------------------------------------------------------
----------------------------------------------------------------------------------------------------
--//Server Animations
------//Idle Position
self.SV_GunPos = CFrame.new(-.3, -.2, -0.4) * CFrame.Angles(math.rad(-90), math.rad(0), math.rad(0))

self.SV_RightArmPos = CFrame.new(-.9, 1.25, -0.35) * CFrame.Angles(math.rad(-30), math.rad(0), math.rad(0))	--Server
self.SV_LeftArmPos = CFrame.new(1,1,-1) * CFrame.Angles(math.rad(-80),math.rad(30),math.rad(-10))	--server

self.SV_RightElbowPos = CFrame.new(0,-0.45,-.25) * CFrame.Angles(math.rad(-80), math.rad(0), math.rad(0))		--Client
self.SV_LeftElbowPos = CFrame.new(0,0, -0.1) * CFrame.Angles(math.rad(-15),math.rad(0),math.rad(0))	--Client

self.SV_RightWristPos = CFrame.new(0,0,0.15) * CFrame.Angles(math.rad(20), math.rad(0), math.rad(0))		--Client
self.SV_LeftWristPos = CFrame.new(0,0,0) * CFrame.Angles(math.rad(0),math.rad(-15),math.rad(0))	

------//High Ready Animations
self.RightHighReady = CFrame.new(-1, 1.3, 0) * CFrame.Angles(math.rad(0), math.rad(-20), math.rad(-20));
self.LeftHighReady = CFrame.new(.75,.15,-1.5) * CFrame.Angles(math.rad(-100),math.rad(30),math.rad(24));

self.RightElbowHighReady = CFrame.new(0,-.5,-.3) * CFrame.Angles(math.rad(-80), math.rad(-10), math.rad(0));
self.LeftElbowHighReady = CFrame.new(0,0, -0.1) * CFrame.Angles(math.rad(-35),math.rad(0),math.rad(0));

self.RightWristHighReady = CFrame.new(0,0,-.3) * CFrame.Angles(math.rad(-40), math.rad(0), math.rad(10));
self.LeftWristHighReady = CFrame.new(0,0,0) * CFrame.Angles(math.rad(0),math.rad(-15),math.rad(0));
------//Low Ready Animations
self.RightLowReady = CFrame.new(.2,1.3, 0.25) * CFrame.Angles(math.rad(0), math.rad(-10), math.rad(-60));
self.LeftLowReady = CFrame.new(-.5,1.2,-1.4) * CFrame.Angles(math.rad(-110),math.rad(30),math.rad(90));

self.RightElbowLowReady = CFrame.new(0,-.5,-.3) * CFrame.Angles(math.rad(-90), math.rad(10), math.rad(0));
self.LeftElbowLowReady = CFrame.new(0,0,-.2) * CFrame.Angles(math.rad(-25),math.rad(0),math.rad(0));

self.RightWristLowReady = CFrame.new(-.2,-.05,.2) * CFrame.Angles(math.rad(0), math.rad(30), math.rad(40));
self.LeftWristLowReady = CFrame.new(0,.1,0) * CFrame.Angles(math.rad(-10),math.rad(-15),math.rad(0)); 
------//Patrol Animations
self.RightPatrol = CFrame.new(-.85, 0.75, -1.3) * CFrame.Angles(math.rad(-30), math.rad(-90), math.rad(0));
self.LeftPatrol = CFrame.new(1.5,1.1,0) * CFrame.Angles(math.rad(0),math.rad(0),math.rad(0));

self.RightElbowPatrol = CFrame.new(0,-0.2,-.1) * CFrame.Angles(math.rad(-40), math.rad(0), math.rad(0));
self.LeftElbowPatrol = CFrame.new(0,-0.15,-0.25)  * CFrame.Angles(math.rad(-50), math.rad(0), math.rad(0));

self.RightWristPatrol = CFrame.new(0,0,0) * CFrame.Angles(math.rad(0), math.rad(0), math.rad(-15));
self.LeftWristPatrol = CFrame.new(0,0,0)  * CFrame.Angles(math.rad(0), math.rad(-90), math.rad(0));	

------//Aim Animations
self.RightAim = CFrame.new(-.6, 0.85, -0.5) * CFrame.Angles(math.rad(-50), math.rad(0), math.rad(0));
self.LeftAim = CFrame.new(1.6,0.6,-0.85) * CFrame.Angles(math.rad(-95),math.rad(35),math.rad(-25));

self.RightElbowAim = CFrame.new(0,-0.2,-.25) * CFrame.Angles(math.rad(-60), math.rad(0), math.rad(0));
self.LeftElbowAim = CFrame.new(0,0,0)  * CFrame.Angles(math.rad(0), math.rad(0), math.rad(0));

self.RightWristAim = CFrame.new(0,0,0.15) * CFrame.Angles(math.rad(20), math.rad(0), math.rad(0));
self.LeftWristAim = CFrame.new(0,0,0)  * CFrame.Angles(math.rad(0), math.rad(0), math.rad(0));

------//Sprinting Animations
self.RightSprint = CFrame.new(-.9, 1.25, 0) * CFrame.Angles(math.rad(0), math.rad(0), math.rad(0));
self.LeftSprint = CFrame.new(1,1,-0.6) * CFrame.Angles(math.rad(-45),math.rad(15),math.rad(-25));

self.RightElbowSprint = CFrame.new(0,-0.45,-.25) * CFrame.Angles(math.rad(-80), math.rad(0), math.rad(0));
self.LeftElbowSprint = CFrame.new(0,0,0)  * CFrame.Angles(math.rad(0), math.rad(0), math.rad(0));

self.RightWristSprint = CFrame.new(0,0,0.15) * CFrame.Angles(math.rad(20), math.rad(0), math.rad(0));
self.LeftWristSprint = CFrame.new(0,0,0)  * CFrame.Angles(math.rad(0), math.rad(0), math.rad(0));

return self
