repeat
	wait()
until game.Players.LocalPlayer.Character

local plr 			= game.Players.LocalPlayer
local char 			= plr.Character or plr.CharacterAdded:Wait()
local mouse 		= plr:GetMouse()
local cam 			= workspace.CurrentCamera

local User 			= game:GetService("UserInputService")
local CAS 			= game:GetService("ContextActionService")
local Run 			= game:GetService("RunService")
local TS 			= game:GetService('TweenService')
local Debris 		= game:GetService("Debris")

local StarterGUI = game:GetService("StarterGui")
local RS 			= game.ReplicatedStorage
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ACS_Workspace = workspace:WaitForChild("ACS_WorkSpace")
local Engine 		= RS:WaitForChild("ACS_MICTLAN")
local Evt 			= Engine:WaitForChild("Events")
local Mods 			= Engine:WaitForChild("Modules")
local HUDs 			= Engine:WaitForChild("HUD")
local Essential 	= Engine:WaitForChild("Essential")
local ArmModel 		= Engine:WaitForChild("ArmModel")
local GunModels 	= Engine:WaitForChild("GunModels")
local AttModels 	= Engine:WaitForChild("AttModels")
local AttModules  	= Engine:WaitForChild("AttModules")
local Rules			= Engine:WaitForChild("GameRules")
local PastaFx		= Engine:WaitForChild("FX")

local Packages = ReplicatedStorage:WaitForChild("Packages")
local Satchel = require(Packages:WaitForChild("Satchel"))

local Controllers = ReplicatedStorage:WaitForChild("Controllers")
local ToolController = require(Controllers.ToolController)


local gameRules		= require(Rules:WaitForChild("Config"))
local SpringMod 	= require(Mods:WaitForChild("Spring"))
local HitMod 		= require(Mods:WaitForChild("Hitmarker"))
local Thread 		= require(Mods:WaitForChild("Thread"))
local Ultil			= require(Mods:WaitForChild("Utilities"))
local ACS_Client 	= char:WaitForChild("ACS_Client")
local newTracer = require(script:WaitForChild("Tracer")).New
local Equipped 		= 0
local Isrunning = ACS_Client:WaitForChild("Stances"):WaitForChild("Value")
local CanRun = char:WaitForChild("CharStats"):WaitForChild("CanRun")
local Ammo
local StoredAmmo
local GLAmmo
local GLSAmmo
local BulletType

local OverHeat = false 
local WeaponInHand, WeaponTool, WeaponData, AnimData
local ViewModel, AnimPart, LArm, RArm, LArmWeld, RArmWeld, GunWeld

local SightData, BarrelData, UnderBarrelData, OtherData
local generateBullet = 1
local BSpread
local RecoilPower
local LastSpreadUpdate = time()
local SE_GUI
local SKP_01 = Evt.AcessId:InvokeServer(plr.UserId)


local charspeed 	= 0
local running 		= false
local runKeyDown 	= false
local aimming 		= false
local shooting 		= false
local reloading 	= false
local mouse1down 	= false
local AnimDebounce 	= false
local CancelReload 	= false
local SafeMode		= false
local JumpDelay 	= false

local GunStance 	= 0
local AimPartMode 	= 1

local SightAtt		= nil
local reticle		= nil
local CurAimpart 	= nil

local BarrelAtt 	= nil
local Suppressor 	= false
local FlashHider 	= false
local UnderBarrelAtt= nil
local OtherAtt 		= nil
local LaserAtt 		= false

local IRmode		= false
local IREnable		= false

local Laser 		= nil
local Pointer 		= nil
local TorchAtt 		= false

local BipodAtt 		= false

local BipodActive 	= false

local GRDebounce 	= false
local CookGrenade 	= false

local ToolEquip 	= false
local Sens 			= 50
local Power = 150

local BipodCF 		= CFrame.new()

local ModTable = {

	camRecoilMod 	= {
		RecoilTilt 	= 1,
		RecoilUp 	= 1,
		RecoilLeft 	= 1,
		RecoilRight = 1
	}

	,gunRecoilMod	= {
		RecoilUp 	= 1,
		RecoilTilt 	= 1,
		RecoilLeft 	= 1,
		RecoilRight = 1
	}

	,ZoomValue 		= 80
	,Zoom2Value 	= 80
	,Zoom3Value     = 80
	,AimRM 			= 1
	,SpreadRM 		= 1
	,DamageMod 		= 1
	,minDamageMod 	= 1

	,MinRecoilPower 			= 1
	,MaxRecoilPower 			= 1
	,RecoilPowerStepAmount 		= 1

	,MinSpread 					= 1
	,MaxSpread 					= 1					
	,AimInaccuracyStepAmount 	= 1
	,AimInaccuracyDecrease 		= 1
	,WalkMult 					= 1
	,adsTime 					= 1		
	,MuzzleVelocity 			= 1

	,GLVelocity 				= 1
}  

local maincf 		= CFrame.new()
local guncf  		= CFrame.new() 
local larmcf 		= CFrame.new() 
local rarmcf 		= CFrame.new()
tiltaxis = Instance.new('Part')
tiltaxis.CFrame = CFrame.new()
local gunbobcf		= CFrame.new()
local recoilcf 		= CFrame.new()
local aimcf 		= CFrame.new()
local AimTween 		= TweenInfo.new(
	0.2,
	Enum.EasingStyle.Linear,
	Enum.EasingDirection.InOut,
	0,
	false,
	0
)

local Ignore_Model = {cam,char,ACS_Workspace.Client,ACS_Workspace.Server}

function RAND(Min, Max, Accuracy)
	local Inverse = 1 / (Accuracy or 1)
	return (math.random(Min * Inverse, Max * Inverse) / Inverse)
end
if gameRules.TeamTags then
	local tag = Essential.TeamTag:clone()
	tag.Parent = char
	tag.Disabled = false
end
SE_GUI = HUDs:WaitForChild("StatusUI"):Clone()
SE_GUI.Parent = plr.PlayerGui

local CHup, CHdown, CHleft, CHright = UDim2.new(),UDim2.new(),UDim2.new(),UDim2.new()
local Crosshair = SE_GUI.Crosshair
local OnMobile = plr.PlayerScripts.Data:WaitForChild("OnMobile")
local MobileUI = SE_GUI.MobileUI
local MobileGunUI = SE_GUI.MobileGunUI
local MobileHudController = {}
MobileHudController.__index = MobileHudController

function MobileHudController.new(onMobileValue, mobileUI)
	local self = setmetatable({}, MobileHudController)
	self._onMobileValue = onMobileValue
	self._mobileUI = mobileUI
	self._isDriving = false
	self:_apply()
	return self
end

function MobileHudController:SetDriving(state)
	self._isDriving = state == true
	self:_apply()
end

function MobileHudController:_apply()
	if not self._mobileUI then return end
	local show = self._onMobileValue and self._onMobileValue.Value == true and not self._isDriving
	self._mobileUI.Visible = show
end

local MobileHud = MobileHudController.new(OnMobile, MobileUI)
local SprintOn = false
SwaySpringNew = require(Mods:WaitForChild("SpringModule"))
local SwaySpringV2 = SwaySpringNew.new()

local RecoilSpring = SpringMod.new(Vector3.new())
RecoilSpring.d = .85
RecoilSpring.s = 25

local cameraspring = SpringMod.new(Vector3.new())
cameraspring.d	= 0.85
cameraspring.s	= 17.5
local AnimationHandler = SpringMod.new(Vector3.new())
AnimationHandler.d = .15
AnimationHandler.s = 20
local Stance = Evt.Stance
local Stances = 0
local Virar = 0
local CameraX = 0
local CameraY = 0

local Sentado 		= false
local Swimming		= false
local falling 		= false

local Crouched 		= false
local Proned		= false

local CanLean 		= true
local ChangeStance 	= true

local Humanoid = char:WaitForChild('Humanoid')
local HumanoidRootPart = char:WaitForChild('HumanoidRootPart')
local Head = char:WaitForChild('Head')
local Neck = Head:WaitForChild('Neck')
local YOffset = Neck.C0.Y
local CFNew, CFAng = CFrame.new, CFrame.Angles
local Asin = math.asin

User.MouseIconEnabled 	= true
plr.CameraMode 			= Enum.CameraMode.Classic

cam.CameraType = Enum.CameraType.Custom
cam.CameraSubject = Humanoid

CharArmParts = {
	LeftUpperArm = char:FindFirstChild("LeftUpperArm"),
	LeftLowerArm = char:FindFirstChild("LeftLowerArm"),
	LeftHand = char:FindFirstChild("LeftHand"),
	RightUpperArm = char:FindFirstChild("RightUpperArm"),
	RightLowerArm = char:FindFirstChild("RightLowerArm"),
	RightHand = char:FindFirstChild("RightHand")

}

local function Tween(part,Time,properties,style,direction,de)
	local tw = game:GetService("TweenService")
	local ti = TweenInfo.new(
		Time or 1,
		style or Enum.EasingStyle.Quint,
		direction or Enum.EasingDirection.Out,
		0,
		false,
		de or 0
	)
	tw:Create(part,ti,properties):Play()
end

local function FireButtonHeld()
	if AnimDebounce then
		Shoot()

		if WeaponData.Type == "Grenade" then
			CookGrenade = true
			Grenade()
		end
	end
end

local function FireButtonUnheld()
	mouse1down = false
	CookGrenade = false
end

local function ReloadButton()
	if AnimDebounce and not CheckingMag and not reloading then
		Reload()
	end
end

local function CancelReloadButton()
	if reloading and WeaponData.ShellInsert and running then
		CancelReload = true
	end
end

local function LaserButton()
	if LaserAtt then
		SetLaser()
	end
end

local function LightButton()
	if TorchAtt then
		SetTorch()
	end
end

local function FiremodeButton()
	if WeaponData and WeaponData.FireModes.ChangeFiremode then
		Firemode()
	end
end
local function SecondaryAimButton()
	SetAimpart()
end

local function CheckMagButton()
	if not CheckingMag and not reloading and not runKeyDown and AnimDebounce then
		CheckMagFunction()
	end
end

local function BipodButton()
	BipodActive = not BipodActive
	if BipodActive  then
		BipodAnim1()
		UpdateGui()
	else
		BipodAnim2()
		UpdateGui()
	end
end
local canslide = true

local function ADSButton()
	if AnimDebounce then
		if WeaponData.Type == "Gun" and GunStance > -2 and not reloading and not runKeyDown and not CheckingMag then
			aimming = not aimming
			ADS(aimming)
		end

		if WeaponData.Type == "Grenade" then
			GrenadeMode()
		end
	end
end
local stancedelay = 0
local function StandButton()
	if ChangeStance and not Swimming and not Sentado and not runKeyDown then
		if Stances == 2 then
			Crouched = true
			Proned = false
			Stances = 1
			CameraY = -1
			Crouch()
			stancedelay = tick() + 0.5
			Crouched = true

		elseif Stances == 1 then		
			Crouched = false
			Stances = 0
			CameraY = 0
			stancedelay = tick() + 0.5
			Stand()
		end	
	end
end

local function LeanLeftButton()
	if Stances ~= 2 and ChangeStance and not Swimming and not runKeyDown and CanLean then
		if Virar == 0 or Virar == 1 then
			Virar = -1
			CameraX = -1.35
			Lean()
		else
			Virar = 0
			CameraX = 0
			Lean()
			if Crouched then
				Tween(tiltaxis,.8,{CFrame = CFrame.new(-.07,0,0)*CFrame.Angles(0,0,-math.rad(-30))})
			end
		end
	end
end
local function LeanRightButton()
	if Stances ~= 2 and ChangeStance and not Swimming and not runKeyDown and CanLean then
		if Virar == 0 or Virar == -1 then
			Virar = 1
			CameraX = 1.35
			Lean()
		else
			Virar = 0
			CameraX = 0
			Lean()
			if Crouched then
				Tween(tiltaxis,.8,{CFrame = CFrame.new(-.07,0,0)*CFrame.Angles(0,0,-math.rad(-30))})
			end
		end
	end
end
local function RunButtonHeld()
	if running and tick() > stancedelay  then

		runKeyDown 	= true
		Stand()
		Stances = 0
		Virar = 0
		CameraX = 0
		CameraY = 0
		Lean()
		Isrunning.Value = true
		char:WaitForChild("Humanoid").WalkSpeed = gameRules.RunWalkSpeed
		Crouched = false
		if aimming then
			aimming = false
			ADS(aimming)
		end

		if not CheckingMag and not reloading and WeaponData and WeaponData.Type ~= "Grenade" and (GunStance == 0 or GunStance == 2 or GunStance == 3) then
			GunStance = 3
			Evt.GunStance:FireServer(GunStance,AnimData)
			SprintAnim()
		end

	end
end

local function RunButtonUnheld()
	if runKeyDown then
		runKeyDown 	= false
		Isrunning.Value = false
		Crouched = false
		Stand()
		if not CheckingMag and not reloading and WeaponData and WeaponData.Type ~= "Grenade" and (GunStance == 0 or GunStance == 2 or GunStance == 3) then
			GunStance = 0
			Evt.GunStance:FireServer(GunStance,AnimData)
			IdleAnim()
		end
	end
end

local Cover = false
local function CrouchButton()
	if ChangeStance and not Swimming and not Sentado and not runKeyDown then
		SprintOn = false
		MobileUI.Sprint.ImageColor3 = Color3.fromRGB(0,0,0)
		RunButtonUnheld()

		-- TOGGLE ONLY: Stand <-> Crouch (no prone)
		if Stances == 0 then
			Stances = 1
			CameraX = 0
			CameraY = -1
			Virar = 0
			stancedelay = tick() + 0.5

			Lean()       -- keeps camera/tilt consistent
			Crouch()
			Crouched = true
			Proned = false
		else
			Stances = 0
			CameraX = 0
			CameraY = 0
			Virar = 0
			stancedelay = tick() + 0.5

			Lean()
			Stand()
			Crouched = false
			Proned = false
		end
	end
end


