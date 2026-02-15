local TS = game:GetService('TweenService')
local module = {}

--/Sight
module.SightZoom 	= 0		-- Set to 0 if you want to use weapon's default zoom
module.SightZoom2 	= 0		--Set this to alternative zoom or Aimpart2 Zoom

--/Barrel
module.IsSuppressor 	= false
module.IsFlashHider		= false

--/UnderBarrel
module.IsBipod 			= true

--/Other
module.EnableLaser 		= false
module.EnableFlashlight = false
module.InfraRed 		= false

--/Damage Modification
module.DamageMod = 1
module.minDamageMod = 1

--/Recoil Modification
module.camRecoil = {
	RecoilUp 		= 0.5
	,RecoilTilt 	= 0.7
	,RecoilLeft 	= 0.7
	,RecoilRight 	= 0.7
}

module.gunRecoil = {
	RecoilUp 		= 0.5
	,RecoilTilt 	= 0.7
	,RecoilLeft 	= 0.7
	,RecoilRight 	= 0.7
}

module.AimRecoilReduction = 1
module.AimSpreadReduction = 1

module.MinRecoilPower 			= 1
module.MaxRecoilPower 			= 0.8
module.RecoilPowerStepAmount 	= 1

module.MinSpread 				= 0.5
module.MaxSpread 				= 0.75				
module.AimInaccuracyStepAmount 	= 1
module.AimInaccuracyDecrease 	= 1
module.WalkMult 				= 1

module.MuzzleVelocityMod	 	= 1

return module