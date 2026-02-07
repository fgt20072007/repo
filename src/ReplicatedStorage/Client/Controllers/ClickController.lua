--!nocheck

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local SoundService = game:GetService("SoundService")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")

local Shared = ReplicatedStorage.Shared
local Assets = ReplicatedStorage.Assets

local Animations = Assets:WaitForChild("Animations")
local Networker = require(Shared.Packages:WaitForChild("networker"))
local Client = require(ReplicatedStorage.Client)
local Math = require(Shared.CustomPackages.Math)
local DNAData = require(Shared.Data.DNA)
local RankData = require(Shared.Data.Ranks)
local Interface = require(ReplicatedStorage.Interface)
local Spring = require(Shared.Packages.Spr)
local DamagedPlayerRemote = require(Shared.Remotes.DamagedPlayer):Client()

local Player = game.Players.LocalPlayer
local Character = Player.Character or Player.CharacterAdded:Wait()
local Humanoid = Character:WaitForChild("Humanoid")

local random = Random.new(tick())

local cachedHurtSounds = nil

local function GetRandomSound(): Sound?
	if cachedHurtSounds == nil then
		cachedHurtSounds = {}
		for _, instance in SoundService:GetDescendants() do
			if instance:IsA("Sound") and string.match(instance.Name, "^Hurt%d+$") then
				table.insert(cachedHurtSounds, instance)
			end
		end
	end

	if #cachedHurtSounds == 0 then return nil end

	local index = random:NextInteger(1, #cachedHurtSounds)
	return cachedHurtSounds[index]
end

local function GetRandomUDim2InFrame(frame)
	local absPos = frame.AbsolutePosition
	local absSize = frame.AbsoluteSize
	local viewport = workspace.CurrentCamera.ViewportSize

	local x = absPos.X + math.random() * absSize.X
	local y = absPos.Y + math.random() * absSize.Y

	return UDim2.fromScale(x / viewport.X, y / viewport.Y)
end

local function FadeOverheadGui(character: Model)
	local tweenInfo = TweenInfo.new(0.3, Enum.EasingStyle.Quad, Enum.EasingDirection.Out, 1, true)
	local head = character:FindFirstChild("Head")
	local playerGui = head and head:FindFirstChild("Player")
	if not playerGui then return end

	for _, guiObject in playerGui:GetDescendants() do
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
		if playerGui then playerGui.Enabled = false end
	end)
end

local ClickController = {}

