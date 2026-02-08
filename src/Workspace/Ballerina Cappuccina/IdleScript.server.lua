local rig = script.Parent
local humanoid = rig:WaitForChild("Humanoid") -- or AnimationController
local animator = humanoid:WaitForChild("Animator")

-- Put your Animation object inside the rig and reference it here
local animation = rig:WaitForChild("Idle")

-- Load and play the animation
local animationTrack = animator:LoadAnimation(animation)
animationTrack:Play()

-- Optional: Make it loop
animationTrack.Looped = true