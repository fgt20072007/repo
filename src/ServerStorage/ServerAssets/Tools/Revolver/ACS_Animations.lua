local TS = game:GetService('TweenService')
local self = {}

self.MainCFrame 	= CFrame.new(0.4,-0.7,-0.2)*CFrame.Angles(math.rad(0), math.rad(0), math.rad(5))

self.GunModelFixed 	= true
self.GunCFrame 		= CFrame.new(0.2, -0.14, .8) * CFrame.Angles(math.rad(90), math.rad(0), math.rad(-5))
self.LArmCFrame 	= CFrame.new(-.44,-0.35,-0.07) * CFrame.Angles(math.rad(102),math.rad(0),math.rad(10))
self.RArmCFrame 	= CFrame.new(0,-0.15,0) * CFrame.Angles(math.rad(90),math.rad(0),math.rad(-5))

self.EquipAnim = function(objs)

	TS:Create(objs[1], TweenInfo.new(.4,Enum.EasingStyle.Sine), {C1 = (CFrame.new(1,-0.15,0) * CFrame.Angles(math.rad(25),math.rad(0),math.rad(0))):inverse() }):Play()
	TS:Create(objs[2], TweenInfo.new(.4,Enum.EasingStyle.Sine), {C1 = (CFrame.new(-1,-1,0) * CFrame.Angles(math.rad(25),math.rad(0),math.rad(0))):inverse() }):Play()	
	wait(0.5)
	objs[4].Handle.AimUp:Play()	
	objs[6]:accelerate(Vector3.new(0,0,1))
	objs[7]:accelerate(Vector3.new(0,2,2))
	
	wait(0.2)
	objs[4].Handle.ShoulderEquip:Play()	
	TS:Create(objs[1], TweenInfo.new(0.6,Enum.EasingStyle.Back), {C1 = self.RArmCFrame:Inverse()}):Play()
	TS:Create(objs[2], TweenInfo.new(0.9,Enum.EasingStyle.Back), {C1 = self.LArmCFrame:Inverse()}):Play()
	objs[6]:accelerate(Vector3.new(-0.05,-0.05,-0.4))
	objs[7]:accelerate(Vector3.new(-0.5,-0.5,-0.5))
	wait(0.1)
	objs[6]:accelerate(Vector3.new(0.05,0.05,0.4))
	objs[7]:accelerate(Vector3.new(0.5,0.5,0.5))
	wait(0.3)

end;

self.IdleAnim = function(objs)
	
	TS:Create(objs[1], TweenInfo.new(.3,Enum.EasingStyle.Sine), {C1 = self.RArmCFrame:Inverse()}):Play()
	TS:Create(objs[2], TweenInfo.new(.3,Enum.EasingStyle.Sine), {C1 = self.LArmCFrame:Inverse()}):Play()
end;

self.LowReady = function(objs)
	TS:Create(objs[1],TweenInfo.new(.25,Enum.EasingStyle.Sine),{C1 = (CFrame.new(0,-0.15,0.1) * CFrame.Angles(math.rad(70), math.rad(0), math.rad(0))):inverse() }):Play()
	TS:Create(objs[2],TweenInfo.new(.25,Enum.EasingStyle.Sine),{C1 = (CFrame.new(-.55,-0.45,0) * CFrame.Angles(math.rad(75),math.rad(25),math.rad(15))):inverse() }):Play()
	wait(0.25)	
end;

self.HighReady = function(objs)
	TS:Create(objs[1],TweenInfo.new(.25,Enum.EasingStyle.Sine),{C1 = (CFrame.new(0.15,-0.1,0.5) * CFrame.Angles(math.rad(145), math.rad(0), math.rad(0))):inverse() }):Play()
	TS:Create(objs[2],TweenInfo.new(.25,Enum.EasingStyle.Sine),{C1 = (CFrame.new(-.2,-0.25,0) * CFrame.Angles(math.rad(155),math.rad(55),math.rad(15))):inverse() }):Play()
	wait(0.25)	
end;

