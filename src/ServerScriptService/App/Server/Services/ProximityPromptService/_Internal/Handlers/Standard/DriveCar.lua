--!strict

local DriveCar = {}

local function getCarSpawnerService(context: any)
	if type(context) ~= "table" then
		return nil
	end

	return context.CarSpawnerService
end

local function getGarageService(context: any)
	if type(context) ~= "table" then
		return nil
	end

	return context.GarageService
end

function DriveCar.OnTriggered(player: Player, prompt: ProximityPrompt, context: any)
	local carSpawnerService = getCarSpawnerService(context)
	if carSpawnerService == nil then
		return
	end

	local garageService = getGarageService(context)
	if garageService == nil then
		return
	end

	local driveableVehicle = carSpawnerService:SpawnDriveableCarFromPrompt(player, prompt)
	if driveableVehicle == nil then
		return
	end

	task.defer(function()
		if player.Parent ~= game:GetService("Players") then
			return
		end

		if carSpawnerService:WaitForVehicleSpawnUnlock(driveableVehicle) ~= true then
			return
		end

		carSpawnerService:SeatPlayerInDriveSeat(player, driveableVehicle)
		garageService:DestroyGarageForPlayer(player)
	end)
end

return table.freeze(DriveCar)
