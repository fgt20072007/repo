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
		units			= "KM/H"			,
		scaling			= (10/12) * 1.09728	, -- 1 stud : 10 inches | ft/s to KP/H
		maxSpeed		= 370				,
		spInc			= 40				, -- Increment between labelled notches
	},

}

-----------------------------------------------------------------------------------------------


local Speedometer = script.Parent
local parkingLabel = Speedometer:WaitForChild("Parking")
local gearLabel = Speedometer:WaitForChild("Gear")
local speedText = Speedometer:WaitForChild("Speed") 

local player= game.Players.LocalPlayer
local mouse= player:GetMouse()

local car = script.Parent.Parent.Parent.Car.Value
car.DriveSeat.HeadsUpDisplay = false

local _Tune = require(car["Drive"])

local _pRPM = _Tune.PeakRPM
local _lRPM = _Tune.Redline

local currentUnits = 1
local revEnd = math.ceil(_lRPM/1000)

local GaugeController = {}
GaugeController.__index = GaugeController

function GaugeController.new(speedometer: Instance, vehicle: Model, localPlayer: Player)
	local self = setmetatable({}, GaugeController)
	self.speedometer = speedometer
	self.vehicle = vehicle
	self.localPlayer = localPlayer
	self.connections = {}
	self.cleaned = false
	self:bind()
	return self
end

function GaugeController:isPlayerDriver(): boolean
	local character = self.localPlayer.Character
	local humanoid = character and character:FindFirstChildOfClass("Humanoid")
	if not humanoid then return false end
	return self.vehicle.DriveSeat.Occupant == humanoid
end

function GaugeController:cleanup()
	if self.cleaned then return end
	self.cleaned = true
	for _, connection in ipairs(self.connections) do
		connection:Disconnect()
	end
	table.clear(self.connections)

	if self.speedometer and self.speedometer.Parent then
		if self.speedometer:IsA("ScreenGui") then
			self.speedometer.Enabled = false
		end
		self.speedometer:Destroy()
	end
end

function GaugeController:track(connection: RBXScriptConnection?)
	if connection then
		table.insert(self.connections, connection)
	end
end

function GaugeController:bind()
	if not self:isPlayerDriver() then
		self:cleanup()
		return
	end

	self:track(self.vehicle.DriveSeat:GetPropertyChangedSignal("Occupant"):Connect(function()
		if not self:isPlayerDriver() then self:cleanup() end
	end))

	self:track(self.localPlayer:GetAttributeChangedSignal("Detained"):Connect(function()
		local state = self.localPlayer:GetAttribute("Detained")
		if state and state ~= "Not Detained" then self:cleanup() end
	end))

	self:track(self.localPlayer.CharacterRemoving:Connect(function()
		self:cleanup()
	end))
end

local _controller = GaugeController.new(Speedometer, car, player)

--Automatic Gauge Scaling
if autoscaling then
	local Drive={}
	if _Tune.Config == "FWD" or _Tune.Config == "AWD" then
		if car.Wheels:FindFirstChild("FL")~= nil then
			table.insert(Drive,car.Wheels.FL)
		end
		if car.Wheels:FindFirstChild("FR")~= nil then
			table.insert(Drive,car.Wheels.FR)
		end
		if car.Wheels:FindFirstChild("F")~= nil then
			table.insert(Drive,car.Wheels.F)
		end
	end
	if _Tune.Config == "RWD" or _Tune.Config == "AWD" then
		if car.Wheels:FindFirstChild("RL")~= nil then
			table.insert(Drive,car.Wheels.RL)
		end
		if car.Wheels:FindFirstChild("RR")~= nil then
			table.insert(Drive,car.Wheels.RR)
		end
		if car.Wheels:FindFirstChild("R")~= nil then
			table.insert(Drive,car.Wheels.R)
		end
	end

	local wDia = 0
	for i,v in pairs(Drive) do
		if v.Size.x>wDia then wDia = v.Size.x end
	end
	Drive = nil
	for i,v in pairs(UNITS) do
		v.maxSpeed = math.ceil(v.scaling*wDia*math.pi*_lRPM/60/_Tune.Ratios[#_Tune.Ratios]/_Tune.FinalDrive)
		v.spInc = math.max(math.ceil(v.maxSpeed/200)*20,20)
	end
end







script.Parent.Parent.Parent.Values.Gear.Changed:connect(function()
	local gearText = script.Parent.Parent.Parent.Values.Gear.Value
	if gearText == 0 then gearText = "N"
	elseif gearText == -1 then gearText = "R"
	end
	gearLabel.Text = gearText
end)





function PBrake()
	local pBrake = script.Parent.Parent.Parent.Values.PBrake.Value

	if pBrake then
		local color = Color3.fromRGB(255, 85, 127)
		parkingLabel.TextColor3 = color
	else
		local color = Color3.fromRGB(0, 0, 0)
		parkingLabel.TextColor3 = color
	end
end
script.Parent.Parent.Parent.Values.PBrake.Changed:connect(PBrake)




script.Parent.Parent.Parent.Values.Velocity.Changed:connect(function(property)
	speedText.Text = math.floor(UNITS[currentUnits].scaling*script.Parent.Parent.Parent.Values.Velocity.Value.Magnitude) .. " "..UNITS[currentUnits].units
end)


wait(.1)

PBrake()
