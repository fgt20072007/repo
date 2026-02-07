local padGreen = script.Parent

-- CONFIGURACIÓN
local COLOR_NORMAL = padGreen.Color
local COLOR_AL_TOCAR = Color3.fromRGB(0, 158, 0) -- 👈 CAMBIA ESTE COLOR al que quieras

local touchingPlayers = {}

padGreen.Touched:Connect(function(hit)
	local character = hit.Parent
	if not character then return end

	local humanoid = character:FindFirstChildOfClass("Humanoid")
	if not humanoid then return end

	local player = game.Players:GetPlayerFromCharacter(character)
	if not player then return end

	-- Evitar múltiples activaciones
	if touchingPlayers[player] then return end
	touchingPlayers[player] = true

	-- Cambiar color
	padGreen.Color = COLOR_AL_TOCAR
end)

padGreen.TouchEnded:Connect(function(hit)
	local character = hit.Parent
	if not character then return end

	local player = game.Players:GetPlayerFromCharacter(character)
	if not player then return end

	touchingPlayers[player] = nil

	-- Si nadie lo toca, vuelve al color normal
	if next(touchingPlayers) == nil then
		padGreen.Color = COLOR_NORMAL
	end
end)
