local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local CollectionService = game:GetService("CollectionService")

local Packages = ReplicatedStorage:WaitForChild("Packages")
local Net = require(Packages.Net)

local Notification = Net:RemoteEvent("Notification")
local RecalcEvent = Net:RemoteEvent("RecalcPlayerSeated")

local idle_T = 1
local detectionTIME = 60
local rmv_time = 20
local check_intrvl = 1

local noParkParts: {BasePart} = {}

local function isFedsOnlyZone(part: BasePart): boolean
	if CollectionService:HasTag(part, "FedsOnly") then
		return true
	end

	local value = part:GetAttribute("FedsOnly")
	if typeof(value) == "boolean" then
		return value
	end

	return false
end

local function isPointInsidePart(part: BasePart, point: Vector3): boolean
	local localPoint = part.CFrame:PointToObjectSpace(point)
	local halfSize = part.Size * 0.5
	return math.abs(localPoint.X) <= halfSize.X
		and math.abs(localPoint.Y) <= halfSize.Y
		and math.abs(localPoint.Z) <= halfSize.Z
end

local function getCarPrimary(model: Model): BasePart?
	if model.PrimaryPart then return model.PrimaryPart end
	local seat = model:FindFirstChildOfClass("VehicleSeat")
	if seat then return seat end
	for _, desc in model:GetDescendants() do
		if desc:IsA("VehicleSeat") then return desc end
	end
	return nil
end

local function isModelInsideZone(model: Model): (boolean, boolean)
	local primary = getCarPrimary(model)
	if not primary then
		return false, false
	end
	local position = primary.Position
	local inGeneral = false
	local inFedsOnly = false
	for _, part in noParkParts do
		if not part or not part.Parent then continue end
		if isPointInsidePart(part, position) then
			if isFedsOnlyZone(part) then
				inFedsOnly = true
			else
				inGeneral = true
			end
		end
	end
	return inGeneral, inFedsOnly
end

local function getOwnerPlayer(car: Model): Player?
	local ownerName = car:GetAttribute("Owner")
	if not ownerName then return nil end
	return Players:FindFirstChild(ownerName)
end

local function isCarOwnedByFederal(car: Model): boolean
	local owner = getOwnerPlayer(car)
	if not owner then return false end
	local team = owner.Team
	if not team then return false end
	return team:HasTag("Federal")
end

local function isCarIdle(model: Model): boolean
	local primary = getCarPrimary(model)
	if not primary then return true end
	return primary.AssemblyLinearVelocity.Magnitude < idle_T
end

local function ejectAllOccupants(car: Model)
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

local function notifyOccupants(car: Model, id: string, args: {[string]: any}?)
	local notified: {[Player]: boolean} = {}

	for _, seat in car:GetDescendants() do
		if not (seat:IsA("Seat") or seat:IsA("VehicleSeat")) then continue end
		local occupant = seat.Occupant
		if not occupant then continue end
		local player = Players:GetPlayerFromCharacter(occupant.Parent)
		if player and not notified[player] then
			notified[player] = true
			Notification:FireClient(player, id, args)
		end
	end

	local owner = getOwnerPlayer(car)
	if owner and not notified[owner] then
		Notification:FireClient(owner, id, args)
	end
end

local function initZoneParts()
	local folder = workspace:FindFirstChild("CantParkHere")
	if not folder then return end

	local count = 0
	for _, descendant in folder:GetDescendants() do
		if not descendant:IsA("BasePart") then continue end
		descendant.Transparency = 1
		table.insert(noParkParts, descendant)
		count += 1
	end

	for _, child in folder:GetChildren() do
		if not child:IsA("BasePart") then continue end
		child.Transparency = 1
		if not table.find(noParkParts, child) then
			table.insert(noParkParts, child)
			count += 1
		end
	end

	folder.DescendantAdded:Connect(function(descendant)
		if not descendant:IsA("BasePart") then return end
		descendant.Transparency = 1
		table.insert(noParkParts, descendant)
	end)
	folder.DescendantRemoving:Connect(function(descendant)
		if not descendant:IsA("BasePart") then return end
		local index = table.find(noParkParts, descendant)
		if index then table.remove(noParkParts, index) end
	end)
end

local trackedCars: {[Model]: thread} = {}

local function stopTracking(car: Model)
	local thread = trackedCars[car]
	if not thread then return end
	trackedCars[car] = nil
	if coroutine.status(thread) ~= "running" then
		pcall(task.cancel, thread)
	end
end

local function startTracking(car: Model)
	if trackedCars[car] then return end

	trackedCars[car] = task.spawn(function()
		local idleTime = 0
		local warned = false
		local warningTime = 0

		while car and car.Parent do
			local inGeneral, inFedsOnly = isModelInsideZone(car)
			local inZone = inGeneral or (inFedsOnly and isCarOwnedByFederal(car))
			local idle = isCarIdle(car)

			if inZone and idle then
				idleTime += check_intrvl

				if not warned and idleTime >= detectionTIME then
					warned = true
					warningTime = 0
					notifyOccupants(car, "Parking/Warning", { time = rmv_time })
				end

				if warned then
					warningTime += check_intrvl

					if warningTime % 5 == 0 and warningTime < rmv_time then
						local remaining = rmv_time - warningTime
						notifyOccupants(car, "Parking/Countdown", { time = remaining })
					end

					if warningTime >= rmv_time then
						notifyOccupants(car, "Parking/Removed")
						ejectAllOccupants(car)
						task.delay(0.1, function()
							if car and car.Parent then car:Destroy() end
						end)
						trackedCars[car] = nil
						return
					end
				end
			else
				idleTime = 0
				warned = false
				warningTime = 0
			end

			task.wait(check_intrvl)
		end

		trackedCars[car] = nil
	end)
end

local Manager = {}

function Manager.Init()
	initZoneParts()

	for _, car in CollectionService:GetTagged("Car") do
		if not car:IsA("Model") or not car:IsDescendantOf(workspace) then continue end
		startTracking(car)
	end

	CollectionService:GetInstanceAddedSignal("Car"):Connect(function(car: Instance)
		if not car:IsA("Model") or not car:IsDescendantOf(workspace) then return end
		startTracking(car)
	end)

	CollectionService:GetInstanceRemovedSignal("Car"):Connect(function(car: Instance)
		if not car:IsA("Model") then return end
		stopTracking(car)
	end)
end

return Manager