function ClickController._Init(self: ClickController)
	self.Networker = Networker.client.new("ClickService", self)
	self:_SetupCombat()

	DamagedPlayerRemote:On(function(HitCharacter, Damage, Dead)
		local highlight = Instance.new("Highlight")
		local DamageIndicator = Player.PlayerGui.DamageIndicator:Clone() :: BillboardGui
		if not HitCharacter or not HitCharacter:IsA("Model") then return end

		DamageIndicator.StudsOffset =
			Vector3.new(random:NextNumber(-3, 3), random:NextNumber(-2, 2), random:NextNumber(-3, 3))
		DamageIndicator.Display.Text = `-{Damage}`
		DamageIndicator.Parent = HitCharacter.HumanoidRootPart
		DamageIndicator.Enabled = true

		highlight.OutlineTransparency = 1
		highlight.DepthMode = Enum.HighlightDepthMode.Occluded
		highlight.FillTransparency = 1
		highlight.FillColor = Color3.fromRGB(180, 0, 0)
		highlight.Parent = HitCharacter

		Spring.target(highlight, 1, 3, { FillTransparency = 0.3 })

		if Dead then
			local deathSound = SoundService.Goblin.Death:Clone()
			local deathVFX = Assets.VFX.GoblinDeath:Clone()

			deathVFX.Parent = HitCharacter.HumanoidRootPart
			deathSound.Parent = HitCharacter.HumanoidRootPart
			deathSound:Play()

			deathSound.Ended:Once(function()
				deathSound:Destroy()
			end)

			for _, part in HitCharacter:GetDescendants() do
				if not part:IsA("BasePart") then
					continue
				end

				Spring.target(part, 1, 1, { Transparency = 1 })
			end

			local head = HitCharacter:FindFirstChild("Head")
			if head then
				for _, decal in head:GetDescendants() do
					if decal:IsA("Decal") then
						Spring.target(decal, 1, 1, { Transparency = 1 })
					end
				end
			end

			FadeOverheadGui(HitCharacter)

			task.delay(0.5, function()
				deathVFX.CFrame = HitCharacter.HumanoidRootPart.CFrame * CFrame.new(0, 1.5, 0)
				deathVFX.Anchored = true
				for _, emitter in deathVFX:GetDescendants() do
					if not emitter:IsA("ParticleEmitter") then
						continue
					end
					emitter:Emit(emitter:GetAttribute("EmitCount"))
				end
			end)
		else
			local sound = GetRandomSound()
			if not sound then return end
			sound = sound:Clone()
			sound.Parent = HitCharacter.HumanoidRootPart
			sound:Play()

			sound.Ended:Connect(function()
				sound:Destroy()
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

	self:BindInput()
end

function ClickController.Spawn(self: ClickController)
	self.currencyFrame = Interface:_GetComponent({ "HUD", "HudLeft", "Currency" })
	self.currencyDisplay = Interface:_GetComponent({ "HUD", "CurrencyDisplayArea" })
	self:_SetupAutoSwing()

	local DataController = Client.Controllers.DataController
	local Profile = DataController:GetProfile(true)

	self.currencyFrame.Coins.Amount.Text = Math.FormatCurrency(Profile.Coins)
	self.currencyFrame.Shards.Amount.Text = Math.FormatCurrency(Profile.Shards)
	self:UpdateSkullsDisplay(Profile.Skulls, Profile.EquippedDNA)
	self:UpdateRankMultipliers(Profile.EquippedRank)

	DataController:OnChange("Skulls", function(new, old)
		self:UpdateSkullsDisplay(new, DataController:Get("EquippedDNA"))
		self:DisplayChange("Skulls", new - old)
	end)

	DataController:OnChange("EquippedDNA", function(new)
		local updatedProfile = DataController:GetProfile(false)
		self:UpdateSkullsDisplay(updatedProfile.Skulls, new)
	end)

	DataController:OnChange("EquippedRank", function(new)
		self:UpdateRankMultipliers(new)
	end)

	DataController:OnChange("Shards", function(new, old)
		self.currencyFrame.Shards.Amount.Text = Math.FormatCurrency(new)
		self:DisplayChange("Shards", new - old)
	end)

	DataController:OnChange("Coins", function(new, old)
		SoundService:PlayLocalSound(SoundService.SFX.CoinGain)
		self.currencyFrame.Coins.Amount.Text = Math.FormatCurrency(new)
		self:DisplayChange("Coins", new - old)
	end)
end

function ClickController.UpdateSkullsDisplay(self: ClickController, skulls: number, equippedDna: string?)
	local dnaInfo = DNAData.Sorted[equippedDna] or DNAData.Sorted.dna1
	local maxStorage = dnaInfo and dnaInfo.StorageSpace or 0
	self.currencyFrame.Skulls.Amount.Text = `{Math.FormatCurrency(skulls)}/{Math.FormatCurrency(maxStorage)}`
end

function ClickController.UpdateRankMultipliers(self: ClickController, equippedRank: string?)
	if not self.currencyFrame then return end

	local rankInfo = RankData.Sorted[equippedRank] or RankData.Sorted.Rank1
	if not rankInfo or not rankInfo.Boosts then return end

	local boosts = rankInfo.Boosts
	local coinsMult = self.currencyFrame.Coins.Frame.Icon:FindFirstChild("Mult")
	local shardsMult = self.currencyFrame.Shards.Frame.Icon:FindFirstChild("Mult")
	local skullsMult = self.currencyFrame.Skulls.Frame.Icon:FindFirstChild("Mult")

	if coinsMult then coinsMult.Text = `x{boosts.Coins}` end
	if shardsMult then shardsMult.Text = `x{boosts.Shards}` end
	if skullsMult then skullsMult.Text = `x{boosts.Skulls}` end
end

function ClickController.BindInput(self: ClickController)
	UserInputService.InputBegan:Connect(function(input, gameProcessedEvent)
		if gameProcessedEvent then return end

		if
			input.UserInputType == Enum.UserInputType.MouseButton1
			or input.UserInputType == Enum.UserInputType.Touch
		then
			self:_TrySwing()
		end
	end)
end

function ClickController._SetupCombat(self: ClickController)
	self.LastClickTime = 0
	self.Combo = 0
	self.SwingAnimations = {
		[1] = Humanoid.Animator:LoadAnimation(Animations.M1_1),
		[2] = Humanoid.Animator:LoadAnimation(Animations.M1_2),
	}
end

function ClickController._TrySwing(self: ClickController)
	if os.clock() - self.LastClickTime <= 0.4 then return end

	self.Combo = self.Combo >= #self.SwingAnimations and 1 or self.Combo + 1
	SoundService:PlayLocalSound(SoundService.Scythe[tostring(self.Combo)])
	self.SwingAnimations[self.Combo]:Play(0.15)
	self.Networker:fire("OnClick", self.Combo)
	self.LastClickTime = os.clock()
end

function ClickController._SetupAutoSwing(self: ClickController)
	local button = Interface:_GetComponent({ "HUD", "HudLeft", "Buttons", "AutoSwing" })
	if not button or button.Name ~= "AutoSwing" then return end

	self.AutoSwingButton = button
	self.AutoSwingIndicator = button:WaitForChild("Frame"):WaitForChild("Indicator")
	self.AutoSwingOn = self.AutoSwingIndicator:WaitForChild("On")
	self.AutoSwingOff = self.AutoSwingIndicator:WaitForChild("Off")

	self:_SetAutoSwing(false)

	button.MouseButton1Click:Connect(function()
		self:_SetAutoSwing(not self.AutoSwingEnabled)
	end)
end

function ClickController._SetAutoSwing(self: ClickController, enabled: boolean)
	self.AutoSwingEnabled = enabled == true

	if self.AutoSwingOn and self.AutoSwingOff then
		self.AutoSwingOn.Enabled = self.AutoSwingEnabled
		self.AutoSwingOff.Enabled = not self.AutoSwingEnabled
	end

	if self.AutoSwingEnabled then
		self:_StartAutoSwing()
	else
		self:_StopAutoSwing()
	end
end

function ClickController._StartAutoSwing(self: ClickController)
	if self.AutoSwingConnection then return end
	self.AutoSwingConnection = RunService.Heartbeat:Connect(function()
		self:_TrySwing()
	end)
end

function ClickController._StopAutoSwing(self: ClickController)
	if not self.AutoSwingConnection then return end
	self.AutoSwingConnection:Disconnect()
	self.AutoSwingConnection = nil
end

function ClickController.DisplayChange(self: ClickController, Currency, Amount)
	if Amount <= 0 then
		return
	end

	local movePos = self.currencyDisplay[Currency .. "_Move"]

	local function display(value)
		task.spawn(function()
			local position = GetRandomUDim2InFrame(self.currencyDisplay)
			local icon = self.currencyDisplay[Currency]:Clone()
			icon.Position = UDim2.fromScale(0.5, 0.5)
			icon.Title.Text = `+{Math.FormatCurrency(value)}`
			icon.Visible = true
			icon.Parent = self.currencyDisplay

			Spring.target(icon, 1, 2, { Position = position })

			task.wait(2)
			Spring.target(
				icon,
				1,
				2,
				{ Position = movePos.Position, ImageTransparency = 1, Size = UDim2.fromScale(0, 0) }
			)
			Spring.target(icon.Title, 1, 2, { TextTransparency = 1, TextStrokeTransparency = 1 })

			task.wait(1.5)
			icon:Destroy()
		end)
	end

	if Amount >= 10 then
		local base = math.floor(Amount / 5)
		local remainder = Amount - base * 5

		for i = 1, 5 do
			local value = base
			if i <= remainder then
				value += 1
			end
			display(value)
		end
	else
		display(Amount)
	end
end

type ClickController = typeof(ClickController) & {
	currencyDisplay: Frame,
	currencyFrame: Frame,
	Networker: Networker.Client?,
	AutoSwingButton: GuiButton?,
	AutoSwingIndicator: Frame?,
	AutoSwingOn: GuiObject?,
	AutoSwingOff: GuiObject?,
	AutoSwingEnabled: boolean,
	AutoSwingConnection: RBXScriptConnection?,
	SwingAnimations: { [number]: AnimationTrack },
	Combo: number,
	LastClickTime: number,
}

return ClickController