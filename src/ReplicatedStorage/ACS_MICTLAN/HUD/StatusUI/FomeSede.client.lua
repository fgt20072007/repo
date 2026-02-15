-- place this LocalScript into your thirst ScreenGui
local Engine = game.ReplicatedStorage:WaitForChild("ACS_BT")
local ServerConfig = require(Engine.ServerConfigs:WaitForChild("Config"))

local thirstGui = script.Parent
local MedicSys = game.ReplicatedStorage.ACS_BT.Eventos.MedSys
--local Text = thirstGui:WaitForChild("Back"):WaitForchild("Text")
local plr = game.Players.LocalPlayer

repeat wait() until plr.Character -- waiting for player to load

local UIS = game:GetService("UserInputService")
local hum = plr.Character:WaitForChild("Humanoid")
local maxThirst = 100
local maxHunger = 100
local thirstValue
local hungerValue

if plr:FindFirstChild("HungerVal") then
	hungerValue = plr.HungerVal
	hungerValue.Value = maxHunger
else
	Instance.new("IntValue", plr).Name = "HungerVal"
	plr.HungerVal.Value = maxHunger
	hungerValue = plr.HungerVal
end

if plr:FindFirstChild("ThirstVal") then
	thirstValue = plr.ThirstVal
	thirstValue.Value = maxThirst
else
	Instance.new("IntValue", plr).Name = "ThirstVal"
	plr.ThirstVal.Value = maxThirst
	thirstValue = plr.ThirstVal
end

local hungerValue = plr:WaitForChild("HungerVal")
local Frame = thirstGui.Frame

local TS = game:GetService("TweenService")

thirstValue.Changed:connect(function()



	if thirstValue.Value > 60 then
		TS:Create(Frame.Sede,TweenInfo.new(1,Enum.EasingStyle.Linear,Enum.EasingDirection.InOut,0,false,0),{ImageColor3 = Color3.fromRGB(255,255,255),ImageTransparency = 1}):Play()
	elseif thirstValue.Value <= 0 then
		MedicSys.Fome:FireServer()
	elseif thirstValue.Value <= 30 then
		TS:Create(Frame.Sede,TweenInfo.new(1,Enum.EasingStyle.Linear,Enum.EasingDirection.InOut,0,false,0),{ImageColor3 = Color3.fromRGB(255,((thirstValue.Value/30)*255),((thirstValue.Value/60)*255)),ImageTransparency = 0}):Play()
	elseif thirstValue.Value <= 60 then
		TS:Create(Frame.Sede,TweenInfo.new(1,Enum.EasingStyle.Linear,Enum.EasingDirection.InOut,0,false,0),{ImageColor3 = Color3.fromRGB(255,255,((thirstValue.Value/60)*255)),ImageTransparency = 0}):Play()
	end
end)


hungerValue.Changed:connect(function()

	if hungerValue.Value > 60 then
		TS:Create(Frame.Fome,TweenInfo.new(1,Enum.EasingStyle.Linear,Enum.EasingDirection.InOut,0,false,0),{ImageColor3 = Color3.fromRGB(255,255,255),ImageTransparency = 1}):Play()
	elseif hungerValue.Value <= 0 then
		MedicSys.Fome:FireServer()
	elseif hungerValue.Value <= 30 then
		TS:Create(Frame.Fome,TweenInfo.new(1,Enum.EasingStyle.Linear,Enum.EasingDirection.InOut,0,false,0),{ImageColor3 = Color3.fromRGB(255,((hungerValue.Value/30)*255),((hungerValue.Value/60)*255)),ImageTransparency = 0}):Play()
	elseif hungerValue.Value <= 60 then
		TS:Create(Frame.Fome,TweenInfo.new(1,Enum.EasingStyle.Linear,Enum.EasingDirection.InOut,0,false,0),{ImageColor3 = Color3.fromRGB(255,255,((hungerValue.Value/60)*255)),ImageTransparency = 0}):Play()
	end
end)


while wait(ServerConfig.HungerWaitTime) do

	if thirstValue.Value - 1 >= 0 then
		thirstValue.Value = thirstValue.Value - 1
	end

	if hungerValue.Value - 1 >= 0 then
		hungerValue.Value = hungerValue.Value - 1
	end
	
end