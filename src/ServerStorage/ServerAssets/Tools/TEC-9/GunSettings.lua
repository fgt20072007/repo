local TS = game:GetService('TweenService')
local self = {}

self.SlideEx 		= CFrame.new(0,0,-0.4)
self.SlideLock 		= true

self.isAPistol = true

self.Zoom 			= 60
self.Zoom2 			= 50
self.Zoom3 			= 40
self.ADSEnabled 		= { -- Ignore this setting if not using an ADS Mesh
	false, -- Enabled for primary sight
	false} -- Enabled for secondary sight (T)

self.gunName 		= script.Parent.Name
self.Type 			= "Gun"
self.EnableHUD		= true
self.IncludeChamberedBullet = true
self.Ammo 			= 18
self.StoredAmmo 	= 180
self.AmmoInGun 		= self.Ammo
self.MaxStoredAmmo	= math.huge
self.CanCheckMag 	= true
self.MagCount		= true
self.ShellInsert	= false
self.ShootRate 		= 500
self.Bullets 		= 1
self.BurstShot 		= 3
self.ShootType 		= 3 --[1 = SEMI; 2 = BURST; 3 = AUTO; 4 = PUMP ACTION; 5 = BOLT ACTION]
self.FireModes = {
	ChangeFiremode = true;		
	Semi = true;
	Burst = false;
	Auto = true;}

self.LimbDamage 	= {17,21}
self.TorsoDamage 	= {22,22} 
self.HeadDamage 	= {29,31}  
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
	camRecoilUp 	= {15,15}
	,camRecoilTilt 	= {100,105}
	,camRecoilLeft 	= {0,0}
	,camRecoilRight = {0,0}

}


self.gunRecoil = {
	gunRecoilUp 	= {20,20}
	,gunRecoilTilt 	= {50,60}
	,gunRecoilLeft 	= {1,1}
	,gunRecoilRight = {1,2}
}


self.AimRecoilReduction 		= 1
self.AimSpreadReduction 		= 1

self.MinRecoilPower 			= 1
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

self.BulletType 				= "9×19mm"
self.MuzzleVelocity 			= 360 --m/s
self.BulletDrop 				= 0 --Between 0 - 1

self.Tracer						= true
self.BulletFlare 				= false
self.TracerWidth = .1
self.TracerLightEmission = 1
self.TracerColor = Color3.fromRGB(17, 255, 0)
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