self.Patrol = function(objs)
	TS:Create(objs[1],TweenInfo.new(.25,Enum.EasingStyle.Sine),{C1 = (CFrame.new(0,-0.15,0.5) * CFrame.Angles(math.rad(55), math.rad(0), math.rad(0))):inverse() }):Play()
	TS:Create(objs[2],TweenInfo.new(.25,Enum.EasingStyle.Sine),{C1 = (CFrame.new(-.55,-0.45,0.4) * CFrame.Angles(math.rad(60),math.rad(25),math.rad(15))):inverse() }):Play()	
	wait(.25)	
end;

self.SprintAnim = function(objs)
	objs[4].Handle.Draw:Play()	
	TS:Create(objs[1], TweenInfo.new(.4,Enum.EasingStyle.Sine), {C1 = (CFrame.new(1,-0.15,0) * CFrame.Angles(math.rad(25),math.rad(0),math.rad(0))):inverse() }):Play()
	TS:Create(objs[2], TweenInfo.new(.4,Enum.EasingStyle.Sine), {C1 = (CFrame.new(-1,-1,0) * CFrame.Angles(math.rad(25),math.rad(0),math.rad(0))):inverse() }):Play()	
	wait(.25)
end;

self.ReloadAnim = function(objs)
	TS:Create(objs[1], TweenInfo.new(.25,Enum.EasingStyle.Sine), {C1 = (CFrame.new(0,-0.15,0) * CFrame.Angles(math.rad(90),math.rad(-25),math.rad(0))):Inverse() }):Play()
	TS:Create(objs[2], TweenInfo.new(.25,Enum.EasingStyle.Sine), {C1 = (CFrame.new(-.6,-0.3,0) * CFrame.Angles(math.rad(60),math.rad(50),math.rad(30))):Inverse() }):Play()
	wait(.3)

	TS:Create(objs[1], TweenInfo.new(.5,Enum.EasingStyle.Back), {C1 = (CFrame.new(0,-0.15,0) * CFrame.Angles(math.rad(85),math.rad(-15),math.rad(0))):Inverse() }):Play()
	TS:Create(objs[2], TweenInfo.new(.5,Enum.EasingStyle.Sine), {C1 = (CFrame.new(-1.5,-.5,.75) * CFrame.Angles(math.rad(0),math.rad(50),math.rad(15))):Inverse() }):Play()
	wait(.05)
	objs[6]:accelerate(Vector3.new(0,0,-1))
	objs[4].Handle.MagOut:Play()
	objs[4].Mag.Transparency = 1

	wait(.5)
	objs[6]:accelerate(Vector3.new(0,0,2))
	objs[7]:accelerate(Vector3.new(0,2,2))
	objs[4].Handle.AimUp:Play()
	TS:Create(objs[2], TweenInfo.new(.25,Enum.EasingStyle.Sine), {C1 = (CFrame.new(-1.7,-0.5,0) * CFrame.Angles(math.rad(90),math.rad(0),math.rad(90))):Inverse() }):Play()
	wait(0.2)
	objs[6]:accelerate(Vector3.new(0,0,2))
	objs[7]:accelerate(Vector3.new(0,2,2))
	TS:Create(objs[2], TweenInfo.new(.25,Enum.EasingStyle.Sine), {C1 = (CFrame.new(-1.7,-0.3,0) * CFrame.Angles(math.rad(70),math.rad(10),math.rad(90))):Inverse() }):Play()
	wait(.25)
	TS:Create(objs[2], TweenInfo.new(.25,Enum.EasingStyle.Sine), {C1 = (CFrame.new(-1.7,-0.5,0) * CFrame.Angles(math.rad(90),math.rad(0),math.rad(90))):Inverse() }):Play()
	wait(.25)
	objs[4].Handle.AimDown:Play()
	objs[6]:accelerate(Vector3.new(0,0,2))
	objs[7]:accelerate(Vector3.new(0,2,2))

	TS:Create(objs[2], TweenInfo.new(.25,Enum.EasingStyle.Sine), {C1 = (CFrame.new(-1.7,-0.3,0) * CFrame.Angles(math.rad(70),math.rad(10),math.rad(90))):Inverse() }):Play()
	wait(0.25)
	TS:Create(objs[2], TweenInfo.new(.5,Enum.EasingStyle.Sine), {C1 = (CFrame.new(-1.7,-0.5,0) * CFrame.Angles(math.rad(90),math.rad(10),math.rad(90))):Inverse() }):Play()
	objs[6]:accelerate(Vector3.new(0,0,-1))
	objs[7]:accelerate(Vector3.new(0,-1,-1))

	wait(0.2)
	TS:Create(objs[2], TweenInfo.new(.4,Enum.EasingStyle.Sine), {C1 = (CFrame.new(-0.5,-1.4,-0.5) * CFrame.Angles(math.rad(100),math.rad(50),math.rad(0))):Inverse() }):Play()
	wait(.35)

	TS:Create(objs[2], TweenInfo.new(.25,Enum.EasingStyle.Sine), {C1 = (CFrame.new(-.6,-0.3,0) * CFrame.Angles(math.rad(60),math.rad(50),math.rad(30))):Inverse() }):Play()
	TS:Create(objs[1], TweenInfo.new(.15,Enum.EasingStyle.Sine), {C1 = (CFrame.new(0,-0.15,0) * CFrame.Angles(math.rad(90),math.rad(-25),math.rad(0))):Inverse() }):Play()
	wait(.25)
	objs[4].Handle.MagIn:Play()
	wait(.1)
	objs[6]:accelerate(Vector3.new(0,0,1))
	objs[7]:accelerate(Vector3.new(0,1,1))
	objs[4].Handle.AimUp:Play()
	TS:Create(objs[2], TweenInfo.new(.15,Enum.EasingStyle.Elastic), {C1 = (CFrame.new(-.6,-0.3,0) * CFrame.Angles(math.rad(70),math.rad(50),math.rad(30))):Inverse() }):Play()
	TS:Create(objs[1], TweenInfo.new(.15,Enum.EasingStyle.Elastic), {C1 = (CFrame.new(0,-0.15,0) * CFrame.Angles(math.rad(95),math.rad(-25),math.rad(0))):Inverse() }):Play()
	wait(.1)
	TS:Create(objs[2], TweenInfo.new(.15,Enum.EasingStyle.Sine), {C1 = (CFrame.new(-.6,-0.3,0) * CFrame.Angles(math.rad(60),math.rad(50),math.rad(30))):Inverse() }):Play()
	TS:Create(objs[1], TweenInfo.new(.15,Enum.EasingStyle.Sine), {C1 = (CFrame.new(0,-0.15,0) * CFrame.Angles(math.rad(90),math.rad(-25),math.rad(0))):Inverse() }):Play()
	objs[4].Mag.Transparency = 0
	wait(.15)
