return {
	StarterCash = 100, -- Starting cash amount
	StarterGrabAmount = 1, -- Starter grab amount
	StarterRebirth = 0, -- Starter rebirth amount (Keep)
	
	StarterStands = 10, -- Starter amount of stands
	StandsPerFloor = 10, -- Stand amount per floor of your base
	TeleportPartName = "TeleportPart", -- Name of the part to teleport to plot wise
	MaxFloors = 3, -- Max number of floors (You have to modify the template plot aswell to make this function for more floors)
	
	DistanceFromStand = 0, -- Distance of an entity from the stand underneath
	AnglesOfRotation = 180, -- Angle offset of an entity placed on a stand
	UseLowerPivotMode = false, -- If true, the stand will use the lower pivot mode (I won't offset the entity by 1/2 it's size )
	
	RebirthCash = false, -- Remove cash on rebirth
	
	MockInStudio = true, -- Use a mocked version of a datastore (No saves)
	CurrentDatastoreVersion = "0.0.6", -- Datastore version usefull for changing datastores
	
	EventId = "", -- Event id on the side
	
	SpawnOrentationOffset = -90, -- Offset of the spawn orientation of entities
	GrabAnimationId = 83340734028612, -- Animation id for grabbbing
	
	StealEntities = true, -- If entities get taken away from the player that is being stolen from
	
	GroupID = 530208229, -- Group id for group rewards
	GroupRewards = { -- Group rewards follows the base format [ObjectName] = Type 
		["Default"] = "Entity",
	},
	
	MaxEntityUpgradeSize = 1.5, -- Max size of an entity after upgrades
	StarterSize = 0.8, -- Starter size of entity 
	SizeIncrements = 0.03, -- Size increments between upgrades
	
	StarterWalkspeed = 16, -- Starter walkspeed of a player
	RebirthIncrements = 0.5, -- Multiplier increments between rebirths
	SpeedBetweenRebirths = 20, -- Speed necessary between rebirth
	
	AmountOfStandsPerBase = 8, -- Amount of stands per spawned base (not the plot base)
	
	PlotSpawnsFolder = workspace.PlotSpawns,
	PlotsFolder = workspace.Plots,
	PlotTemplate = workspace:FindFirstChild("PlotTemplate"),
	
	OfflineTime = 60 * 60 * 3, -- 3 Hours of offline time 
	
	PlaceableSurface = workspace:FindFirstChild("PlaceableSurface"),
	ClaimArea = workspace:FindFirstChild("ClaimZone"),
	AddedTimeOnDrop = 4, -- Time added once an entity is dropped
	DisappearTime = 60, -- Time taken for an entity to disappear
	
	EntitiesForMulti = 20, -- Number of entities required to get the index multiplier
	IndexMultiplier = 0.5, -- Index multiplier
	TimeBetweenEvents = 60 * 15,
	
	MythicalSpawnAmount = 10 * 60,
	SecretSpawnAmount = 20 * 60,
	GodlySpawnAmount = 30 * 60,
	
	-- EXTRA DON'T TOUCH UNLESS YOU KNOW WHAT YOU ARE DOING --
	StandTemplateName = "StandTemplate"
}