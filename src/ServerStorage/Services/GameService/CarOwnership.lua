local ReplicatedStorage = game:GetService('ReplicatedStorage')
local Players = game:GetService('Players')

local Packages = ReplicatedStorage.Packages
local Observer = require(Packages.Observers)
local Net = require(Packages.Net)

local NotifEvent = Net:RemoteEvent('Notification')
local RecalcEvent = Net:RemoteEvent('RecalcPlayerSeated')

local Manager = {}

function Manager._HandleOccupant(seat: VehicleSeat)
	local owner = seat.Parent:GetAttribute('Owner')
	local occupant = seat.Occupant
	if not occupant then return end

	local player = Players:GetPlayerFromCharacter(occupant.Parent)
	if player and player.Name == owner then return end

	task.delay(nil, function()
		local weld = seat:WaitForChild('SeatWeld')
		if weld then weld:Destroy() end

		seat.Parent:SetNetworkOwnershipAuto()

		occupant.Jump = true
		occupant.SeatPart = nil

		if player then
			RecalcEvent:FireClient(player)
			NotifEvent:FireClient(player, 'Vehicle/IsNotOwner')
			print('h')
		end
	end)
end

local function EjectAllOccupants(car: Model)
	for _, seat in car:GetDescendants() do
		if not (seat:IsA("Seat") or seat:IsA("VehicleSeat")) then continue end

		local occupant = seat.Occupant
		if not occupant then continue end

		local weld = seat:FindFirstChild("SeatWeld")
		if weld then weld:Destroy() end

		occupant.Sit = false
		occupant.Jump = true

		local player = Players:GetPlayerFromCharacter(occupant.Parent)
		if player then RecalcEvent:FireClient(player) end
	end
end

function Manager.Init()
	Observer.observeTag('Car', function(inst: Instance)
		if not inst:IsA('Model') then return end

		local seat = inst:FindFirstChildOfClass("VehicleSeat")
		if not seat then return end

		local conn = seat:GetPropertyChangedSignal('Occupant'):Connect(function()
			Manager._HandleOccupant(seat)
		end)

		task.spawn(Manager._HandleOccupant, seat)

		return function()
			if conn then
				conn:Disconnect()
				conn = nil
			end

			EjectAllOccupants(inst)
		end
	end, {workspace})
end

return Manager