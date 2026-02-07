local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local SoundService = game:GetService("SoundService")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")

local Shared = ReplicatedStorage.Shared
local Assets = ReplicatedStorage.Assets

local Spring = require(Shared.Packages:WaitForChild("Spr"))
local Client = require(ReplicatedStorage.Client)
local DamagedGoblinRemote = require(Shared.Remotes:WaitForChild("DamagedGoblin")):Client()
local CollectDroppablesRemote = require(Shared.Remotes:WaitForChild("CollectDroppables")):Client()

local Player = game.Players.LocalPlayer
local PlayerGui = Player.PlayerGui

local random = Random.new(tick())

local function FadeOverheadGui(character: Model)
	local tweenInfo = TweenInfo.new(0.3, Enum.EasingStyle.Quad, Enum.EasingDirection.Out, 1, true)
	local head = character:FindFirstChild("Head")
	local health = head and head:FindFirstChild("Health")
	local container = health and health:FindFirstChild("Container")
	if not (container and container:IsA("Frame")) then return end

	TweenService:Create(container, tweenInfo, {
		BackgroundTransparency = 1,
	}):Play()

	for _, guiObject in container:GetDescendants() do
		if guiObject:IsA("TextLabel") or guiObject:IsA("TextButton") then
			TweenService:Create(guiObject, tweenInfo, {
				TextTransparency = 1,
				TextStrokeTransparency = 1,
				BackgroundTransparency = 1,
			}):Play()
		elseif guiObject:IsA("ImageLabel") or guiObject:IsA("ImageButton") then
			TweenService:Create(guiObject, tweenInfo, {
				ImageTransparency = 1,
				BackgroundTransparency = 1,
			}):Play()
		elseif guiObject:IsA("Frame") then
			TweenService:Create(guiObject, tweenInfo, {
				BackgroundTransparency = 1,
			}):Play()
		end
	end

	task.delay(0.7, function()
		if container then container.Visible = false end
	end)
end

local function GetClosestGoblin()
	local maxDistance = 1000
	local closestGoblin
	local character = Player.Character or Player.CharacterAdded:Wait()
	local characterRoot = character:FindFirstChild("HumanoidRootPart")
	if not characterRoot then return nil, maxDistance end

	for _, goblinCharacter in workspace.Goblins:GetChildren() do
		local goblinRoot = goblinCharacter:FindFirstChild("HumanoidRootPart")
		local goblinHumanoid = goblinCharacter:FindFirstChildOfClass("Humanoid")
		local isDead = goblinCharacter:GetAttribute("Dead") == true
		if isDead then continue end
		if not goblinHumanoid or goblinHumanoid.Health <= 0 then continue end
		if not goblinRoot then continue end
		local distance = (characterRoot.Position - goblinRoot.Position).Magnitude

		if maxDistance > distance then
			maxDistance = distance
			closestGoblin = goblinCharacter
		end
	end

	return closestGoblin, maxDistance
end

local GoblinController = {}

