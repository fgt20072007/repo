
local Tool = script.Parent
local remote = Tool:WaitForChild("RemoteEvent")
local Tween = require(script.Tween)



local Player = game.Players.LocalPlayer
local mouse = Player:GetMouse()

local last = nil
local sendrate = Tool:GetAttribute("FireRate")

local function CanSend()
	if not last then
		last = tick()
		return last
	end
	
	return tick() - last >= sendrate and tick() or nil
end

local CurrentGui = nil
local UpdateEvent = nil
local BarTweens = {}

local function CleanBarTweens()
	for _, tween:Tween in BarTweens do
		tween:Cancel()
	end
	BarTweens = {}
end

local function UpdateBar(FiredAt)
	CleanBarTweens()
	local Now = workspace:GetServerTimeNow()
	FiredAt = FiredAt or Tool:GetAttribute("FiredAt")
	local BarProgress = math.clamp((Now - FiredAt)/sendrate, 0, 1)
	CurrentGui.EnergyBar.Fill.Size = UDim2.new(BarProgress, 0, 1, 0)
	
	
	if BarProgress < 1 then
		local NewTween = Tween:Create(CurrentGui.EnergyBar.Fill, {(1 - BarProgress) * sendrate, "Linear", "Out"}, {Size = UDim2.new(1, 0, 1, 0)})
		NewTween:Play()
		table.insert(BarTweens, NewTween)
	end
end

local function Fire()
	remote:FireServer(mouse.Hit.Position)
	UpdateBar(workspace:GetServerTimeNow())
end


--> Events
Tool.Equipped:Connect(function()
	CurrentGui = script.TaserGui:Clone()
	CurrentGui.Parent = Player.PlayerGui
	
	UpdateEvent = Tool:GetAttributeChangedSignal("FiredAt"):Connect(function()
		print("UPDATE")
		UpdateBar()
	end)
	UpdateBar()
end)

Tool.Unequipped:Connect(function()
	CurrentGui:Destroy()
	CurrentGui = nil
	if UpdateEvent then UpdateEvent:Disconnect() end
	CleanBarTweens()
	
end)

Tool.Activated:Connect(function()
	local now = CanSend()
	if not now then return end
	last = now
	
	Fire()
end)