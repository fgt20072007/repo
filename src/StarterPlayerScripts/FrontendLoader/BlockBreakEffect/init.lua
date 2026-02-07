-- Services
local ReplicatedStorage = game:GetService('ReplicatedStorage')
local Players = game:GetService('Players')
local TweenService = game:GetService('TweenService')

-- Variables

-- Dependencies
local DataService = require(ReplicatedStorage.Utilities.DataService)
local RemoteBank = require(ReplicatedStorage.RemoteBank)

local BlockBreakEffect = {}
local RNG = Random.new()

function BlockBreakEffect.SpawnEffect(Amount, SpawnPosition, Color)
	local RandomAmountOfBlocks = Amount or 15
	for i = 1, RandomAmountOfBlocks do
		local Block = script.TemplateBlock:Clone()
		Block.Position = SpawnPosition
		Block.Color = Color or Color3.new(1, 1, 1)
		
		local BodyVelocity = Instance.new("BodyVelocity")
		BodyVelocity.MaxForce = Vector3.new(math.huge, math.huge, math.huge)
		BodyVelocity.P = 100
		BodyVelocity.Velocity = Vector3.new(RNG:NextNumber(-20, 20), 40, RNG:NextNumber(-20, 20))
		BodyVelocity.Parent = Block
		
		local RotationVelocity = Instance.new("BodyAngularVelocity")
		RotationVelocity.P = 10000
		RotationVelocity.MaxTorque = Vector3.new(math.huge, math.huge, math.huge)
		RotationVelocity.AngularVelocity = Vector3.new(RNG:NextNumber(10, 20), RNG:NextNumber(10, 20), RNG:NextNumber(10, 20))
		RotationVelocity.Parent = Block
		
		task.delay(0.05, function()
			BodyVelocity:Destroy()
			RotationVelocity:Destroy()
		end)
		
		Block.Parent = workspace
		
		task.delay(1, function()
			TweenService:Create(Block, TweenInfo.new(0.25, Enum.EasingStyle.Sine), {Size = Vector3.new(0, 0, 0)}):Play()
			task.wait(0.4)
			Block:Destroy()
		end)
	end
end

-- Initialization function for the script
function BlockBreakEffect:Initialize()
	RemoteBank.BlockBreakEffect.OnClientEvent:Connect(BlockBreakEffect.SpawnEffect)
end

return BlockBreakEffect
