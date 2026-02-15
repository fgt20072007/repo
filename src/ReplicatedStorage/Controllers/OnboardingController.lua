--!strict
local ReplicatedStorage = game:GetService 'ReplicatedStorage'
local TweenService = game:GetService 'TweenService'
local RunService = game:GetService 'RunService'
local Players = game:GetService 'Players'

-- UI
local Client = Players.LocalPlayer :: Player
local Camera = workspace.CurrentCamera :: Camera
local PlayerGui = Client:WaitForChild('PlayerGui') :: PlayerGui

local HUDScreen = PlayerGui:WaitForChild('HUD') :: ScreenGui
local MainScreen = PlayerGui:WaitForChild('Main') :: ScreenGui
local Holder = MainScreen:WaitForChild('Onboarding') :: Frame

local Label = Holder:WaitForChild('Label') :: TextLabel
local LabelScale = Label:WaitForChild('UIScale') :: UIScale

local NextButton = Holder:WaitForChild('Next') :: ImageButton
local PrevButton = Holder:WaitForChild('Prev') :: ImageButton
local SkipButton = Holder:WaitForChild('Skip') :: ImageButton

-- Ref
local Assets = ReplicatedStorage:WaitForChild('Assets'):WaitForChild('Onboarding')
local HighlightTemp = Assets:WaitForChild('Highlight') :: Highlight

local Sequences = workspace:WaitForChild('_CameraSequences_') :: Model

-- Data & Comm
local Packages = ReplicatedStorage.Packages
local Net = require(Packages.Net)
local Trove = require(Packages.Trove)
local Satchel = require(Packages.Satchel)

local Controllers = ReplicatedStorage.Controllers
local ReplicaController = require(Controllers.ReplicaController)
local PromptController = require(Controllers.PromptController)

local Spotlight = require(Controllers.UIController.Managers.Spotlight)
local OnboardingData = require(ReplicatedStorage.Data.Onboarding)

local SkipEvent = Net:RemoteEvent('SkippedOnboarding')
local CompleteEvent = Net:RemoteEvent('CompletedOnboarding')

local LabelTween = TweenService:Create(
	LabelScale,
	TweenInfo.new(.2, Enum.EasingStyle.Quad, Enum.EasingDirection.Out, 0, true),
	{ Scale = 1.1 }
)

-- Util
local function Bezier(p0: Vector3, p1: Vector3, p2: Vector3, p3: Vector3, t: number)
	local u = 1 - t
	return
		u^3 * p0 +
		3*u^2*t * p1 +
		3*u*t^2 * p2 +
		t^3 * p3
end

local function EaseInOut(t: number): number
	return t * t * (3 - 2 * t)
end

local function GetAutoControls(a: CFrame, b: CFrame): (Vector3, Vector3)
	local dir = (b.Position - a.Position)
	local dist = dir.Magnitude

	local forwardA = a.LookVector
	local backB = -b.LookVector

	local strength = math.clamp(dist * .35, 4, 25)

	return
		a.Position + forwardA * strength,
		b.Position + backB * strength
end

local function GetOrderedPoints(sequence: Model): {BasePart}
	local parts = sequence:QueryDescendants('>BasePart') :: {BasePart}
	
	table.sort(parts, function(a: BasePart, b: BasePart)
		return (tonumber(a.Name) :: number) < (tonumber(b.Name) :: number)
	end)
	
	return parts
end

local function FindUI(path: {string}): GuiObject?
	local node = PlayerGui
	
	for _, name in path do
		node = node:FindFirstChild(name)
		if not node then return nil end
	end
	
	return node :: GuiObject
end

local function LockCamera()
	Camera.CameraType = Enum.CameraType.Scriptable
end

local function UnlockCamera()
	local character = Client.Character
	local hum = character and character:FindFirstChildOfClass('Humanoid') or nil

	Camera.CameraType = Enum.CameraType.Custom
	Camera.CameraSubject = hum
end

-- Cinematic Camera
type ActiveSection = {
	From: CFrame,
	To: CFrame,
	
	P0: Vector3,
	P1: Vector3,
	P2: Vector3,
	P3: Vector3,

	Elapsed: number,
	Duration : number,
}

local Cinematic = {
	Data = nil :: OnboardingData.Cutscene?,
	List = nil :: {[number]: {BasePart}}?,
	
	SeqIndex = 1,
	PointIndex = 1,
	
	Active = nil :: ActiveSection?,
	Connection = nil :: RBXScriptConnection?,
}