function GoblinController._Init(self: GoblinController)
	DamagedGoblinRemote:On(function(goblin, damage, dead, character, droppables)
		local highlight = Instance.new("Highlight")
		local DamageIndicator = PlayerGui.DamageIndicator:Clone() :: BillboardGui
		if not goblin or not goblin:IsA("Model") then return end

		DamageIndicator.StudsOffset =
			Vector3.new(random:NextNumber(-3, 3), random:NextNumber(-2, 2), random:NextNumber(-3, 3))
		DamageIndicator.Display.Text = `-{damage}`
		DamageIndicator.Parent = goblin.HumanoidRootPart
		DamageIndicator.Enabled = true

		highlight.OutlineTransparency = 1
		highlight.DepthMode = Enum.HighlightDepthMode.Occluded
		highlight.FillTransparency = 1
		highlight.FillColor = Color3.fromRGB(180, 0, 0)
		highlight.Parent = goblin

		Spring.target(highlight, 1, 3, { FillTransparency = 0.3 })

		if dead then
			goblin:SetAttribute("Dead", true)
			local deathSound = SoundService.Goblin.Death:Clone()
			local deathVFX = Assets.VFX.GoblinDeath:Clone()

			deathVFX.Parent = goblin.HumanoidRootPart
			deathSound.Parent = goblin.HumanoidRootPart
			deathSound:Play()

			deathSound.Ended:Once(function()
				deathSound:Destroy()
			end)

			for _, part in goblin:GetDescendants() do
				if not part:IsA("BasePart") then
					continue
				end

				part.CanCollide = false
				Spring.target(part, 1, 1, { Transparency = 1 })
			end

			local head = goblin:FindFirstChild("Head")
			if head then
				for _, decal in head:GetDescendants() do
					if decal:IsA("Decal") then
						Spring.target(decal, 1, 1, { Transparency = 1 })
					end
				end
			end

			FadeOverheadGui(goblin)

			task.delay(0.5, function()
				deathVFX.CFrame = goblin.HumanoidRootPart.CFrame * CFrame.new(0, 1.5, 0)
				deathVFX.Anchored = true
				for _, emitter in deathVFX:GetDescendants() do
					if not emitter:IsA("ParticleEmitter") then
						continue
					end
					emitter:Emit(emitter:GetAttribute("EmitCount"))
				end
			end)
		end

		task.wait(0.4)
		Spring.stop(highlight, "FillTransparency")
		Spring.target(highlight, 1, 2.5, { FillTransparency = 1 })
		Spring.target(DamageIndicator, 1, 2, { StudsOffset = DamageIndicator.StudsOffset + Vector3.new(0, 2, 0) })
		Spring.target(DamageIndicator.Display, 1, 2, { TextTransparency = 1 })

		task.wait(2)
		highlight:Destroy()
		DamageIndicator:Destroy()
	end)

	CollectDroppablesRemote:On(function(droppables, character)
		local connection

		connection = RunService.Heartbeat:Connect(function(dt)
			character = Player.Character or Player.CharacterAdded:Wait()
			local root = character.HumanoidRootPart
			local rootPos = root.Position

			if #droppables == 0 then
				connection:Disconnect()
				connection = nil
				return
			end

			for i = #droppables, 1, -1 do
				local droppable = droppables[i]
				if not droppable or not droppable.Parent then
					table.remove(droppables, i)
					continue
				end

				local delta = rootPos - droppable.Position
				local dist = delta.Magnitude

				if dist <= 2 then
					droppable:Destroy()
					table.remove(droppables, i)
					continue
				end

				local step = math.min(dist, dt * 120)
				droppable.CFrame = CFrame.new(droppable.Position + delta.Unit * step)
			end
		end)
	end)

	RunService.RenderStepped:Connect(function(deltaTime)
		local closestGoblin, maxDistance = GetClosestGoblin()

		if not closestGoblin or maxDistance >= 12 then
			return
		end

		local character = Player.Character or Player.CharacterAdded:Wait()
		local root = character:FindFirstChild("HumanoidRootPart")
		if not root then return end
		local rootPos = root.Position
		local goblinRoot = closestGoblin:FindFirstChild("HumanoidRootPart")
		local goblinHumanoid = closestGoblin:FindFirstChildOfClass("Humanoid")
		if closestGoblin:GetAttribute("Dead") == true then return end
		if not goblinHumanoid or goblinHumanoid.Health <= 0 then return end
		if not goblinRoot then return end

		local lookDir = Vector3.new(
			goblinRoot.Position.X - rootPos.X,
			0,
			goblinRoot.Position.Z - rootPos.Z
		)

		if lookDir.Magnitude == 0 then
			return
		end

		lookDir = lookDir.Unit
		local forward = root.CFrame.LookVector
		local dot = forward:Dot(lookDir)

		local targetCFrame = CFrame.new(rootPos, rootPos + lookDir)

		if dot < 0 then
			root.CFrame = root.CFrame:Lerp(targetCFrame, math.clamp(6 * deltaTime, 0, 1))
		else
			root.CFrame = targetCFrame
		end
	end)
end

type GoblinController = typeof(GoblinController) & {}

return GoblinController
