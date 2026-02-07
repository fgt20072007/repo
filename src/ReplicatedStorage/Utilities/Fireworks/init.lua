local Fireworks = {}

--[ Services ]--
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService('RunService')
local Debris = game:GetService("Debris")
local TweenService = game:GetService("TweenService")

--[ Variables ]--
local FireworkAssets = script.Particles

local RemoteBank = require(ReplicatedStorage.RemoteBank)

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
	if position == nil then return end
	
	task.spawn(function()
		local RandomColor = Colors[RNG:NextInteger(1, #Colors)]
		
		local NewPart = Instance.new("Part")
		NewPart.CanCollide = false
		NewPart.Anchored = true
		NewPart.CFrame = position
		NewPart.Size = Vector3.new()
		NewPart.Name = "Firework"
		NewPart.Parent = game.Workspace
		
		local Trail = FireworkAssets:FindFirstChild("Trail"):Clone();
		Trail.Parent = NewPart;
		
		local Time = RNG:NextNumber(8, 11);
		local Height = RNG:NextNumber(4,7)
		TweenService:Create(NewPart, TweenInfo.new(Time / 10, Enum.EasingStyle.Linear), {CFrame = position + Vector3.new(0, Height, 0)}):Play()

		task.wait(1)

		Trail.Enabled = false
		
		local ExplosionParticle = FireworkAssets:FindFirstChild("Explosion"):Clone();
		ExplosionParticle.Color = ColorSequence.new({ColorSequenceKeypoint.new(0, RandomColor), ColorSequenceKeypoint.new(1, RandomColor) });
		ExplosionParticle.Parent = NewPart
		ExplosionParticle:Emit(25)
		
		Debris:AddItem(NewPart, 4);
	end)
end

function Fireworks.PlayFireworks(object, playsound: boolean?, player: Player?)
	if RunService:IsServer() then
		RemoteBank.PlayFireworks:FireClient(object)
		return
	end
	
	local NumberOfFireworks = RNG:NextInteger(12, 16)
	local WhenToStop = 0
	
	if playsound then
		game.SoundService.Fireworks:Play()
	end

	while WhenToStop < NumberOfFireworks do
		MakeFirework(object.CFrame + Vector3.new(RNG:NextNumber(-4, 4), -2, RNG:NextNumber(-4, 4)))
		WhenToStop = WhenToStop + 1
	end
end

if RunService:IsClient() then
	RemoteBank.PlayFireworks.OnClientEvent:Connect(function()
		local player = game.Players.LocalPlayer
		local char = player.Character
		if char then
			local head = char:FindFirstChild("Head")
			Fireworks.PlayFireworks(head, true)
		end
	end)
end

return Fireworks