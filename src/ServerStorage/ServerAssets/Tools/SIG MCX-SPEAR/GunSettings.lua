local TS = game:GetService('TweenService')
local self = {}

self.SlideEx 		= CFrame.new(0,0,-0.4)
self.SlideLock 		= false

self.canAim 		= true
self.Zoom 			= 50
self.Zoom2 			= 35
self.Zoom3 			= 55
self.ADSEnabled 		= { -- Ignore this setting if not using an ADS Mesh
	true, -- Enabled for primary sight
	true} -- Enabled for secondary sight (T)

self.gunName 		= script.Parent.Name
self.Type 			= "Gun"

self.EnableHUD		= true
self.IncludeChamberedBullet = true
self.Ammo 			= 25
self.StoredAmmo 	= 375
self.AmmoInGun 		= self.Ammo
self.MaxStoredAmmo	= math.huge
self.CanCheckMag 	= true
self.MagCount		= true
self.ShellInsert	= false
self.ShootRate 		= 850
self.Bullets 		= 1
self.BurstShot 		= 3
self.ShootType 		= 3	--[1 = SEMI; 2 = BURST; 3 = AUTO; 4 = PUMP ACTION; 5 = BOLT ACTION]
self.FireModes = {
	ChangeFiremode = true;		
	Semi = true;
	Burst = false;
	Auto = true;}

self.LimbDamage 	= {21,21}
self.TorsoDamage 	= {21,26} 
self.HeadDamage 	= {26,32} 
self.DamageFallOf 	= 1
self.MinDamage 		= 5
self.IgnoreProtection = false
self.BulletPenetration = 67

self.adsTime 		= 1

self.CrossHair 		= false
self.CenterDot 		= false
self.CrosshairOffset= 0
self.CanBreachDoor 	= false

self.SightAtt 		= ""
self.BarrelAtt		= ""
self.UnderBarrelAtt = ""
self.OtherAtt 		= ""



self.camRecoil = {
	camRecoilUp 	= {5,11}
	,camRecoilTilt 	= {150,150}
	,camRecoilLeft 	= {0,0}
	,camRecoilRight = {0,0}

}


self.gunRecoil = {
	gunRecoilUp 	= {11,25}
	,gunRecoilTilt 	= {10,25}
	,gunRecoilLeft 	= {1,5}
	,gunRecoilRight = {1,5}

}


self.AimRecoilReduction 		= 4
self.AimSpreadReduction 		= 1

self.MinRecoilPower 			= .5
self.MaxRecoilPower 			= 1.5
self.RecoilPowerStepAmount 		= .1


self.MinSpread 					= 0
self.MaxSpread 					= 0					
self.AimInaccuracyStepAmount 	= 0.25
self.AimInaccuracyDecrease 		= .25
self.WalkMult 					= 0

self.EnableZeroing 				= true
self.MaxZero 					= 500
self.ZeroIncrement 				= 50
self.CurrentZero 				= 0

self.BulletType 				= "5.56×45mm NATO"
self.MuzzleVelocity 			= 880 --m/s
self.BulletDrop 				= 0 --Between 0 - 1
self.Tracer						= true
self.BulletFlare 				= false
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
self.Distance = 1000
self.BDrop = .01
self.BSpeed = 1950
self.CanBreak	= true
self.Jammed		= false

self.Holster			= false
self.HolsterPoint		= "UpperTorso"
self.HolsterCFrame		= CFrame.new(1.05,-1.5,0) * CFrame.Angles(math.rad(20),math.rad(0),math.rad(0));

self.ExplosiveSettings = {}


self.BulletLight = true
self.BulletLightBrightness = 2
self.BulletLightColor = Color3.fromRGB(255, 50, 40)
self.BulletLightRange = 15

return self