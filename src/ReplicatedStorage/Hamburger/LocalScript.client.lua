local tool = script.Parent
local player = game.Players.LocalPlayer
local event = tool:WaitForChild("UseEvent")

local ANIM_ID = "rbxassetid://89594786143494"
local SOUND_ID = "rbxassetid://18787611572"

local clicks = 0
local canUse = true

tool.Activated:Connect(function()
	if not canUse then return end
	canUse = false

	clicks += 1
	event:FireServer("Anchor")

	local character = player.Character
	if not character then return end

	local humanoid = character:FindFirstChildOfClass("Humanoid")
	local root = character:FindFirstChild("HumanoidRootPart")
	if not humanoid or not root then return end

	-- ANIMACIÓN (SIN LOOP + PRIORIDAD ACTION 4)
	local animation = Instance.new("Animation")
	animation.AnimationId = ANIM_ID

	local track = humanoid:LoadAnimation(animation)
	track.Looped = false
	track.Priority = Enum.AnimationPriority.Action4 -- 🔥 CLAVE
	track:Play()

	-- SONIDO A LOS 2 SEGUNDOS
	task.delay(2, function()
		if root and root.Parent then
			local sound = Instance.new("Sound")
			sound.SoundId = SOUND_ID
			sound.Volume = 1
			sound.Parent = root
			sound:Play()
			game.Debris:AddItem(sound, 5)
		end
	end)

	-- ESPERAR FIN DE ANIMACIÓN
	track.Stopped:Wait()
	event:FireServer("Unanchor")

	-- DESTRUIR TOOL A LOS 5 USOS
	if clicks >= 5 then
		tool:Destroy()
	end

	canUse = true
end)
