local Players = game:GetService('Players')
local ReplicatedStorage = game:GetService('ReplicatedStorage')

local ExtraGui = Players.LocalPlayer.PlayerGui:WaitForChild("Extra")

local Label = ExtraGui.Top.OfflineText
local RemoteBank = require(ReplicatedStorage.RemoteBank)
local Format = require(ReplicatedStorage.Utilities.Format)

local function UpdateLabel(t)
	Label.Text = 'You make <font color="#59FF00">' .. Format.abbreviateCash(t) .. '</font> Offline 😂'
end

RemoteBank.OfflineUpdated.OnClientEvent:Connect(function()
	local offlineEarnings = RemoteBank.GetOfflineAmount:InvokeServer()
	UpdateLabel(offlineEarnings)
end)

local currentOfflineEarnings = RemoteBank.GetOfflineAmount:InvokeServer()
UpdateLabel(currentOfflineEarnings)