MobileGunUI.Fire.ActivateCircle.InputBegan:Connect(FireButtonHeld)
MobileGunUI.Fire.ActivateCircle.InputEnded:Connect(FireButtonUnheld)
MobileGunUI.Reload.InputBegan:Connect(function()
	if AnimDebounce and not CheckingMag and not reloading then
		ReloadButton()
	elseif reloading and WeaponData.ShellInsert then
		CancelReloadButton()
	end
end)

MobileGunUI.Firemode.InputBegan:Connect(FiremodeButton)



MobileGunUI.Aim.InputBegan:Connect(ADSButton)
MobileUI.Crouch.InputBegan:Connect(CrouchButton)

MobileUI.Sprint.InputBegan:Connect(function()
	if SprintOn then
		SprintOn = false
		MobileUI.Sprint.ImageColor3 = Color3.fromRGB(0,0,0)
		RunButtonUnheld()
	else
		SprintOn = true
		MobileUI.Sprint.ImageColor3 = Color3.fromRGB(255,255,255)
	end
end)


function handleAction(actionName, inputState, inputObject)
	if actionName == "Fire" and inputState == Enum.UserInputState.Begin then
		FireButtonHeld()
	elseif actionName == "Fire" and inputState == Enum.UserInputState.End then
		FireButtonUnheld()
	end

	if actionName == "Reload" and inputState == Enum.UserInputState.Begin then
		ReloadButton()
	end

	if actionName == "Reload" and inputState == Enum.UserInputState.Begin then
		CancelReloadButton()
	end

	if actionName == "CycleLaser" and inputState == Enum.UserInputState.Begin then
		LaserButton()	
	end

	if actionName == "CycleLight" and inputState == Enum.UserInputState.Begin then
		LightButton()
	end   

	if actionName == "CycleFiremode" and inputState == Enum.UserInputState.Begin then
		FiremodeButton()
	end

	if actionName == "CycleAimpart" and inputState == Enum.UserInputState.Begin then
		SetAimpart()
	end

	if actionName == "ZeroUp" and inputState == Enum.UserInputState.Begin and WeaponData and WeaponData.EnableZeroing  then
		if WeaponData.CurrentZero < WeaponData.MaxZero then
			WeaponInHand.Handle.Click:play()
			WeaponData.CurrentZero = math.min(WeaponData.CurrentZero + WeaponData.ZeroIncrement, WeaponData.MaxZero) 
			UpdateGui()
		end
	end

	if actionName == "ZeroDown" and inputState == Enum.UserInputState.Begin and WeaponData and WeaponData.EnableZeroing  then
		if WeaponData.CurrentZero > 0 then
			WeaponInHand.Handle.Click:play()
			WeaponData.CurrentZero = math.max(WeaponData.CurrentZero - WeaponData.ZeroIncrement, 0) 
			UpdateGui()
		end
	end

	if actionName == "CheckMag" and inputState == Enum.UserInputState.Begin then
		CheckMagButton()
	end

	if actionName == "ToggleBipod" and inputState == Enum.UserInputState.Begin then
		BipodButton()
	end

	if actionName == "ADS" and inputState == Enum.UserInputState.Begin then
		ADSButton()
	end

	if actionName == "Stand" and inputState == Enum.UserInputState.Begin then
		if tick() < stancedelay then
			return
		else
			StandButton()
		end
	end
	if actionName == "Crouch" and inputState == Enum.UserInputState.Begin then
		if tick() < stancedelay then
			return
		else
			CrouchButton()
		end
	end
	if actionName == "LeanLeft" and inputState == Enum.UserInputState.Begin then
		LeanLeftButton()
	end

	if actionName == "LeanRight" and inputState == Enum.UserInputState.Begin then
		LeanRightButton()
	end

	if actionName == "Run" and inputState == Enum.UserInputState.Begin then

		RunButtonHeld()

	elseif actionName == "Run" and inputState == Enum.UserInputState.End then
		RunButtonUnheld()
	end
end


function resetMods()

	ModTable.camRecoilMod.RecoilUp 		= 1
	ModTable.camRecoilMod.RecoilLeft 	= 1
	ModTable.camRecoilMod.RecoilRight 	= 1
	ModTable.camRecoilMod.RecoilTilt 	= 1

	ModTable.gunRecoilMod.RecoilUp 		= 1
	ModTable.gunRecoilMod.RecoilTilt 	= 1
	ModTable.gunRecoilMod.RecoilLeft 	= 1
	ModTable.gunRecoilMod.RecoilRight 	= 1

	ModTable.AimRM			= 1
	ModTable.SpreadRM 		= 1
	ModTable.DamageMod 		= 1
	ModTable.minDamageMod 	= 1

	ModTable.MinRecoilPower 		= 1
	ModTable.MaxRecoilPower 		= 1
	ModTable.RecoilPowerStepAmount 	= 1

	ModTable.MinSpread 					= 1
	ModTable.MaxSpread 					= 1
	ModTable.AimInaccuracyStepAmount 	= 1
	ModTable.AimInaccuracyDecrease 		= 1
	ModTable.WalkMult 					= 1
	ModTable.MuzzleVelocity 			= 1

end

function setMods(ModData)

	ModTable.camRecoilMod.RecoilUp 		= ModTable.camRecoilMod.RecoilUp * ModData.camRecoil.RecoilUp
	ModTable.camRecoilMod.RecoilLeft 	= ModTable.camRecoilMod.RecoilLeft * ModData.camRecoil.RecoilLeft
	ModTable.camRecoilMod.RecoilRight 	= ModTable.camRecoilMod.RecoilRight * ModData.camRecoil.RecoilRight
	ModTable.camRecoilMod.RecoilTilt 	= ModTable.camRecoilMod.RecoilTilt * ModData.camRecoil.RecoilTilt

	ModTable.gunRecoilMod.RecoilUp 		= ModTable.gunRecoilMod.RecoilUp * ModData.gunRecoil.RecoilUp
	ModTable.gunRecoilMod.RecoilTilt 	= ModTable.gunRecoilMod.RecoilTilt * ModData.gunRecoil.RecoilTilt
	ModTable.gunRecoilMod.RecoilLeft 	= ModTable.gunRecoilMod.RecoilLeft * ModData.gunRecoil.RecoilLeft
	ModTable.gunRecoilMod.RecoilRight 	= ModTable.gunRecoilMod.RecoilRight * ModData.gunRecoil.RecoilRight

	ModTable.AimRM						= ModTable.AimRM * ModData.AimRecoilReduction
	ModTable.SpreadRM 					= ModTable.SpreadRM * ModData.AimSpreadReduction
	ModTable.DamageMod 					= ModTable.DamageMod * ModData.DamageMod
	ModTable.minDamageMod 				= ModTable.minDamageMod * ModData.minDamageMod

	ModTable.MinRecoilPower 			= ModTable.MinRecoilPower * ModData.MinRecoilPower
	ModTable.MaxRecoilPower 			= ModTable.MaxRecoilPower * ModData.MaxRecoilPower
	ModTable.RecoilPowerStepAmount 		= ModTable.RecoilPowerStepAmount * ModData.RecoilPowerStepAmount

	ModTable.MinSpread 					= ModTable.MinSpread * ModData.MinSpread
	ModTable.MaxSpread 					= ModTable.MaxSpread * ModData.MaxSpread
	ModTable.AimInaccuracyStepAmount 	= ModTable.AimInaccuracyStepAmount * ModData.AimInaccuracyStepAmount
	ModTable.AimInaccuracyDecrease 		= ModTable.AimInaccuracyDecrease * ModData.AimInaccuracyDecrease
	ModTable.WalkMult 					= ModTable.WalkMult * ModData.WalkMult
	ModTable.MuzzleVelocity 			= ModTable.MuzzleVelocity * ModData.MuzzleVelocityMod
end

function loadAttachment(weapon)
	if weapon and weapon:FindFirstChild("Nodes") ~= nil then
		if weapon.Nodes:FindFirstChild("Sight") ~= nil and WeaponData.SightAtt ~= "" then

			SightData =  require(AttModules[WeaponData.SightAtt])

			SightAtt = AttModels[WeaponData.SightAtt]:Clone()
			SightAtt.Parent = weapon
			SightAtt:SetPrimaryPartCFrame(weapon.Nodes.Sight.CFrame)
			weapon.AimPart.CFrame = SightAtt.AimPos.CFrame

			reticle = SightAtt.SightMark.SurfaceGui.Border.Scope	
			if SightData.SightZoom > 0 then
				ModTable.ZoomValue = SightData.SightZoom
			end
			if SightData.SightZoom2 > 0 then
				ModTable.Zoom2Value = SightData.SightZoom2
			end
			setMods(SightData)


			for index, key in pairs(weapon:GetChildren()) do
				if key.Name == "IS" then
					key.Transparency = 1
				end
			end

			for index, key in pairs(SightAtt:GetChildren()) do
				if key:IsA('BasePart') then
					Ultil.Weld(weapon:WaitForChild("Handle"), key )
					key.Anchored = false
					key.CanCollide = false
				end
			end

		end
		if weapon.Nodes:FindFirstChild("Barrel") ~= nil and WeaponData.BarrelAtt ~= "" then

			BarrelData =  require(AttModules[WeaponData.BarrelAtt])

			BarrelAtt = AttModels[WeaponData.BarrelAtt]:Clone()
			BarrelAtt.Parent = weapon
			BarrelAtt:SetPrimaryPartCFrame(weapon.Nodes.Barrel.CFrame)


			if BarrelAtt:FindFirstChild("BarrelPos") ~= nil then
				weapon.Handle.Muzzle.WorldCFrame = BarrelAtt.BarrelPos.CFrame
			end

			Suppressor 		= BarrelData.IsSuppressor
			FlashHider 		= BarrelData.IsFlashHider

			setMods(BarrelData)

			for index, key in pairs(BarrelAtt:GetChildren()) do
				if key:IsA('BasePart') then
					Ultil.Weld(weapon:WaitForChild("Handle"), key )
					key.Anchored = false
					key.CanCollide = false
				end
			end
		end
		if weapon.Nodes:FindFirstChild("UnderBarrel") ~= nil and WeaponData.UnderBarrelAtt ~= "" then

			UnderBarrelData =  require(AttModules[WeaponData.UnderBarrelAtt])

			UnderBarrelAtt = AttModels[WeaponData.UnderBarrelAtt]:Clone()
			UnderBarrelAtt.Parent = weapon
			UnderBarrelAtt:SetPrimaryPartCFrame(weapon.Nodes.UnderBarrel.CFrame)


			setMods(UnderBarrelData)
			BipodAtt = UnderBarrelData.IsBipod

			if BipodAtt then
				CAS:BindAction("ToggleBipod", handleAction, false, Enum.KeyCode.B)
				MobileGunUI.Attachments.List.Bipod.Visible = true
			else
				MobileGunUI.Attachments.List.Bipod.Visible = false
			end

			for index, key in pairs(UnderBarrelAtt:GetChildren()) do
				if key:IsA('BasePart') then
					Ultil.Weld(weapon:WaitForChild("Handle"), key )
					key.Anchored = false
					key.CanCollide = false
				end
			end
		end

		if weapon.Nodes:FindFirstChild("Other") ~= nil and WeaponData.OtherAtt ~= "" then

			OtherData =  require(AttModules[WeaponData.OtherAtt])

			OtherAtt = AttModels[WeaponData.OtherAtt]:Clone()
			OtherAtt.Parent = weapon
			OtherAtt:SetPrimaryPartCFrame(weapon.Nodes.Other.CFrame)


			setMods(OtherData)
			LaserAtt = OtherData.EnableLaser
			TorchAtt = OtherData.EnableFlashlight

			if LaserAtt then
				MobileGunUI.Attachments.List.Laser.Visible = true
			else
				MobileGunUI.Attachments.List.Laser.Visible = false
			end

			if TorchAtt then
				MobileGunUI.Attachments.List.Flashlight.Visible = true
			else
				MobileGunUI.Attachments.List.Flashlight.Visible = false
			end

			if OtherData.InfraRed then
				IREnable = true
			end

			for index, key in pairs(OtherAtt:GetChildren()) do
				if key:IsA('BasePart') then
					Ultil.Weld(weapon:WaitForChild("Handle"), key )
					key.Anchored = false
					key.CanCollide = false
				end
			end
		end
	end
end

function SetLaser()
	-- laser to work on :)
end

function SetTorch()
	if Equipped and not reloading then
		for _,v in pairs(WeaponInHand:GetChildren()) do
			if v.Name == 'GFlash' and v.Key.Value then
				WeaponInHand.Handle.FlashOn:play()
				v.Enabled.Value = not v.Enabled.Value
				if 	v.Enabled.Value == true then

					TS:Create(SE_GUI.GunHUD.Att.Flash, TweenInfo.new(.1,Enum.EasingStyle.Linear), {ImageColor3 = Color3.fromRGB(255,255,255), ImageTransparency = .123}):Play()
				else
					TS:Create(SE_GUI.GunHUD.Att.Flash, TweenInfo.new(.1,Enum.EasingStyle.Linear), {ImageColor3 = Color3.fromRGB(255, 0, 0), ImageTransparency = .123}):Play()
				end
				for _,g in pairs(v:GetDescendants()) do
					if g:IsA('SpotLight') or v:IsA('PointLight') or v:IsA('SurfaceLight') then
						g.Enabled = v.Enabled.Value
					end
				end
				Evt.SVFlash:FireServer(WeaponInHand.Name,v.Enabled.Value,1)
			end
		end

	end

end

function ToggleADS(Type)
	local ADSTween
	ADSTween = TweenInfo.new(0.1,Enum.EasingStyle.Linear,Enum.EasingDirection.Out,0,false,0.2)

	if Type == "REG" then
		for _, child in pairs(WeaponInHand:GetChildren()) do
			if child.Name == "REG" then
				child.Transparency = 0
			elseif child.Name == "ADS" then
				child.Transparency = 1
			end
		end
	elseif Type == "ADS" then
		for _, child in pairs(WeaponInHand:GetChildren()) do
			if child.Name == "REG" then
				child.Transparency = 1
			elseif child.Name == "ADS" then
				child.Transparency = 0
			end
		end
	end
end

