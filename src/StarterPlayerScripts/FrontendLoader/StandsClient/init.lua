-- Services
local ReplicatedStorage = game:GetService('ReplicatedStorage')
local Players = game:GetService('Players')
local TweenService = game:GetService('TweenService')

-- Variables

-- Dependencies
local DataService = require(ReplicatedStorage.Utilities.DataService)
local RemoteBank = require(ReplicatedStorage.RemoteBank)
local SharedFunctions = require(ReplicatedStorage.DataModules.SharedFunctions)
local Format = require(ReplicatedStorage.Utilities.Format)

local ModelTween = require(ReplicatedStorage.Utilities.ModelTween)
local guiHandler = require("./GuiController")

local StandsClient = {}

local UpgradeGuisCaches = {}

local previousTweens = {} :: {Tween}
function StandsClient.MakeEntityJump(Entity, StartingPosition, Offset)
	local EndPostion = StartingPosition * Offset
	local TweenInformations = TweenInfo.new(0.2, Enum.EasingStyle.Sine, Enum.EasingDirection.Out, 0, false, 0)

	ModelTween.ModelTween(Entity, TweenInformations, EndPostion)
	task.delay(TweenInformations.Time, function()
		ModelTween.ModelTween(Entity, TweenInformations, StartingPosition)
	end)
end

local function GetTextLabel(owns: boolean, currentState: string)
	if owns then
		if currentState == "Empty" then
			return "Place"
		elseif currentState == "Occupied" then
			return "Pickup / Swap"
		elseif currentState == "Luckyblock" then
			return "Open Mystery Box"
		end
	else
		if currentState == "Occupied" then
			return "Steal"
		end
	end

	return nil
end

function StandsClient.HandleUpgradeGui(standNumber: number, stand: Model)
	local Newgui = script.UpgradeButtonTemplate:Clone()
	Newgui.Parent = stand:FindFirstChild("UpgradeButton")

	guiHandler.AddButton(Newgui.ImageButton)

	local function Update()
		local currentData = DataService.client:get({"stands", standNumber})
		if currentData then
			local hasEntity = currentData.entity
			if hasEntity then
				Newgui.Enabled = true
				local entityName = hasEntity.name
				local upgradeLevel = hasEntity.upgradeLevel or 0
				Newgui.ImageButton.TextLabel.Text = "lvl " .. upgradeLevel .. " -> lvl " .. upgradeLevel + 1
				Newgui.ImageButton.UpgradeCost.Text =  Format.abbreviateCash(SharedFunctions.GetUpgradeCost(entityName, (upgradeLevel or 0) + 1)) .. "$"
			else
				Newgui.Enabled = false
			end
		end
	end
	UpgradeGuisCaches[standNumber] = Update
	Update()

	Newgui.ImageButton.Activated:Connect(function()
		local s, r = pcall(function()
			RemoteBank.UpgradeStand:FireServer(standNumber)
		end)
	end)
end

function StandsClient.HandleStand(owns: boolean, stand: Model, standNumber, player: Player)
	if stand then
		local attachment = stand:FindFirstChild("ProximityAttachment", true)
		assert(attachment, "ProximityAttachment not found")

		if attachment:FindFirstChildOfClass("ProximityPrompt") then return end

		local NewPrompt = script.ProximityPrompt:Clone()
		NewPrompt.Parent = attachment

		local function UpdatePrompt()
			local state = GetTextLabel(owns, stand:GetAttribute("State"))
			if not state then
				NewPrompt.Enabled = false
			else
				NewPrompt.Enabled = true
				NewPrompt.ActionText = state
			end
		end

		UpdatePrompt()
		stand:GetAttributeChangedSignal("State"):Connect(UpdatePrompt)

		NewPrompt.Triggered:Connect(function()
			if owns then
				if stand:GetAttribute("State") == "Empty" then
					RemoteBank.PlaceStand:InvokeServer(standNumber)
				elseif stand:GetAttribute("State") == "Occupied" then
					RemoteBank.PickupStand:InvokeServer(standNumber)
				elseif stand:GetAttribute("State") == "Luckyblock" then
					RemoteBank.OpenStand:InvokeServer(standNumber)
				end
			else
				if stand:GetAttribute("State") == "Occupied" then
					RemoteBank.StealStand:InvokeServer(player, standNumber)
				end
			end
		end)

		if owns then
			StandsClient.HandleUpgradeGui(standNumber, stand)
		end
	end
end

-- Initialization function for the script
function StandsClient:Initialize()
	RemoteBank.StandAdded.OnClientEvent:Connect(function(player, stand, standNumber)
		StandsClient.HandleStand(player == Players.LocalPlayer, stand, standNumber, player)
	end)

	RemoteBank.JumpEntity.OnClientEvent:Connect(StandsClient.MakeEntityJump)

	RemoteBank.UpgradeStand.OnClientEvent:Connect(function(standnumber)
		task.delay(0.1, function()
			local cacheFn = UpgradeGuisCaches[standnumber]
			if cacheFn then
				cacheFn()
			end
		end)
	end)

	task.spawn(function()
		local CurrentlyLoadedStands = RemoteBank.GetStands:InvokeServer()
		for player, container in CurrentlyLoadedStands do
			for standMumber, model in container do
				local owns = player == Players.LocalPlayer.Name

				StandsClient.HandleStand(owns, model, standMumber, Players:FindFirstChild(player))
			end
		end
	end)
end

return StandsClient