local TS = game:GetService('TweenService')
local self = {}

self.SlideEx 		= CFrame.new(0,0,-1	)
self.SlideLock 		= false

self.canAim 		= true
self.Zoom 			= 20
self.Zoom2 			= 10
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
self.Ammo 			= 7
self.StoredAmmo 	= 56
self.AmmoInGun 		= self.Ammo
self.MaxStoredAmmo	= math.huge
self.CanCheckMag 	= true
self.MagCount		= true
self.ShellInsert	= false
self.ShootRate 		= 60
self.Bullets 		= 1
self.BurstShot 		= 3
self.ShootType 		= 1				--[1 = SEMI; 2 = BURST; 3 = AUTO; 4 = PUMP ACTION; 5 = BOLT ACTION]
self.FireModes = {
	ChangeFiremode = false;		
	Semi = true;
	Burst = false;
	Auto = true;}

self.LimbDamage 	= {60,60}
self.TorsoDamage 	= {60,68} 
self.HeadDamage 	= {105,105} 
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
self.UnderBarrelAtt = "MINIMI Bipod"
self.OtherAtt 		= ""

self.camRecoil = {
	camRecoilUp 	= {50,60}
	,camRecoilTilt 	= {40,50}
	,camRecoilLeft 	= {10,20}
	,camRecoilRight = {10,20}

}


self.gunRecoil = {
	gunRecoilUp 	= {50,60}
	,gunRecoilTilt 	= {40,50}
	,gunRecoilLeft 	= {1,15}
	,gunRecoilRight = {1,15}

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

self.BulletType 				= ".50 BMG"
self.MuzzleVelocity 			= 340 --m/s
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
self.HolsterCFrame		= CFrame.new(1.2,0.75,0.9) * CFrame.Angles(math.rad(-270),math.rad(-2),math.rad(100));

self.BulletLight = true
self.BulletLightBrightness = 2
self.BulletLightColor = Color3.fromRGB(255, 50, 40)
self.BulletLightRange = 20

return self
