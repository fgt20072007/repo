
local ServerConfig = {
----------------------------------------------------------------------------------------------------
-----------------=[ General ]=----------------------------------------------------------------------
----------------------------------------------------------------------------------------------------
	 TeamKill = false					--- Enable TeamKill?
	,TeamDmgMult = 1					--- Between 0-1 | This will make you cause less damage if you hit your teammate
	
	,ReplicatedBullets = true			--- Keep in mind that some bullets will pass through surfaces...
	
	,AntiBunnyHop = true				--- Enable anti bunny hop system?
	,JumpCoolDown = 2.3			--- Seconds before you can jump again
	,JumpPower = 1.2				--- Jump power, default is 50
	,BulletDrag = 0.9			
	,ReplicatedLaser = true				--- True = Laser line is invisible
	,ReplicatedFlashlight = true
	
	,EnableRagdoll = false				--- Enable ragdoll death?
	,TeamTags = true					--- Aaaaaaa
	,HitmarkerSound = false				--- GGWP MLG 360 NO SCOPE xD
	,Crosshair = false					--- Crosshair for Hipfire shooters and arcade modes
	,CrosshairOffset = 5				--- Crosshair size offset

----------------------------------------------------------------------------------------------------
------------------=[ Core GUI ]=--------------------------------------------------------------------
----------------------------------------------------------------------------------------------------
	,CoreGuiHealth = true				--- Enable Health Bar?
	,CoreGuiPlayerList = true			--- Enable Player List?
	,TopBarTransparency = 1
----------------------------------------------------------------------------------------------------
------------------=[ Status UI ]=-------------------------------------------------------------------
----------------------------------------------------------------------------------------------------
	,EnableStatusUI 	= true				--- Don't disabled it...
	,RunWalkSpeed 		= 20
	,NormalWalkSpeed 	= 10
	

	,CrouchWalkSpeed 	= 8
	,ProneWalksSpeed 	= 5


	,LimitVisionSit = false
	,ShellSpawn = true
	,GunBobMultiplier = 3				--The more the value, the more the gun will "shake" while walking
	,GunBobReduction = 1	
	,SpeedOfSound = 1360				--- in SPS, default: 340 * 4
	,InteractionMenuKey = Enum.KeyCode.LeftAlt
----------------------------------------------------------------------------------------------------
----------------=[ Medic System ]=------------------------------------------------------------------
----------------------------------------------------------------------------------------------------

	,EnableFallDamage = false			--- Enable Fall Damage?
	,MaxVelocity = 75					--- Velocity that will trigger the damage
	,DamageMult = 1 					--- The min time a player has to fall in order to take fall damage.
----------------------------------------------------------------------------------------------------
--------------------=[ Others ]=--------------------------------------------------------------------
----------------------------------------------------------------------------------------------------
	,VehicleMaxZoom = 150
	
	,AgeRestrictEnabled = false
	,AgeLimit = 60
	
	
	,Blacklist = {1363303139, 112962460, 115267378, 496075583} 		--- Auto kick the player (via ID) when he tries to join
	,RicochetLoss = 1
	,RicochetMaterialMaxAngles = {
		default = 1,

		Plastic = 1,
		SmoothPlastic = 20,

		Wood = 1,
		WoodPlanks = 1,


		Slate = 2,
		Marble = 2,
		Granite = 2,
		Brick = 2,
		Pebble = 2,
		Concrete = 1.5,
		CeramicTiles = 1.5,
		Cobblestone = 1.5,
		Rock = 1.5,
		Sandstone = 1.5,
		Basalt = 1.5,
		Ground = 1.5,
		CrackedLava = 1.5,
		Asphalt = 1.5,
		Pavement = 1.5,
		Limestone = 1.5,

		Grass = 0.8,
		LeafyGrass = 0.8,

		CorrodedMetal = 7,
		DiamondPlate = 7,
		Metal = 20,

		Foil = 0.3,
		Fabric = 0.3,
		Neon = 0.3,
		Glass = 0.3,
		Snow = 0.3,

		Ice = 0,
		Glacier = 0,
		Sand = 0,
		Water = 0,
		Mud = 0,
		Salt = 0,
		ForceField = 20,
	}
	,WallbangMaterialHardness = {	-- resistance to wallbang penetration of each material
		default = 2,

		Plastic = 2,
		SmoothPlastic = 2,

		Wood = 2,
		WoodPlanks = 2,


		Slate = 4,
		Marble = 4,
		Granite = 4,
		Brick = 4,
		Pebble = 4,
		Concrete = 4,
		CeramicTiles = 1.5,
		Cobblestone = 4,
		Rock = 4,
		Sandstone = 4,
		Basalt = 4,
		Ground = 4,
		CrackedLava = 4,
		Asphalt = 4,
		Pavement = 4,
		Limestone = 4,

		Grass = 20,
		LeafyGrass = 0.8,

		CorrodedMetal = 5,
		DiamondPlate = 5,
		Metal = 5,

		Foil = 0.3,
		Fabric = 0.3,
		Neon = 0.3,
		Glass = 0.3,
		Snow = 0.3,

		Ice = 10,
		Glacier = 10,
		Sand = 10,
		Water = 10,
		Mud = 10,
		Salt = 10,
		ForceField = 10,
	}
	,WallbangSpecialNames = { -- parts with special names will override material based wallbang resistance
		BulletproofGlass = 2,
		Armor = 20,
	}
}
return ServerConfig