function ADS(aimming)
	if not WeaponData or not WeaponInHand then return; end;
	if aimming then
		if SafeMode then
			SafeMode = false
			GunStance = 0
			IdleAnim()
			UpdateGui()
		end
		game:GetService('UserInputService').MouseDeltaSensitivity = (Sens/100)

		WeaponInHand.Handle.AimDown:Play()

		if WeaponData.ADSEnabled then
			if WeaponData.ADSEnabled[AimPartMode] then
				ToggleADS("ADS")
			end
		else
			ToggleADS("ADS")
		end

		GunStance = 2
		Evt.GunStance:FireServer(GunStance,AnimData)

	else
		game:GetService('UserInputService').MouseDeltaSensitivity = 1
		WeaponInHand.Handle.AimUp:Play()

		ToggleADS("REG")

		GunStance = 0
		Evt.GunStance:FireServer(GunStance,AnimData)
	end
end

function SetAimpart()
	if aimming then
		if AimPartMode == 1 then
			AimPartMode = 2
			GunStance = 5
			Evt.GunStance:FireServer(GunStance,AnimData)
			if WeaponInHand:FindFirstChild('AimPart2') then
				CurAimpart = WeaponInHand:FindFirstChild('AimPart2')
			end 
		elseif AimPartMode == 2 then
			if WeaponInHand:FindFirstChild('AimPart3') then
				AimPartMode = 3
				CurAimpart = WeaponInHand:FindFirstChild('AimPart3')
			else
				GunStance = 2
				Evt.GunStance:FireServer(GunStance,AnimData)
				AimPartMode = 1
				CurAimpart = WeaponInHand:FindFirstChild('AimPart')
			end 
		elseif AimPartMode == 3 then
			AimPartMode = 1
			CurAimpart = WeaponInHand:FindFirstChild('AimPart')
		end
		if WeaponData.ADSEnabled then
			if WeaponData.ADSEnabled[AimPartMode] then
				ToggleADS("ADS")
			else
				ToggleADS("REG")
			end
		end
	end
end

function Firemode()
	if not reloading and not shooting then
		reloading = true
		AnimDebounce = true
		if not AnimData.FiremodeAnim then
			local anims = require(Engine.Animations)
			anims.FiremodeAnim(char,nil,{
				RArmWeld,
				LArmWeld,
				GunWeld,
				WeaponInHand,
				ViewModel,
			})
		else
			AnimData.FiremodeAnim({
				RArmWeld,
				LArmWeld,
				GunWeld,
				WeaponInHand,
				ViewModel,
				cameraspring,

			})
		end
		AnimDebounce = false
		IdleAnim()
		reloading = false
		mouse1down = false

		if WeaponData.ShootType == 1 and WeaponData.FireModes.Burst == true then
			WeaponData.ShootType = 2
		elseif WeaponData.ShootType == 1 and WeaponData.FireModes.Burst == false and WeaponData.FireModes.Auto == true then
			WeaponData.ShootType = 3
		elseif WeaponData.ShootType == 2 and WeaponData.FireModes.Explosive == true then
			WeaponData.ShootType = 6
		elseif WeaponData.ShootType == 2 and WeaponData.FireModes.Auto == true then
			WeaponData.ShootType = 3
		elseif WeaponData.ShootType == 2 and WeaponData.FireModes.Semi == true and WeaponData.FireModes.Auto == false then
			WeaponData.ShootType = 1
		elseif WeaponData.ShootType == 3 and WeaponData.FireModes.Explosive == true then
			WeaponData.ShootType = 6
		elseif WeaponData.ShootType == 3 and WeaponData.FireModes.Semi == true then
			WeaponData.ShootType = 1
		elseif WeaponData.ShootType == 6 then
			WeaponData.ShootType = 1
		end
		UpdateGui()
	end
end

function setup(Tool)

	if char and char:WaitForChild("Humanoid").Health > 0 and Tool ~= nil then
		ToolEquip = true
		User.MouseIconEnabled 	= false
		plr.CameraMode 			= Enum.CameraMode.LockFirstPerson

		WeaponTool 		= Tool
		WeaponData 		= require(Tool:WaitForChild("GunSettings"))
		AnimData 		= require(Tool:WaitForChild("ACS_Animations"))
		WeaponInHand 	= GunModels:WaitForChild(Tool.Name):Clone()
		WeaponInHand.PrimaryPart = WeaponInHand:WaitForChild("Handle")
		GunStance = 0
		Evt.GunStance:FireServer(GunStance,AnimData)
		Evt.Equip:FireServer(Tool,1,WeaponData,AnimData)

		ViewModel = ArmModel:WaitForChild("Arms"):Clone()
		ViewModel.Name = "Viewmodel"

		if char:FindFirstChild("Body Colors") ~= nil then
			local Colors = char:WaitForChild("Body Colors"):Clone()
			Colors.Parent = ViewModel
		end
		if char:FindFirstChild("Shirt") ~= nil then
			local Shirt = char:FindFirstChild("Shirt"):Clone()
			Shirt.Parent = ViewModel
		end

		AnimPart = Instance.new("Part",ViewModel)
		AnimPart.Size = Vector3.new(0.1,0.1,0.1)
		AnimPart.Anchored = true
		AnimPart.CanCollide = false
		AnimPart.Transparency = 1

		ViewModel.PrimaryPart = AnimPart

		LArmWeld = Instance.new("Motor6D",AnimPart)
		LArmWeld.Name = "LeftArm"
		LArmWeld.Part0 = AnimPart

		RArmWeld = Instance.new("Motor6D",AnimPart)
		RArmWeld.Name = "RightArm"
		RArmWeld.Part0 = AnimPart

		GunWeld = Instance.new("Motor6D",AnimPart)
		GunWeld.Name = "Handle"

		ViewModel.Parent = cam

		maincf = AnimData.MainCFrame
		guncf = AnimData.GunCFrame

		larmcf = AnimData.LArmCFrame
		rarmcf = AnimData.RArmCFrame

		LArm = ViewModel:WaitForChild("Left Arm")
		LArmWeld.Part1 = LArm
		LArmWeld.C0 = CFrame.new()
		LArmWeld.C1 = CFrame.new(1,-1,-5) * CFrame.Angles(math.rad(0),math.rad(0),math.rad(0)):inverse()

		RArm = ViewModel:WaitForChild("Right Arm")
		RArmWeld.Part1 = RArm
		RArmWeld.C0 = CFrame.new()
		RArmWeld.C1 = CFrame.new(-1,-1,-5) * CFrame.Angles(math.rad(0),math.rad(0),math.rad(0)):inverse()
		GunWeld.Part0 = RArm

		LArm.Anchored = false
		RArm.Anchored = false

		ModTable.ZoomValue 		= WeaponData.Zoom
		ModTable.Zoom2Value 	= WeaponData.Zoom2
		ModTable.Zoom3Value = WeaponData.Zoom3
		IREnable 				= WeaponData.InfraRed

		CAS:BindAction("Fire", handleAction, false, Enum.UserInputType.MouseButton1, Enum.KeyCode.ButtonR2)
		CAS:BindAction("ADS", handleAction, false, Enum.UserInputType.MouseButton2, Enum.KeyCode.ButtonL2) 
		CAS:BindAction("Reload", handleAction, false, Enum.KeyCode.R, Enum.KeyCode.ButtonX)
		CAS:BindAction("CycleAimpart", handleAction, false, Enum.KeyCode.T, Enum.KeyCode.ButtonY)

		CAS:BindAction("CycleLaser", handleAction, false, Enum.KeyCode.H, Enum.KeyCode.DPadUp)
		CAS:BindAction("CycleLight", handleAction, false, Enum.KeyCode.J, Enum.KeyCode.DPadDown)

		CAS:BindAction("CycleFiremode", handleAction, false, Enum.KeyCode.V)
		CAS:BindAction("CheckMag", handleAction, false, Enum.KeyCode.M)

		CAS:BindAction("ZeroDown", handleAction, false, Enum.KeyCode.LeftBracket)
		CAS:BindAction("ZeroUp", handleAction, false, Enum.KeyCode.RightBracket)

		loadAttachment(WeaponInHand)

		BSpread				= math.min(WeaponData.MinSpread * ModTable.MinSpread, WeaponData.MaxSpread * ModTable.MaxSpread)
		RecoilPower 		= math.min(WeaponData.MinRecoilPower * ModTable.MinRecoilPower, WeaponData.MaxRecoilPower * ModTable.MaxRecoilPower)
		GLAmmo	   = WeaponData.GLAmmo
		GLSAmmo	   = WeaponData.GLStoredAmmo
		BulletType = WeaponData.BulletType
		Ammo = WeaponData.AmmoInGun
		StoredAmmo = WeaponData.StoredAmmo
		CurAimpart = WeaponInHand:FindFirstChild("AimPart")
		if  WeaponData.CrossHair then
			TS:Create(Crosshair.Up, TweenInfo.new(.2,Enum.EasingStyle.Linear), {BackgroundTransparency = 0}):Play()
			TS:Create(Crosshair.Down, TweenInfo.new(.2,Enum.EasingStyle.Linear), {BackgroundTransparency = 0}):Play()
			TS:Create(Crosshair.Left, TweenInfo.new(.2,Enum.EasingStyle.Linear), {BackgroundTransparency = 0}):Play()
			TS:Create(Crosshair.Right, TweenInfo.new(.2,Enum.EasingStyle.Linear), {BackgroundTransparency = 0}):Play()	

			if WeaponData.Bullets > 1 then
				Crosshair.Up.Rotation = 90
				Crosshair.Down.Rotation = 90
				Crosshair.Left.Rotation = 90
				Crosshair.Right.Rotation = 90
			else
				Crosshair.Up.Rotation = 0
				Crosshair.Down.Rotation = 0
				Crosshair.Left.Rotation = 0
				Crosshair.Right.Rotation = 0
			end

		else
			TS:Create(Crosshair.Up, TweenInfo.new(.2,Enum.EasingStyle.Linear), {BackgroundTransparency = 1}):Play()
			TS:Create(Crosshair.Down, TweenInfo.new(.2,Enum.EasingStyle.Linear), {BackgroundTransparency = 1}):Play()
			TS:Create(Crosshair.Left, TweenInfo.new(.2,Enum.EasingStyle.Linear), {BackgroundTransparency = 1}):Play()
			TS:Create(Crosshair.Right, TweenInfo.new(.2,Enum.EasingStyle.Linear), {BackgroundTransparency = 1}):Play()
		end

		if  WeaponData.CenterDot then
			TS:Create(Crosshair.Center, TweenInfo.new(.2,Enum.EasingStyle.Linear), {ImageTransparency = 0}):Play()
		else
			TS:Create(Crosshair.Center, TweenInfo.new(.2,Enum.EasingStyle.Linear), {ImageTransparency = 1}):Play()
		end
		for index, Key in pairs(WeaponInHand:GetDescendants()) do
			if Key:IsA("BasePart") and Key.Name == "GFlash" then
				TorchAtt = true
			end
			if Key:IsA("BasePart") and Key.Name == "GLaser" then
				LaserAtt = true
			end
		end
		if WeaponData.Type == "Gun" then
			WeaponInHand.Bolt.SlidePull.Played:Connect(function()

				if Ammo > 0 then
					WeaponInHand.Handle.Chamber.Smoke:Emit(5)

				end
			end)
		end

		if WeaponData.EnableHUD then
			SE_GUI.GunHUD.Visible = true
			if OnMobile.Value == true then
				MobileGunUI.Visible = true
			end
		end
		UpdateGui()

		for index, key in pairs(WeaponInHand:GetChildren()) do
			if key:IsA('BasePart') and key.Name ~= 'Handle' then

				if key.Name ~= "Bolt" and key.Name ~= 'Lid' and key.Name ~= "Slide" then
					Ultil.Weld(WeaponInHand:WaitForChild("Handle"), key)
				end

				if key.Name == "Bolt" or key.Name == "Slide" then
					Ultil.WeldComplex(WeaponInHand:WaitForChild("Handle"), key, key.Name)
				end;


				if key.Name == "Lid" then
					if WeaponInHand:FindFirstChild('LidHinge') then
						Ultil.Weld(key, WeaponInHand:WaitForChild("LidHinge"))
					else
						Ultil.Weld(key, WeaponInHand:WaitForChild("Handle"))
					end
				end
			end
		end;

		for L_213_forvar1, L_214_forvar2 in pairs(WeaponInHand:GetChildren()) do
			if L_214_forvar2:IsA('BasePart') then
				L_214_forvar2.Anchored = false
				L_214_forvar2.CanCollide = false
			end
		end;

		if WeaponInHand:FindFirstChild("Nodes") then
			for L_213_forvar1, L_214_forvar2 in pairs(WeaponInHand.Nodes:GetChildren()) do
				if L_214_forvar2:IsA('BasePart') then
					Ultil.Weld(WeaponInHand:WaitForChild("Handle"), L_214_forvar2)
					L_214_forvar2.Anchored = false
					L_214_forvar2.CanCollide = false
				end
			end;
		end

		GunWeld.Part1 = WeaponInHand:WaitForChild("Handle")
		GunWeld.C1 = guncf

		WeaponInHand.Parent = ViewModel	
		if Ammo <= 0 and WeaponData.Type == "Gun" and WeaponData.SlideLock == true then
			WeaponInHand.Handle.Slide.C0 = WeaponData.SlideEx:inverse()
		end
		ACS_Client:SetAttribute("Equipped", true)

		for _,key in pairs(CharArmParts) do
			key.LocalTransparencyModifier = 1
		end

		EquipAnim()
		if WeaponData and WeaponData.Type ~= "Grenade" then
			RunCheck()
		end

	end
end

