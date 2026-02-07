local part = script.Parent

-- Crear ProximityPrompt si no existe
local prompt = part:FindFirstChildOfClass("ProximityPrompt") or Instance.new("ProximityPrompt")
prompt.ActionText = "Deliver your burger"
prompt.ObjectText = "Door"
prompt.HoldDuration = 0
prompt.RequiresLineOfSight = false
prompt.MaxActivationDistance = 10
prompt.Parent = part

local COOLDOWN = 15
local busy = false -- evita activaciones múltiples

prompt.Triggered:Connect(function(player)
	if busy then return end
	busy = true

	local character = player.Character
	if not character then busy = false return end

	local backpack = player:FindFirstChild("Backpack")
	if not backpack then busy = false return end

	-- Buscar la Hamburger (equipada o no)
	local hamburger =
		backpack:FindFirstChild("Hamburger")
		or character:FindFirstChild("Hamburger")

	if not hamburger then
		warn(player.Name .. " I try to open without a burger")
		busy = false
		return
	end

	-- 🍔 Hamburger
	hamburger:Destroy()

	-- 🚪 Abrir puerta
	prompt.Enabled = false
	part.CanCollide = false
	part.Transparency = 1

	print(player.Name .. " YES")

	-- ⏱️ Esperar 15 segundos
	task.wait(COOLDOWN)

	-- 🚧 Cerrar puerta
	part.CanCollide = true
	part.Transparency = 0.7
	prompt.Enabled = true

	busy = false
end)
