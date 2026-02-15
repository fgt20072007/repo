local CarModel = script.Parent.Parent
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Net = require(ReplicatedStorage.Packages.Net)
local Notification = Net:RemoteEvent("Notification")

local function JumpPlayer(humanoid:Humanoid)
	task.spawn(function()
		task.wait(.1)
		humanoid.Jump = true
	end)
end

local function OnSeat(Seat:Seat)
	Seat:GetPropertyChangedSignal("Occupant"):Connect(function()
		if not Seat.Occupant then return end
		
		local Character = Seat.Occupant.Parent
		local Player = Character and game.Players:GetPlayerFromCharacter(Character)
		if not Player then return end
		
		local CarOwner = CarModel:GetAttribute("Owner")
		if Seat:IsA("VehicleSeat") and CarOwner ~= Player.Name then
			JumpPlayer(Seat.Occupant)

			Notification:FireClient(Player, "Vehicle/IsNotOwner")
			return
		end
		
		if CarOwner and CarModel:GetAttribute("Locked") and CarOwner ~= Player.Name then
			JumpPlayer(Seat.Occupant)
			Notification:FireClient(Player, "Vehicle/DoorLocked")
		end
	end)
end

OnSeat(CarModel:FindFirstChildOfClass("VehicleSeat"))
for _, Seat:Seat in CarModel.Body.Seats:GetChildren() do
	if not Seat:IsA("Seat") then return end
	OnSeat(Seat)
end