function unset()
	ToolEquip = false

	Evt.Equip:FireServer(WeaponTool,2)
	CAS:UnbindAction("Fire")
	CAS:UnbindAction("ADS")
	CAS:UnbindAction("Reload")
	CAS:UnbindAction("CycleLaser")
	CAS:UnbindAction("CycleLight")
	CAS:UnbindAction("CycleFiremode")
	CAS:UnbindAction("CycleAimpart")
	CAS:UnbindAction("ZeroUp")
	CAS:UnbindAction("ZeroDown")
	CAS:UnbindAction("CheckMag")

	mouse1down = false
	aimming = false

	TS:Create(cam,AimTween,{FieldOfView = 80}):Play()
	TS:Create(Crosshair.Up, TweenInfo.new(.2,Enum.EasingStyle.Linear), {BackgroundTransparency = 1}):Play()
	TS:Create(Crosshair.Down, TweenInfo.new(.2,Enum.EasingStyle.Linear), {BackgroundTransparency = 1}):Play()
	TS:Create(Crosshair.Left, TweenInfo.new(.2,Enum.EasingStyle.Linear), {BackgroundTransparency = 1}):Play()
	TS:Create(Crosshair.Right, TweenInfo.new(.2,Enum.EasingStyle.Linear), {BackgroundTransparency = 1}):Play()
	TS:Create(Crosshair.Center, TweenInfo.new(.2,Enum.EasingStyle.Linear), {ImageTransparency = 1}):Play()
	User.MouseIconEnabled = true
	game:GetService('UserInputService').MouseDeltaSensitivity = 1
	cam.CameraType = Enum.CameraType.Custom
	plr.CameraMode = Enum.CameraMode.Classic

	ToolController.BackpackDisabledCases.PlayerReloading = false
	ToolController:CompareDisableCases()

	if WeaponInHand then
		WeaponData.AmmoInGun = Ammo
		WeaponData.StoredAmmo = StoredAmmo
		WeaponData.GLAmmo = GLAmmo
		WeaponData.GLStoredAmmo = GLSAmmo

		ViewModel:Destroy()
		ViewModel 		= nil
		WeaponInHand	= nil
		WeaponTool		= nil
		LArm 			= nil
		RArm 			= nil
		LArmWeld 		= nil
		RArmWeld 		= nil
		WeaponData 		= nil
		AnimData		= nil
		SightAtt		= nil
		reticle			= nil
		BarrelAtt 		= nil
		UnderBarrelAtt 	= nil
		OtherAtt 		= nil
		LaserAtt 		= false

		IRmode			= false
		TorchAtt 		= false

		BipodAtt 		= false
		BipodActive 	= false

		Pointer 		= nil
		BSpread 		= nil
		RecoilPower 	= nil
		Suppressor 		= false
		FlashHider 		= false
		CancelReload 	= false
		reloading 		= false
		SafeMode		= false
		CheckingMag		= false
		GRDebounce 		= false
		CookGrenade 	= false
		GunStance 		= nil
		Evt.GunStance:FireServer(GunStance,AnimData)
		resetMods()
		generateBullet 	= 1
		AimPartMode 	= 1
		OverHeat = false 
		SE_GUI.GunHUD.Visible = false
		MobileGunUI.Visible = false
		SE_GUI.GrenadeForce.Visible = false
		BipodCF = CFrame.new()
		for _,key in pairs(CharArmParts) do
			key.LocalTransparencyModifier = 0
		end
		if gameRules.ReplicatedLaser then
			Evt.SVLaser:FireServer(nil,2,nil,false,WeaponTool)
		end
	end
end

function renderCam()			
	cam.CFrame = cam.CFrame*CFrame.Angles(cameraspring.p.x,cameraspring.p.y,cameraspring.p.z)
end

function renderGunRecoil()			
	recoilcf = recoilcf*CFrame.Angles(RecoilSpring.p.x,RecoilSpring.p.y,RecoilSpring.p.z)
end

function Recoil()
	local vr = (math.random(WeaponData.camRecoil.camRecoilUp[1], WeaponData.camRecoil.camRecoilUp[2])/2) * ModTable.camRecoilMod.RecoilUp
	local lr = (math.random(WeaponData.camRecoil.camRecoilLeft[1], WeaponData.camRecoil.camRecoilLeft[2])) * ModTable.camRecoilMod.RecoilLeft
	local rr = (math.random(WeaponData.camRecoil.camRecoilRight[1], WeaponData.camRecoil.camRecoilRight[2])) * ModTable.camRecoilMod.RecoilRight
	local hr = (math.random(-rr, lr)/2)
	local tr = (math.random(WeaponData.camRecoil.camRecoilTilt[1], WeaponData.camRecoil.camRecoilTilt[2])/2) * ModTable.camRecoilMod.RecoilTilt

	local RecoilX = math.rad(vr * RAND( 1, 1, .1))
	local RecoilY = math.rad(hr * RAND(-1, 1, .1))
	local RecoilZ = math.rad(tr * RAND(-5, 1, .1))

	local gvr = (math.random(WeaponData.gunRecoil.gunRecoilUp[1], WeaponData.gunRecoil.gunRecoilUp[2]) /10) * ModTable.gunRecoilMod.RecoilUp
	local gdr = (math.random(-1,1) * math.random(WeaponData.gunRecoil.gunRecoilTilt[1], WeaponData.gunRecoil.gunRecoilTilt[2]) /10) * ModTable.gunRecoilMod.RecoilTilt
	local glr = (math.random(WeaponData.gunRecoil.gunRecoilLeft[1], WeaponData.gunRecoil.gunRecoilLeft[2])) * ModTable.gunRecoilMod.RecoilLeft
	local grr = (math.random(WeaponData.gunRecoil.gunRecoilRight[1], WeaponData.gunRecoil.gunRecoilRight[2])) * ModTable.gunRecoilMod.RecoilRight

	local ghr = (math.random(-grr, glr)/10)	

	local ARR = WeaponData.AimRecoilReduction * ModTable.AimRM

	if BipodActive then
		cameraspring:accelerate(Vector3.new( RecoilX, RecoilY/2, 0 ))
		if not aimming then
			RecoilSpring:accelerate(Vector3.new( math.rad(.25 * gvr * RecoilPower), math.rad(.25 * ghr * RecoilPower), math.rad(.25 * gdr)))
			recoilcf = recoilcf * CFrame.new(0,0,.1) * CFrame.Angles( math.rad(.25 * gvr * RecoilPower ),math.rad(.25 * ghr * RecoilPower ),math.rad(.25 * gdr * RecoilPower ))

		else
			RecoilSpring:accelerate(Vector3.new( math.rad( .25 * gvr * RecoilPower/ARR) , math.rad(.25 * ghr * RecoilPower/ARR), math.rad(.25 * gdr/ ARR)))
			recoilcf = recoilcf * CFrame.new(0,0,.1) * CFrame.Angles( math.rad(.25 * gvr * RecoilPower/ARR ),math.rad(.25 * ghr * RecoilPower/ARR ),math.rad(.25 * gdr * RecoilPower/ARR ))
		end
		coroutine.wrap(function()
			task.wait(0.03);
			cameraspring:accelerate(Vector3.new(  -RecoilX, -RecoilY, -RecoilZ ))
		end)();
	else
		cameraspring:accelerate(Vector3.new( RecoilX , RecoilY, RecoilZ ))
		if not aimming then
			RecoilSpring:accelerate(Vector3.new( math.rad(gvr * RecoilPower), math.rad(ghr * RecoilPower), math.rad(gdr)))
			recoilcf = recoilcf * CFrame.new(0,-.0,WeaponData.Culatazo) * CFrame.Angles( math.rad( gvr * RecoilPower/ARR ),math.rad( ghr * RecoilPower ),math.rad( gdr * RecoilPower ))
		else
			RecoilSpring:accelerate(Vector3.new( math.rad(gvr * RecoilPower/ARR) , math.rad(ghr * RecoilPower/ARR), math.rad(gdr/ ARR)))
			recoilcf = recoilcf * CFrame.new(0,-.0,WeaponData.CulatazoAim) * CFrame.Angles( math.rad( gvr * RecoilPower/ARR ),math.rad( ghr * RecoilPower/ARR ),math.rad( gdr * RecoilPower/ARR ))
		end
		coroutine.wrap(function()
			task.wait(0.03);
			cameraspring:accelerate(Vector3.new(  -RecoilX, -RecoilY, -RecoilZ ))
		end)();
	end

	local Muzzle = WeaponInHand.Handle.Muzzle

	if WeaponData.ShootType == 6 then
		local newSound = Muzzle.GLFire:Clone()
		newSound.PlaybackSpeed = newSound.PlaybackSpeed + math.random(-20,20) / 1000
		newSound.Parent = WeaponInHand.Handle
		newSound.Name = "GLFiring"
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
	for _, v in pairs(WeaponInHand.Handle.Muzzle:GetChildren()) do
		if v.Name:sub(1, 7) == "FlashFX" then

			if math.random(1,2) == 1 then
				v.Enabled = true
			end
		end
		if v.Name:sub(1, 7) == "Smoke" then
			v.Enabled = true

		end
	end
	for _, a in pairs(WeaponInHand.Handle.Chamber:GetChildren()) do
		if a.Name:sub(1, 7) == "FlashFX" or a.Name:sub(1, 7) == "Smoke" then
			a.Enabled = true
		end
	end

	delay(1 / 30, function()
		for _, v in pairs(WeaponInHand.Handle.Muzzle:GetChildren()) do
			if v.Name:sub(1, 7) == "FlashFX" or v.Name:sub(1, 7) == "Smoke" then
				v.Enabled = false
			end
		end

		for _, a in pairs(WeaponInHand.Handle.Chamber:GetChildren()) do
			if a.Name:sub(1, 7) == "FlashFX" or a.Name:sub(1, 7) == "Smoke" then
				a.Enabled = false
			end

		end


	end)
	if Ammo > 0 or not WeaponData.SlideLock then
		TS:Create( WeaponInHand.Handle.Slide, TweenInfo.new(20/WeaponData.ShootRate,Enum.EasingStyle.Linear,Enum.EasingDirection.InOut,0,true,0), {C0 =  WeaponData.SlideEx:inverse() }):Play()
	elseif Ammo <= 0 and WeaponData.SlideLock then
		TS:Create( WeaponInHand.Handle.Slide, TweenInfo.new(20/WeaponData.ShootRate,Enum.EasingStyle.Linear,Enum.EasingDirection.InOut,0,false,0), {C0 =  WeaponData.SlideEx:inverse() }):Play()
	end
	WeaponInHand.Handle.Muzzle["Smoke"]:Emit(2)
end
function CheckForHumanoid(L_225_arg1)
	local L_226_ = false
	local L_227_ = nil
	if L_225_arg1 then
		if (L_225_arg1.Parent:FindFirstChildOfClass("Humanoid") or L_225_arg1.Parent.Parent:FindFirstChildOfClass("Humanoid")) then
			L_226_ = true
			if L_225_arg1.Parent:FindFirstChildOfClass('Humanoid') then
				L_227_ = L_225_arg1.Parent:FindFirstChildOfClass('Humanoid')
			elseif L_225_arg1.Parent.Parent:FindFirstChildOfClass('Humanoid') then
				L_227_ = L_225_arg1.Parent.Parent:FindFirstChildOfClass('Humanoid')
			end
		else
			L_226_ = false
		end	
	end
	return L_226_, L_227_
end

local IgnoreAccessoriesList = {
	"Top",
	"Helmet",
	"Up",
	"Down",
	"Face",
	"Olho",
	"Headset",
	"Numero",
	"Vest",
	"Chest",
	"UpperTorso",
	"Back",
	"Belt",
	"Leg1",
	"Leg2",
	"Arm1",
	"Arm2",
	"HumanoidRootPart"
}

local TorsoList = {
	"UpperTorso",
	"LowerTorso",
	"Torso"
}

local LimbsList = {
	"LeftFoot",
	"LeftLowerLeg",
	"LeftUpperLeg",
	"RightFoot",
	"RightLowerLeg",
	"RightUpperLeg",
	"LeftHand",
	"LeftLowerArm",
	"LeftUpperArm",
	"RightHand",
	"RightLowerArm",
	"RightUpperArm",
	"Left Arm",
	"Right Arm",
	"Left Leg",
	"Right Leg",
	"Head",
}

local RicochetMaterialMaxAngles = gameRules.RicochetMaterialMaxAngles
local RicochetLoss = gameRules.RicochetLoss
local WallbangEnabled = gameRules.WallbangEnabled
local WallbangDamage = gameRules.WallbangDamage
local WallbangMaterialHardness = gameRules.WallbangMaterialHardness
local WallbangSpecialNames = gameRules.WallbangSpecialNames

function ShouldbeAddedtoIgnoreList(Part)
	if (Part.CanCollide == false or Part.Transparency >= .7 or Part.Name == "Glass") and Part.Name ~= "RightUpperLeg" and Part.Name ~= "RightLowerLeg" and Part.Name ~= "RightFoot" and Part.Name ~= "LeftUpperLeg" and Part.Name ~= "LeftLowerLeg" and Part.Name ~= "LeftFoot" and Part.Name ~= "RightUpperArm" and Part.Name ~= "RightLowerArm" and Part.Name ~= "RightHand" and Part.Name ~= "LeftUpperArm" and Part.Name ~= "LeftLowerArm" and Part.Name ~= "LeftHand" and Part.Name ~= "UpperTorso" and Part.Name ~= "LowerTorso" and Part.Name ~= "Torso" and Part.Name ~= "Right Arm" and Part.Name ~= "Left Arm" and Part.Name ~= "Left Leg" and Part.Name ~= "Right Leg" and Part.Name ~= "Neck" and Part.Name ~= "Head" and Part.Name ~= "Face" and Part.Name ~= "Tree_Collision" and Part.Name ~= "BulletProtection" then
		table.insert(Ignore_Model, Part)

		return true
	else return false
	end
