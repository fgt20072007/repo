local Fireworks = {}

--[ Services ]--
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService('RunService')
local Debris = game:GetService("Debris")
local TweenService = game:GetService("TweenService")

--[ Variables ]--
local player = game.Players.LocalPlayer
local FireworkAssets = script.Particles

--[ Utils ]--
local RNG = Random.new();
local Colors = {
	Color3.fromRGB(255, 49, 49),
	Color3.fromRGB(255, 179, 55),
	Color3.fromRGB(255, 255, 53),
	Color3.fromRGB(105, 255, 79),
	Color3.fromRGB(70, 252, 255),
	Color3.fromRGB(193, 85, 255),
	Color3.fromRGB(255, 169, 225) 
};

local function MakeFirework(position : Vector3)
	if not position then return end

	task.spawn(function()
		local RandomColor = Colors[RNG:NextInteger(1, #Colors)]

		local NewPart = Instance.new("Part")
		NewPart.CanCollide = false
		NewPart.Anchored = true
		NewPart.CFrame = position
		NewPart.Size = Vector3.new()
		NewPart.Name = "Firework"
		NewPart.Parent = game.Workspace

		local TrailAsset = FireworkAssets:FindFirstChild("Trail")
		if TrailAsset then
			local Trail = TrailAsset:Clone()
			Trail.Parent = NewPart
			task.delay(1, function()
				Trail.Enabled = false
			end)
		end

		local Time = RNG:NextNumber(8, 11);
		local Height = RNG:NextNumber(4,7)
		TweenService:Create(NewPart, TweenInfo.new(Time / 10, Enum.EasingStyle.Linear), {CFrame = position + Vector3.new(0, Height, 0)}):Play()

		task.wait(1)

		local ExplosionAsset = FireworkAssets:FindFirstChild("Explosion")
		if ExplosionAsset then
			local ExplosionParticle = ExplosionAsset:Clone()
			ExplosionParticle.Color = ColorSequence.new({ColorSequenceKeypoint.new(0, RandomColor), ColorSequenceKeypoint.new(1, RandomColor)})
			ExplosionParticle.Parent = NewPart
			ExplosionParticle:Emit(25)
		end

		Debris:AddItem(NewPart, 4)
	end)
end

function Fireworks.PlayFireworks(object, playsound: boolean?, player: Player?)
	local NumberOfFireworks = RNG:NextInteger(4, 6)
	local WhenToStop = 0

	if playsound then
		game.SoundService.Fireworks:Play()
	end

	while WhenToStop < NumberOfFireworks do
		MakeFirework(object.CFrame + Vector3.new(RNG:NextNumber(-4, 4), -2, RNG:NextNumber(-4, 4)))
		WhenToStop = WhenToStop + 1
	end
end

return Fireworks