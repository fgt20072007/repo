local ReplicatedStorage = game:GetService('ReplicatedStorage')
local TweenService = game:GetService("TweenService")
local Players = game:GetService('Players')
local SoundService = game:GetService("SoundService")

local NotificationHandler = {}
NotificationHandler.__index = NotificationHandler

-- Configuration
NotificationHandler.NotificationTemplate = script.Template 
NotificationHandler.NotificationContainer =  Players.LocalPlayer.PlayerGui:WaitForChild("MainGui").Notifications
NotificationHandler.NotificationLifetime = 4 
NotificationHandler.TweenInDuration = 0.3
NotificationHandler.TweenOutDuration = 0.2

local NotificationEvent = ReplicatedStorage.Communication.Remotes.SendNotification

local activeNotifications = {}

local function findExistingNotification(message)
	for _, notif in ipairs(activeNotifications) do
		if notif.message == message and notif.frame and notif.frame.Parent then
			return notif
		end
	end
	return nil
end

local function updateNotificationCount(notificationData)
	if not notificationData.frame or not notificationData.frame.Parent then return end

	local textLabel = notificationData.frame:FindFirstChildWhichIsA("TextLabel")
	if textLabel and notificationData.count > 1 then
		textLabel.Text = string.format("%s (x%d)", notificationData.message, notificationData.count)
	end
end

local function removeFromActive(notificationData)
	for i, notif in ipairs(activeNotifications) do
		if notif == notificationData then
			table.remove(activeNotifications, i)
			break
		end
	end
end

local function tweenIn(frame)
	frame.ImageTransparency = 1

	for _, descendant in ipairs(frame:GetDescendants()) do
		if descendant:IsA("GuiObject") then
			descendant.BackgroundTransparency = 1
		end
		if descendant:IsA("TextLabel") or descendant:IsA("TextButton") then
			descendant.TextTransparency = 1
		end
		if descendant:IsA("ImageLabel") or descendant:IsA("ImageButton") then
			descendant.ImageTransparency = 1
		end
	end

	local tweenInfo = TweenInfo.new(
		NotificationHandler.TweenInDuration,
		Enum.EasingStyle.Quad,
		Enum.EasingDirection.Out
	)

	local tweens = {}

	table.insert(tweens, TweenService:Create(frame, tweenInfo, {ImageTransparency = 0.75}))

	for _, descendant in ipairs(frame:GetDescendants()) do
		if descendant:IsA("TextLabel") or descendant:IsA("TextButton") then
			table.insert(tweens, TweenService:Create(descendant, tweenInfo, {TextTransparency = 0}))
		end
		if descendant:IsA("UIStroke") then
			table.insert(tweens, TweenService:Create(descendant, tweenInfo, {Transparency = 0}))
		end
		if descendant:IsA("ImageLabel") or descendant:IsA("ImageButton") then
			table.insert(tweens, TweenService:Create(descendant, tweenInfo, {ImageTransparency = 0}))
		end
	end

	for _, tween in ipairs(tweens) do
		tween:Play()
	end

	return tweens[1] 
end

-- Tween notification out (through transparency)
local function tweenOut(frame, callback)
	local tweenInfo = TweenInfo.new(
		NotificationHandler.TweenOutDuration,
		Enum.EasingStyle.Quad,
		Enum.EasingDirection.In
	)

	local tweens = {}

	table.insert(tweens, TweenService:Create(frame, tweenInfo, {ImageTransparency = 1}))

	for _, descendant in ipairs(frame:GetDescendants()) do
		if descendant:IsA("TextLabel") or descendant:IsA("TextButton") then
			table.insert(tweens, TweenService:Create(descendant, tweenInfo, {TextTransparency = 1}))
		end
		if descendant:IsA("UIStroke") then
			table.insert(tweens, TweenService:Create(descendant, tweenInfo, {Transparency = 1}))
		end
		if descendant:IsA("ImageLabel") or descendant:IsA("ImageButton") then
			table.insert(tweens, TweenService:Create(descendant, tweenInfo, {ImageTransparency = 1}))
		end
	end

	for _, tween in ipairs(tweens) do
		tween:Play()
	end

	if tweens[1] then
		tweens[1].Completed:Connect(function()
			if callback then
				callback()
			end
		end)
	end
end

-- Main notification function
function NotificationHandler:Notify(message, lifetime)
	assert(self.NotificationTemplate, "NotificationHandler.NotificationTemplate is not set!")
	assert(self.NotificationContainer, "NotificationHandler.NotificationContainer is not set!")

	lifetime = lifetime or self.NotificationLifetime
	local existingNotif = findExistingNotification(message)

	if existingNotif then
		existingNotif.count = existingNotif.count + 1
		updateNotificationCount(existingNotif)

		if existingNotif.lifetimeConnection then
			task.cancel(existingNotif.lifetimeConnection)
		end

		existingNotif.lifetimeConnection = task.delay(lifetime, function()
			tweenOut(existingNotif.frame, function()
				existingNotif.frame:Destroy()
				removeFromActive(existingNotif)
			end)
		end)

		return existingNotif
	end

	local notifFrame = self.NotificationTemplate:Clone()
	notifFrame.Visible = true
	notifFrame.Parent = self.NotificationContainer

	local textLabel = notifFrame:FindFirstChildWhichIsA("TextLabel")
	if textLabel then
		textLabel.Text = message
	else
		warn("NotificationHandler: No TextLabel found in template!")
	end

	local notificationData = {
		message = message,
		frame = notifFrame,
		count = 1,
		lifetimeConnection = nil
	}

	table.insert(activeNotifications, notificationData)
	tweenIn(notifFrame)

	notificationData.lifetimeConnection = task.delay(lifetime, function()
		tweenOut(notifFrame, function()
			notifFrame:Destroy()
			removeFromActive(notificationData)
		end)
	end)
	
	SoundService.Notification:Play()

	return notificationData
end

-- Clear all notifications
function NotificationHandler:ClearAll()
	for _, notif in ipairs(activeNotifications) do
		if notif.lifetimeConnection then
			notif.lifetimeConnection:Disconnect()
		end
		if notif.frame and notif.frame.Parent then
			tweenOut(notif.frame, function()
				notif.frame:Destroy()
			end)
		end
	end
	activeNotifications = {}
end

function NotificationHandler.Initialize()
	NotificationEvent.OnClientEvent:Connect(function(message)
		NotificationHandler:Notify(message or "")
	end)
end

return NotificationHandler