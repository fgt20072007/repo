--> Services
local ProximityPrompt = game:GetService("ProximityPromptService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

--> Dependencies
local PackagesFolder = ReplicatedStorage:WaitForChild("Packages")
local Satchel = require(PackagesFolder:WaitForChild("Satchel"))
local Net = require(PackagesFolder.Net)

local Controllers = ReplicatedStorage.Controllers
local PromptController = require(Controllers.PromptController)

--> Misc
local localPlayer = game.Players.LocalPlayer
local RecalcEvent = Net:RemoteEvent('RecalcPlayerSeated')

local UIController = require(script.Parent.UIController)

local module = {}

local seatStateToken = 0

local function ApplySeatState(isSeated: boolean)
	if isSeated then
		PromptController.LockFrom('Seat')
	else
		PromptController.UnlockFrom('Seat')
	end

	Satchel:SetBackpackEnabled(not isSeated)
end

local function OnChange(hum: Humanoid)
	seatStateToken += 1
	local token = seatStateToken
	local seat = hum.SeatPart

	if seat then
		ApplySeatState(true)
		return
	end

	-- SeatPart can briefly drop to nil while the sit weld/state settles.
	-- Delay unlock slightly so prompts do not reappear while still driving.
	task.delay(0.1, function()
		if token ~= seatStateToken then return end
		ApplySeatState(hum.SeatPart ~= nil)
	end)
end

local function OnCharacterAdded(Character:Model)
	if not Character then return end
	local hum: Humanoid = Character:FindFirstChildOfClass("Humanoid")
	if not hum then return end
	seatStateToken += 1

	local SeatConnection = hum:GetPropertyChangedSignal("SeatPart"):Connect(function()
		OnChange(hum)
	end)

	hum.Died:Once(function()
		SeatConnection:Disconnect()
		OnChange(hum)
	end)

	OnChange(hum)
end

function module.Init()
	RecalcEvent.OnClientEvent:Connect(function()
		local char = localPlayer.Character
		if not char then return end

		local hum = char:FindFirstChildOfClass('Humanoid')
		if not hum then return end

		OnChange(hum)
	end)

	localPlayer.CharacterAdded:Connect(OnCharacterAdded)
	OnCharacterAdded(localPlayer.Character)

	ProximityPrompt.PromptTriggered:Connect(function(prompt: ProximityPrompt, playerWhoTriggered: Player) 
		if playerWhoTriggered ~= game.Players.LocalPlayer then return end

		local uiManager = UIController.Managers.Notifications		

		local Character = localPlayer.Character
		local Humanoid:Humanoid = Character and Character:FindFirstChild("Humanoid")
		if not Humanoid then return end
		if Humanoid.Health <= 0 then return end


		--Prevents player getting on cars while ragdolled or detained
		local PlayerDetained = playerWhoTriggered:GetAttribute("Detained")
		if PlayerDetained == "Detained" or PlayerDetained == "Arrested" or playerWhoTriggered:GetAttribute("Ragdoll") then
			return
		end


		if Humanoid:GetState() == Enum.HumanoidStateType.Physics then return end

		local seat = prompt.Parent.Parent
		if not (seat:IsA("VehicleSeat") or seat:IsA("Seat")) then return end

		local Vehicle = seat.Parent
		if Vehicle.Name == "Seats" then
			Vehicle = Vehicle.Parent.Parent
		end

		local owner = Vehicle:GetAttribute('Owner')
		if not owner then return end

		if owner ~= localPlayer.Name then
			if seat:IsA("VehicleSeat") then
				uiManager.Add('Vehicle/IsNotOwner')
				return
			end
			if Vehicle:GetAttribute("Locked") then
				if uiManager then uiManager.Add('Vehicle/DoorLocked') end
				return
			end
		end

		seat:Sit(Humanoid)
	end)
end

return module
