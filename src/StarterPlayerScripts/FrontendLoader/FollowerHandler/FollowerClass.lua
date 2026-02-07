local Players = game:GetService('Players')
local ReplicatedStorage = game:GetService('ReplicatedStorage')
local RemoteBank = require(ReplicatedStorage.RemoteBank)
local RunService = game:GetService('RunService')
local Player = Players.LocalPlayer
local Zone = require(ReplicatedStorage.Utilities.Zone)

local function Attack(HumanoidCFrame)
	local char = Player.Character
	if not char then return end
	RemoteBank.DropEntity:InvokeServer(true, HumanoidCFrame)
end

local function StartFollowing(model: Model, checkForElegibility, normalSpeed, startCFrame, IdleAnimationId, WalkingAnimationId)
	local Humanoid = model:FindFirstChildOfClass("Humanoid")
	if Humanoid then
		local Animator = if Humanoid then Humanoid:FindFirstChildOfClass("Animator") else if model:FindFirstChildOfClass("AnimationController") then model:FindFirstChildOfClass("AnimationController").Animator else nil

		local IdleTrack: AnimationTrack
		local WalkingTrack: AnimationTrack

		if Animator and IdleAnimationId and WalkingAnimationId then
			local IdleAnimation = Instance.new("Animation")
			IdleAnimation.AnimationId = "rbxassetid://"..IdleAnimationId
			local WalkingAnimation = Instance.new("Animation")
			WalkingAnimation.AnimationId = "rbxassetid://"..WalkingAnimationId
			IdleTrack = Animator:LoadAnimation(IdleAnimation)
			WalkingTrack = Animator:LoadAnimation(WalkingAnimation)
			IdleTrack:Play()
		end

		local PlayingAnimation = "Idle"

		task.spawn(function()
			while true do
				task.wait(0.01)
				local CurrentStatus = checkForElegibility()
				local modelRoot = model:FindFirstChild("HumanoidRootPart")

				if CurrentStatus == nil then
					Humanoid.WalkSpeed = 0
					if PlayingAnimation == "Walking" and WalkingTrack then
						IdleTrack:Play()
						WalkingTrack:Stop()
						PlayingAnimation = "Idle"
					end
					continue
				end

				if not CurrentStatus then
					Humanoid.WalkSpeed = 0
					if PlayingAnimation == "Walking" and WalkingTrack then
						IdleTrack:Play()
						WalkingTrack:Stop()
						PlayingAnimation = "Idle"
					end
					continue
				else
					Humanoid.WalkSpeed = normalSpeed
					if PlayingAnimation == "Idle" and IdleTrack then
						IdleTrack:Stop()
						WalkingTrack:Play()
						PlayingAnimation = "Walking"
					end
				end
				
				task.wait(0.25)

				if Player.Character then
					local Root = Player.Character:FindFirstChild("HumanoidRootPart")
					Humanoid:MoveTo(Root.Position, Root)
					local MagnitudeBetween = (Root.Position - model:GetPivot().Position).Magnitude
					if MagnitudeBetween and MagnitudeBetween < 10 then
						Attack(model:GetPivot())
					end
				end
			end
		end)
	end
end

return function(spawnPosition, model, baseNumber, zone, baseSpeed, i, w)
	zone.CollisionGroup = "Default"
	local NewZone = Zone.new(zone)

	local function Check()
		local CurrentAttributeValue = Player:GetAttribute("Carrying")
		if not CurrentAttributeValue then
			if NewZone:findLocalPlayer() then
				return false
			else
				return nil
			end
		elseif CurrentAttributeValue == baseNumber then
			return true
		else
			return nil
		end
	end

	local PrviousValue = false
	Player:GetAttributeChangedSignal("Carrying"):Connect(function()
		local CurrentAttributeValue = Player:GetAttribute("Carrying")
		if PrviousValue == baseNumber then
			model:PivotTo(spawnPosition)
		end
		PrviousValue = CurrentAttributeValue
	end)

	StartFollowing(model, Check, baseSpeed, spawnPosition, i, w)
end