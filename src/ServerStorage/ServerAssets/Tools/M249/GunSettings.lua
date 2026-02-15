local TS = game:GetService('TweenService')
local self = {}

self.SlideEx 		= CFrame.new(0,0,-0.4)
self.SlideLock 		= false

self.canAim 		= true
self.Zoom 			= 50
self.Zoom2 			= 30
self.Zoom3 			= 40
self.ADSEnabled 		= { -- Ignore this setting if not using an ADS Mesh
	false, -- Enabled for primary sight
	false} -- Enabled for secondary sight (T)

self.gunName 		= script.Parent.Name
self.Type 			= "Gun"
self.EnableHUD		= true
self.IncludeChamberedBullet = true
self.Ammo 			= 100
self.StoredAmmo 	= 300
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
	Auto = true;
	Explosive = false;}


self.LimbDamage 	= {16,16}
self.TorsoDamage 	= {17,17} 
self.HeadDamage 	= {23,28}  
self.DamageFallOf 	= 1
self.MinDamage 		= 5
self.IgnoreProtection = false
self.BulletPenetration = 50

self.CrossHair 		= false
self.CenterDot 		= false
self.CrosshairOffset= 0
self.CanBreachDoor 	= false

self.SightAtt 		= ""
self.BarrelAtt		= ""
self.UnderBarrelAtt = ""
self.OtherAtt 		= ""

self.camRecoil = {
	camRecoilUp     = {35, 45},
	camRecoilTilt   = {120, 160},
	camRecoilLeft   = {3, 7},
	camRecoilRight  = {3, 7},
}

self.gunRecoil = {
	gunRecoilUp     = {18, 32},
	gunRecoilTilt   = {12, 22},
	gunRecoilLeft   = {14, 24},
	gunRecoilRight  = {14, 24},
}



self.AimRecoilReduction 		= 3
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

--Trazadora , Balas , Velocidad , ETC--

self.BulletType 				= "5.56×45mm NATO"
self.MuzzleVelocity 			= 1006 --m/s
self.BulletDrop 				= 0 --Between 0 - 1

self.Tracer						= true
self.BulletFlare 				= false
self.TracerWidth = .15
self.TracerLightEmission = 1
self.TracerColor = Color3.fromRGB(255,63,63)
self.TracerLifeTime = .04

self.RandomTracer				= {
	Enabled = true
	,Chance = 100 -- 0-100%
}
self.TracerEveryXShots			= 3

--Otros

self.RainbowMode 				= false
self.InfraRed 					= false

self.CanBreak	= false
self.Jammed		= false


return self