function Cinematic._UpdateSegment(): boolean
	if not (Cinematic.Data and Cinematic.List) then return false end

	local seq = Cinematic.List[Cinematic.SeqIndex]
	if not seq then return false end

	local aPart = seq[Cinematic.PointIndex]
	local bPart = seq[Cinematic.PointIndex + 1]
	
	if not (aPart and bPart) then return false end

	local a = (aPart :: BasePart).CFrame
	local b = (bPart :: BasePart).CFrame
	
	local dist = (b.Position - a.Position).Magnitude
	if dist < 1 then return false end

	local p1, p2 = GetAutoControls(a, b)

	task.spawn(Client.RequestStreamAroundAsync, Client, (b * CFrame.new(0, 0, 7.5)).Position, 0)
	Cinematic.Active = {
		From = a,
		To = b,
		
		P0 = a.Position,
		P3 = b.Position,
		P1 = p1,
		P2 = p2,
		
		Elapsed = 0,
		Duration = dist / Cinematic.Data.Speed,
	}
	
	return true
end

function Cinematic._Advance()
	if not Cinematic.List then return end
	
	local seq = Cinematic.List[Cinematic.SeqIndex]
	local upcoming = Cinematic.PointIndex + 1

	if upcoming >= #seq then
		Cinematic.SeqIndex += 1
		Cinematic.PointIndex = 1

		if Cinematic.SeqIndex > #Cinematic.List then
			Cinematic.SeqIndex = 1
		end
	else
		Cinematic.PointIndex = upcoming
	end
end

function Cinematic._OnStep(dT: number)
	if not (Cinematic.Data and Cinematic.List and Cinematic.Active) then return end
	Cinematic.Active.Elapsed += dT
	
	local t = math.clamp(Cinematic.Active.Elapsed / Cinematic.Active.Duration, 0, 1)
	if t < 1 then
		local eased = EaseInOut(t)

		local rot = Cinematic.Active.From:Lerp(Cinematic.Active.To, eased)
		local pos = Bezier(
			Cinematic.Active.P0, Cinematic.Active.P1,
			Cinematic.Active.P2, Cinematic.Active.P3,
			t
		)

		Camera.CFrame = CFrame.new(pos) * rot.Rotation
		return
	end
	
	Camera.CFrame = CFrame.new(Cinematic.Active.P3) * Cinematic.Active.To.Rotation

	while true do
		Cinematic._Advance()
		local succ = Cinematic._UpdateSegment()
		if succ then break end
	end
end

function Cinematic.Start(
	data: OnboardingData.Cutscene,
	list: {[number]: {BasePart}}
)
	if Cinematic.Connection then return end

	Cinematic.Data = data
	Cinematic.List = list

	Cinematic.SeqIndex = 1
	Cinematic.PointIndex = 1
	
	Cinematic._UpdateSegment()
	Cinematic.Connection = RunService.RenderStepped:Connect(Cinematic._OnStep)
end

function Cinematic.Stop()
	Cinematic.Connection = Cinematic.Connection and
		Cinematic.Connection:Disconnect() or nil
end

-- Controller
local Controller = {
	Target = '',
	CurrentStep = 1,
	Active = false,
	
	GeneralTrove = Trove.new(),
	StepTrove = Trove.new(),
}

