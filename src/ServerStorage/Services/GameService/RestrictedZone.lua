local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")

local Packages = ReplicatedStorage:WaitForChild("Packages")
local Net = require(Packages.Net)

local Notification = Net:RemoteEvent("Notification")

local COUNTDOWN_TIME = 15
local CHECK_INTERVAL = 1

local mexicoZoneParts: {BasePart} = {}
local playerTimers: {[Player]: {thread: thread?, remaining: number?}} = {}
local playerLoops: {[Player]: thread} = {}

local function isPointInsidePart(part: BasePart, point: Vector3): boolean
	if not part or not part.Parent then return false end

	local localPoint = part.CFrame:PointToObjectSpace(point)
	local halfSize = part.Size * 0.5
	local epsilon = math.max(0.01, math.min(0.1, halfSize.Magnitude * 0.001))

	if math.abs(localPoint.X) > halfSize.X + epsilon then return false end
	if math.abs(localPoint.Y) > halfSize.Y + epsilon then return false end
	if math.abs(localPoint.Z) > halfSize.Z + epsilon then return false end
	return true
end

local function isPlayerInMexicoZone(player: Player): boolean
	local character = player.Character
	if not character then return false end

	local humanoid = character:FindFirstChildOfClass("Humanoid")
	if not humanoid or humanoid.Health <= 0 then return false end

	local root = character:FindFirstChild("HumanoidRootPart")
	if not root then return false end

	local position = root.Position

	for _, part in ipairs(mexicoZoneParts) do
		if not part or not part.Parent then continue end
		if isPointInsidePart(part, position) then return true end
	end

	return false
end

local function isPlayerFederal(player: Player): boolean
	local team = player and player.Team
	if not team then return false end
	return team:HasTag("Federal")
end

local function killPlayer(player: Player)
	local character = player.Character
	if not character then return end

	local humanoid = character:FindFirstChildOfClass("Humanoid")
	if humanoid then humanoid.Health = 0 end
end

local function stopCountdown(player: Player)
	local data = playerTimers[player]
	if not data then return end

	if data.thread and coroutine.status(data.thread) ~= "running" then
		pcall(task.cancel, data.thread)
	end
	playerTimers[player] = nil
end

local function cleanupPlayer(player: Player)
	stopCountdown(player)

	local loop = playerLoops[player]
	if loop and coroutine.status(loop) ~= "running" then
		pcall(task.cancel, loop)
	end
	playerLoops[player] = nil
end

local function startCountdown(player: Player)
	if playerTimers[player] then return end

	local data = {thread = nil, remaining = COUNTDOWN_TIME, active = true}
	playerTimers[player] = data

	data.thread = task.spawn(function()
		while data.active and data.remaining and data.remaining > 0 do
			if not player or not player.Parent then break end
			if not isPlayerFederal(player) then data.active = false; break end
			if not isPlayerInMexicoZone(player) then data.active = false; break end

			Notification:FireClient(player, "RestrictedZone/Warning", {time = data.remaining})
			data.remaining -= 1
			task.wait(CHECK_INTERVAL)
		end

		if data.active and player and player.Parent and isPlayerFederal(player) and isPlayerInMexicoZone(player) then
			killPlayer(player)
		end

		playerTimers[player] = nil
	end)
end

local function revokeApproval(player: Player)
	if player:GetAttribute("Revision") == "Approved" then
		player:SetAttribute("Revision", nil)
	end
end

local function checkPlayer(player: Player)
	if isPlayerInMexicoZone(player) then
		revokeApproval(player)
		if isPlayerFederal(player) then startCountdown(player) end
	else
		stopCountdown(player)
	end
end

local function initZoneParts()
	local folder = Workspace:FindFirstChild("Restricted")
	if not folder then return end

	for _, descendant in ipairs(folder:GetDescendants()) do
		if descendant:IsA("BasePart") and descendant.Name == "Mexico" then
			descendant.Transparency = 1
			table.insert(mexicoZoneParts, descendant)
		end
	end

	folder.DescendantAdded:Connect(function(descendant)
		if not descendant:IsA("BasePart") or descendant.Name ~= "Mexico" then return end
		descendant.Transparency = 1
		table.insert(mexicoZoneParts, descendant)
	end)

	folder.DescendantRemoving:Connect(function(descendant)
		local index = table.find(mexicoZoneParts, descendant)
		if index then table.remove(mexicoZoneParts, index) end
	end)
end

local function bindPlayer(player: Player)
	if playerLoops[player] then return end

	playerLoops[player] = task.spawn(function()
		while player and player.Parent do
			checkPlayer(player)
			task.wait(CHECK_INTERVAL)
		end
	end)
end

local Manager = {}

function Manager.Init()
	initZoneParts()

	for _, player in ipairs(Players:GetPlayers()) do
		bindPlayer(player)
	end

	Players.PlayerAdded:Connect(bindPlayer)
	Players.PlayerRemoving:Connect(cleanupPlayer)
end

return Manager