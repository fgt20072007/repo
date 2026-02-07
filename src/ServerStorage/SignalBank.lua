local ReplicatedStorage = game:GetService('ReplicatedStorage')
local Signal = require(ReplicatedStorage.Utilities.Signal)

return {
	PlotInitialized = Signal.new(),
	UpgradeAdd = Signal.new(),
	ClearEntityOnStand = Signal.new(),
	
	SpawnEvent = Signal.new(),
	SetLuck = Signal.new()
}