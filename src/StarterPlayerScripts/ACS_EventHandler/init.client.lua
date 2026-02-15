local plr 			= game.Players.LocalPlayer
local mouse 		= plr:GetMouse()
local cam 			= workspace.CurrentCamera
local char = plr.CharacterAdded:wait()
local hum = char:WaitForChild("Humanoid")

local User 			= game:GetService("UserInputService")
local CAS 			= game:GetService("ContextActionService")
local Run 			= game:GetService("RunService")
local TS 			= game:GetService('TweenService')
local Debris 		= game:GetService("Debris")
local PhysicsService= game:GetService("PhysicsService")

local RS 			= game.ReplicatedStorage
local ACS_Workspace = workspace:WaitForChild("ACS_WorkSpace")
local Engine 		= RS:WaitForChild("ACS_MICTLAN")
local Evt 			= Engine:WaitForChild("Events")
local Mods 			= Engine:WaitForChild("Modules")
local HUDs 			= Engine:WaitForChild("HUD")
local ArmModel 		= Engine:WaitForChild("ArmModel")
local GunModels 	= Engine:WaitForChild("GunModels")
local AttModels 	= Engine:WaitForChild("AttModels")
local AttModules  	= Engine:WaitForChild("AttModules")
local Rules			= Engine:WaitForChild("GameRules")
local PastaFx		= Engine:WaitForChild("FX")
local WhizzSounds = PastaFx:WaitForChild("WhizzSounds")
local gameRules		= require(Rules:WaitForChild("Config"))
local SpringMod 	= require(Mods:WaitForChild("Spring"))
local HitMod 		= require(Mods:WaitForChild("Hitmarker"))
local Ultil			= require(Mods:WaitForChild("Utilities"))
local newTracer = require(script:WaitForChild("Tracer")).New
local WhizzSound = {"4872110675"; "5303773495"; "5303772965"; "5303773495"; "5303772257"; "342190005"; "342190012"; "342190017"; "342190024";}
local Ignore_Model = {cam, plr.Character, ACS_Workspace.Client, ACS_Workspace.Server}
local SpeedOfSound = require(Engine:WaitForChild("GameRules").Config).SpeedOfSound

local NVG = false

local AllMaterials = Enum.Material:GetEnumItems() 
local function ProcessBatchHits(BufferData, InstanceList, Settings)
	local count = buffer.readu8(BufferData, 0)

	for i = 1, count do
		local offset = 1 + ((i - 1) * 16)

		local pX = buffer.readf32(BufferData, offset + 0)
		local pY = buffer.readf32(BufferData, offset + 4)
		local pZ = buffer.readf32(BufferData, offset + 8)
		local position = Vector3.new(pX, pY, pZ)

		local nX = buffer.readi8(BufferData, offset + 12) / 127
		local nY = buffer.readi8(BufferData, offset + 13) / 127
		local nZ = buffer.readi8(BufferData, offset + 14) / 127
		local normal = Vector3.new(nX, nY, nZ)

		local matIndex = buffer.readu8(BufferData, offset + 15)
		local material = AllMaterials[matIndex] or Enum.Material.Plastic

		local hitPart = InstanceList[i]

		if hitPart then
			HitMod.HitEffect(Ignore_Model, position, hitPart, normal, material, Settings)
		end
	end
end

local function GetWeaponSettings(Player)
	if not Player or not Player.Character then return nil end
	local weapon = Player.Character:FindFirstChildOfClass("Tool")
	if weapon then
		local configModule = weapon:FindFirstChild("GunSettings") or weapon:FindFirstChild("GunSettings")
		if configModule then
			return require(configModule)
		end
	end
	return nil
end

Evt.NVG.Event:Connect(function(Value)
	NVG = Value
end)

