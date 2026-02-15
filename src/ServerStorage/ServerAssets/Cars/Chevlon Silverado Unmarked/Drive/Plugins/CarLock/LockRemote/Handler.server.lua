local ToggleSirenRE = script.Parent :: RemoteEvent

ToggleSirenRE.OnServerEvent:Connect(function(Player:Player)
	local Car = ToggleSirenRE.Parent
	
	local CarOwner = Car:GetAttribute("Owner")
	if CarOwner and CarOwner ~= Player.Name then return end
	
	local IsLocked = Car:GetAttribute("Locked")	and true or false
	
	print("ServerEnvetsdf", IsLocked)
	Car:SetAttribute("Locked", not IsLocked)
	
	Car.DriveSeat.DoorLock:Play()
end)