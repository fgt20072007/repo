local TS = game:GetService('TweenService')
local self = {}

self.SlideEx 		= CFrame.new(0,0,-1	)
self.SlideLock 		= false

self.canAim 		= true
self.Zoom 			= 60
self.Zoom2 			= 15
self.ADSsettings = {
	ProjectorSight = false;

	ADSmesh = true;
	DoF = false;
	DoFDistance = 0;

	ADSmesh2 = false;
	DoF2 = false;
	DoF2Distance = 0;
}
self.gunName 		= script.Parent.Name
self.Type 			= "Gun"
self.EnableHUD		= true
self.IncludeChamberedBullet = true
self.Ammo 			= 10
self.StoredAmmo 	= 70
self.AmmoInGun 		= self.Ammo
self.MaxStoredAmmo	= math.huge
self.CanCheckMag 	= true
self.MagCount		= true
self.ShellInsert	= false
self.ShootRate 		= 200
self.Bullets 		= 1
self.BurstShot 		= 3
self.ShootType 		= 1				--[1 = SEMI; 2 = BURST; 3 = AUTO; 4 = PUMP ACTION; 5 = BOLT ACTION]
self.FireModes = {
	ChangeFiremode = false;		
	Semi = true;
	Burst = false;
	Auto = false;}

self.LimbDamage 	= {25,25}
self.TorsoDamage 	= {27,32} 
self.HeadDamage 	= {64,70}  
self.DamageFallOf 	= 1
self.MinDamage 		= 5
self.IgnoreProtection = true
self.BulletPenetration = 43

self.adsTime 		= 1.5


self.CrossHair 		= false
self.CenterDot 		= false
self.CrosshairOffset= 0
self.CanBreachDoor 	= false

self.SightAtt 		= ""
self.BarrelAtt		= ""
self.UnderBarrelAtt = ""
self.OtherAtt 		= ""

self.camRecoil = {
	camRecoilUp 	= {25,31}
	,camRecoilTilt 	= {150,150}
	,camRecoilLeft 	= {0,0}
	,camRecoilRight = {0,0}
}


self.gunRecoil = {
	gunRecoilUp 	= {11,25}
	,gunRecoilTilt 	= {10,25}
	,gunRecoilLeft 	= {11,23}
	,gunRecoilRight = {11,23}
}


self.AimRecoilReduction 		= 4
self.AimSpreadReduction 		= 1

self.MinRecoilPower 			= .75
self.MaxRecoilPower 			= 2.5
self.RecoilPowerStepAmount 		= .1

self.MinSpread 					= 0
self.MaxSpread 					= 0				
self.AimInaccuracyStepAmount 	= 0.75
self.AimInaccuracyDecrease 		= .25
self.WalkMult 					= 0

self.EnableZeroing 				= true
self.MaxZero 					= 500
self.ZeroIncrement 				= 50
self.CurrentZero 				= 0

self.BulletType 				= "7.62×51mm NATO"
self.MuzzleVelocity 			= 783 --m/s
self.BulletDrop 				= 0 --Between 0 - 1
self.Tracer						= true
self.BulletFlare 				= true
self.TracerWidth = .15
self.TracerLightEmission = 1
self.TracerColor = Color3.fromRGB(255,63,63)
self.TracerLifeTime = .04
self.TracerEveryXShots			= 3
self.RandomTracer				= {
	Enabled = true
	,Chance = 90 -- 0-100%
}
self.RainbowMode 				= false
self.InfraRed 					= false
self.Distance = 10000
self.BDrop = .01
self.BSpeed = 1950
self.CanBreak	= false
self.Jammed		= false
self.WalkMultiplier = 0	
self.CAL50 = true
self.Holster			= false
self.HolsterPoint		= "LowerTorso"
self.HolsterCFrame		= CFrame.new(0.75,0.75,0.6) * CFrame.Angles(math.rad(-270),math.rad(-2),math.rad(100));

self.BulletLight = true
self.BulletLightBrightness = 2
self.BulletLightColor = Color3.fromRGB(255, 50, 40)
self.BulletLightRange = 20

return self