end;


self.TacticalReloadAnim = function(objs)
	TS:Create(objs[1], TweenInfo.new(.25,Enum.EasingStyle.Back), {C1 = (CFrame.new(0,-0.15,0) * CFrame.Angles(math.rad(95),math.rad(0),math.rad(0))):Inverse() }):Play()
	TS:Create(objs[2], TweenInfo.new(.5,Enum.EasingStyle.Sine), {C1 = (CFrame.new(-1.5,-1,1) * CFrame.Angles(math.rad(0),math.rad(50),math.rad(15))):Inverse() }):Play()
	wait(.2)
	objs[6]:accelerate(Vector3.new(0.1,0.1,5))
	objs[7]:accelerate(Vector3.new(0.1,0.1,5))
	TS:Create(objs[1], TweenInfo.new(.5,Enum.EasingStyle.Elastic), {C1 = (CFrame.new(0.3,-0.3,0.1) * CFrame.Angles(math.rad(100),math.rad(50),math.rad(0))):Inverse() }):Play()
	wait(.1)
	objs[4].Handle.MagOut:Play()
	objs[4].Mag.Transparency = 1

	local FakeMag = objs[4]:WaitForChild("Mag"):Clone()
	--FakeMag:ClearAllChildren()
	FakeMag.Transparency = 0
	FakeMag.Parent = objs[4]
	FakeMag.Anchored = false
	FakeMag.CanCollide = false
	FakeMag.RotVelocity = Vector3.new(0,0,0)
	FakeMag:ApplyImpulse(FakeMag.CFrame.UpVector * -0.5) --FakeMag.CFrame.LookVector * 15

	wait(.15)
	objs[6]:accelerate(Vector3.new(0,0,2))
	objs[7]:accelerate(Vector3.new(0,2,2))
	objs[4].Handle.AimUp:Play()

	TS:Create(objs[2], TweenInfo.new(.25,Enum.EasingStyle.Sine), {C1 = (CFrame.new(-1.7,-0.5,0) * CFrame.Angles(math.rad(90),math.rad(0),math.rad(90))):Inverse() }):Play()
	wait(0.2)
	TS:Create(objs[1], TweenInfo.new(.7,Enum.EasingStyle.Sine), {C1 = (CFrame.new(0,-0.15,0) * CFrame.Angles(math.rad(90),math.rad(-25),math.rad(0))):Inverse() }):Play()
	objs[6]:accelerate(Vector3.new(0,0,2))
	objs[7]:accelerate(Vector3.new(0,2,2))
	TS:Create(objs[2], TweenInfo.new(.25,Enum.EasingStyle.Sine), {C1 = (CFrame.new(-1.7,-0.3,0) * CFrame.Angles(math.rad(70),math.rad(10),math.rad(90))):Inverse() }):Play()
	wait(.25)
	TS:Create(objs[2], TweenInfo.new(.25,Enum.EasingStyle.Sine), {C1 = (CFrame.new(-1.7,-0.5,0) * CFrame.Angles(math.rad(90),math.rad(0),math.rad(90))):Inverse() }):Play()
	wait(.25)

	objs[6]:accelerate(Vector3.new(0,0,2))
	objs[7]:accelerate(Vector3.new(0,2,2))
	TS:Create(objs[2], TweenInfo.new(.25,Enum.EasingStyle.Sine), {C1 = (CFrame.new(-1.7,-0.3,0) * CFrame.Angles(math.rad(70),math.rad(10),math.rad(90))):Inverse() }):Play()
	wait(0.25)



	TS:Create(objs[2], TweenInfo.new(.5,Enum.EasingStyle.Sine), {C1 = (CFrame.new(-1.7,-0.5,0) * CFrame.Angles(math.rad(90),math.rad(10),math.rad(90))):Inverse() }):Play()
	objs[6]:accelerate(Vector3.new(0,0,-1))
	objs[7]:accelerate(Vector3.new(0,-1,-1))
	wait(0.2)
	TS:Create(objs[2], TweenInfo.new(.4,Enum.EasingStyle.Sine), {C1 = (CFrame.new(-0.5,-1.4,-0.5) * CFrame.Angles(math.rad(100),math.rad(50),math.rad(0))):Inverse() }):Play()
	wait(.35)

	objs[6]:accelerate(Vector3.new(0,0,2))
	objs[7]:accelerate(Vector3.new(0,-2,-2))
	TS:Create(objs[2], TweenInfo.new(.25,Enum.EasingStyle.Sine), {C1 = (CFrame.new(-.6,-0.4,0) * CFrame.Angles(math.rad(50),math.rad(50),math.rad(30))):Inverse() }):Play()
	TS:Create(objs[1], TweenInfo.new(.5,Enum.EasingStyle.Sine), {C1 = (CFrame.new(0,-0.15,0) * CFrame.Angles(math.rad(95),math.rad(-20),math.rad(0))):Inverse() }):Play()
	wait(0.5)

	objs[4].Handle.MagIn:Play()
	objs[6]:accelerate(Vector3.new(-0.1,-0.1,0))
	objs[7]:accelerate(Vector3.new(-0.1,-0.1,0))
	TS:Create(objs[1], TweenInfo.new(.15,Enum.EasingStyle.Bounce), {C1 = (CFrame.new(0,-0.15,0) * CFrame.Angles(math.rad(90),math.rad(-25),math.rad(0))):Inverse() }):Play()
	TS:Create(objs[2], TweenInfo.new(.25,Enum.EasingStyle.Sine), {C1 = (CFrame.new(-.6,-0.3,0) * CFrame.Angles(math.rad(70),math.rad(50),math.rad(30))):Inverse() }):Play()
	objs[4].Mag.Transparency = 0
	wait(0.3)
	objs[6]:accelerate(Vector3.new(-0.1,-0.1,4))
	TS:Create(objs[2], TweenInfo.new(.25,Enum.EasingStyle.Sine), {C1 = (CFrame.new(-.6,-0.3,0) * CFrame.Angles(math.rad(80),math.rad(50),math.rad(30))):Inverse() }):Play()
	TS:Create(objs[1], TweenInfo.new(.15,Enum.EasingStyle.Sine), {C1 = (CFrame.new(0,-0.15,0) * CFrame.Angles(math.rad(110),math.rad(-25),math.rad(0))):Inverse() }):Play()
	wait(0.1)
	objs[6]:accelerate(Vector3.new(0,0,1))
	objs[7]:accelerate(Vector3.new(0,-1,1))
	TS:Create(objs[1], TweenInfo.new(.25,Enum.EasingStyle.Sine), {C1 = self.RArmCFrame:Inverse()}):Play()
	TS:Create(objs[2], TweenInfo.new(.25,Enum.EasingStyle.Sine), {C1 = self.LArmCFrame:Inverse()}):Play()
	objs[4].Bolt.SlideRelease:Play()
	TS:Create(objs[4].Handle.Slide, TweenInfo.new(.05,Enum.EasingStyle.Linear), {C0 =  CFrame.new():Inverse() }):Play()
	wait(0.1)
	TS:Create(objs[2], TweenInfo.new(.25,Enum.EasingStyle.Sine), {C1 = (CFrame.new(-.6,-0.3,0) * CFrame.Angles(math.rad(80),math.rad(50),math.rad(30))):Inverse() }):Play()
	TS:Create(objs[1], TweenInfo.new(.25,Enum.EasingStyle.Sine), {C1 = (CFrame.new(0,-0.15,0) * CFrame.Angles(math.rad(110),math.rad(-25),math.rad(0))):Inverse() }):Play()
	wait(.3)
	objs[6]:accelerate(Vector3.new(0,0,-1))
	objs[7]:accelerate(Vector3.new(0,-1,-1))
