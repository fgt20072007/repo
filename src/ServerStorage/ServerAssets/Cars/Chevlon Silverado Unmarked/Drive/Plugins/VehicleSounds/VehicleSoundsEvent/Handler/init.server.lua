local car = script.Parent.Parent

local driveSound = Instance.new("Sound", car.DriveSeat)
driveSound.SoundId = script.Rev.SoundId
driveSound.Volume = script.Rev.Volume
driveSound.Pitch = 0
driveSound.Looped = true

car.DriveSeat:GetPropertyChangedSignal("Occupant"):Connect(function() 
	if not car.DriveSeat.Occupant then
		driveSound:Stop()
	end	
end)

script.Parent.OnServerEvent:connect(function(player, rpm, redline, on)
	if player.Character.Humanoid ~= car.DriveSeat.Occupant then return end
	local pitch = math.max((((script.Rev.SetPitch.Value + script.Rev.SetRev.Value*rpm/redline))*on^2),script.Rev.SetPitch.Value)
	driveSound.Pitch = pitch
	if not driveSound.IsPlaying then driveSound:Play() end
end)