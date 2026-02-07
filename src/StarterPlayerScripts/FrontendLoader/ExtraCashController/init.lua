-- Services
local ReplicatedStorage = game:GetService('ReplicatedStorage')
local Players = game:GetService('Players')
local TweenService = game:GetService('TweenService')
local SoundService = game:GetService('SoundService')

-- Variables
local Gui = Players.LocalPlayer.PlayerGui:WaitForChild("MainGui")
local Container = Gui.Currencies

-- Dependencies
local DataService = require(ReplicatedStorage.Utilities.DataService)
local RemoteBank = require(ReplicatedStorage.RemoteBank)
local Format = require(ReplicatedStorage.Utilities.Format)

local ExtraCashController = {}

function ExtraCashController.CreateCashNotification(amount)
	SoundService.Cash:Play()
	
	local NewTemplate = script.PlusCashTemplate:Clone()
	NewTemplate.TextLabel.Text = "+" .. Format.abbreviateCash(amount) .. "$"
	NewTemplate.Parent = Container
	
	NewTemplate.Visible = true
	task.delay(2, function()
		local tween = TweenService:Create(NewTemplate, TweenInfo.new(0.4, Enum.EasingStyle.Sine), {GroupTransparency = 1})
		tween:Play()
		tween.Completed:Connect(function()
			tween:Destroy()
			NewTemplate:Destroy()
		end)
	end)
end

-- Initialization function for the script
function ExtraCashController:Initialize()
	RemoteBank.CashNotification.OnClientEvent:Connect(function(Amount)
		ExtraCashController.CreateCashNotification(Amount)
	end)
end

return ExtraCashController