end;

self.JammedAnim = function(objs)
	TS:Create(objs[1], TweenInfo.new(.25,Enum.EasingStyle.Sine), {C1 = self.RArmCFrame:Inverse()}):Play()
	TS:Create(objs[2], TweenInfo.new(.25,Enum.EasingStyle.Sine), {C1 = (CFrame.new(-.8,0.1,0) * CFrame.Angles(math.rad(115),math.rad(-25),math.rad(30))):inverse() }):Play()
	wait(.25)
	objs[4].Bolt.SlidePull:Play()
	TS:Create(objs[4].Handle.Slide, TweenInfo.new(.25,Enum.EasingStyle.Sine), {C0 =  CFrame.new(0,0,-0.4):inverse() }):Play()
	TS:Create(objs[2], TweenInfo.new(.25,Enum.EasingStyle.Sine), {C1 = (CFrame.new(-.8,0.1,0.4) * CFrame.Angles(math.rad(115),math.rad(-25),math.rad(30))):inverse() }):Play()
	wait(.35)
	objs[4].Bolt.SlideRelease:Play()
	TS:Create(objs[4].Handle.Slide, TweenInfo.new(.05,Enum.EasingStyle.Linear), {C0 =  CFrame.new():inverse() }):Play()
end;

self.PumpAnim = function(objs)
	
