local ToggleHornRE = script.Parent
local DriveSeat:VehicleSeat = ToggleHornRE.Parent.DriveSeat
local Horn = DriveSeat.Horn

local FADE_TIME = 0.1
local MAX_VOLUME = 1
local STEP_INTERVAL = 0.01

Horn.Volume = 0
Horn.Looped = true
Horn:Play()


local HornTask = nil

local function CancelHornTask()
	if HornTask then
		task.cancel(HornTask)
		HornTask = nil
	end
end

local function FadeSound(isFadingIn)
	
	CancelHornTask()
	
	HornTask = task.spawn(function()
		local targetVolume = isFadingIn and MAX_VOLUME or 0
		local startVolume = Horn.Volume
		local steps = FADE_TIME / STEP_INTERVAL
		local volumeStep = (targetVolume - startVolume) / steps

		for i = 1, steps do
			Horn.Volume = Horn.Volume + volumeStep
			task.wait(STEP_INTERVAL)
		end

		Horn.Volume = targetVolume
	end)
end

DriveSeat:GetPropertyChangedSignal("Occupant"):Connect(function()
	local Occupant = DriveSeat.Occupant
	if not Occupant then
		CancelHornTask()
		Horn.Volume = 0
	end
end)

ToggleHornRE.OnServerEvent:Connect(function(player, value)
	FadeSound(value)
end)
