--[[
		___      _______                _     
	   / _ |____/ ___/ /  ___ ____ ___ (_)__ 
	  / __ /___/ /__/ _ \/ _ `(_-<(_-</ (_-<
	 /_/ |_|   \___/_//_/\_,_/___/___/_/___/
 						SecondLogic @ Inspare
]]


local autoscaling	= false					--Estimates top speed

local UNITS	= {								--Click on speed to change units
											--First unit is default	
	{
		units			= "MPH"				,
		scaling			= (10/12) * (60/88)	, -- 1 stud : 10 inches | ft/s to MPH
		maxSpeed		= 230				,
		spInc			= 20				, -- Increment between labelled notches
	},
	
	{
		units			= "KM/H"			,
		scaling			= (10/12) * 1.09728	, -- 1 stud : 10 inches | ft/s to KP/H
		maxSpeed		= 370				,
		spInc			= 40				, -- Increment between labelled notches
	},
	
	{
		units			= "SPS"				,
		scaling			= 1					, -- Roblox standard
		maxSpeed		= 400				,
		spInc			= 40				, -- Increment between labelled notches
	}
}

-----------------------------------------------------------------------------------------------
local ButtonsFrame = script.Parent.Buttons


local gaugeFrame = ButtonsFrame:WaitForChild("Gauge")
local speedLabel = gaugeFrame:WaitForChild("Speed")
local gearLabel = gaugeFrame:WaitForChild("Gear")
local ExitButton = ButtonsFrame.Exit

local player=game.Players.LocalPlayer
local mouse=player:GetMouse()

local car = script.Parent.Car.Value
car.DriveSeat.HeadsUpDisplay = false

local _Tune = require(car["Drive"])

local _pRPM = _Tune.PeakRPM
local _lRPM = _Tune.Redline

local currentUnits = 1
local revEnd = math.ceil(_lRPM/1000)



script.Parent.Values.Velocity.Changed:connect(function(property)
	speedLabel.Text = math.floor(UNITS[currentUnits].scaling*script.Parent.Values.Velocity.Value.Magnitude) .. " "..UNITS[currentUnits].units
end)


script.Parent.Values.Gear.Changed:connect(function()
	local gearText = script.Parent.Values.Gear.Value
	if gearText == 0 then gearText = "N"
	elseif gearText == -1 then gearText = "R"
	end
	gearLabel.Text = gearText
end)

ExitButton.MouseButton1Click:Connect(function()
	local Character = player.Character
	local Humanoid = Character and Character:FindFirstChild("Humanoid")
	if Humanoid and Humanoid.Health > 0 then
		Humanoid.Jump = true
	end
end)



wait(.1)