end;

self.MagCheck = function(objs)
	TS:Create(objs[1],TweenInfo.new(.25,Enum.EasingStyle.Sine),{C1 = (CFrame.new(0.05,-0.15,0) * CFrame.Angles(math.rad(115), math.rad(0), math.rad(0))):inverse() }):Play()
	TS:Create(objs[2],TweenInfo.new(.25,Enum.EasingStyle.Sine),{C1 = (CFrame.new(-0.35,-0.2,0) * CFrame.Angles(math.rad(110), math.rad(15), math.rad(15))):inverse() }):Play()
	wait(.25)
	local magC = objs[4].Mag:Clone()
	magC:BreakJoints()
	magC.Parent = objs[4]
	local weld = Instance.new("WeldConstraint",magC)
	weld.Part0 = objs[5]:FindFirstChild("Left Arm")
	weld.Part1 = magC
	objs[4].Mag.Transparency = 1
	objs[4].Handle.MagOut:Play()
	TS:Create(objs[1],TweenInfo.new(.25,Enum.EasingStyle.Sine),{C1 = (CFrame.new(0.05,-0.15,0) * CFrame.Angles(math.rad(100), math.rad(-15), math.rad(0))):inverse() }):Play()
	TS:Create(objs[2],TweenInfo.new(.25,Enum.EasingStyle.Sine),{C1 = (CFrame.new(-0.35,-1,-.5) * CFrame.Angles(math.rad(110), math.rad(15), math.rad(15))):inverse() }):Play()
	wait(.25)
	--TS:Create(objs[1],TweenInfo.new(.25,Enum.EasingStyle.Sine),{C1 = (CFrame.new(0.05,-0.15,1) * CFrame.Angles(math.rad(115), math.rad(0), math.rad(0))):inverse() }):Play()
	TS:Create(objs[2],TweenInfo.new(.25,Enum.EasingStyle.Sine),{C1 = (CFrame.new(-0.8,-0.8,-.5) * CFrame.Angles(math.rad(130), math.rad(15), math.rad(15))):inverse() }):Play()
	wait(1)
	--TS:Create(objs[1],TweenInfo.new(.25,Enum.EasingStyle.Sine),{C1 = (CFrame.new(0.05,-0.15,1) * CFrame.Angles(math.rad(100), math.rad(0), math.rad(0))):inverse() }):Play()
	TS:Create(objs[2],TweenInfo.new(.25,Enum.EasingStyle.Sine),{C1 = (CFrame.new(-0.35,-1,0) * CFrame.Angles(math.rad(110), math.rad(15), math.rad(15))):inverse() }):Play()
	wait(.2)
	TS:Create(objs[1],TweenInfo.new(.25,Enum.EasingStyle.Sine),{C1 = (CFrame.new(0.05,-0.15,0) * CFrame.Angles(math.rad(115), math.rad(0), math.rad(0))):inverse() }):Play()
	TS:Create(objs[2],TweenInfo.new(.25,Enum.EasingStyle.Sine),{C1 = (CFrame.new(-0.35,-0.2,0) * CFrame.Angles(math.rad(110), math.rad(15), math.rad(15))):inverse() }):Play()
	wait(.25)
	magC:Destroy()
	objs[4].Mag.Transparency = 0
	objs[4].Handle.MagIn:Play()

	wait(0.25)

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

