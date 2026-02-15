--!strict
local ReplicatedStorage = game:GetService 'ReplicatedStorage'
local ServerStorage = game:GetService 'ServerStorage'

local Assets = ReplicatedStorage.Assets.Jobs
local BroomTemp = Assets.Broom
local PuddleTemp = Assets.Puddle
local AnimTemp = Assets.Mop

local Packages = ReplicatedStorage.Packages
local Net = require(Packages.Net)

local Data = ReplicatedStorage.Data
local GeneralData = require(Data.General)

local Services = ServerStorage.Services
local DataService = require(Services.DataService)

local NotifEvent = Net:RemoteEvent('Notification')

local Spots = workspace:WaitForChild('JanitorJob')
	:QueryDescendants('>BasePart') :: {BasePart}

-- Config
local MAX_COUNT = 5
local SPAWN_EVERY = 15

local CLEAN_TIME = 2.5

local BROOM_NAME = `_Job_Broom_`
local ATT_NAME = `ActivePlayerId`

local MAX_PER_REF = 1
local MAX_REF_ATTEMPTS = 20

local RADIUS = math.max(PuddleTemp.Size.X, PuddleTemp.Size.Z)
local MAX_DIST = RADIUS * 2.5

local RNG = Random.new()

-- Util
local function LoadAnim(from: Model): AnimationTrack?
	local hum = from:FindFirstChildOfClass('Humanoid')
	if not hum then return nil end
	
	local animator: Animator = hum:FindFirstChildOfClass('Animator') :: any
	if not animator then
		local new = Instance.new('Animator')
			new.Parent = hum
		
		animator = new
	end
	
	return animator:LoadAnimation(AnimTemp)
end

local function WeldBroom(from: Model)
	local found = from:FindFirstChild(BROOM_NAME)
	if found then return end
	
	local hand = from:FindFirstChild('RightHand') :: BasePart?
	if not hand then return end
	
	local new = BroomTemp:Clone()
		new.Name = BROOM_NAME
		
	local handle = new:FindFirstChild('Handle') :: Attachment
	local motor = Instance.new('Motor6D')
		motor.Name = `Grip{BROOM_NAME}`
		motor.Part0 = hand
		motor.Part1 = new
		motor.C0 = CFrame.Angles(-math.pi / 2, 0, 0)
		motor.C1 = handle.CFrame
		motor.Parent = new
	
	new.Parent = from :: any	
end

local function UnWeldBroom(from: Model)
	local found = from:FindFirstChild(BROOM_NAME)
	if not found then return end
	
	found:Destroy()
end

local function PlaceNearby(char: Model, ref: Vector3)
	local root = char.PrimaryPart or char:FindFirstChild('HumanoidRootPart') :: BasePart?
	if not root then return end
	
	local hum = char:FindFirstChildOfClass('Humanoid')
	local hipHeight = hum and hum.HipHeight or 7.5
	
	local flatPos = root.Position * Vector3.new(1, 0, 1)
	local flatRef = ref * Vector3.new(1, 0, 1)
	
	local dir = flatPos - flatRef
	local unit = if dir.Magnitude < 1e-4 then -Vector3.zAxis else dir.Unit
	
	local flatTarget = flatRef + unit * RADIUS
	local target = Vector3.new(
		flatTarget.X,
		hipHeight + root.Size.Y / 3,
		flatTarget.Z
	)
	
	local look = target - Vector3.new(ref.X, target.Y, ref.Z)
	
	root.Anchored = true
	root.CFrame = CFrame.new(target)
		* CFrame.Angles(0, math.atan2(look.X, look.Z), 0)
end

-- Manager
local Manager = {
	Active = {} :: {[BasePart]: {BasePart}},
}

function Manager._GetActiveCount(): number
	local count = 0
	for _, list in Manager.Active do
		count += #list
	end
	return count
end

function Manager._CanSpawnOnRef(ref: BasePart): boolean
	local list = Manager.Active[ref]
	return not list or #list < MAX_PER_REF
