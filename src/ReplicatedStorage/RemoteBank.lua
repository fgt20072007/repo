local ReplicatedStorage = game:GetService('ReplicatedStorage')
local TypedRemote = require(ReplicatedStorage.Utilities.TypedRemote)

return {
	Purchase  = TypedRemote.func("Purchase"),
	
	OnPurchaseStarted = TypedRemote.event("OnPurchaseStarted"),
	OnPurchaseFinished = TypedRemote.event("OnPurchaseFinished"),
	
	SendNotification = TypedRemote.event("SendNotification"),
	
	SendSystemMessage = TypedRemote.unreliable("SystemMessage"),
	
	PlayFireworks = TypedRemote.event("PlayFireworks"),
	PlaySound = TypedRemote.unreliable("PlaySound"),
	
	Rebirth = TypedRemote.func("Rebirth"),
	Drop = TypedRemote.func("Drop"),
	
	TryGroupJoin = TypedRemote.func("TryGroupJoin"),
	SpawnTsunami = TypedRemote.event("SpawnTsunami"),
	
	StandAdded = TypedRemote.event("StandAdded"),
	GetStands = TypedRemote.func("GetStands"),
	
	GetPlot = TypedRemote.func("GetPlot"),
	
	PlaceStand = TypedRemote.func("PlaceStand"),
	PickupStand = TypedRemote.func("PickupStand"),
	UpgradeStand = TypedRemote.event("UpgradeStand"),
	
	CashNotification = TypedRemote.event("CashNotification"),
	PurchaseUpgrade = TypedRemote.event("PurchaseUpgrade"),
	
	StealStand = TypedRemote.func("StealStand"),
	DropButton = TypedRemote.event("DropButton"),
	
	CompletedTutorial = TypedRemote.func("CompletedTutorial"),
	SlowModeCommunication = TypedRemote.func("SlowMode"),
	
	JumpEntity = TypedRemote.event("JumpEntity"),
	
	PlacedEntity = TypedRemote.event("PlacedEntity"),
	PromptAsk = TypedRemote.func("PromptAsk"),
	TryGifting = TypedRemote.event("TryGifting"),
	
	SellRemote = TypedRemote.func("SellRemote"),
	
	OpenStand = TypedRemote.func("OpenStand"),
	
	LuckyblockOpened = TypedRemote.event("LuckyblockOpened"),
	
	BlockBreakEffect = TypedRemote.event("BlockBreakEffect"),

	ScaleTween = TypedRemote.event("ScaleTween"),
	FOVEffect = TypedRemote.event("FOVEffect"),
	Confetti = TypedRemote.event("Confetti"),
	
	GetServerRegion = TypedRemote.func("GetServerRegion"),
	GetServerUptime = TypedRemote.func("GetServerUptime"),
	
	ScalePart = TypedRemote.event("ScalePart"),
	
	RisingLava = TypedRemote.event("RisingLava"),
	LavaRisen = TypedRemote.event("LavaRisen"),
	Overflow = TypedRemote.event("Overflow"),
	
	GotEntity = TypedRemote.event("GotEntity"),
	
	GetOfflineAmount = TypedRemote.func("GetOfflineAmount"),
	OfflineUpdated = TypedRemote.event("OfflineUpdated"),
	
	DropEntity = TypedRemote.func("DropEntity"),
	
	TryPurchaseBase = TypedRemote.func("TryPurchaseBase"),
	BasePurchased = TypedRemote.event("BasePurchased"),
	
	PurchaseGear = TypedRemote.func("PurchaseGear"),
	
}