end
local raycastParams = RaycastParams.new()
raycastParams.FilterDescendantsInstances = Ignore_Model
raycastParams.FilterType = Enum.RaycastFilterType.Exclude
raycastParams.IgnoreWater = true
function CastRay(Bullet, Origin)
	local Hit2, Pos2, Norm2, Mat2
	local raycastResult
	local BulletVector
	local WallbangRay

	local Mp

	local PrevPos = Origin
	local BulletPos = Bullet.Position
	local TotalDistTraveled = 0
	local recast
	local BulletStopped = false
	local WallbangParts = {}
	local Debounce = false

	local RicoHappened = false
	local RicoPos = Vector3.new(0,0,0)

	local MPosition = WeaponInHand.Handle.Muzzle.WorldPosition
	local MVector = WeaponInHand.Handle.Muzzle.WorldCFrame.LookVector


	local WhizzedPlayers = {}
	local SplashedPlayers = {}
	local SmokePart = WeaponInHand.Handle.Muzzle
	while not BulletStopped do
		Run.Heartbeat:wait()
		BulletPos = Bullet.Position
		TotalDistTraveled = TotalDistTraveled + (BulletPos - PrevPos).magnitude
		if TotalDistTraveled > 7000 or Bullet.AssemblyLinearVelocity.Magnitude <= 10 then
			Bullet:Destroy()
			break
		end
		local bspeed = Bullet.Velocity.Magnitude

		for _, plyr in pairs(game.Players:GetPlayers()) do
			local SPPosition = SmokePart.Position
			local SPVector = SmokePart.CFrame.LookVector
			local Angle2 = (plyr.Character.Head.Position - SPPosition).Unit:Dot(SPVector)
			if Debounce or plyr == plr or not plyr.Character or not plyr.Character:FindFirstChild('Head') or (plyr.Character.Head.Position - BulletPos).magnitude > 45 then continue; end;
			local HeadDist = (SPPosition - plyr.Character.Head.Position).Magnitude
			local CrackFactor = math.min(HeadDist / 64 * Angle2, 1) -- this variable adjusts whizz loudness based on distance of target from muzzle AND angle relative to muzzle
			Evt.Whizz:FireServer(plyr,BulletType,bspeed,CrackFactor,raycastResult)
			Evt.Suppression:FireServer(plyr,1,nil,nil)
			Debounce = true
		end

		Hit2, Pos2, Norm2, Mat2 = workspace:FindPartOnRayWithIgnoreList(Ray.new(PrevPos, (BulletPos - PrevPos)*5), Ignore_Model, false, true)

		local BulletRay = Ray.new(PrevPos, (BulletPos - PrevPos))
		raycastResult = workspace:Raycast(PrevPos, (BulletPos - PrevPos), raycastParams)
		BulletVector = BulletPos - PrevPos

		for _, plyr in pairs(game.Players:GetPlayers()) do
			if Debounce or plyr == plr or not plyr.Character or not plyr.Character:FindFirstChild('Head') or (plyr.Character.Head.Position - PrevPos).magnitude > 25 then continue; end;
			Evt.Suppression:FireServer(plyr,1,nil,nil)
			Debounce = true
		end

		if raycastResult then

			if Hit2 then
				while not recast do
					if Hit2 then
						if Hit2.CanCollide == false or Hit2.Name == "Ignorable" then
							if not LimbsList[Hit2.Name] and Hit2 and ( Hit2.CanCollide == false) and Hit2.Name ~= 'Head' and Hit2.Name ~= 'Right Arm' and Hit2.Name ~= 'Left Arm' and Hit2.Name ~= 'Right Leg' and Hit2.Name ~= 'Left Leg' and Hit2.Name ~= "UpperTorso" and Hit2.Name ~= "LowerTorso" and Hit2.Name ~= "RightUpperArm" and Hit2.Name ~= "RightLowerArm" and Hit2.Name ~= "RightHand" and Hit2.Name ~= "LeftUpperArm" and Hit2.Name ~= "LeftLowerArm" and Hit2.Name ~= "LeftHand" and Hit2.Name ~= "RightUpperLeg" and Hit2.Name ~= "RightLowerLeg" and Hit2.Name ~= "RightFoot" and Hit2.Name ~= "LeftUpperLeg" and Hit2.Name ~= "LeftLowerLeg" and Hit2.Name ~= "LeftFoot" and Hit2.Name ~= 'Armor' and Hit2.Name ~= 'RL' and Hit2.Name ~= 'VMotor'and Hit2.Name ~= 'FL'and Hit2.Name ~= 'FR' and Hit2.Name ~= 'RR' and Hit2.Name ~= "Armor" and Hit2.Name ~= "EShield" then
								table.insert(Ignore_Model, Hit2)
								raycastParams.FilterDescendantsInstances = Ignore_Model
								recast = true
							end
						elseif IgnoreAccessoriesList[Hit2.Parent.Name] then
							table.insert(Ignore_Model, Hit2)
							raycastParams.FilterDescendantsInstances = Ignore_Model
							recast = true
						end
					end
					if recast then
						Hit2, Pos2, Norm2, Mat2 = workspace:FindPartOnRayWithIgnoreList(Ray.new(PrevPos, (BulletPos - PrevPos)*20), Ignore_Model, false, true);

						raycastResult = workspace:Raycast(PrevPos, (BulletPos - PrevPos), raycastParams)
						BulletVector = BulletPos - PrevPos
						recast = false
					else
						break
					end
				end
			end

			if raycastResult and raycastResult.Instance then
				--visualizer.VisualizeRay(WeaponInHand.Muzzle.Position, (BulletPos - PrevPos) * TotalDistTraveled, raycastParams)
				local CastDist
				local WallbangIgnore
				if Ignore_Model then
					WallbangIgnore = {table.unpack(Ignore_Model)}
				else
					WallbangIgnore = {}
				end


				local RayDirection = (BulletPos - PrevPos).Unit

				-- while bullet is passing through walls continue, if all exhausted (if not below) then pass on loop to next iteration
				while not BulletStopped do

					if raycastResult and raycastResult.Instance and Bullet.AssemblyLinearVelocity.Magnitude >= 0 then
						local FoundHuman,Victim = CheckForHumanoid(raycastResult.Instance)

						local HitPart = raycastResult.Instance
						TotalDistTraveled = (raycastResult.Position - Origin).Magnitude

						if FoundHuman == true and Victim.Health > 0 then

							local SKP_02 = SKP_01.."-"..plr.UserId
							if HitPart.Name == "Head" or HitPart.Parent.Name == "Top" or HitPart.Parent.Name == "Headset" or HitPart.Parent.Name == "Olho" or HitPart.Parent.Name == "Face" or HitPart.Parent.Name == "Numero" then
								Evt.Damage:InvokeServer(WeaponTool, Victim, TotalDistTraveled, 1, WeaponData, ModTable, nil, nil, SKP_02)
							elseif HitPart.Name == "Torso" or HitPart.Name == "UpperTorso" or HitPart.Name == "LowerTorso" or HitPart.Parent.Name == "Chest" or HitPart.Parent.Name == "Waist" or HitPart.Name == "Right Arm" or HitPart.Name == "Left Arm" or HitPart.Name == "RightUpperArm" or HitPart.Name == "RightLowerArm" or HitPart.Name == "RightHand" or HitPart.Name == "LeftUpperArm" or HitPart.Name == "LeftLowerArm" or HitPart.Name == "LeftHand" then				
								Evt.Damage:InvokeServer(WeaponTool, Victim, TotalDistTraveled, 2, WeaponData, ModTable, nil, nil, SKP_02)
							elseif HitPart.Name == "Right Leg" or HitPart.Name == "Left Leg" or HitPart.Name == "RightUpperLeg" or HitPart.Name == "RightLowerLeg" or HitPart.Name == "RightFoot" or HitPart.Name == "LeftUpperLeg" or HitPart.Name == "LeftLowerLeg" or HitPart.Name == "LeftFoot" then
								Evt.Damage:InvokeServer(WeaponTool, Victim, TotalDistTraveled, 3, WeaponData, ModTable, nil, nil, SKP_02)	
							end	
						end
						local WallbangParams = RaycastParams.new()
						WallbangParams.FilterDescendantsInstances = {raycastResult.Instance}
						WallbangParams.FilterType = Enum.RaycastFilterType.Include
						local BulletPenetration = WeaponData.BulletPenetration / 50
						local Hardness = WallbangMaterialHardness[tostring(raycastResult.Material.Name)]

						if WallbangSpecialNames[raycastResult.Instance.Name] then
							CastDist = BulletPenetration / WallbangSpecialNames[raycastResult.Instance.Name]
						elseif Hardness then
							CastDist = BulletPenetration / Hardness
						else
							CastDist = BulletPenetration / WallbangMaterialHardness["default"]
						end

						local CastDist2 = CastDist * (Bullet.AssemblyLinearVelocity.Magnitude / (WeaponData.MuzzleVelocity * ModTable.MuzzleVelocity))
						local WBRayPosition = raycastResult.Position + RayDirection * CastDist2
						local WBRayVector = -RayDirection * CastDist2
						WallbangRay = workspace:Raycast(WBRayPosition, WBRayVector, WallbangParams)
						-- down the road, once all parts to raycast are exhausted, the function will eventually return Hit as nil, so this stops the loop
						if WallbangRay then
							local thickness = (WallbangRay.Position - raycastResult.Position).Magnitude
							local velocityMultiplier = 0
							if not (table.find(LimbsList, raycastResult.Instance.Name) or table.find(TorsoList, raycastResult.Instance.Name)) then
								velocityMultiplier = math.max((Bullet.AssemblyLinearVelocity.Magnitude / (WeaponData.MuzzleVelocity * ModTable.MuzzleVelocity)) - thickness, 0)
							end

							Bullet.AssemblyLinearVelocity = Bullet.AssemblyLinearVelocity * velocityMultiplier


							table.insert(WallbangParts,WallbangRay.Instance)
							table.insert(WallbangIgnore,WallbangRay.Instance)

							--HitMod.HitEffect(Ignore_Model, raycastResult.Position, raycastResult.Instance, raycastResult.Normal, raycastResult.Material,WeaponData)
							--Evt.HitEffect:FireServer(raycastResult.Position, raycastResult.Instance, raycastResult.Normal, raycastResult.Material,WeaponData)

							--HitMod.HitEffect(WallbangIgnore, WallbangRay.Position, WallbangRay.Instance, WallbangRay.Normal, WallbangRay.Material,WeaponData)
							--Evt.HitEffect:FireServer(WallbangRay.Position, WallbangRay.Instance, WallbangRay.Normal, WallbangRay.Material,WeaponData)
							BulletVector = BulletPos - PrevPos

							local params = RaycastParams.new()
							params.FilterDescendantsInstances = WallbangIgnore
							params.FilterType = Enum.RaycastFilterType.Exclude
							params.IgnoreWater = true
							raycastResult = workspace:Raycast(PrevPos, BulletVector, params)

						else
							--HitMod.HitEffect(Ignore_Model, raycastResult.Position, raycastResult.Instance, raycastResult.Normal, raycastResult.Material,WeaponData)
							--Evt.HitEffect:FireServer(raycastResult.Position, raycastResult.Instance, raycastResult.Normal, raycastResult.Material,WeaponData)
							if (RicoPos - raycastResult.Position).Magnitude > 0.2 then
								local Angle = math.deg(math.acos(BulletVector.Unit:Dot(raycastResult.Normal.Unit))) - 90
								local RicochetMaxAngle = RicochetMaterialMaxAngles[tostring(raycastResult.Material.Name)]
								if Angle < RicochetMaxAngle then
									Bullet.Position = raycastResult.Position
									Bullet.AssemblyLinearVelocity = (Bullet.AssemblyLinearVelocity.Magnitude * (BulletVector.Unit - (2 * BulletVector.Unit:Dot(raycastResult.Normal) * raycastResult.Normal))) * 0.35
									RicoPos = raycastResult.Position
									PrevPos = Bullet.Position
									raycastResult = nil
									RicoHappened  = true
								else
									Bullet:Destroy()
									BulletStopped = true
								end
							else
								Bullet:Destroy()
								BulletStopped = true
							end
						end
					else
						break
					end
				end
			end
		end
		if RicoHappened then
			RicoHappened = false
		else 
			PrevPos = BulletPos
		end
	end
end
local Tracers = 0
function TracerCalculation()
	if not WeaponData.Tracer then return false; end;
	if math.random(1, 100) <= 5 then return true; end;
	if Tracers >= WeaponData.TracerEveryXShots then
		Tracers = 0;
		return true;
	end;
	Tracers = Tracers + 1;
	return false;
end;
local RunService = game:GetService("RunService")

local PendingHits = {} 

local AllMaterials = Enum.Material:GetEnumItems()
local MaterialToIndex = {}
for i, m in ipairs(AllMaterials) do MaterialToIndex[m] = i end

local function PackBatchHits(raycastResults)
	local count = #raycastResults
	if count == 0 then return nil, nil end

	local bufferSize = 1 + (count * 16)
	local b = buffer.create(bufferSize)
	local instanceList = table.create(count) 

	buffer.writeu8(b, 0, count)

	for i, result in ipairs(raycastResults) do
		local offset = 1 + ((i - 1) * 16)
		local pos = result.Position
		local norm = result.Normal
		local mat = result.Material

		buffer.writef32(b, offset + 0, pos.X)
		buffer.writef32(b, offset + 4, pos.Y)
		buffer.writef32(b, offset + 8, pos.Z)

		buffer.writei8(b, offset + 12, math.round(norm.X * 127))
		buffer.writei8(b, offset + 13, math.round(norm.Y * 127))
		buffer.writei8(b, offset + 14, math.round(norm.Z * 127))

		local matIndex = MaterialToIndex[mat] or 1
		buffer.writeu8(b, offset + 15, matIndex)

		instanceList[i] = result.Instance
	end

	return b, instanceList
end

