local Lighting = game:GetService("Lighting")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local SoundService = game:GetService("SoundService")

local Shared = ReplicatedStorage.Shared
local Assets = ReplicatedStorage.Assets

local VFX = Assets.VFX
local Eggs = Assets.Models:WaitForChild("Eggs")
local Pets = Assets.Models:WaitForChild("Pets")
local EggsData = Shared.Data.Eggs

local TweenPlus = require(ReplicatedStorage:WaitForChild("Tween+"))
local Interface = require(ReplicatedStorage.Interface)
local Spring = require(Shared.Packages.Spr)
local Types = require(Shared.Types)
local Module3D = require(Shared.Packages.module3d)
local Zone = require(Shared.Packages.Zone)
local Index = require(Shared.Classes.Index)
local Rarities = require(Shared.Data.Rarities)
local HatchEggRemote = require(Shared.Remotes.HatchEgg):Client()
local HatchResultRemote = require(Shared.Remotes.HatchResult):Client()

local Player = game.Players.LocalPlayer
local PlayerGui = Player:WaitForChild("PlayerGui")
local PetDisplayTemplate = PlayerGui:WaitForChild("PetDisplay")

local Camera = workspace.CurrentCamera

local CrackSounds = {
	SoundService.Egg.Crack1,
	SoundService.Egg.Crack2,
	SoundService.Egg.Crack3,
}

local Offsets = {
	CFrame.new(0, 10, -12),
	CFrame.new(7, 10, -12),
	CFrame.new(-7, 10, -12),
}

local REVEAL_DURATION = 3.5
local FLOAT_AMPLITUDE = 0.3
local FLOAT_FREQUENCY = 2

local PetController = {}

function PetController._Init(self: PetController)
	local EggDisplayTemplate = Interface:_GetComponent({ "Frames", "EggDisplays", "Template" })

	local StarterEggClone = EggDisplayTemplate:Clone()
	local StarterEggButtons = StarterEggClone:WaitForChild("Buttons")
	local StarterEggPetTemp = StarterEggClone.Container.EggSlots.Holder:WaitForChild("PetTemp")

	local newIndex = Index.new(Interface.Frames.PetIndex)
	local success, err = pcall(function()
		return newIndex:LoadPetsAsync()
	end)

	if not success then
		warn("Failed to load pets into index:", err)
	end

	StarterEggClone.Name = "StarterEgg"
	StarterEggClone.Topper.EggName.Text = "Starter Egg"

	for _, pet in require(EggsData.StarterEgg) do
		local petTempClone = StarterEggPetTemp:Clone()
		local petModelClone = Pets:FindFirstChild(pet.Name):Clone()
		local model3d = Module3D:Attach3D(petTempClone.Frame, petModelClone)

		model3d:SetDepthMultiplier(1.2)
		model3d.CurrentCamera.FieldOfView = 5
		model3d:SetCFrame(CFrame.new(0, 0, 0) * CFrame.fromOrientation(0, math.rad(90), 0))
		model3d.Visible = true

		petTempClone.Name = pet.Name
		petTempClone.Frame.Chance.Text = string.format(" %.1f%%", pet.Chance * 100, "%")
		petTempClone.LayoutOrder = math.round(pet.Chance)
		petTempClone.Visible = true
		petTempClone.Parent = StarterEggClone.Container.EggSlots.Holder
	end

	StarterEggButtons.SINGLE.MouseButton1Click:Connect(function()
		HatchEggRemote:Fire("StarterEgg", 1)
		StarterEggClone.Visible = false
	end)

	StarterEggButtons.MAX.MouseButton1Click:Connect(function()
		HatchEggRemote:Fire("StarterEgg", 3)
		StarterEggClone.Visible = false
	end)

	StarterEggClone.Parent = EggDisplayTemplate.Parent

	HatchResultRemote:On(function(result: { Types.HatchingRecord })
		self:HatchEgg(result)
	end)

	local starterEggZone = Zone.new(workspace.LobbyZones:WaitForChild("StarterEgg"))

	starterEggZone.localPlayerEntered:Connect(function()
		StarterEggClone.Visible = true
	end)

	starterEggZone.localPlayerExited:Connect(function()
		StarterEggClone.Visible = false
	end)
