


local COOLDOWN = 0.15


local Buttons = script.Parent:WaitForChild("Buttons")
local Gauge = script.Parent:WaitForChild("Gauge")


--> Dependencies
local Icons = require(script.Icons)


local Carlock = Gauge:WaitForChild("Gauge"):WaitForChild("CarLock")
local MobileCarLock = Buttons:WaitForChild("CarLock")

local Car = script.Parent.Car.Value
local LockedRE = Car.LockRemote

local function UpdateButtons(Locked)
	
	local IsLocked = nil
	if Locked == nil then
		IsLocked = Car:GetAttribute("Locked")
	else
		IsLocked = Locked
	end
	
	
	local Image = IsLocked and Icons.Locked or Icons.Unlocked
	
	MobileCarLock.Frame.ImageLabel.Image = Image
	Carlock.Image = Image
end
UpdateButtons()

local last = tick()
local function ToggleCarLock()
	local now = tick()
	if now - last < COOLDOWN then return end
	last = now
	
	local IsLocked = Car:GetAttribute("Locked") and true or false

	LockedRE:FireServer()
	UpdateButtons(not IsLocked)
end

Carlock.MouseButton1Down:Connect(function()
	ToggleCarLock()
end)

MobileCarLock.MouseButton1Down:Connect(function()
	ToggleCarLock()
end)