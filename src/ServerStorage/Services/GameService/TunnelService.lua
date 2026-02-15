--!strict
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerStorage = game:GetService("ServerStorage")

local Packages = ReplicatedStorage.Packages
local Net = require(Packages.Net)
local RateLimit = require(Packages.ReplicaShared.RateLimit)

local Data = ReplicatedStorage.Data
local GeneralData = require(Data.General)

local Services = ServerStorage.Services
local DataService = require(Services.DataService)

local NotifyEvent = Net:RemoteEvent("Notification")

local DEFAULT_ENTER_COST = 100
local DEFAULT_USA_ENTER_COST = 1_950
local TELEPORT_OFFSET = Vector3.new(0, 3.5, 0)

local EnterRateLimit = RateLimit.New(3)
local ExitRateLimit = RateLimit.New(3)

local Manager = {}

local function GetPrompt(partName: string): ProximityPrompt?
	local part = workspace:WaitForChild(partName, 15)
	if not part then
		return nil
	end

	local attachment = part:FindFirstChild("Attachment")
	if not attachment then
		return nil
	end

	local prompt = attachment:FindFirstChild("Tunnel")
	if not (prompt and prompt:IsA("ProximityPrompt")) then
		return nil
	end

	return prompt
end

local function GetDestinationCFrame(name: string): CFrame?
	local node = workspace:WaitForChild(name, 15)
	if not node then
		return nil
	end

	if node:IsA("BasePart") then
		return node.CFrame + TELEPORT_OFFSET
	end

	if node:IsA("Attachment") then
		return node.WorldCFrame + TELEPORT_OFFSET
	end

	if node:IsA("Model") then
		return node:GetPivot() + TELEPORT_OFFSET
	end

	return nil
end

local function TeleportPlayer(player: Player, target: CFrame): boolean
	local character = player.Character
	if not character then return false end

	local humanoid = character:FindFirstChildOfClass("Humanoid")
	if not humanoid or humanoid.Health <= 0 then return false end

	character:PivotTo(target)
	return true
end

local function GetEnterCost(): number
	local cost = (GeneralData :: any).TunnelEnterCost
	if typeof(cost) ~= "number" then
		return DEFAULT_ENTER_COST
	end

	return math.max(0, math.floor(cost))
end

local function GetUSAEnterCost(): number
	local cost = (GeneralData :: any).TunnelEnterUSACost
	if typeof(cost) ~= "number" then
		return DEFAULT_USA_ENTER_COST
	end

	return math.max(0, math.floor(cost))
end

local function HandleEnter(player: Player, target: CFrame, customCost: number?)
	if not EnterRateLimit:CheckRate(player) then return end

	local cost = customCost
	if typeof(cost) ~= "number" then
		cost = GetEnterCost()
	end

	if cost > 0 then
		local balance = DataService.GetBalance(player) or 0
		if balance < cost then
			NotifyEvent:FireClient(player, "Tunnel/NotEnoughCash", {
				needed = cost - balance,
			})
			return
		end

		local paid = DataService.AdjustBalance(player, -cost)
		if not paid then
			local updatedBalance = DataService.GetBalance(player) or 0
			NotifyEvent:FireClient(player, "Tunnel/NotEnoughCash", {
				needed = math.max(1, cost - updatedBalance),
			})
			return
		end
	end

	local teleported = TeleportPlayer(player, target)
	if not teleported then
		if cost > 0 then
			DataService.AdjustBalance(player, cost)
		end
		return
	end

	NotifyEvent:FireClient(player, "Tunnel/Entered")
end

local function HandleExit(player: Player, target: CFrame)
	if not ExitRateLimit:CheckRate(player) then return end
	TeleportPlayer(player, target)
end

local function BindTunnelPair(
	enterPromptName: string,
	exitPromptName: string,
	enterTargetName: string,
	exitTargetName: string,
	enterCost: number?
)
	local enterPrompt = GetPrompt(enterPromptName)
	local exitPrompt = GetPrompt(exitPromptName)
	local enterTarget = GetDestinationCFrame(enterTargetName)
	local exitTarget = GetDestinationCFrame(exitTargetName)
	if not (enterPrompt and exitPrompt and enterTarget and exitTarget) then
		return
	end

	enterPrompt.Triggered:Connect(function(player: Player)
		HandleEnter(player, enterTarget, enterCost)
	end)

	exitPrompt.Triggered:Connect(function(player: Player)
		HandleExit(player, exitTarget)
	end)
end

function Manager.Init()
	BindTunnelPair(
		"TunnelPartEnter",
		"TunnelPartExit",
		"TunnelTeleport1",
		"TunnelTeleport2",
		nil
	)

	BindTunnelPair(
		"TunnelPartEnterUSA",
		"TunnelPartExitUSA",
		"TunnelTeleport3",
		"TunnelTeleport4",
		GetUSAEnterCost()
	)
end

table.freeze(Manager)
return Manager