self.SV_RightArmPos = CFrame.new(-1, 0.65, -1) * CFrame.Angles(math.rad(-90), math.rad(0), math.rad(0))	--Server
self.SV_LeftArmPos = CFrame.new(0.55,1.5,-1) * CFrame.Angles(math.rad(-10),math.rad(20),math.rad(30));

self.SV_RightElbowPos = CFrame.new(0,0,0) * CFrame.Angles(math.rad(0), math.rad(0), math.rad(0))		--Client
self.SV_LeftElbowPos = CFrame.new(0,0,0) * CFrame.Angles(math.rad(-9),math.rad(0),math.rad(0));

self.SV_RightWristPos = CFrame.new(0,0,0) * CFrame.Angles(math.rad(0), math.rad(0), math.rad(0))		--Client
self.SV_LeftWristPos = CFrame.new(0,0,0) * CFrame.Angles(math.rad(0),math.rad(-15),math.rad(0));	

------//High Ready Animations
self.RightHighReady = CFrame.new(-1, .45, -1.15) * CFrame.Angles(math.rad(-90), math.rad(0), math.rad(0));
self.LeftHighReady = CFrame.new(.75,.45,-1.15) * CFrame.Angles(math.rad(-90),math.rad(45),math.rad(0));

self.RightElbowHighReady = CFrame.new(0,-0.45,-0.45)  * CFrame.Angles(math.rad(-75), math.rad(0), math.rad(0));
self.LeftElbowHighReady = CFrame.new(0,-.4,-.4)  * CFrame.Angles(math.rad(-60), math.rad(30), math.rad(0));