end

function PetController.HatchEgg(self: PetController, records: { Types.HatchingRecord })
	for index, record in records do
		task.spawn(function()
			local EggModel = Eggs:FindFirstChild(record.EggType):Clone()
			local PetModel = Pets:FindFirstChild(record.PetType):Clone()
			local scaleDown = 0.9
			local EggVfx = VFX.EggHatching:Clone()
			local PetHatchingVfx = VFX.PetHatching:Clone()
			local PetBeamsVfx = VFX.PetBeams:Clone()
			local angle = 0
			local floatTime = 0
			local cameraConnection
			local PetDisplayClone = PetDisplayTemplate:Clone()
			local vfxAnchor
			local vfxFollowPart

			local localOffset = Offsets[index] * CFrame.new(0, -10, 0)
			local currentRotation = CFrame.identity
			local showingPet = false

			local chanceText = record.PetChance >= 1 and string.format("1/%d", math.floor(1 / record.PetChance)) or string.format("%.1f%%", record.PetChance * 100)
			local rarity = Rarities.GetFromChance(record.PetChance)

			PetDisplayClone.Enabled = false

			local container = PetDisplayClone:FindFirstChild("Container")
			local isCanvasGroup = container and container:IsA("CanvasGroup")

			if container then
				container.Size = UDim2.new(0, 0, 0, 0)
				if isCanvasGroup then container.GroupTransparency = 1 end

				local nameLabel = container:FindFirstChild("name")
				local chanceLabel = container:FindFirstChild("Chance")
				local rarityLabel = container:FindFirstChild("Rarity")

				if nameLabel and nameLabel:IsA("TextLabel") then
					nameLabel.Text = record.PetType
					nameLabel.TextColor3 = rarity.Color
					if not isCanvasGroup then nameLabel.TextTransparency = 1 end
				end
				if chanceLabel and chanceLabel:IsA("TextLabel") then
					chanceLabel.Text = chanceText
					chanceLabel.TextColor3 = rarity.Color
					if not isCanvasGroup then chanceLabel.TextTransparency = 1 end
				end
				if rarityLabel and rarityLabel:IsA("TextLabel") then
					rarityLabel.Text = rarity.Name
					rarityLabel.TextColor3 = rarity.Color
					if not isCanvasGroup then rarityLabel.TextTransparency = 1 end
				end
			end

			PetModel:ScaleTo(0.001)
			PetModel:PivotTo(CFrame.new(0, -1000, 0))
			PetModel.Parent = workspace

			local petPrimaryPart = PetModel.PrimaryPart or PetModel:FindFirstChild("HumanoidRootPart") or PetModel:FindFirstChildWhichIsA("BasePart")

			EggModel:PivotTo(Camera.CFrame * Offsets[index])
			EggModel.Parent = workspace

			EggVfx.Parent = EggModel.PrimaryPart

			cameraConnection = RunService.RenderStepped:Connect(function(dt)
				local targetCFrame = Camera.CFrame * localOffset

				if showingPet then
					floatTime += dt
					angle -= dt * math.rad(45)
					local floatOffset = math.sin(floatTime * FLOAT_FREQUENCY * math.pi) * FLOAT_AMPLITUDE
					if PetModel and PetModel.Parent then
						local desiredCenter = targetCFrame * CFrame.new(0, floatOffset, 0) * CFrame.fromOrientation(0, angle, 0)
						local boxCFrame = select(1, PetModel:GetBoundingBox())
						local pivotToCenter = PetModel:GetPivot():ToObjectSpace(boxCFrame)
						PetModel:PivotTo(desiredCenter * pivotToCenter:Inverse())
					end
					if vfxAnchor and vfxFollowPart then
						vfxAnchor.CFrame = vfxFollowPart.CFrame
					end
				else
					if EggModel and EggModel.Parent and EggModel.PrimaryPart then
						EggModel:PivotTo(targetCFrame * currentRotation)
					end
				end
			end)

			task.wait(0.6)

			for i = 1, 10 do
				local right = i % 2 == 1
				local intensityMult = math.min(1, i / 6)
				currentRotation = CFrame.fromOrientation(0, 0, math.rad((right and 25 or -25) * intensityMult))
				local WaitTime = math.max(0.08, 0.35 - (i * 0.025))
				local randomSound = CrackSounds[math.random(1, #CrackSounds)]

				if i >= 4 then
					scaleDown -= 0.04
					for _, emitter in EggVfx:GetChildren() do
						if emitter:IsA("ParticleEmitter") then
							emitter.Enabled = true
							emitter.Rate = emitter.Rate * 1.15
						end
					end
				elseif i % 2 == 1 then
					for _, emitter in EggVfx:GetChildren() do
						if emitter:IsA("ParticleEmitter") then
							emitter:Emit(emitter:GetAttribute("EmitCount") or 10)
						end
					end
				end

				if not EggModel:FindFirstChild("Highlight") then
					local highlight = Instance.new("Highlight")
					highlight.OutlineTransparency = 1
					highlight.FillTransparency = 1
					highlight.FillColor = Color3.fromRGB(255, 255, 255)
					highlight.Parent = EggModel

					Spring.target(highlight, 0.8, 6, { FillTransparency = 0.15 })
					task.delay(0.15, function()
						Spring.target(highlight, 0.8, 4, { FillTransparency = 1 })
						task.delay(0.2, function()
							if highlight and highlight.Parent then highlight:Destroy() end
						end)
					end)
				end

				SoundService:PlayLocalSound(randomSound)

				TweenPlus(EggModel, { Scale = scaleDown }, {
					Time = WaitTime * 0.6,
					EasingStyle = "Back",
					EasingDirection = "Out",
					Reverses = true,
				}):Start()

				task.wait(WaitTime)
			end

			SoundService:PlayLocalSound(SoundService.Egg.PetObtainment)

			task.wait(0.1)

			showingPet = true
			localOffset = Offsets[index] * CFrame.new(0, -10, 0) * CFrame.fromOrientation(0, math.rad(180), 0)

			EggModel:Destroy()
			PetModel:PivotTo(Camera.CFrame * localOffset)

			local petAdornee = PetModel.PrimaryPart or PetModel:FindFirstChild("HumanoidRootPart") or PetModel:FindFirstChildWhichIsA("BasePart")

			if petAdornee then
				vfxAnchor = Instance.new("Part")
				vfxAnchor.Name = "PetVfxAnchor"
				vfxAnchor.Size = Vector3.new(0.2, 0.2, 0.2)
				vfxAnchor.Transparency = 1
				vfxAnchor.Anchored = true
				vfxAnchor.CanCollide = false
				vfxAnchor.CanQuery = false
				vfxAnchor.CanTouch = false
				vfxAnchor.CFrame = petAdornee.CFrame
				vfxAnchor.Parent = workspace

				vfxFollowPart = petAdornee
				PetHatchingVfx.Parent = vfxAnchor
				PetBeamsVfx.Parent = vfxAnchor

				for _, emitter in PetHatchingVfx:GetDescendants() do
					if emitter:IsA("ParticleEmitter") then
						local emitCount = emitter:GetAttribute("EmitCount") or 0
						local emitDelay = emitter:GetAttribute("EmitDelay") or 0
						local emitDuration = emitter:GetAttribute("EmitDuration")

						if emitDelay > 0 then
							task.delay(emitDelay, function()
								if emitCount > 0 then emitter:Emit(emitCount) end
								if emitDuration then
									emitter.Enabled = true
									task.delay(emitDuration, function()
										emitter.Enabled = false
									end)
								end
							end)
						else
							if emitCount > 0 then emitter:Emit(emitCount) end
							if emitDuration then
								emitter.Enabled = true
								task.delay(emitDuration, function()
									emitter.Enabled = false
								end)
							end
						end
					end

					for _, emitter in PetBeamsVfx:GetDescendants() do
						if emitter:IsA("ParticleEmitter") then
							local emitCount = emitter:GetAttribute("EmitCount") or 0
							local emitDelay = emitter:GetAttribute("EmitDelay") or 0
							local emitDuration = emitter:GetAttribute("EmitDuration")

							if emitDelay > 0 then
								task.delay(emitDelay, function()
									if emitCount > 0 then emitter:Emit(emitCount) end
									if emitDuration then
										emitter.Enabled = true
										task.delay(emitDuration, function()
											emitter.Enabled = false
										end)
									end
								end)
							else
								if emitCount > 0 then emitter:Emit(emitCount) end
								if emitDuration then
									emitter.Enabled = true
									task.delay(emitDuration, function()
										emitter.Enabled = false
									end)
								end
							end
						end
					end
				end

				PetDisplayClone.Adornee = petAdornee
				PetDisplayClone.StudsOffset = Vector3.new(0, -4.5, 0)
				PetDisplayClone.Size = UDim2.new(0, 450, 0, 180)
				PetDisplayClone.Parent = PlayerGui
				PetDisplayClone.Enabled = true

				if container then
					local targetSize = UDim2.new(0, 420, 0, 170)
					if isCanvasGroup then
						Spring.target(container, 0.7, 4, { Size = targetSize, GroupTransparency = 0 })
					else
						Spring.target(container, 0.7, 4, { Size = targetSize })
						local nameLabel = container:FindFirstChild("name")
						local chanceLabel = container:FindFirstChild("Chance")
						local rarityLabel = container:FindFirstChild("Rarity")
						if nameLabel then Spring.target(nameLabel, 0.7, 4, { TextTransparency = 0 }) end
						if chanceLabel then Spring.target(chanceLabel, 0.7, 4, { TextTransparency = 0 }) end
						if rarityLabel then Spring.target(rarityLabel, 0.7, 4, { TextTransparency = 0 }) end
					end

					task.defer(function()
						local nameLabel = container:FindFirstChild("name")
						local chanceLabel = container:FindFirstChild("Chance")
						local rarityLabel = container:FindFirstChild("Rarity")
						if nameLabel and nameLabel:IsA("TextLabel") then nameLabel.TextColor3 = rarity.Color end
						if chanceLabel and chanceLabel:IsA("TextLabel") then chanceLabel.TextColor3 = rarity.Color end
						if rarityLabel and rarityLabel:IsA("TextLabel") then rarityLabel.TextColor3 = rarity.Color end
					end)
				end
			end

			TweenPlus(PetModel, { Scale = 9 }, { Time = 0.5, EasingStyle = "Back", EasingDirection = "Out" }):Start()
			task.wait(0.5)
			TweenPlus(PetModel, { Scale = 8.5 }, { Time = 0.3, EasingStyle = "Sine", EasingDirection = "InOut" }):Start()

			local petHighlight = Instance.new("Highlight")
			petHighlight.OutlineTransparency = 0.5
			petHighlight.FillTransparency = 0.85
			petHighlight.OutlineColor = rarity.Color
			petHighlight.FillColor = rarity.Color
			petHighlight.Parent = PetModel

			task.wait(REVEAL_DURATION - 0.8)

			if container then
				if isCanvasGroup then
					Spring.target(container, 0.6, 5, { Size = UDim2.new(0, 0, 0, 0), GroupTransparency = 1 })
				else
					Spring.target(container, 0.6, 5, { Size = UDim2.new(0, 0, 0, 0) })
					local nameLabel = container:FindFirstChild("name")
					local chanceLabel = container:FindFirstChild("Chance")
					local rarityLabel = container:FindFirstChild("Rarity")
					if nameLabel then Spring.target(nameLabel, 0.6, 5, { TextTransparency = 1 }) end
					if chanceLabel then Spring.target(chanceLabel, 0.6, 5, { TextTransparency = 1 }) end
					if rarityLabel then Spring.target(rarityLabel, 0.6, 5, { TextTransparency = 1 }) end
				end
			end

			Spring.target(petHighlight, 0.5, 4, { FillTransparency = 1, OutlineTransparency = 1 })

			TweenPlus(PetModel, { Scale = 0.001 }, { Time = 0.5, EasingStyle = "Back", EasingDirection = "In" }):Start()

			task.wait(0.5)

			if cameraConnection then cameraConnection:Disconnect() end
			PetDisplayClone:Destroy()
			if vfxAnchor then vfxAnchor:Destroy() end
			PetModel:Destroy()
		end)
	end

	task.wait(REVEAL_DURATION + 2.5)
end

type PetController = typeof(PetController)

return PetController
