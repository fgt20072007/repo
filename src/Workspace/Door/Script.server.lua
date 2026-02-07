local Players = game:GetService("Players")

-- CONFIG
local OPEN_TIME = 30 -- segundos que la puerta queda abierta

-- PARTES
local door = workspace:WaitForChild("Door")
local padRed = workspace:WaitForChild("PadRed")
local padGreen = workspace:WaitForChild("PadGreen")

-- ESTADO
local playersOnRed = {}
local playersOnGreen = {}
local doorOpen = false

-- FUNCIONES
local function countPlayers(tbl)
	local n = 0
	for _ in pairs(tbl) do
		n += 1
	end
	return n
end

local function openDoor()
	door.Transparency = 0.7 -- qué tan invisible es (0 = visible, 1 = invisible)
	door.CanCollide = false
	doorOpen = true

	task.delay(OPEN_TIME, function()
		door.Transparency = 0
		door.CanCollide = true
		doorOpen = false
	end)
end

local function checkDoor()
	if doorOpen then return end

	if countPlayers(playersOnRed) >= 1 and countPlayers(playersOnGreen) >= 1 then
		openDoor()
	end
end

local function onTouch(list, hit)
	local character = hit.Parent
	local player = Players:GetPlayerFromCharacter(character)
	if not player then return end

	list[player] = true
	checkDoor()
end

local function onTouchEnded(list, hit)
	local character = hit.Parent
	local player = Players:GetPlayerFromCharacter(character)
	if not player then return end

	list[player] = nil
end

-- CONEXIONES
padRed.Touched:Connect(function(hit)
	onTouch(playersOnRed, hit)
end)

padRed.TouchEnded:Connect(function(hit)
	onTouchEnded(playersOnRed, hit)
end)

padGreen.Touched:Connect(function(hit)
	onTouch(playersOnGreen, hit)
end)

padGreen.TouchEnded:Connect(function(hit)
	onTouchEnded(playersOnGreen, hit)
end)