Evt.HitEffect.OnClientEvent:Connect(function(Shooter, HitInstances, BufferData)

	if Shooter == plr then return end

	local Settings = GetWeaponSettings(Shooter)

	if Settings then

		ProcessBatchHits(BufferData, HitInstances, Settings)
	end
end)
Evt.HeadRot.OnClientEvent:Connect(function(Player, CF)
	if Player ~= plr and Player.Character and Player.Character:FindFirstChild("HumanoidRootPart") ~= nil then
		local Neck = Player.Character.Head:FindFirstChild("Neck")
		if Neck then
			TS:Create(Neck, TweenInfo.new(.2, Enum.EasingStyle.Sine, Enum.EasingDirection.Out, 0, false, 0), {C0 = CF}):Play()
		end
	end
end)
Evt.Atirar.OnClientEvent:Connect(function(Player,Arma,Suppressor,FlashHider)
	if Player ~= plr and Arma then 
		local gun =Player.Character:FindFirstChild("S"..Arma.Name)
		if not gun then return end
		local handle = gun:FindFirstChild("Handle")
		if not handle then return end
		if Player.Character:FindFirstChild("S"..Arma.Name) and Player.Character:FindFirstChild('S'..Arma.Name).Handle:FindFirstChild("Muzzle") then
			local Muzzle = Player.Character:FindFirstChild("S"..Arma.Name).Handle.Muzzle
			local Chamber = Player.Character:FindFirstChild("S"..Arma.Name).Handle.Chamber

			if Suppressor then
				local newSound = Muzzle.Supressor:Clone()
				newSound.PlaybackSpeed = newSound.PlaybackSpeed + math.random(-20,20) / 1000
				newSound.Parent = Muzzle
				newSound.Name = "Firing"
				newSound:Play()
				newSound.PlayOnRemove = true
				newSound:Destroy()
			else
				local newSound = Muzzle.Fire:Clone()
				newSound.PlaybackSpeed = newSound.PlaybackSpeed + math.random(-100,100) / 1000
				newSound.Parent = Muzzle
				newSound.Name = "Firing"
				newSound:Play()
				newSound.PlayOnRemove = true
				newSound:Destroy()
			end

			if Muzzle:FindFirstChild("Echo") then
				local newSound = Muzzle.Echo:Clone()
				newSound.PlaybackSpeed = newSound.PlaybackSpeed + math.random(-100,100) / 1000
				newSound.Parent = Muzzle
				newSound.Name = "FireEcho"
				newSound:Play()
				newSound.PlayOnRemove = true
				newSound:Destroy()
			end
			if Muzzle:FindFirstChild("Far") then
				local newSound = Muzzle.Far:Clone()
				newSound.PlaybackSpeed = newSound.PlaybackSpeed + math.random(-100,100) / 1000
				newSound.Parent = Muzzle
				newSound.Name = "FireEcho"
				newSound:Play()
				newSound.PlayOnRemove = true
				newSound:Destroy()
			end
			if Muzzle:FindFirstChild("Medium") then
				local newSound = Muzzle.Medium:Clone()
				newSound.PlaybackSpeed = newSound.PlaybackSpeed + math.random(-100,100) / 1000
				newSound.Parent = Muzzle
				newSound.Name = "FireEcho"
				newSound:Play()
				newSound.PlayOnRemove = true
				newSound:Destroy()
			end


			for _, v in pairs(Muzzle:GetChildren()) do
				if v.Name:sub(1, 7) == "FlashFX" then
					if math.random(1,2) == 1 then
						v.Enabled = true
					end
				end
				if v.Name:sub(1, 7) == "Smoke" then
					v.Enabled = true
				end
			end
			for _, a in pairs(Chamber:GetChildren()) do
				if a.Name:sub(1, 7) == "FlashFX" or a.Name:sub(1, 7) == "Smoke" then
					a.Enabled = true
				end
			end

			delay(1 / 30, function()
				for _, v in pairs(Muzzle:GetChildren()) do
					if v.Name:sub(1, 7) == "FlashFX" or v.Name:sub(1, 7) == "Smoke" then
						v.Enabled = false
					end
				end

				for _, a in pairs(Chamber:GetChildren()) do
					if a.Name:sub(1, 7) == "FlashFX" or a.Name:sub(1, 7) == "Smoke" then
						a.Enabled = false
					end
				end
			end)
		end

		if Player.Character:FindFirstChild("AnimBase") ~= nil and Player.Character.AnimBase:FindFirstChild("AnimBaseW") then
			local AnimBase = Player.Character:WaitForChild("AnimBase"):WaitForChild("AnimBaseW")
			local gunSettings = require(Arma.GunSettings)
			local Culatazo = gunSettings.Culatazo

			TS:Create(AnimBase, TweenInfo.new(0.1,Enum.EasingStyle.Back), {C1 =  CFrame.new(0,0,Culatazo)* CFrame.Angles(math.rad(5), math.rad(0), math.rad(0)):Inverse()} ):Play()
			delay(.1,function()
				TS:Create(AnimBase, TweenInfo.new(.1,Enum.EasingStyle.Bounce), {C1 =  CFrame.new():Inverse()} ):Play()
			end)
		end
	end
end)
Evt.Melee.OnClientEvent:Connect(function(Player,Arma,Suppressor,FlashHider)
	if Player ~= plr and Arma then 
		if Player.Character:FindFirstChild("AnimBase") ~= nil and Player.Character.AnimBase:FindFirstChild("AnimBaseW") then
			local AnimBase = Player.Character:WaitForChild("AnimBase"):WaitForChild("AnimBaseW")
			if Player.Character:FindFirstChild("S"..Arma.Name) and Player.Character:FindFirstChild('S'..Arma.Name).Handle:FindFirstChild("Muzzle") then
				local Muzzle = Player.Character:FindFirstChild("S"..Arma.Name).Handle
				local newSound = Muzzle.Swing:Clone()
				newSound.PlaybackSpeed = newSound.PlaybackSpeed + math.random(-100,100) / 1000
				newSound.Parent = Muzzle
				newSound.Name = "Firing"
				newSound:Play()
				newSound.PlayOnRemove = true
				newSound:Destroy()
				TS:Create(AnimBase, TweenInfo.new(.6,Enum.EasingStyle.Elastic), {C1 =  CFrame.new(0.3,0,0.5) * CFrame.Angles(math.rad(-50), math.rad(0), math.rad(0)):Inverse()} ):Play()
				delay(.1,function()
					TS:Create(AnimBase, TweenInfo.new(1,Enum.EasingStyle.Bounce), {C1 =  CFrame.new():Inverse()} ):Play()
				end)
			end
		end
	end
end)

