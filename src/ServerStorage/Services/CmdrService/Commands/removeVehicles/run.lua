local ServerStorage = game:GetService('ServerStorage')

local Services = ServerStorage:WaitForChild('Services')
local DataService = require(Services:WaitForChild('DataService'))



return function(context, player: Player, amount: number)
	local playerCash = DataService.GetBalance(player)
	local PlayerData = DataService.GetManager('PlayerData')
	local PlayerVehicleData = PlayerData:Get(player, {'Vehicles'})
	
	print("aTTEMPT")
	for _, VehicleId:string in PlayerVehicleData do
		DataService.RemoveVehicle(player, table.find(PlayerVehicleData, VehicleId))
	end
	print(PlayerVehicleData)
	
	local succ = #PlayerVehicleData == 0
	return succ and `Successfully removed all player cars` or `Failed to update player cars`
end