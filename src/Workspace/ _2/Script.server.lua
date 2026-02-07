local npc = script.Parent
local humanoid = npc:WaitForChild("Humanoid")
local hrp = npc:WaitForChild("HumanoidRootPart")

-- Mantenerlo fijo
hrp.Anchored = true
humanoid.AutoRotate = false

-- Animator
local animator = humanoid:FindFirstChildOfClass("Animator")
if not animator then
	animator = Instance.new("Animator")
	animator.Parent = humanoid
end

-- Animación
local animation = Instance.new("Animation")
animation.AnimationId = "rbxassetid://92719349154615"

local track = animator:LoadAnimation(animation)
track.Looped = true
track:Play()
