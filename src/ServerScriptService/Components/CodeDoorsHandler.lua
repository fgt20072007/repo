-- Services
local ServerStorage = game:GetService('ServerStorage')
local CollectionService = game:GetService('CollectionService')
local ReplicatedStorage = game:GetService('ReplicatedStorage')

-- Modules
local GlobalConfiguration = require(ReplicatedStorage.DataModules.GlobalConfiguration)
local CodeDoors = require(ServerStorage.ServerModules.CodeDoors)

local CodeDoorsHandler = {}

type DoorButton = {ClickDetector: ClickDetector}
type KeyPad = Folder & {Buttons: Folder & {[string]: BasePart & DoorButton}, Clear: BasePart & DoorButton, Enter: BasePart & DoorButton, Combination: BasePart & {SurfaceGui: SurfaceGui & {TextLabel: TextLabel}}}

function CodeDoorsHandler.HandleKeyPadDoor(Door: Folder & {KeyPad: KeyPad, Openable: BasePart})
	local KeypadContainer = Door.KeyPad
	local answeringDebounce = false
	local currentCode = CodeDoors[Door.Name]
	local CurrentCombinationTable = {}
	local function GetCombinationString()
		local function get(index) return CurrentCombinationTable[math.max(#CurrentCombinationTable - (4 - index), index)] or "#" end
		return `{get(1)}{get(2)}{get(3)}{get(4)}`
	end
	local function update(entering: boolean)
		local currentCombination = GetCombinationString()
		local success = nil
		if entering then
			if tonumber(currentCombination) == currentCode then
				currentCombination = "✅"
				success = true
				-- TODO: Play the sound once answered
			else
				currentCombination = "❌"
			end
		end
		KeypadContainer.Combination.SurfaceGui.TextLabel.Text = currentCombination
		return success
	end
	
	KeypadContainer.Enter.ClickDetector.MouseClick:Connect(function()
		answeringDebounce = true
		if update(true) then
			Door.Openable.Transparency = 0.8
			Door.Openable.CanCollide = false
			task.delay(GlobalConfiguration.CorrectDoorOpenTime, function()
				Door.Openable.Transparency = 0
				Door.Openable.CanCollide = true
			end)
		end
		
		task.delay(0.4, function()
			table.clear(CurrentCombinationTable)
			answeringDebounce = false
			update(false)
		end)
	end)
	
	KeypadContainer.Clear.ClickDetector.MouseClick:Connect(function()
		table.clear(CurrentCombinationTable)
		update(false)
	end)
	
	local Buttons = KeypadContainer.Buttons
	for _, v: BasePart & DoorButton in pairs(Buttons:GetChildren()) do
		v.SurfaceGui.TextLabel.Text = v.Name
		v.ClickDetector.MouseClick:Connect(function()
			if answeringDebounce then return end
			table.insert(CurrentCombinationTable, v.Name)
			v.Color = Color3.fromRGB(161, 161, 161)
			task.delay(0.1, function()
				v.Color = Color3.fromRGB(229, 229, 229)
			end)
			update()
		end)
	end
end

function CodeDoorsHandler.Initialize()
	local CodeDoors = CollectionService:GetTagged(GlobalConfiguration.CodeDoorsTag)
	for _, codeDoorContainer in CodeDoors do
		CodeDoorsHandler.HandleKeyPadDoor(codeDoorContainer)
	end
end

return CodeDoorsHandler
