-- Services
local ReplicatedStorage = game:GetService('ReplicatedStorage')
local Players = game:GetService('Players')
local TweenService = game:GetService('TweenService')
local SoundService = game:GetService('SoundService')

-- Variables
local Gui = Players.LocalPlayer.PlayerGui:WaitForChild("Extra")
local Container = Gui.Top.NotificationContainer
local Template = script.TemplateNotification

-- Dependencies
local DataService = require(ReplicatedStorage.Utilities.DataService)
local RemoteBank = require(ReplicatedStorage.RemoteBank)

local NotificationComponent = {}
local CreatedNotifications = {}

function NotificationComponent.CreateNewNotification(notificationText, color, strokeColor)
	if CreatedNotifications[notificationText] then
		return CreatedNotifications[notificationText]()
	end
	
	local delayConnection
	local runningTween : Tween
	local newTemplate = Template:Clone()
	newTemplate.Parent = Container
	
	local startersSize = newTemplate.Size
	
	newTemplate.Size = UDim2.fromScale(0, 0)
	
	if strokeColor then
		newTemplate.AmountLabel.UIStroke.Color = strokeColor
	end
	
	if color then
		if typeof(color) == "string" then
			local gradient = script.Gradients:FindFirstChild(color)
			if gradient then
				local clone = gradient:Clone()
				clone.Parent = newTemplate.AmountLabel
			end
		else
			newTemplate.AmountLabel.TextColor3 = color
		end
	end
	
	local currentAmount = 1
	
	local function changeText(amount)
		SoundService.Notification:Play()
		local extra = if amount == 1 then `` else `(x{amount or 1})`
		newTemplate.AmountLabel.Text = `{notificationText} {extra}` 
	end
	local function resetAppearence()
		if delayConnection then
			task.cancel(delayConnection)
		end
		if runningTween then
			runningTween:Cancel()
		end
		newTemplate.Size = startersSize
	end
	local function tweenSize(amount)
		local tween = TweenService:Create(newTemplate, TweenInfo.new(0.2, Enum.EasingStyle.Back), {Size = amount}); tween:Play()
		runningTween = tween
		tween.Completed:Wait()
	end
	
	local function delayDissapear()
		delayConnection = task.delay(3, function()
			tweenSize(UDim2.fromScale(0, 0))
			newTemplate:Destroy()
			CreatedNotifications[notificationText] = nil
		end)
	end
	
	CreatedNotifications[notificationText] = function()
		currentAmount += 1
		changeText(currentAmount)
		resetAppearence()
		delayDissapear()
	end
	
	changeText(1)
	tweenSize(startersSize)
	delayDissapear()
end

-- Initialization function for the script
function NotificationComponent:Initialize()
	RemoteBank.SendNotification.OnClientEvent:Connect(function(text, color)
		NotificationComponent.CreateNewNotification(text, color)
	end)
end

return NotificationComponent
