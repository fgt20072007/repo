local npc = script.Parent
local humanoid = npc:WaitForChild("Humanoid")

local animator = humanoid:FindFirstChildOfClass("Animator")
if not animator then
	animator = Instance.new("Animator")
	animator.Parent = humanoid
end

local anim = Instance.new("Animation")
anim.AnimationId = "rbxassetid://113144193225597"

local track = animator:LoadAnimation(anim)
track.Priority = Enum.AnimationPriority.Action
track.Looped = true
track:Play()