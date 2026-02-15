--!strict
local CollectionService = game:GetService("CollectionService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local Lighting = game:GetService("Lighting")

local GetServerTimeNow = require(ReplicatedStorage.Util.GetServerTimeNow)

local HOUR = 60 -- TESTING

local DAY_TIME = 12 * HOUR
local NIGHT_TIME = 6 * HOUR
local TOTAL_TIME = DAY_TIME + NIGHT_TIME

local DAY_START = 7.5
local NIGHT_START = 17.4

-- 
local NIGHT_SETTINGS = {
	Brightness = 5,
	EnvironmentDiffuseScale = 1,
	Ambient = Color3.fromRGB(100, 100, 100),
	ExposureCompensation = .5
}
local DAY_SETTINGS = {}

local NIGHT_INSTANCES = {
	SunRays = { Enabled = false },
	Sky = { CelestialBodiesShown = true },
}
local DAY_INSTANCES = {}

--
local isCurrentlyDay: boolean? = nil
local cachedLightState: boolean? = nil

-- Util
local function ElapsedToDayTime(elapsed: number): number
	if elapsed < DAY_TIME then
		local alpha = elapsed / DAY_TIME
		return DAY_START + alpha * 12
	end

	local alpha = (elapsed - DAY_TIME) / NIGHT_TIME
	local dayTime = 18 + alpha * 12
	return dayTime >= 24 and dayTime - 24 or dayTime
end

local function ApplyLightStateToInstance(inst: Instance, state: boolean)
	if inst:IsA("Light") then
		inst.Enabled = state
		
		local parent = inst.Parent
		if not parent then return end
		
		if not parent:IsA("BasePart") then return end
		
		if state then
			parent.Material = Enum.Material.Neon
		else
			parent.Material = Enum.Material.SmoothPlastic
		end
		return
	end

	for _, d in ipairs(inst:GetDescendants()) do
		if d:IsA("Light") then
			d.Enabled = state
		end
	end
end

local function SetLightState(state: boolean)
	if cachedLightState == state then
		return
	end
	cachedLightState = state
	
	for id, value in (state and NIGHT_SETTINGS or DAY_SETTINGS) do
		Lighting[id] = value
	end
	
	for name, data in (state and NIGHT_INSTANCES or DAY_INSTANCES) do
		local inst = Lighting:FindFirstChild(name)
		if not inst then continue end
		
		for id, value in data do
			inst[id] = value
		end
	end

	for _, inst in ipairs(CollectionService:GetTagged("StreetLight")) do
		ApplyLightStateToInstance(inst, state)
	end
end

-- Controller
local DayCycleController = {}

function DayCycleController._OnStep(_dT: number)
	local syncedTime = GetServerTimeNow()
	local elapsed = syncedTime % TOTAL_TIME

	local clock = ElapsedToDayTime(elapsed)
	Lighting.ClockTime = clock

	local isDay = clock >= DAY_START and clock < NIGHT_START

	if isCurrentlyDay == nil then
		isCurrentlyDay = isDay
		SetLightState(not isDay)
	elseif isCurrentlyDay ~= isDay then
		isCurrentlyDay = isDay
		SetLightState(not isDay)
	end
end

function DayCycleController.Init()
	for id, _ in NIGHT_SETTINGS :: any do
		DAY_SETTINGS[id] = Lighting[id] 
	end
	
	for name, data in NIGHT_INSTANCES :: any do
		local inst = Lighting:FindFirstChild(name)
		if not inst then continue end
		
		local saved = {}
		for id, _ in data do
			saved[id] = inst[id]
		end
		
		DAY_INSTANCES[name] = saved
	end
	
	RunService.RenderStepped:Connect(DayCycleController._OnStep)
end

return DayCycleController
