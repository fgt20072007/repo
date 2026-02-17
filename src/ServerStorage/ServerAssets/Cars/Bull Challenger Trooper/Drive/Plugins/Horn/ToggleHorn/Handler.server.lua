local ToggleHornRE = script.Parent
local DriveSeat = ToggleHornRE.Parent.DriveSeat
local Horn = DriveSeat.Horn

local FADE_TIME = 0.1
local MAX_VOLUME = 1
local STEP_INTERVAL = 0.01

Horn.Volume = 0
Horn.Looped = true
Horn:Play()

local function FadeSound(isFadingIn)
	local targetVolume = isFadingIn and MAX_VOLUME or 0
	local startVolume = Horn.Volume
	local steps = FADE_TIME / STEP_INTERVAL
	local volumeStep = (targetVolume - startVolume) / steps

	for i = 1, steps do
		Horn.Volume = Horn.Volume + volumeStep
		task.wait(STEP_INTERVAL)
	end

	Horn.Volume = targetVolume
end

ToggleHornRE.OnServerEvent:Connect(function(player, value)
	FadeSound(value)
end)