end

function Manager._GetAvailableSpot(): BasePart?
	for _ = 1, MAX_REF_ATTEMPTS do
		local ref = Spots[RNG:NextInteger(1, #Spots)]
		if Manager._CanSpawnOnRef(ref) then
			return ref
		end
	end

	for _, ref in Spots do
		if Manager._CanSpawnOnRef(ref) then
			return ref
		end
	end

	return nil
end

function Manager.GetCleaning(player: Player): BasePart?
	local id = player.UserId
	
	for _, list in Manager.Active do
		for _, puddle in list do
			if puddle:GetAttribute(ATT_NAME) ~= id then continue end
			return puddle
		end
	end
	
	return nil
end

function Manager.RemoveFromActive(ref: BasePart)
	for _, list in Manager.Active do
		local index = table.find(list, ref)
		if not index then continue end
		
		table.remove(list, index)
	end
end

function Manager._OnCleanAttempt(player: Player, puddle: BasePart): boolean
	if Manager.GetCleaning(player) or puddle:GetAttribute(ATT_NAME) then return false end
	
	local char = player.Character
	if not char then return false end
	
	local team = player.Team
	if team and team:HasTag('Federal') then
		NotifEvent:FireClient(player, 'Jobs/FedBlocked')
		return false
	end
	
	local refPos = puddle.Position
	local root = char.PrimaryPart or char:FindFirstChild('HumanoidRootPart') :: BasePart?
	if not root or (refPos - root.Position).Magnitude > MAX_DIST then return false end
	
	puddle:SetAttribute(ATT_NAME, player.UserId)
	
	PlaceNearby(char, refPos)
	WeldBroom(char)
	
	local track = LoadAnim(char)
	if track then track:Play() end
	
	task.delay(CLEAN_TIME, function()
		Manager.RemoveFromActive(puddle)
		puddle:Destroy()
		
		if track then
			track:Stop()
			track:Destroy()
		end

		if not (root and root:IsDescendantOf(workspace)) then return end
		
		root.Anchored = false
		UnWeldBroom(char)

		if (refPos - root.Position).Magnitude > MAX_DIST then return end
		
		DataService.AdjustBalance(player, GeneralData.JanitorReward)
		NotifEvent:FireClient(player, 'Jobs/Completed')
	end)
	
	return true
end

function Manager.Spawn()
	if Manager._GetActiveCount() >= MAX_COUNT then return end
	
	local ref = Manager._GetAvailableSpot()
	if not ref then return end -- Just In Case
	
	local halfX = math.max(0, ref.Size.X / 2 - RADIUS)
	local halfZ = math.max(0, ref.Size.Z / 2 - RADIUS)

	local localOffset = Vector3.new(
		RNG:NextNumber(-halfX, halfX),
		-ref.Size.Y / 2,
		RNG:NextNumber(-halfZ, halfZ)
	)
	
	local cFrame = ref.CFrame
		* CFrame.new(localOffset)
		* CFrame.Angles(0, math.pi * RNG:NextNumber(), 0)
	
	local new = PuddleTemp:Clone()
		new.CFrame = cFrame 
		new.Parent = workspace :: any
	
	local prompt = new.Prompt
		prompt.MaxActivationDistance = MAX_DIST * .85
	
	new.Prompt.Triggered:Connect(function(player: Player)
		local succ = Manager._OnCleanAttempt(player, new)
		if not succ then return end
		
		prompt.Enabled = false
	end)
	
	local list = Manager.Active[ref]
	if list then
		table.insert(list, new)
	else
		Manager.Active[ref] = {new}
	end
end

function Manager.Init()
	for _, des in Spots do
		des.Transparency = 1
	end
	
	task.spawn(function()
		while true do
			Manager.Spawn()
			task.wait(SPAWN_EVERY)
		end
	end)
end

table.freeze(Manager)
return Manager