self.RightWristHighReady = CFrame.new(0,0,0)  * CFrame.Angles(math.rad(0), math.rad(0), math.rad(0));
self.LeftWristHighReady = CFrame.new(0,0,0)  * CFrame.Angles(math.rad(0), math.rad(0), math.rad(0));	

------//Low Ready Animations
self.RightLowReady = CFrame.new(-1, 1.1, -0.5) * CFrame.Angles(math.rad(-30), math.rad(0), math.rad(0));
self.LeftLowReady = CFrame.new(1,1,-0.9) * CFrame.Angles(math.rad(-30),math.rad(35),math.rad(-25));

self.RightElbowLowReady = CFrame.new(0,0,0)  * CFrame.Angles(math.rad(0), math.rad(0), math.rad(0));
self.LeftElbowLowReady = CFrame.new(0,0,0)  * CFrame.Angles(math.rad(0), math.rad(0), math.rad(0));

self.RightWristLowReady = CFrame.new(0,0,0)  * CFrame.Angles(math.rad(0), math.rad(0), math.rad(0));
self.LeftWristLowReady = CFrame.new(0,0,0)  * CFrame.Angles(math.rad(0), math.rad(0), math.rad(0));	

------//Patrol Animations
self.RightPatrol = CFrame.new(-1, 1.1, -0.5) * CFrame.Angles(math.rad(-30), math.rad(0), math.rad(0));
self.LeftPatrol = CFrame.new(1,1,-0.9) * CFrame.Angles(math.rad(-30),math.rad(35),math.rad(-25));

self.RightElbowPatrol = CFrame.new(0,0,0)  * CFrame.Angles(math.rad(0), math.rad(0), math.rad(0));
self.LeftElbowPatrol = CFrame.new(0,0,0)  * CFrame.Angles(math.rad(0), math.rad(0), math.rad(0));

self.RightWristPatrol = CFrame.new(0,0,0)  * CFrame.Angles(math.rad(0), math.rad(0), math.rad(0));
self.LeftWristPatrol = CFrame.new(0,0,0)  * CFrame.Angles(math.rad(0), math.rad(0), math.rad(0));	

------//Aim Animations
self.RightAim = CFrame.new(-.575, .45, -1.15) * CFrame.Angles(math.rad(-105), math.rad(0), math.rad(0));
self.LeftAim = CFrame.new(1.3,0.2,-0.85) * CFrame.Angles(math.rad(-95),math.rad(35),math.rad(-25));

self.RightElbowAim = CFrame.new(0,0,0)  * CFrame.Angles(math.rad(0), math.rad(0), math.rad(0));
self.LeftElbowAim = CFrame.new(0,0,0)  * CFrame.Angles(math.rad(0), math.rad(0), math.rad(0));

self.RightWristAim = CFrame.new(0,0,0.1)  * CFrame.Angles(math.rad(15), math.rad(0), math.rad(0));
self.LeftWristAim = CFrame.new(0,0,0)  * CFrame.Angles(math.rad(0), math.rad(0), math.rad(0));

------//Sprinting Animations
self.RightSprint = CFrame.new(-1, 1.1, -0.5) * CFrame.Angles(math.rad(-30), math.rad(0), math.rad(0));
self.LeftSprint = CFrame.new(1,1,-0.9) * CFrame.Angles(math.rad(-30),math.rad(35),math.rad(-25));

self.RightElbowSprint = CFrame.new(0,0,0)  * CFrame.Angles(math.rad(0), math.rad(0), math.rad(0));
self.LeftElbowSprint = CFrame.new(0,0,0)  * CFrame.Angles(math.rad(0), math.rad(0), math.rad(0));

self.RightWristSprint = CFrame.new(0,0,0)  * CFrame.Angles(math.rad(0), math.rad(0), math.rad(0));
self.LeftWristSprint = CFrame.new(0,0,0)  * CFrame.Angles(math.rad(0), math.rad(0), math.rad(0));

return self