RunService.Heartbeat:Connect(function()
	if #PendingHits > 0 then
		local bufferData, hitInstances = PackBatchHits(PendingHits)

		if bufferData then
			Evt.HitEffect:FireServer(hitInstances, bufferData)
		end

		table.clear(PendingHits)
	end
end)
function CreateBullet()
	if not WeaponData or not WeaponInHand then return end

	local CollectionService = game:GetService("CollectionService") -- Servicio necesario
	local Origin = WeaponInHand.Handle.Muzzle.WorldPosition
	local BaseDirection = WeaponInHand.Handle.Muzzle.WorldCFrame.LookVector + (WeaponInHand.Handle.Muzzle.WorldCFrame.UpVector * (((WeaponData.BulletDrop * WeaponData.CurrentZero/4)/WeaponData.MuzzleVelocity))/2)

	local WalkMul = WeaponData.WalkMult * ModTable.WalkMult
	local balaspread

	if aimming and WeaponData.Bullets <= 1 then
		balaspread = CFrame.Angles(
			math.rad(RAND(-BSpread - (charspeed/1) * WalkMul, BSpread + (charspeed/1) * WalkMul) / (10 * WeaponData.AimSpreadReduction)),
			math.rad(RAND(-BSpread - (charspeed/1) * WalkMul, BSpread + (charspeed/1) * WalkMul) / (10 * WeaponData.AimSpreadReduction)),
			math.rad(RAND(-BSpread - (charspeed/1) * WalkMul, BSpread + (charspeed/1) * WalkMul) / (10 * WeaponData.AimSpreadReduction))
		)
	else
		balaspread = CFrame.Angles(
			math.rad(RAND(-BSpread - (charspeed/1) * WalkMul, BSpread + (charspeed/1) * WalkMul) / 10),
			math.rad(RAND(-BSpread - (charspeed/1) * WalkMul, BSpread + (charspeed/1) * WalkMul) / 10),
			math.rad(RAND(-BSpread - (charspeed/1) * WalkMul, BSpread + (charspeed/1) * WalkMul) / 10)
		)
	end

	local Direction = balaspread * BaseDirection
	local RayDistance = 1000

	local RayParams = RaycastParams.new()
	RayParams.FilterType = Enum.RaycastFilterType.Exclude

	local CurrentIgnoreList = {}
	if typeof(Ignore_Model) == "table" then
		for _, v in pairs(Ignore_Model) do table.insert(CurrentIgnoreList, v) end
	else
		table.insert(CurrentIgnoreList, Ignore_Model)
	end

	for _, tagged in pairs(CollectionService:GetTagged("ACS_IGNORE")) do
		table.insert(CurrentIgnoreList, tagged)
	end

	for _, v in pairs(workspace.BorderHitbox:GetDescendants()) do
		if v:IsA("BasePart") then table.insert(CurrentIgnoreList, v) end
	end

	for _, v in pairs(workspace.CantParkHere:GetDescendants()) do
		if v:IsA("BasePart") then table.insert(CurrentIgnoreList, v) end
	end

	for _, v in pairs(workspace.CantArrestHere:GetDescendants()) do
		if v:IsA("BasePart") then table.insert(CurrentIgnoreList, v) end
	end

	local ray
	local hitSomethingValid = false
	local sanityCheck = 0

	repeat
		sanityCheck = sanityCheck + 1
		RayParams.FilterDescendantsInstances = CurrentIgnoreList
		ray = workspace:Raycast(Origin, Direction * RayDistance, RayParams)

		if ray then
			local hit = ray.Instance
			--print(hit:HasTag("ACS_IGNORE"))
			local isIgnored = false

			if hit.Parent:IsA("Accessory") or hit.Parent:IsA("Accoutrement") then
				isIgnored = true
				table.insert(CurrentIgnoreList, hit.Parent)
			elseif hit:HasTag("ACS_IGNORE") then
				isIgnored = true
				table.insert(CurrentIgnoreList, hit)
			end

			if not isIgnored then
				hitSomethingValid = true
			end
		else
			hitSomethingValid = true
		end
	until hitSomethingValid or sanityCheck > 20

	if ray then
		local HitPart = ray.Instance
		local character = HitPart.Parent
		local Victim = character:FindFirstChildOfClass("Humanoid")

		HitMod.HitEffect(nil, ray.Position, ray.Instance, ray.Normal, ray.Material)

		table.insert(PendingHits, ray) 

		if not Victim then
			if character.Parent:FindFirstChildOfClass("Humanoid") then
				character = character.Parent
				Victim = character:FindFirstChildOfClass("Humanoid")
			end
		end

		if Victim and typeof(Victim) == "Instance" and Victim:IsA("Humanoid") and Victim.Health > 0 then
			local TotalDistTraveled = ray.Distance
			local SKP_02 = SKP_01.."-"..plr.UserId
			local PartName = HitPart.Name

			local HeadParts = { ["Head"] = true, ["Face"] = true } 

			local TorsoAndArms = {
				["Torso"] = true, ["UpperTorso"] = true, ["LowerTorso"] = true, ["HumanoidRootPart"] = true,
				["Chest"] = true, ["Waist"] = true,
				["Right Arm"] = true, ["Left Arm"] = true,
				["RightUpperArm"] = true, ["RightLowerArm"] = true, ["RightHand"] = true,
				["LeftUpperArm"] = true, ["LeftLowerArm"] = true, ["LeftHand"] = true
			}

			local Legs = {
				["Right Leg"] = true, ["Left Leg"] = true,
				["RightUpperLeg"] = true, ["RightLowerLeg"] = true, ["RightFoot"] = true,
				["LeftUpperLeg"] = true, ["LeftLowerLeg"] = true, ["LeftFoot"] = true
			}

			if HeadParts[PartName] or HitPart.Name == "Head" then
				Evt.Damage:InvokeServer(WeaponTool, Victim, TotalDistTraveled, 1, WeaponData, ModTable, nil, nil, SKP_02)
			elseif TorsoAndArms[PartName] then
				Evt.Damage:InvokeServer(WeaponTool, Victim, TotalDistTraveled, 2, WeaponData, ModTable, nil, nil, SKP_02)
			elseif Legs[PartName] then
				Evt.Damage:InvokeServer(WeaponTool, Victim, TotalDistTraveled, 3, WeaponData, ModTable, nil, nil, SKP_02)
			else
				Evt.Damage:InvokeServer(WeaponTool, Victim, TotalDistTraveled, 2, WeaponData, ModTable, nil, nil, SKP_02)
			end
		end
	end

	generateBullet = generateBullet + 1
	LastSpreadUpdate = time()
end
local FovAim = 80
function UpdateGui()
	if SE_GUI then
		local HUD = SE_GUI.GunHUD
		if WeaponData ~= nil then


			--if OnMobile.Value == false then

			--end


			if OnMobile.Value == true then
				HUD.Position = UDim2.new(0.85, -40,1, -30)
			elseif OnMobile.Value == false then
				HUD.Position = UDim2.new(1, -40,1., -30)
			end

			HUD.AmmoCount.Text = Ammo.."/"..StoredAmmo

			HUD.GunName.Text = WeaponTool.Name
			if WeaponData.ShootType == 1 then
				HUD.ShootType.Text = "Semi"
			elseif WeaponData.ShootType == 2 then
				HUD.ShootType.Text = "Burst"
			elseif WeaponData.ShootType == 3 then
				HUD.ShootType.Text = "Auto"
			elseif WeaponData.ShootType == 4 then
				HUD.ShootType.Text = "Pump"
			elseif WeaponData.ShootType == 5 then
				HUD.ShootType.Text = "Bolt"
			end







		end
	end
end

function CheckMagFunction()
	if aimming then
		aimming = false
		ADS(aimming)
	end
	local cmtext =  SE_GUI.GunHUD.Frame.CheckGUI.Frame.CMText

	cmtext.TextTransparency = 0
	cmtext.TextStrokeTransparency = 1
	SE_GUI.GunHUD.Frame.CheckGUI.Adornee = WeaponInHand.Mag
	cmtext.TextColor3 = Color3.fromRGB(255, 255, 255)

	if Ammo >= WeaponData.Ammo then
		cmtext.Text = "Lleno("..math.floor(WeaponData.Ammo)..")"
	elseif Ammo > math.floor((WeaponData.Ammo)*.75) and Ammo < WeaponData.Ammo then
		cmtext.Text = "Casi Lleno (~"..math.floor(WeaponData.Ammo*.9)..")"
	elseif Ammo < math.floor((WeaponData.Ammo)*.75) and Ammo > math.floor((WeaponData.Ammo)*.5) then
		cmtext.Text = "Casi Mitad(~"..math.floor(WeaponData.Ammo*.65)..")"
	elseif Ammo == math.floor((WeaponData.Ammo)*.5) then
		cmtext.Text = "Mitad(~"..math.floor(WeaponData.Ammo*.5)..")"
	elseif Ammo > math.ceil((WeaponData.Ammo)*.25) and Ammo <  math.floor((WeaponData.Ammo)*.5) then
		cmtext.Text = "Menos De La Mitad(~"..math.floor(WeaponData.Ammo*.3)..")"
	elseif Ammo < math.ceil((WeaponData.Ammo)*.25) and Ammo > 0 then
		cmtext.Text = "Casi Vacio(~"..math.floor(WeaponData.Ammo*.15)..")"
	elseif Ammo == 0 then
		cmtext.Text = "Vacio"
		cmtext.TextColor3 = Color3.fromRGB(255,25,25)
	end



	TS:Create(cmtext,TweenInfo.new(7),{TextTransparency = 1}):Play()
	mouse1down 	= false
	SafeMode 	= false
	GunStance 	= 0
	Evt.GunStance:FireServer(GunStance,AnimData)
	UpdateGui()
	MagCheckAnim()
	RunCheck()
end

function Grenade()
	if GRDebounce then return; end;
	GRDebounce = true;
	GrenadeReady()
	repeat task.wait() until not CookGrenade;
	TossGrenade()
end

function TossGrenade()
	if not WeaponTool or not WeaponData or not GRDebounce then return; end;
	local SKP_02 = SKP_01.."-"..plr.UserId
	GrenadeThrow()
	if not WeaponTool or not WeaponData then return; end;
	Evt.Grenade:FireServer(WeaponTool,WeaponData,cam.CFrame,cam.CFrame.LookVector,Power,SKP_02)
	unset()
end

function GrenadeMode()
	if Power >= 150 then
		Power = 100
		SE_GUI.GrenadeForce.Text = "Mid Throw" 

	elseif Power >= 100 then
		Power = 50
		SE_GUI.GrenadeForce.Text = "Low Throw"
	elseif Power >= 50 then
		Power = 150
		SE_GUI.GrenadeForce.Text = "High Throw"
	end
end

function Reload()
	if WeaponData.Type == "Gun" and StoredAmmo > 0 and (Ammo < WeaponData.Ammo or WeaponData.IncludeChamberedBullet and Ammo < WeaponData.Ammo + 1) then
		if aimming then
			aimming = false
			ADS(aimming)
		end

		mouse1down = false
		reloading = true
		SafeMode = false
		GunStance = 0
		Evt.GunStance:FireServer(GunStance,AnimData)
		ToolController.BackpackDisabledCases.PlayerReloading = true
		ToolController:CompareDisableCases()
		UpdateGui()

		if WeaponData.ShellInsert then
			if Ammo > 0 then
				for i = 1,WeaponData.Ammo - Ammo do
					if StoredAmmo > 0 and Ammo < WeaponData.Ammo then
						if CancelReload then
							break
						end
						ReloadAnim()
						Ammo = Ammo + 1
						StoredAmmo = StoredAmmo - 1
						UpdateGui()
					end
				end
			else
				TacticalReloadAnim()
				Ammo = Ammo + 1
				StoredAmmo = StoredAmmo - 1
				UpdateGui()
				for i = 1,WeaponData.Ammo - Ammo do
					if StoredAmmo > 0 and Ammo < WeaponData.Ammo then
						if CancelReload then
							break
						end
						ReloadAnim()
						Ammo = Ammo + 1
						StoredAmmo = StoredAmmo - 1
						UpdateGui()
					end
				end
			end
		else
			if WeaponData.ShootType == 6 then

				if GLAmmo > 0 then
					PumpAnim()
				end
				if (GLAmmo - (WeaponData.GLAmmo - GLSAmmo)) < 0 then
					GLAmmo = GLAmmo + GLSAmmo
					GLSAmmo = 0
				elseif GLAmmo <= 0 then
					GLSAmmo = GLSAmmo - (WeaponData.GLAmmo - GLAmmo)
					GLAmmo = WeaponData.GLAmmo

				end
			else
				if Ammo > 0 then
					ReloadAnim()
				else
					TacticalReloadAnim()
				end

				if (Ammo - (WeaponData.Ammo - StoredAmmo)) < 0 then
					Ammo = Ammo + StoredAmmo
					StoredAmmo = 0

				elseif Ammo <= 0 then
					StoredAmmo = StoredAmmo - (WeaponData.Ammo - Ammo)
					Ammo = WeaponData.Ammo

				elseif Ammo > 0 and WeaponData.IncludeChamberedBullet then
					StoredAmmo = StoredAmmo - (WeaponData.Ammo - Ammo) - 1
					Ammo = WeaponData.Ammo + 1

				elseif Ammo > 0 and not WeaponData.IncludeChamberedBullet then
					StoredAmmo = StoredAmmo - (WeaponData.Ammo - Ammo)
					Ammo = WeaponData.Ammo
				end
			end
		end

		CancelReload = false
		reloading = false
		RunCheck()
		UpdateGui()

		ToolController.BackpackDisabledCases.PlayerReloading = false
		ToolController:CompareDisableCases()
	end
end

