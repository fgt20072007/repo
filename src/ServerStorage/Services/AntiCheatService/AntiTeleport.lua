local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")

local GAME_GROUP_ID = if game.CreatorType == Enum.CreatorType.Group then game.CreatorId else nil
local STAFF_RANK_MIN = 50

local tune = {
	sampleStep = 0.15,
	onFootHardJump = 95,
	carHardJump = 260,
	onFootHits = 2,
	carHits = 2,
}

local AntiTeleport = {}

local running = false
local elapsed = 0
local players = {}
local tunnelLinks = {}

local function newTracker()
	return {
		foot = {
			hits = 0,
		},
		car = {
			hits = 0,
		},
		graceUntil = 0,
		rollbackUntil = 0,
		seatUntil = 0,
		exempt = false,
		exemptChecked = false,
		nextExemptCheck = 0,
	}
end

local function getTracker(player)
	local tracker = players[player]
	if tracker then
		return tracker
	end

	tracker = newTracker()
	players[player] = tracker
	return tracker
end

local function updateExemptStatus(player, tracker, now)
	if not GAME_GROUP_ID then
		tracker.exempt = false
		tracker.exemptChecked = true
		return
	end

	if (tracker.nextExemptCheck or 0) > now then
		return
	end

	tracker.nextExemptCheck = now + 30
	local ok, rank = pcall(function()
		return player:GetRankInGroup(GAME_GROUP_ID)
	end)
	if not ok then
		return
	end

	tracker.exempt = (tonumber(rank) or 0) >= STAFF_RANK_MIN
	tracker.exemptChecked = true
end

local function clearCarSnapshot(tracker)
	local car = tracker.car
	car.model = nil
	car.pos = nil
	car.at = nil
	car.safe = nil
	car.hits = 0
end

local function slackFromPing(player)
	local ping = 0
	local ok, value = pcall(function()
		return player:GetNetworkPing()
	end)
	if ok then
		ping = math.clamp(tonumber(value) or 0, 0, 0.45)
	end
	return ping * 240
end

local function giveGrace(tracker, now, seconds)
	tracker.graceUntil = math.max(tracker.graceUntil or 0, now + seconds)
end

local function snapshot(player, tracker, now, character, humanoid, root)
	tracker.char = character
	tracker.hum = humanoid
	tracker.root = root

	local foot = tracker.foot
	foot.pos = root.Position
	foot.at = now
	foot.safe = root.CFrame
	foot.hits = 0

	local seat = humanoid.SeatPart
	tracker.seat = seat
	tracker.detained = player:GetAttribute("Detained")

	if seat and seat:IsA("VehicleSeat") and seat.Occupant == humanoid then
		local model = seat:FindFirstAncestorOfClass("Model")
		tracker.car.model = model
		if model then
			local pivot = model:GetPivot()
			tracker.car.pos = pivot.Position
			tracker.car.at = now
			tracker.car.safe = pivot
		else
			tracker.car.pos = nil
			tracker.car.at = nil
			tracker.car.safe = nil
		end
		tracker.car.hits = 0
	else
		clearCarSnapshot(tracker)
	end
end

local function bindTunnelPrompt(prompt)
	if not prompt or not prompt:IsA("ProximityPrompt") then return end
	if prompt.Name ~= "Tunnel" then return end
	if tunnelLinks[prompt] then return end

	tunnelLinks[prompt] = prompt.Triggered:Connect(function(player)
		if not player or not player:IsA("Player") then return end
		local tracker = getTracker(player)
		giveGrace(tracker, os.clock(), 2.0)
	end)
end

local function unbindTunnelPrompt(prompt)
	local conn = tunnelLinks[prompt]
	if conn then
		conn:Disconnect()
		tunnelLinks[prompt] = nil
	end
end

local function pullBackPlayer(player, tracker, now)
	if now < (tracker.rollbackUntil or 0) then return end

	local character = player.Character
	local safe = tracker.foot.safe
	if not (character and character.Parent and safe) then return end

	character:PivotTo(safe)
	tracker.rollbackUntil = now + 1.25
	giveGrace(tracker, now, 0.8)
end

local function pullBackCar(player, tracker, now, model)
	if now < (tracker.rollbackUntil or 0) then return end

	local safe = tracker.car.safe
	if model and model.Parent and safe then
		model:PivotTo(safe)
		tracker.rollbackUntil = now + 1.25
		giveGrace(tracker, now, 0.8)
		return
	end

	pullBackPlayer(player, tracker, now)
end

local function hitLimit(tracker, field, suspicious, limit)
	local value = tracker[field]
	if suspicious then
		value += 1
	else
		value = math.max(0, value - 1)
	end
	tracker[field] = value
	return value >= limit
end

local function checkFoot(player, tracker, now, root, dt, dist, pingSlack)
	local foot = tracker.foot
	local speed = math.min(root.AssemblyLinearVelocity.Magnitude, 95)
	local allowed = (speed * dt * 1.25) + 14 + pingSlack
	allowed = math.max(allowed, 24 + (pingSlack * 0.35))

	local suspicious = dist > allowed
	local veryFar = dist >= (tune.onFootHardJump + pingSlack)
	local reached = hitLimit(foot, "hits", suspicious, tune.onFootHits)

	if veryFar or reached then
		pullBackPlayer(player, tracker, now)
		foot.hits = 0
		tracker.car.hits = 0
		return true
	end

	if not suspicious then
		foot.safe = root.CFrame
	end

	return false
