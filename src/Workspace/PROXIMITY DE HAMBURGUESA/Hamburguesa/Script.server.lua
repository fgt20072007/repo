local part = script.Parent
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local toolName = "Hamburger"

-- RemoteEvent
local remote = ReplicatedStorage:FindFirstChild("HideBurger")
if not remote then
	remote = Instance.new("RemoteEvent")
	remote.Name = "HideBurger"
	remote.Parent = ReplicatedStorage
end

-- ProximityPrompt
local prompt = part:FindFirstChildOfClass("ProximityPrompt")
if not prompt then
	prompt = Instance.new("ProximityPrompt")
	prompt.ActionText = "Get Burger"
	prompt.ObjectText = "Hamburger"
	prompt.HoldDuration = 0.5
	prompt.RequiresLineOfSight = false
	prompt.Parent = part
end

-- 🔍 Función para verificar si ya tiene la hamburguesa
local function hasBurger(player)
	if player.Backpack:FindFirstChild(toolName) then
		return true
	end

	if player.Character and player.Character:FindFirstChild(toolName) then
		return true
	end

	return false
end

prompt.Triggered:Connect(function(player)
	-- ❌ No dar otra si ya tiene una
	if hasBurger(player) then
		return
	end

	local tool = ReplicatedStorage:FindFirstChild(toolName)
	if tool then
		local clone = tool:Clone()
		clone.Parent = player.Backpack

		-- Avisar SOLO a ese jugador que la oculte
		remote:FireClient(player, part)
	end
end)
