local SKP_1 = game.ReplicatedStorage.ACS_MICTLAN.Events
local SKP_2 = game.Players.LocalPlayer
local SKP_3 = game:GetService("RunService")
local MD = game.ReplicatedStorage:WaitForChild("ACS_MICTLAN")
local SKP_4 = MD.Events.MedSys
local SKP_5 = {"342190005"; "342190012"; "342190017"; "342190024";} -- Bullet Whizz
local SKP_00 = require(game.ReplicatedStorage.ACS_MICTLAN.GameRules:WaitForChild("Config"))
game.Workspace.CurrentCamera:ClearAllChildren()

local SKP_6 = game:GetService("StarterGui")
SKP_6:SetCoreGuiEnabled(Enum.CoreGuiType.PlayerList, SKP_00.CoreGuiPlayerList)
SKP_2.PlayerGui:SetTopbarTransparency(SKP_00.TopBarTransparency)
SKP_6:SetCoreGuiEnabled(Enum.CoreGuiType.Health,SKP_00.CoreGuiHealth)
local SKP_7 = script.Parent.Parent.Humanoid

if game.Workspace.CurrentCamera:FindFirstChild("BS") == nil then
	local SKP_8 = Instance.new("ColorCorrectionEffect")
	SKP_8.Parent = game.Workspace.CurrentCamera
	SKP_8.Name = "BS"
end

if game.Workspace.CurrentCamera:FindFirstChild("BO") == nil then
	local SKP_8 = Instance.new("ColorCorrectionEffect")
	SKP_8.Parent = game.Workspace.CurrentCamera
	SKP_8.Name = "BO"
end


local SKP_10 = game:GetService("TweenService")
local SKP_11 = game:GetService("Debris")


local SKP_12 = game.Workspace.CurrentCamera.BS
local SKP_13 = game.Workspace.CurrentCamera.BO

local SE_GUI = SKP_2.PlayerGui:WaitForChild("StatusUI")
local Tween = SKP_10:Create(SKP_12,TweenInfo.new(1,Enum.EasingStyle.Linear,Enum.EasingDirection.InOut,0,false,0),{Contrast = 0}):Play()
local Tween = SKP_10:Create(SKP_13,TweenInfo.new(1,Enum.EasingStyle.Linear,Enum.EasingDirection.InOut,0,false,0),{Brightness = 0}):Play()
SKP_13.Saturation 	= 0


local SKP_15 = SKP_2.Character:WaitForChild("ACS_Client")
local Stances = SKP_15:WaitForChild("Stances")

local Morto = false


local SKP_19 = true
local SKP_20 = SKP_7.Health

--SKP_7:SetStateEnabled(Enum.HumanoidStateType.Dead, false)



SKP_7.HealthChanged:Connect(function(Health)
	SE_GUI.Efeitos.Health.ImageTransparency = ((Health - (SKP_7.MaxHealth/2))/(SKP_7.MaxHealth/2))
	
	if Health < SKP_20 and Health < SKP_7.MaxHealth/2  then

		local Hurt = ((Health/SKP_20) - 1) * -1
	
		local SKP_23 = script.FX.ColorCorrection:clone()
		SKP_23.Parent = game.Workspace.CurrentCamera

	SKP_23.TintColor 	= Color3.new(1,((Health/2) /SKP_20),((Health/2)/SKP_20))

		
		SKP_10:Create(SKP_23,TweenInfo.new(3 * Hurt,Enum.EasingStyle.Sine,Enum.EasingDirection.In,0,false,0),{TintColor = Color3.new(1,1,1)}):Play()

		SKP_11:AddItem(SKP_23, 3 * Hurt)
	end

	SKP_20 = Health
end)

local SKP_24 = false







SKP_7.Died:Connect(function()

	Morto = true

	SKP_7.AutoRotate = false
	
	SKP_13.TintColor = Color3.new(1,1,1)

	--SKP_13.Brightness = 0

	SKP_12.Saturation = 0

	SKP_12.Contrast = 0


	SKP_12.Saturation = 0

	SKP_12.Contrast = 0

	

	if SKP_19 == true then
		Tween = SKP_10:Create(SKP_13,TweenInfo.new(0.1,Enum.EasingStyle.Linear,Enum.EasingDirection.InOut,0,false,0),{Brightness = 0, Contrast = 0,TintColor = Color3.new(0,0,0)}):Play()
	end	
end)