function Controller._UpdateUI()
	local step = Controller.CurrentStep
	local target = Controller.Target
	
	local list = target and OnboardingData[target] or nil
	local data = list and list[step] or nil
	if not (list and data) then return end
	
	Label.Text = data.Label
	LabelTween:Play()
	
	local lastAction = list[#list].InterfaceGuide ~= nil
	
	NextButton.Visible = if lastAction then step < #list else step <= #list
	PrevButton.Visible = step > 1
end

function Controller._HandleUIGuide(data: OnboardingData.InterfaceGuide): boolean
	if data.Action then
		local actionUI = FindUI(data.Action)
		if not actionUI then return false end
		
		Spotlight.Track(actionUI)
	end
	
	local target = FindUI(data.Track.Input)
	if not target then return false end
	
	local curr = (target :: any)[data.Track.Property]
	if data.Track.Check(curr) then return false end
	
	Controller.StepTrove:Add(target:GetPropertyChangedSignal(data.Track.Property):Connect(function()
		local new = (target :: any)[data.Track.Property]
		if not data.Track.Check(new) then return end
		
		Controller._Next()
	end))
	
	return true
end

function Controller._HandleCutscene(data: OnboardingData.Cutscene): boolean
	local fixed: {[number]: {BasePart}} = {}
	for _, id in ipairs(data.Sequences) do
		local seqHolder = Sequences:FindFirstChild(id)
		if not seqHolder then continue end
		
		local list = GetOrderedPoints(seqHolder :: any)
		if #list <= 0 then continue end
		
		table.insert(fixed, list)
	end
	
	if #fixed <= 0 then return false end
	LockCamera()
	
	if #fixed == 1 and #fixed[1] == 1 then
		Camera.CFrame = fixed[1][1].CFrame
		return true
	end
	
	if data.NonStop then
		local first = fixed[1][1]
		local lastList = fixed[#fixed]
		table.insert(lastList, first)
	end
	
	Cinematic.Start(data, fixed)
	Controller.StepTrove:Add(Cinematic.Stop)
	
	return true
end

function Controller._RunActive()
	local step = Controller.CurrentStep
	local target = Controller.Target

	local list = target and OnboardingData[target] or nil
	local data = list and list[step] or nil
	if not data then return end

	Controller.StepTrove:Clean()
	
	Satchel:SetBackpackEnabled(false)
	Controller._UpdateUI()
	
	if data.Cutscene then
		local succ = Controller._HandleCutscene(data.Cutscene)
		if not succ then
			return Controller._Next()
		end
	else
		UnlockCamera()
	end
	
	if data.InterfaceGuide then
		local succ = Controller._HandleUIGuide(data.InterfaceGuide)
		if not succ then
			return Controller._Next()
		end
		
		HUDScreen.Enabled = true
	else
		HUDScreen.Enabled = false
		Spotlight.Stop()
	end
	
	local higlightRef = Sequences:FindFirstChild(`{step}_{target}_Highlights`)
	if higlightRef then
		for _, child in higlightRef:GetChildren() do
			if not (child:IsA('ObjectValue') and child.Value) then continue end
			
			local new = Controller.StepTrove:Clone(HighlightTemp)
				new.Adornee = child.Value
				new.Parent = script
		end
	end
end

function Controller._Next()
	local target = Controller.Target
	local curr = Controller.CurrentStep
	
	local list = target and OnboardingData[target] or nil
	if not (list and curr <= #list) then return end
	
	if curr == #list then
		return Controller._Finish()
	end
	
	Controller.CurrentStep = curr + 1
	Controller._RunActive()
end

function Controller._Prev()
	local curr = Controller.CurrentStep
	if curr <= 1 then return end

	Controller.CurrentStep = curr - 1
	Controller._RunActive()
end

function Controller._Finish()
	if not Controller.Active then return end
	Controller.Active = false
	
	local list = Controller.Target and
		OnboardingData[Controller.Target]
		or nil
	
	if Controller.CurrentStep == #list then
		CompleteEvent:FireServer()
	end
	
	Controller.Target = ''
	
	HUDScreen.Enabled = true
	Holder.Visible = false
	
	Controller.GeneralTrove:Clean()
	Controller.StepTrove:Clean()

	PromptController.UnlockFrom('Onboarding')
	Satchel:SetBackpackEnabled(true)
	
	UnlockCamera()
	Spotlight.Stop()
end

function Controller._BindGeneral()
	Controller.GeneralTrove:Add(Satchel.StateChanged.Event:Connect(function()
		if not Satchel:GetBackpackEnabled() then return end
		Satchel:SetBackpackEnabled(false)
	end))
	
	Controller.GeneralTrove:Add(Satchel.EnabledChanged.Event:Connect(function()
		if not Satchel:GetBackpackEnabled() then return end
		Satchel:SetBackpackEnabled(false)
	end))
	
	Controller.GeneralTrove:Add(Client.CharacterAdded:Connect(function()
		if not Satchel:GetBackpackEnabled() then return end
		Satchel:SetBackpackEnabled(false)
	end))
	
	Controller.GeneralTrove:Add(Client.Backpack.ChildAdded:Connect(function()
		if not Satchel:GetBackpackEnabled() then return end
		Satchel:SetBackpackEnabled(false)
	end))
	
	Controller.GeneralTrove:Add(SkipButton.MouseButton1Up:Connect(function()
		SkipEvent:FireServer()
		Controller._Finish()
	end))

	Controller.GeneralTrove:Add(NextButton.MouseButton1Up:Connect(function()
		Controller._Next()
	end))

	Controller.GeneralTrove:Add(PrevButton.MouseButton1Up:Connect(function()
		Controller._Prev()
	end))
end

function Controller._Begin()
	if Controller.Active then return end
	
	local team = Client.Team
	if not (team and OnboardingData[team.Name]) then return end
	
	Controller.Target = team.Name
	Controller.CurrentStep = 1
	Controller.Active = true
	
	Controller._BindGeneral()
	Controller._RunActive()
	
	PromptController.LockFrom('Onboarding')
	Satchel:SetBackpackEnabled(false)
	
	HUDScreen.Enabled = false
	Holder.Visible = true
end 

function Controller.OnTeamChange()
	local team = Client.Team
	if not (team and OnboardingData[team.Name]) then
		return Controller._Finish()
	end
	
	local replica = ReplicaController.GetReplica('PlayerData')
	if not replica then return Controller._Finish() end
	
	local list = replica.Data and replica.Data.Onboarded or nil
	if not list then return end
	
	if list[team.Name] then
		return Controller._Finish()
	elseif team.Name == Controller.Target then
		return
	end
	
	Controller._Finish()
	task.defer(Controller._Begin)
end

function Controller.Init()
	for _, des in Sequences:QueryDescendants('BasePart') do
		(des :: BasePart).Transparency = 1	
	end
	
	task.spawn(function()
		local succ, replica = ReplicaController.GetReplicaAsync('PlayerData'):await()
		if not succ then return end
		
		Client:GetPropertyChangedSignal('Team'):Connect(Controller.OnTeamChange)
		Controller.OnTeamChange()
	end)
end

return Controller