end

local function checkCar(player, tracker, now, currentPos, pingSlack, seat)
	local car = tracker.car
	local model = seat:FindFirstAncestorOfClass("Model")
	local pos = model and model:GetPivot().Position or currentPos
	local lastPos = car.pos or pos
	local lastAt = car.at or now
	local dt = math.max(0.05, now - lastAt)

	local move = pos - lastPos
	local dist = Vector3.new(move.X, 0, move.Z).Magnitude

	local speed = math.min(seat.AssemblyLinearVelocity.Magnitude, 300)
	local allowed = (speed * dt * 1.35) + 20 + pingSlack
	allowed = math.max(allowed, 42 + (pingSlack * 0.5))

	local suspicious = dist > allowed
	local veryFar = dist >= (tune.carHardJump + pingSlack)
	local reached = hitLimit(car, "hits", suspicious, tune.carHits)

	if veryFar or reached then
		pullBackCar(player, tracker, now, model)
		car.hits = 0
		tracker.foot.hits = 0
		return true
	end

	if not suspicious then
		tracker.foot.safe = tracker.root and tracker.root.CFrame or tracker.foot.safe
		if model then
			car.safe = model:GetPivot()
		end
	end

	car.model = model
	car.pos = pos
	car.at = now
	return false
end

local function samplePlayer(player, tracker, now)
	if not player.Parent then
		players[player] = nil
		return
	end

	if not tracker.exemptChecked or GAME_GROUP_ID then
		updateExemptStatus(player, tracker, now)
	end
	if tracker.exempt then
		return
	end

	local character = player.Character
	if not character then
		tracker.char = nil
		tracker.hum = nil
		tracker.root = nil
		tracker.foot.pos = nil
		tracker.foot.at = nil
		tracker.foot.safe = nil
		clearCarSnapshot(tracker)
		return
	end

	local humanoid = character:FindFirstChildOfClass("Humanoid")
	local root = character:FindFirstChild("HumanoidRootPart")
	if not humanoid or not root then
		return
	end

	if tracker.char ~= character or tracker.foot.pos == nil or tracker.foot.at == nil then
		snapshot(player, tracker, now, character, humanoid, root)
		giveGrace(tracker, now, 2.5)
		tracker.seatUntil = now + 1.0
		return
	end

	local detainedText = player:GetAttribute("Detained")
	if detainedText ~= tracker.detained then
		if detainedText == "Arrested" then
			giveGrace(tracker, now, 3.5)
		end
		tracker.detained = detainedText
	end

	local seat = humanoid.SeatPart
	if seat ~= tracker.seat then
		tracker.seat = seat
		tracker.seatUntil = now + 1.0
		tracker.foot.hits = 0
		tracker.car.hits = 0
	end

	local blocked = false
	if now < (tracker.graceUntil or 0) then
		blocked = true
	elseif now < (tracker.seatUntil or 0) then
		blocked = true
	elseif humanoid.Health <= 0 then
		blocked = true
	elseif root.Anchored then
		blocked = true
	end

	if blocked then
		snapshot(player, tracker, now, character, humanoid, root)
		return
	end

	local dt = now - (tracker.foot.at or now)
	if dt <= 0 then return end

	local currentPos = root.Position
	local move = currentPos - (tracker.foot.pos or currentPos)
	local dist = Vector3.new(move.X, 0, move.Z).Magnitude
	local pingSlack = slackFromPing(player)

	local driving = seat and seat:IsA("VehicleSeat") and seat.Occupant == humanoid
	if driving then
		local didRollback = checkCar(player, tracker, now, currentPos, pingSlack, seat)
		if didRollback then
			snapshot(player, tracker, now, character, humanoid, root)
			return
		end
		tracker.foot.hits = 0
	else
		local didRollback = checkFoot(player, tracker, now, root, dt, dist, pingSlack)
		if didRollback then
			snapshot(player, tracker, now, character, humanoid, root)
			return
		end
		clearCarSnapshot(tracker)
	end

	tracker.char = character
	tracker.hum = humanoid
	tracker.root = root
	tracker.foot.pos = currentPos
	tracker.foot.at = now
end

function AntiTeleport.Init()
	if running then return end
	running = true

	for _, player in Players:GetPlayers() do
		getTracker(player)
	end

	Players.PlayerAdded:Connect(function(player)
		getTracker(player)
	end)

	Players.PlayerRemoving:Connect(function(player)
		players[player] = nil
	end)

	for _, item in Workspace:GetDescendants() do
		if item:IsA("ProximityPrompt") then
			bindTunnelPrompt(item)
		end
	end

	Workspace.DescendantAdded:Connect(function(item)
		if item:IsA("ProximityPrompt") then
			bindTunnelPrompt(item)
		end
	end)

	Workspace.DescendantRemoving:Connect(function(item)
		if item:IsA("ProximityPrompt") then
			unbindTunnelPrompt(item)
		end
	end)

	RunService.Heartbeat:Connect(function(dt)
		elapsed += dt
		if elapsed < tune.sampleStep then return end
		elapsed = 0

		local now = os.clock()
		for player, tracker in players do
			samplePlayer(player, tracker, now)
		end
	end)
end

return AntiTeleport