Evt.Whizz.OnClientEvent:connect(function(btype,bspeed,loud)
	local Sound
	local Folder = WhizzSounds:FindFirstChild(btype)
	if Folder then -- custom whizz sounds
		while Folder:IsA("ObjectValue") do
			Folder = Folder.Value
		end
		local sounds = Folder:GetChildren()

		if Folder:FindFirstChild("supersonic") then
			if bspeed > SpeedOfSound then
				sounds = Folder.supersonic:GetChildren()
			elseif Folder:FindFirstChild("subsonic") then
				sounds = Folder.subsonic:GetChildren()
			else
				sounds = WhizzSounds.subsonic:GetChildren()
			end

		elseif Folder:FindFirstChild("subsonic") then
			if bspeed > SpeedOfSound then
				sounds = WhizzSounds.supersonic:GetChildren()
			else
				sounds = Folder.subsonic:GetChildren()
			end
		end

		Sound = sounds[math.random(#sounds)]:Clone()

	else
		local Folder
		if bspeed > SpeedOfSound then
			Folder = WhizzSounds.supersonic
		else
			Folder = WhizzSounds.subsonic
		end
		local sounds = Folder:GetChildren()
		Sound = sounds[math.random(#sounds)]:Clone()
	end


	local eff = Instance.new("EqualizerSoundEffect")
	eff.Name = "DistEQ"
	eff.LowGain =12
	eff.MidGain = 0
	eff.HighGain = 38
	eff.Parent = Sound

	Sound.Parent = plr.PlayerGui
	Sound.Volume = loud
	Sound.PlayOnRemove = true
	Sound:Destroy()
end)

Evt.Suppression.OnClientEvent:Connect(function(Mode,Intensity,Tempo)
	local SE_GUI = plr.PlayerGui:FindFirstChild("StatusUI")
	if plr.Character and plr.Character.Humanoid.Health > 0 and SE_GUI then
		if Mode == 1 then

			TS:Create(SE_GUI.Efeitos.Suppress,TweenInfo.new(.1),{ImageTransparency = 0, Size = UDim2.fromScale(1.8,1.8)}):Play()
			delay(.1,function()
				TS:Create(SE_GUI.Efeitos.Suppress,TweenInfo.new(.5,Enum.EasingStyle.Exponential,Enum.EasingDirection.InOut,0,false,0.15),{ImageTransparency = 1,Size = UDim2.fromScale(2,2)}):Play()
			end)
		end
	end
end)

Evt.GunStance.OnClientEvent:Connect(function(Player,stance,Data)
	local Weapon = Player.Character:FindFirstChildOfClass("Tool")
	if Player.Character.Humanoid.Health > 0 and Player.Character:FindFirstChild("AnimBase") ~= nil and Player.Character.AnimBase:FindFirstChild("RAW") ~= nil and Player.Character.AnimBase:FindFirstChild("LAW") ~= nil then

		local Right_Weld = Player.Character.AnimBase:WaitForChild("RAW")
		local Left_Weld = Player.Character.AnimBase:WaitForChild("LAW")

		local RightElbow = Player.Character.AnimBase:WaitForChild("RLAW")
		local LeftElbow = Player.Character.AnimBase:WaitForChild("LLAW")

		local RightWrist = Player.Character.AnimBase:WaitForChild("RHW")
		local LeftWrist = Player.Character.AnimBase:WaitForChild("LHW")

		local RECFrame =  CFrame.new(0,Player.Character.RightUpperArm.Size.Y/2,0)
		local RWCFrame =  CFrame.new(0,Player.Character.RightLowerArm.Size.Y/1.9,0)

		local LECFrame =  CFrame.new(0,Player.Character.LeftUpperArm.Size.Y/2,0)
		local LWCFrame =  CFrame.new(0,Player.Character.LeftLowerArm.Size.Y/1.9,0)

		if stance == 0 then

			TS:Create(Right_Weld, TweenInfo.new(.25,Enum.EasingStyle.Sine), {C0 = Data.SV_RightArmPos} ):Play()
			TS:Create(RightElbow, TweenInfo.new(.25,Enum.EasingStyle.Sine), {C0 = RECFrame * Data.SV_RightElbowPos} ):Play()
			TS:Create(RightWrist, TweenInfo.new(.25,Enum.EasingStyle.Sine), {C0 = RWCFrame * Data.SV_RightWristPos} ):Play()

			TS:Create(Left_Weld, TweenInfo.new(.25,Enum.EasingStyle.Sine), {C0 = Data.SV_LeftArmPos} ):Play()
			TS:Create(LeftElbow, TweenInfo.new(.25,Enum.EasingStyle.Sine), {C0 = LECFrame * Data.SV_LeftElbowPos} ):Play()
			TS:Create(LeftWrist, TweenInfo.new(.25,Enum.EasingStyle.Sine), {C0 = LWCFrame * Data.SV_LeftWristPos} ):Play()

		elseif stance == 2 then

			TS:Create(Right_Weld, TweenInfo.new(.25,Enum.EasingStyle.Sine), {C0 = Data.RightAim} ):Play()
			TS:Create(RightElbow, TweenInfo.new(.25,Enum.EasingStyle.Sine), {C0 = RECFrame * Data.RightElbowAim} ):Play()
			TS:Create(RightWrist, TweenInfo.new(.25,Enum.EasingStyle.Sine), {C0 = RWCFrame * Data.RightWristAim} ):Play()

			TS:Create(Left_Weld, TweenInfo.new(.25,Enum.EasingStyle.Sine), {C0 = Data.LeftAim} ):Play()
			TS:Create(LeftElbow, TweenInfo.new(.25,Enum.EasingStyle.Sine), {C0 = LECFrame * Data.LeftElbowAim} ):Play()
			TS:Create(LeftWrist, TweenInfo.new(.25,Enum.EasingStyle.Sine), {C0 = LWCFrame * Data.LeftWristAim} ):Play()


		elseif stance == -2 then

			TS:Create(Right_Weld, TweenInfo.new(.25,Enum.EasingStyle.Sine), {C0 = Data.RightPatrol} ):Play()
			TS:Create(RightElbow, TweenInfo.new(.25,Enum.EasingStyle.Sine), {C0 = RECFrame * Data.RightElbowPatrol} ):Play()
			TS:Create(RightWrist, TweenInfo.new(.25,Enum.EasingStyle.Sine), {C0 = RWCFrame * Data.RightWristPatrol} ):Play()

			TS:Create(Left_Weld, TweenInfo.new(.25,Enum.EasingStyle.Sine), {C0 = Data.LeftPatrol} ):Play()
			TS:Create(LeftElbow, TweenInfo.new(.25,Enum.EasingStyle.Sine), {C0 = LECFrame * Data.LeftElbowPatrol} ):Play()
			TS:Create(LeftWrist, TweenInfo.new(.25,Enum.EasingStyle.Sine), {C0 = LWCFrame * Data.LeftWristPatrol} ):Play()

		elseif stance == 4 then
			TS:Create(Right_Weld, TweenInfo.new(.25,Enum.EasingStyle.Sine), {C0 = Data.RightLowReady} ):Play()
			TS:Create(RightElbow, TweenInfo.new(.25,Enum.EasingStyle.Sine), {C0 = RECFrame * Data.RightElbowLowReady} ):Play()
			TS:Create(RightWrist, TweenInfo.new(.25,Enum.EasingStyle.Sine), {C0 = RWCFrame * Data.RightWristLowReady} ):Play()

			TS:Create(Left_Weld, TweenInfo.new(.25,Enum.EasingStyle.Sine), {C0 = Data.LeftLowReady} ):Play()
			TS:Create(LeftElbow, TweenInfo.new(.25,Enum.EasingStyle.Sine), {C0 = LECFrame * Data.LeftElbowLowReady} ):Play()
			TS:Create(LeftWrist, TweenInfo.new(.25,Enum.EasingStyle.Sine), {C0 = LWCFrame * Data.LeftWristLowReady} ):Play()

		elseif stance == 3 then

			TS:Create(Right_Weld, TweenInfo.new(.25,Enum.EasingStyle.Sine), {C0 = Data.RightSprint} ):Play()
			TS:Create(RightElbow, TweenInfo.new(.25,Enum.EasingStyle.Sine), {C0 = RECFrame * Data.RightElbowSprint} ):Play()
			TS:Create(RightWrist, TweenInfo.new(.25,Enum.EasingStyle.Sine), {C0 = RWCFrame * Data.RightWristSprint} ):Play()

			TS:Create(Left_Weld, TweenInfo.new(.25,Enum.EasingStyle.Sine), {C0 = Data.LeftSprint} ):Play()
			TS:Create(LeftElbow, TweenInfo.new(.25,Enum.EasingStyle.Sine), {C0 = LECFrame * Data.LeftElbowSprint} ):Play()
			TS:Create(LeftWrist, TweenInfo.new(.25,Enum.EasingStyle.Sine), {C0 = LWCFrame * Data.LeftWristSprint} ):Play()

		end
	end
end)

function CastRay(Bullet)
	if Bullet then
		local BulletPos = Bullet.Position
		local Bpos2 = BulletPos
		local recast = false
		local raycastResult

		local raycastParams = RaycastParams.new()
		raycastParams.FilterDescendantsInstances = Ignore_Model
		raycastParams.FilterType = Enum.RaycastFilterType.Exclude
		raycastParams.IgnoreWater = true

		while Bullet do
			Run.Heartbeat:Wait()
			if Bullet.Parent ~= nil then
				BulletPos = Bullet.Position
				raycastResult = workspace:Raycast(Bpos2, (BulletPos - Bpos2) * 1, raycastParams)

				recast = false

				if raycastResult then
					local Hit2 = raycastResult.Instance

					if Hit2 and (Hit2.Parent:IsA('Accessory') or Hit2.Parent:IsA('Hat') or Hit2.Transparency >= 1 or Hit2.CanCollide == false or Hit2.Name == "Ignorable" or Hit2.Name == "Glass" or Hit2.Name == "Ignore" or Hit2.Parent.Name == "Top" or Hit2.Parent.Name == "Helmet" or Hit2.Parent.Name == "Up" or Hit2.Parent.Name == "Down" or Hit2.Parent.Name == "Face" or Hit2.Parent.Name == "Olho" or Hit2.Parent.Name == "Headset" or Hit2.Parent.Name == "Numero" or Hit2.Parent.Name == "Vest" or Hit2.Parent.Name == "Chest" or Hit2.Parent.Name == "Waist" or Hit2.Parent.Name == "Back" or Hit2.Parent.Name == "Belt" or Hit2.Parent.Name == "Leg1" or Hit2.Parent.Name == "Leg2" or Hit2.Parent.Name == "Arm1"  or Hit2.Parent.Name == "Arm2") and Hit2.Name ~= 'Right Arm' and Hit2.Name ~= 'Left Arm' and Hit2.Name ~= 'Right Leg' and Hit2.Name ~= 'Left Leg' and Hit2.Name ~= "UpperTorso" and Hit2.Name ~= "LowerTorso" and Hit2.Name ~= "RightUpperArm" and Hit2.Name ~= "RightLowerArm" and Hit2.Name ~= "RightHand" and Hit2.Name ~= "LeftUpperArm" and Hit2.Name ~= "LeftLowerArm" and Hit2.Name ~= "LeftHand" and Hit2.Name ~= "RightUpperLeg" and Hit2.Name ~= "RightLowerLeg" and Hit2.Name ~= "RightFoot" and Hit2.Name ~= "LeftUpperLeg" and Hit2.Name ~= "LeftLowerLeg" and Hit2.Name ~= "LeftFoot" and Hit2.Name ~= 'Armor' and Hit2.Name ~= 'EShield' then
						table.insert(Ignore_Model, Hit2)
						recast = true
						CastRay(Bullet)
						break
					end
				end

				if raycastResult and not recast then

					Bullet:Destroy()
					break
				end

				Bpos2 = BulletPos
			else
				break
			end
		end
	end
end

Evt.ServerBullet.OnClientEvent:Connect(function(Player, Origin, Direction, WeaponData, ModTable)
	if Player ~= plr and Player.Character then 
		local Bullet = Instance.new("Part",ACS_Workspace.Server)
		Bullet.Name = Player.Name.."_Bullet"
		Bullet.CanCollide = false
		Bullet.Shape = Enum.PartType.Ball
		Bullet.Transparency = 1
		Bullet.Size = Vector3.new(1,1,1)

		local BulletCF 		= CFrame.new(Origin, Direction) 
		local WalkMul 		= WeaponData.WalkMult * ModTable.WalkMult
		local BColor 		= Color3.fromRGB(255,255,255)

		if WeaponData.RainbowMode then
			BColor = Color3.fromRGB(math.random(0,255),math.random(0,255),math.random(0,255))
		else
			BColor = WeaponData.TracerColor
		end

		local TracerColor, BulletFlareColor, BulletLightColor

		if WeaponData.Tracer == true then

			TracerColor =  WeaponData.TracerColor

			task.spawn(function()
				if WeaponData.TracerDelay then
					task.wait(WeaponData.TracerDelay)
				end
				if not Bullet then return end
				newTracer(Bullet, ColorSequence.new(TracerColor), WeaponData.TracerWidth, WeaponData.TracerLifeTime, WeaponData.TracerLightEmission, WeaponData.FullTracer, WeaponData.TracerTexture)
			end)

		end

		if WeaponData.BulletLight then
			local pl = Instance.new('PointLight')
			pl.Brightness = WeaponData.BulletLightBrightness
			pl.Range = WeaponData.BulletLightRange
			pl.Color = WeaponData.BulletLightColor
			pl.Parent = Bullet
		end

		local BulletMass = Bullet:GetMass()
		local Force = Vector3.new(0,BulletMass * (196.2) - (WeaponData.BulletDrop) * (196.2), 0)
		local BF = Instance.new("BodyForce",Bullet)

		Bullet.CFrame = BulletCF
		Bullet:ApplyImpulse(Direction * WeaponData.MuzzleVelocity * ModTable.MuzzleVelocity)
		BF.Force = Force

		game.Debris:AddItem(Bullet, 5)
		CastRay(Bullet)
	end
end)

Evt.CombatLog.OnClientEvent:Connect(function(CombatLog)
	local CL = plr.PlayerGui:FindFirstChild("CombatLog")
	if CL then
		CL.Refresh:Fire(CombatLog)
	else
		local CL = HUDs.CombatLog:Clone()
		CL.Parent = plr.PlayerGui
		CL.CLS.Disabled = false
		CL.Refresh:Fire(CombatLog)
	end

end)