function Shoot()
	if WeaponData and WeaponData.Type == "Gun" and not shooting and not reloading then
		if reloading or runKeyDown or SafeMode or CheckingMag then
			mouse1down = false
			return
		end
		if Ammo <= 0 then
			WeaponInHand.Handle.Click:Play()
			mouse1down = false
			return
		end

		if WeaponData.ShootType == 6 and GLAmmo <= 0 then
			WeaponInHand.Handle.Click:Play()
			mouse1down = false
			return
		end
		mouse1down = true

		delay(0, function()
			if WeaponData and WeaponData.ShootType == 1 then 
				shooting = true	
				Evt.Atirar:FireServer(WeaponTool,Suppressor,FlashHider)
				for _ =  1, WeaponData.Bullets do
					Thread:Spawn(CreateBullet)
				end
				Ammo = Ammo - 1
				if WeaponData.BeltFed then
					FireAnim()
				end

				UpdateGui()
				if BSpread >= WeaponData.MaxSpread then
					OverHeat = true
				end
				Thread:Spawn(Recoil)
				wait(60/WeaponData.ShootRate)
				shooting = false

			elseif WeaponData and WeaponData.ShootType == 2 then
				for i = 1, WeaponData.BurstShot do
					if shooting or Ammo <= 0 or mouse1down == false then
						break
					end
					shooting = true	
					Evt.Atirar:FireServer(WeaponTool,Suppressor,FlashHider)
					for _ =  1, WeaponData.Bullets do
						Thread:Spawn(CreateBullet)
					end
					Ammo = Ammo - 1
					if WeaponData.BeltFed then
						FireAnim()
					end

					UpdateGui()
					if BSpread >= WeaponData.MaxSpread then
						OverHeat = true
					end
					Thread:Spawn(Recoil)
					wait(60/WeaponData.ShootRate)
					shooting = false

				end
			elseif WeaponData and WeaponData.ShootType == 3 then
				while mouse1down do
					if shooting or Ammo <= 0 then
						break
					end
					shooting = true	
					Evt.Atirar:FireServer(WeaponTool,Suppressor,FlashHider)

					for _ =  1, WeaponData.Bullets do
						Thread:Spawn(CreateBullet)
					end
					Ammo = Ammo - 1
					if WeaponData.BeltFed then
						FireAnim()
					end

					UpdateGui()
					if BSpread >= WeaponData.MaxSpread then
						OverHeat = true
					end
					Thread:Spawn(Recoil)
					wait(60/WeaponData.ShootRate)
					shooting = false

				end
			elseif WeaponData and WeaponData.ShootType == 4 or WeaponData and WeaponData.ShootType == 5 then
				shooting = true	
				Evt.Atirar:FireServer(WeaponTool,Suppressor,FlashHider)
				for _ =  1, WeaponData.Bullets do
					Thread:Spawn(CreateBullet)
				end
				Ammo = Ammo - 1

				UpdateGui()

				Thread:Spawn(Recoil)
				PumpAnim()
				RunCheck()
				shooting = false
				if BSpread >= WeaponData.MaxSpread then
					OverHeat = true
				end
			elseif WeaponData and WeaponData.ShootType == 6 and WeaponData.GLAmmo > 0 then
				shooting = true
				for _ =  1, WeaponData.Bullets do
					Thread:Spawn(CreateBullet)
				end
				GLAmmo = GLAmmo - 1

				UpdateGui()
				Thread:Spawn(Recoil)
				wait(60/WeaponData.ShootRate)
				shooting = false

			end
		end)

	end
end

local L_150_ = {}
local LeanSpring = {}
LeanSpring.cornerPeek = SpringMod.new(0)
LeanSpring.cornerPeek.d = 1
LeanSpring.cornerPeek.s = 20
LeanSpring.peekFactor = math.rad(-15)
LeanSpring.dirPeek = 0

function L_150_.Update()
	LeanSpring.cornerPeek.t = LeanSpring.peekFactor * Virar
	local NewLeanCF = CFrame.fromAxisAngle(Vector3.new(0, 0, 1), LeanSpring.cornerPeek.p)
	cam.CFrame = cam.CFrame * NewLeanCF
end

game:GetService("RunService"):BindToRenderStep("Camera Update", 200, L_150_.Update)

function RunCheck()
	if runKeyDown then
		mouse1down = false
		GunStance = 3
		Evt.GunStance:FireServer(GunStance,AnimData)
		SprintAnim()
	else
		if aimming then
			if AimPartMode == 1 then
				GunStance = 2
				Evt.GunStance:FireServer(GunStance,AnimData)
			elseif AimPartMode == 2 then
				GunStance = 5
				Evt.GunStance:FireServer(GunStance,AnimData)
			end
		else
			GunStance = 0
			Evt.GunStance:FireServer(GunStance,AnimData)
		end
		IdleAnim()
	end
end

function Stand()
	Stance:FireServer(Stances,Virar)
	if Virar == 0 then
		Tween(tiltaxis,.6,{CFrame = CFrame.new(0,0,0)*CFrame.Angles(0,0,0)})
	end
	TS:Create(char.Humanoid, TweenInfo.new(.7), {CameraOffset = Vector3.new(CameraX,CameraY,0)} ):Play()

	char.Humanoid.WalkSpeed = gameRules.NormalWalkSpeed
	char.Humanoid.JumpPower = gameRules.JumpPower

	char.Humanoid:SetStateEnabled(Enum.HumanoidStateType.Jumping, true)
	IsStanced = false	
end

function Crouch()
	Stance:FireServer(Stances,Virar)
	if Virar == 0 then
		Tween(tiltaxis,.8,{CFrame = CFrame.new(-.07,0,0)*CFrame.Angles(0,0,-math.rad(-30))})
	end

	TS:Create(char.Humanoid, TweenInfo.new(.7), {CameraOffset = Vector3.new(CameraX,CameraY,0)} ):Play()
	char.Humanoid.WalkSpeed = gameRules.CrouchWalkSpeed
	char.Humanoid:SetStateEnabled(Enum.HumanoidStateType.Jumping, false)

	IsStanced = true	
end

function Prone()
	Stance:FireServer(Stances,Virar)
	TS:Create(char.Humanoid, TweenInfo.new(1), {CameraOffset = Vector3.new(CameraX,CameraY,0)} ):Play()

	char.Humanoid:SetStateEnabled(Enum.HumanoidStateType.Jumping, false)
	if ViewModel and WeaponInHand and not reloading then
		require(Engine.Animations).ProneBeginAnim(char,nil,{
			RArmWeld,
			LArmWeld,
			GunWeld,
			WeaponInHand,
			ViewModel,
		})
		IdleAnim()
	end
	IsStanced = true
	char.Humanoid.JumpPower = 0 
end

IsStanced = false	
function Lean()
	TS:Create(char.Humanoid, TweenInfo.new(1), {CameraOffset = Vector3.new(CameraX,CameraY,0)} ):Play()
	Stance:FireServer(Stances,Virar)
	if not tiltaxis then
		tiltaxis = Instance.new('Part')
	end
	if Virar == 0 then
		Tween(tiltaxis,2,{CFrame = CFrame.new(0,0,0)*CFrame.Angles(0,0,0)})
	end
	Tween(tiltaxis,.9,{CFrame = CFrame.new()*CFrame.Angles(0,0,-math.rad(CameraX*13))})
end

function EquipAnim()
	AnimDebounce = false
	reloading = true
	pcall(function()
		AnimData.EquipAnim({
			RArmWeld,
			LArmWeld,
			GunWeld,
			WeaponInHand,
			ViewModel,
			cameraspring,
			AnimationHandler
		})
	end)
	reloading = false
	AnimDebounce = true
end
function BipodAnim1()
	AnimDebounce = false
	pcall(function()
		AnimData.BipodAnim1({
			RArmWeld,
			LArmWeld,
			GunWeld,
			WeaponInHand,
			ViewModel,
			cameraspring,
			AnimationHandler
		})
	end)
	AnimDebounce = true
end
function BipodAnim2()
	AnimDebounce = false
	pcall(function()
		AnimData.BipodAnim2({
			RArmWeld,
			LArmWeld,
			GunWeld,
			WeaponInHand,
			ViewModel,
			cameraspring,
			AnimationHandler
		})
	end)
	AnimDebounce = true
end
function IdleAnim()
	pcall(function()
		AnimData.IdleAnim({
			RArmWeld,
			LArmWeld,
			GunWeld,
			WeaponInHand,
			ViewModel,
		})
	end)
	AnimDebounce = true
end

function SprintAnim()
	AnimDebounce = false
	pcall(function()
		AnimData.SprintAnim({
			RArmWeld,
			LArmWeld,
			GunWeld,
			WeaponInHand,
			ViewModel,
		})
	end)
end

function FireAnim()
	pcall(function()
		AnimData.FireAnim({
			RArmWeld,
			LArmWeld,
			GunWeld,
			WeaponInHand,
			ViewModel,
			cameraspring,
			AnimationHandler
		})
	end)
end

function Patrol()
	pcall(function()
		AnimData.Patrol({
			RArmWeld,
			LArmWeld,
			GunWeld,
			WeaponInHand,
			ViewModel,
			cameraspring,
			AnimationHandler
		})
	end)
end

function ReloadAnim()
	GunStance = 4
	Evt.GunStance:FireServer(GunStance,AnimData)
	pcall(function()
		AnimData.ReloadAnim({
			RArmWeld,
			LArmWeld,
			GunWeld,
			WeaponInHand,
			ViewModel,
			cameraspring,
			AnimationHandler
		})
	end)
	if WeaponInHand and WeaponInHand:FindFirstChild("Mag") then
		WeaponInHand.Mag.Transparency = 0
	end
end

function TacticalReloadAnim()
	GunStance = 4
	Evt.GunStance:FireServer(GunStance,AnimData)
	pcall(function()
		AnimData.TacticalReloadAnim({
			RArmWeld,
			LArmWeld,
			GunWeld,
			WeaponInHand,
			ViewModel,
			cameraspring,
			AnimationHandler
		})
	end)
	if WeaponInHand and WeaponInHand:FindFirstChild("Mag") then
		WeaponInHand.Mag.Transparency = 0
	end
end
function PumpAnim()
	reloading = true
	pcall(function()
		AnimData.PumpAnim({
			RArmWeld,
			LArmWeld,
			GunWeld,
			WeaponInHand,
			ViewModel,
		})
	end)
	reloading = false
end

function MagCheckAnim()
	CheckingMag = true
	pcall(function()
		AnimData.MagCheck({
			RArmWeld,
			LArmWeld,
			GunWeld,
			WeaponInHand,
			ViewModel,
		})
	end)
	CheckingMag = false
end

function GrenadeReady()
	pcall(function()
		AnimData.GrenadeReady({
			RArmWeld,
			LArmWeld,
			GunWeld,
			WeaponInHand,
			ViewModel,
		})
	end)
end

function GrenadeThrow()
	pcall(function()
		AnimData.GrenadeThrow({
			RArmWeld,
			LArmWeld,
			GunWeld,
			WeaponInHand,
			ViewModel,
		})
	end)
end
CAS:BindAction("Run", handleAction, false, Enum.KeyCode.LeftShift, Enum.KeyCode.ButtonL3)

CAS:BindAction("Stand", handleAction, false, Enum.KeyCode.X)
CAS:BindAction("Crouch", handleAction, false, Enum.KeyCode.C, Enum.KeyCode.ButtonB)

CAS:BindAction("LeanLeft", handleAction, false, Enum.KeyCode.Q, Enum.KeyCode.DPadLeft)
CAS:BindAction("LeanRight", handleAction, false, Enum.KeyCode.E, Enum.KeyCode.DPadRight)


local L_199_ = nil
char.ChildAdded:connect(function(Tool)
	if Tool:IsA('Tool') and Humanoid.Health > 0 and not ToolEquip and Tool:FindFirstChild("GunSettings") ~= nil and (require(Tool.GunSettings).Type == 'Gun' or require(Tool.GunSettings).Type == 'Grenade') then
		local L_370_ = true
		if char:WaitForChild('Humanoid').Sit and char.Humanoid.SeatPart:IsA("VehicleSeat") or char:WaitForChild('Humanoid').Sit and char.Humanoid.SeatPart:IsA("VehicleSeat") then
			L_370_ = false;
		end
		if L_370_ then
			L_199_ = Tool
			if not ToolEquip then
				setup(Tool)
			elseif ToolEquip then
				pcall(function()
					unset()
					setup(Tool)
				end)
			end;
		end;
	end
end)

char.ChildRemoved:connect(function(Tool)
	if Tool == WeaponTool then
		if ToolEquip then
			unset()
		end
	end
end)

Humanoid.Running:Connect(function(speed)
	charspeed = speed
	if speed > 0.1 then
		running = true
	else
		running = false
	end
end)

Humanoid.Swimming:Connect(function(speed)
	if Swimming then
		charspeed = speed
		if speed > 0.1 then
			running = true

		else
			running = false

		end
	end
end)

Humanoid.Died:Connect(function(speed)
	Humanoid:UnequipTools()
	TS:Create(char.Humanoid, TweenInfo.new(1), {CameraOffset = Vector3.new(0,0,0)} ):Play()
	ChangeStance = false

	Stances = 0
	Virar = 0
	CameraX = 0
	CameraY = 0
	Lean()
	Equipped = 0
	unset()
end)

Humanoid.Seated:Connect(function(IsSeated, Seat)
	if IsSeated and Seat and (Seat:IsA("VehicleSeat")) then
		unset()
		Humanoid:UnequipTools()
		CanLean = false
		MobileHud:SetDriving(true)
	else
		MobileHud:SetDriving(false)
	end
	if IsSeated then
		Sentado = true
		Stances = 0
		Virar = 0
		CameraX = 0
		CameraY = 0
		Stand()
		Lean()
	else
		Sentado = false
		CanLean = true
	end
end)

Humanoid.Changed:connect(function(Property)
	if gameRules.AntiBunnyHop then
		if Property == "Jump" and Humanoid.Sit == true and Humanoid.SeatPart ~= nil then
			Humanoid.Sit = false
		elseif Property == "Jump" and Humanoid.Sit == false then
			if JumpDelay then
				Humanoid.Jump = false
				return false
			end
			JumpDelay = true
			delay(0, function()
				wait(gameRules.JumpCoolDown)
				JumpDelay = false
			end)
		end
	end
end)

Humanoid.StateChanged:connect(function(Old,state)
	if state == Enum.HumanoidStateType.Swimming then
		Swimming = true
		Stances = 0
		Virar = 0
		CameraX = 0
		CameraY = 0
		Stand()
		Lean()
	else
		Swimming = false
	end
	if gameRules.EnableFallDamage then
		if state == Enum.HumanoidStateType.Freefall and not falling then

			falling = true
			local curVel = 0
			local peak = 0

			while falling do
				curVel = HumanoidRootPart.Velocity.magnitude
				peak = peak + 1
				Thread:Wait()

			end

			local damage = (curVel - (gameRules.MaxVelocity)) * gameRules.DamageMult
			if damage > 5 and peak > 20 then
				local SKP_02 = SKP_01.."-"..plr.UserId


				local hurtSound = PastaFx.FallDamage:Clone()
				hurtSound.Parent = plr.PlayerGui
				hurtSound.Volume = damage/Humanoid.MaxHealth
				hurtSound:Play()
				Debris:AddItem(hurtSound,hurtSound.TimeLength)

				Evt.Damage:InvokeServer(nil, nil, nil, nil, nil, nil, true, damage, SKP_02)
			end
		elseif state == Enum.HumanoidStateType.Landed or state == Enum.HumanoidStateType.Dead then
			falling = false

		end
	end

end)

