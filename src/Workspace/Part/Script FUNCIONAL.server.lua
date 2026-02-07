local part = script.Parent

-- Crear ProximityPrompt si no existe
local prompt = part:FindFirstChildOfClass("ProximityPrompt") or Instance.new("ProximityPrompt")
prompt.ActionText = "Deliver the Tire"
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

	-- 🔧 Buscar la Tool "tire" (equipada o no)
	local tire =
		backpack:FindFirstChild("Tire")
		or character:FindFirstChild("Tire")

	if not tire then
		warn(player.Name .. " tried to open without a Tire")
		busy = false
		return
	end

	-- 🛞 Eliminar la tire
	tire:Destroy()

	-- 🚪 Abrir puerta
	prompt.Enabled = false
	part.CanCollide = false
	part.Transparency = 1

	print(player.Name .. " delivered the tire")

	-- ⏱️ Esperar 15 segundos
	task.wait(COOLDOWN)

	-- 🚧 Cerrar puerta
	part.CanCollide = true
	part.Transparency = 0.7
	prompt.Enabled = true

	busy = false
end)
