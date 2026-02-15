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
self.Ammo 			= 8
self.StoredAmmo 	= 48
self.AmmoInGun 		= self.Ammo
self.MaxStoredAmmo	= math.huge
self.CanCheckMag 	= true
self.MagCount		= true
self.ShellInsert	= false
self.ShootRate 		= 70
self.Bullets 		= 1
self.BurstShot 		= 3
self.ShootType 		= 1 --[1 = SEMI; 2 = BURST; 3 = AUTO; 4 = PUMP ACTION; 5 = BOLT ACTION]
self.FireModes = {
	ChangeFiremode = false;		
	Semi = true;
	Burst = false;
	Auto = false;}

self.LimbDamage 	= {13,13}
self.TorsoDamage 	= {16,16} 
self.HeadDamage 	= {24,24}  
self.DamageFallOf 	= 1
self.MinDamage 		= 5
self.IgnoreProtection = false
self.BulletPenetration = 50

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
	camRecoilUp 	= {5,5}
	,camRecoilTilt 	= {150,150}
	,camRecoilLeft 	= {0,0}
	,camRecoilRight = {0,0}

}


self.gunRecoil = {
	gunRecoilUp 	= {10,20}
	,gunRecoilTilt 	= {0,0}
	,gunRecoilLeft 	= {5,7}
	,DownPunch 	= -.2
	,gunRecoilRight = {5,7}
}


self.AimRecoilReduction 		= 1
self.AimSpreadReduction 		= 1

self.MinRecoilPower 			= 1
self.MaxRecoilPower 			= 1.5
self.RecoilPowerStepAmount 		= .1

self.MinSpread 					= .74
self.MaxSpread 					= 1
self.AimInaccuracyStepAmount 	= 0.25
self.AimInaccuracyDecrease 		= .25
self.WalkMult 					= 0

self.EnableZeroing 				= true
self.MaxZero 					= 500
self.ZeroIncrement 				= 50
self.CurrentZero 				= 0

--Trazadora , Balas , Velocidad , ETC--

self.BulletType 				= "9x19mm"
self.MuzzleVelocity 			= 375 --m/s
self.BulletDrop 				= 0.1 --Between 0 - 1

self.Tracer						= false
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