local function SensDown()
	if ToolEquip and not CheckingMag and not aimming and not reloading and not runKeyDown and AnimDebounce and WeaponData.Type == "Gun" then
		mouse1down = false
		if GunStance == 0 then
			SafeMode = true
			GunStance = -1
			UpdateGui()
			Evt.GunStance:FireServer(GunStance,AnimData)
			Patrol()
		end
	end

	if ToolEquip and aimming and FovAim < 80 then
		UpdateGui()

	end
end

mouse.WheelBackward:Connect(SensDown)

local function SensUp()
	if ToolEquip and not CheckingMag and not aimming and not reloading and not runKeyDown and AnimDebounce and WeaponData.Type == "Gun" then
		mouse1down = false
		if GunStance == -1  then
			SafeMode = false
			GunStance = 0
			UpdateGui()
			Evt.GunStance:FireServer(GunStance,AnimData)
			IdleAnim()
		end
	end

	if ToolEquip and aimming and FovAim > 20 then
		UpdateGui()

	end
end


mouse.WheelForward:Connect(SensUp)


local u6 = {
	Power = 20, 
	Accurary = 0.5, 
	X = { 8, 8 }, 
	Y = { 5, 5 }, 
	Z = { 12, 12 }
};
local u7 = { -1, 1 };
local function u8()
	return math.rad(u6.Power * RAND(u6.X[1], u6.X[2], u6.Accurary)) * u7[math.random(1, 2)], math.rad(u6.Power * RAND(u6.Y[1], u6.Y[2], u6.Accurary)) * u7[math.random(1, 2)], math.rad(u6.Power * RAND(u6.Z[1], u6.Z[2], u6.Accurary)) * u7[math.random(1, 2)];
end;
function flinch(p20)
	u6.Power = p20;
	local v78, v79, v80 = u8();
	cameraspring:accelerate(Vector3.new( v78, v79, v80 ))
	delay(game:GetService('RunService').RenderStepped:Wait(), function()
		cameraspring:accelerate(Vector3.new( -v78, -v79, 0 ))
	end);
end

workspace.DescendantAdded:Connect(function(desc)
	if Humanoid.Health > 0 then
		if desc:IsA("Explosion") then

			local ShakeMagnitude = (plr.Character.Head.Position - desc.Position).magnitude
			if ShakeMagnitude <= 60 then
				local FX = Instance.new('ColorCorrectionEffect')
				FX.Parent = cam
				flinch((2 - math.clamp((plr.Character.UpperTorso.Position - desc.Position).magnitude/desc.BlastRadius, 0, 1)) * 25)
				TS:Create(FX,TweenInfo.new(.15,Enum.EasingStyle.Linear),{Contrast = .5}):Play()
				delay(.15,function()

					TS:Create(FX,TweenInfo.new(1.5,Enum.EasingStyle.Sine,Enum.EasingDirection.In,0,false,0.15),{Contrast = 0}):Play()
					Debris:AddItem(FX,1.5)
				end)

			end
		end
	end
end)

local sway = Vector2.new() 
game:GetService('RunService'):BindToRenderStep('thing',2000,function(dlt)
	if aimming then
		sway = sway:Lerp(Vector2.new(),.05*((1/60)/dlt))
	end
end)
local function LerpNumber(number:number, target:number, speed:number)
	return number + (target-number) * speed
end

local HalfStep = false
local rollAngle = 0
Run.RenderStepped:Connect(function(dt)
	if SprintOn == true then
		if running and (not runKeyDown) then
			RunButtonHeld()
		elseif not running then
			RunButtonUnheld()
		end
	end
	renderGunRecoil()
	renderCam()

	if ViewModel and LArm and RArm and WeaponInHand then 
		local mouseDelta = User:GetMouseDelta()

		if BipodAtt then
			local BipodRay = Ray.new(UnderBarrelAtt.Main.Position,  UnderBarrelAtt.Main.CFrame.UpVector * -1.75)
			local BipodHit, BipodPos, BipodNorm = workspace:FindPartOnRayWithIgnoreList(BipodRay, Ignore_Model, false, true)

			if BipodHit then
				if BipodActive and not runKeyDown and (GunStance == 0 or GunStance == 2) then

					TS:Create(SE_GUI.GunHUD.Att.Bipod, TweenInfo.new(.1,Enum.EasingStyle.Linear), {ImageColor3 = Color3.fromRGB(255,255,255), ImageTransparency = .123}):Play()
					if not aimming then

						BipodCF = BipodCF:Lerp(CFrame.new(0,(((UnderBarrelAtt.Main.Position - BipodPos).magnitude)-1) * (-1.5), 0),.15)
					else
						BipodCF = BipodCF:Lerp(CFrame.new(),.2)
					end				
				else
					BipodActive = false
					BipodCF = BipodCF:Lerp(CFrame.new(),.2)
					TS:Create(SE_GUI.GunHUD.Att.Bipod, TweenInfo.new(.1,Enum.EasingStyle.Linear), {ImageColor3 = Color3.fromRGB(255,255,0), ImageTransparency = .5}):Play()
				end
			else
				BipodActive = false

				BipodCF = BipodCF:Lerp(CFrame.new(),.2)
				TS:Create(SE_GUI.GunHUD.Att.Bipod, TweenInfo.new(.1,Enum.EasingStyle.Linear), {ImageColor3 = Color3.fromRGB(255,0,0), ImageTransparency = .5}):Play()
			end
		end
		sway = sway - (mouseDelta/64)
		if sway.Magnitude >= (2) then
			sway = sway:Lerp(sway.Unit*(2), 0.4)
		end
		if sway.Magnitude == 0 then
		else
			local AimOffsetCF = CFrame.new(
				sway.X* .001,
				sway.Y * -.004,
				0
			) * CFrame.Angles(
				math.rad(sway.Y/4),
				math.rad(sway.X/4),
				0
			)
			if not aimming then
				maincf = maincf * AimOffsetCF

			end
		end

		if OverHeat then
			delay(7,function()
				OverHeat = false
			end)
		end

		if WeaponData.CrossHair then
			local Normalized = ((WeaponData.CrosshairOffset + BSpread + (charspeed * WeaponData.WalkMult * ModTable.WalkMult) ) / 50)/10
			if aimming then
				CHup = CHup:Lerp(UDim2.new(.5,0,.5,0),0.1)
				CHdown = CHdown:Lerp(UDim2.new(.5,0,.5,0),0.1)
				CHleft = CHleft:Lerp(UDim2.new(.5 - Normalized,0,0.9,0),0.1)
				CHright = CHright:Lerp(UDim2.new(.5 + Normalized,0,0.9,0),0.1)
			else


				CHup = CHup:Lerp(UDim2.new(0.5, 0, 0.5 - Normalized,0),0.5)
				CHdown = CHdown:Lerp(UDim2.new(.5, 0, 0.5 + Normalized,0),0.5)
				CHleft = CHleft:Lerp(UDim2.new(.5 - Normalized, 0, 0.5, 0),0.5)
				CHright = CHright:Lerp(UDim2.new(.5 + Normalized, 0, 0.5, 0),0.5)
			end

			if OnMobile == false then
				Crosshair.Position = UDim2.new(0,mouse.X,0,mouse.Y)
			else
				Crosshair.Position = UDim2.new(0.5,0,0.5,0)
			end

			Crosshair.Up.Position = CHup
			Crosshair.Down.Position = CHdown
			Crosshair.Left.Position = CHleft
			Crosshair.Right.Position = CHright

		else

			CHup = CHup:Lerp(UDim2.new(.5,0,.5,0),0.1)
			CHdown = CHdown:Lerp(UDim2.new(.5,0,.5,0),0.1)
			CHleft = CHleft:Lerp(UDim2.new(.5,0,0.5,0),0.1)
			CHright = CHright:Lerp(UDim2.new(.5,0,0.5,0),0.1)

			if OnMobile == false then
				Crosshair.Position = UDim2.new(0,mouse.X,0,mouse.Y)
			else
				Crosshair.Position = UDim2.new(0.5,0,0.5,0)
			end

			Crosshair.Up.Position = CHup
			Crosshair.Down.Position = CHdown
			Crosshair.Left.Position = CHleft
			Crosshair.Right.Position = CHright

		end
		AnimPart.CFrame = cam.CFrame * CFrame.new(0,0,-.5) * BipodCF * maincf * gunbobcf * aimcf * tiltaxis.CFrame * recoilcf
		if not AnimData.GunModelFixed then
			WeaponInHand:SetPrimaryPartCFrame(
				ViewModel.PrimaryPart.CFrame
					* guncf
			)
		end
		if running and not Sentado then
			if aimming then
				gunbobcf = gunbobcf:Lerp(CFrame.new(
					(0.004*(gameRules.GunBobMultiplier*5)/(gameRules.GunBobReduction*5)) * (charspeed/10) * math.sin(tick() * 8),
					(0.004*(gameRules.GunBobMultiplier*5)/(gameRules.GunBobReduction*5)) * (charspeed/10) * math.cos(tick() * 16),
					0
					) * CFrame.Angles(
						math.rad( 1 * (charspeed/10) * math.sin(tick() * 6) ), 
						math.rad( 1 * (charspeed/10) * math.cos(tick() * 2) ), 
						0
					), .1)
			else
				gunbobcf = gunbobcf:Lerp(CFrame.new(
					(0.004*(gameRules.GunBobMultiplier*5)) * (charspeed/10) * math.sin(tick() * 8),
					(0.004*(gameRules.GunBobMultiplier*5)) * (charspeed/10) * math.cos(tick() * 16),
					0
					) * CFrame.Angles(
						math.rad( 1 * 14/10 * math.sin(tick() * charspeed) ), 
						math.rad( 1 * 14/10 * math.cos(tick() * charspeed/8) ), 
						math.rad( 1 * 26/6 * math.sin(tick() * charspeed*1.2) )
					), .1)

			end
		else
			gunbobcf = gunbobcf:Lerp(CFrame.new(
				(0.0025*(2*5*0.75)) * math.sin(tick() * 1.5),
				(0.0025*(2*5*0.75)) * math.cos(tick() * 2),
				0 
				), .1)
		end
		local AimTiming = 0
		AimTiming += dt / (1 * 0.1)

		if CurAimpart and aimming and AnimDebounce and not CheckingMag then

			if AimPartMode == 1 then
				TS:Create(cam,AimTween,{FieldOfView = ModTable.ZoomValue}):Play()
				maincf = maincf:Lerp(maincf * CFrame.new(0,0,-.5) * CurAimpart.CFrame:toObjectSpace(cam.CFrame), AimTiming)

			elseif AimPartMode == 2 then
				TS:Create(cam,AimTween,{FieldOfView = ModTable.Zoom2Value}):Play()

				maincf = maincf:Lerp(maincf * CFrame.new(0,0,-.5)   * CurAimpart.CFrame:toObjectSpace(cam.CFrame),AimTiming)

			elseif AimPartMode == 3 then

				TS:Create(cam,AimTween,{FieldOfView = ModTable.Zoom3Value}):Play()
				maincf = maincf:Lerp(maincf * CFrame.new(0,0,-.5) *CurAimpart.CFrame:toObjectSpace(cam.CFrame),AimTiming)

			end
		else

			TS:Create(cam,AimTween,{FieldOfView = 80}):Play()
			maincf = maincf:Lerp(AnimData.MainCFrame , 0.1)   
		end
		if WeaponData.Type == "Gun" then
			SwaySpringV2:shove(Vector3.new(-mouseDelta.X / 500, mouseDelta.Y / 200, 0))
			local updatedSway = SwaySpringV2:update(dt)
			CurAimpart.CFrame *= CFrame.new(updatedSway.X, updatedSway.Y,  0)
		end

		for index, Part in pairs(WeaponInHand:GetDescendants()) do
			if Part:IsA("BasePart") and Part.Name == "SightMark" then
				local dist_scale = Part.CFrame:pointToObjectSpace(cam.CFrame.Position)/Part.Size
				local reticle = Part.SurfaceGui.Border.Scope	
				reticle.Position=UDim2.new(.5+dist_scale.x,1,.5-dist_scale.y,0.5)	
				if Part.SurfaceGui.Border:FindFirstChild("Vignette") then
					Part.SurfaceGui.Border.Vignette.Position = reticle.Position
				end
			end
		end
		local relativeVelocity = HumanoidRootPart.CFrame:VectorToObjectSpace(HumanoidRootPart.Velocity)
		local targetRollAngle = 0
		if not aimming then targetRollAngle = math.clamp(-relativeVelocity.X, -8, 8) end
		rollAngle = LerpNumber(rollAngle,targetRollAngle,0.07 * dt * 60)
		AnimPart.CFrame *= CFrame.Angles(0,0,math.rad(rollAngle))

		recoilcf = recoilcf:Lerp(CFrame.new() * CFrame.Angles( math.rad(RecoilSpring.p.X), math.rad(RecoilSpring.p.Y), math.rad(RecoilSpring.p.z)), .1)

		if BSpread and not OverHeat then
			local currTime = time()
			if currTime - LastSpreadUpdate > (60/WeaponData.ShootRate) * 2 and not shooting and BSpread > WeaponData.MinSpread * ModTable.MinSpread then
				BSpread = math.max(WeaponData.MinSpread * ModTable.MinSpread, BSpread - WeaponData.AimInaccuracyDecrease * ModTable.AimInaccuracyDecrease)
			end
			if currTime - LastSpreadUpdate > (60/WeaponData.ShootRate) * 1.5 and not shooting and RecoilPower > WeaponData.MinRecoilPower * ModTable.MinRecoilPower then
				RecoilPower =  math.max(WeaponData.MinRecoilPower * ModTable.MinRecoilPower, RecoilPower - WeaponData.RecoilPowerStepAmount * ModTable.RecoilPowerStepAmount)
			end
		end
		if WeaponData.Type == "Gun" then
			if OverHeat then
				WeaponInHand.Handle.Muzzle.OverHeat.Enabled = true
			else
				WeaponInHand.Handle.Muzzle.OverHeat.Enabled = false
			end
		end
	end
end)
