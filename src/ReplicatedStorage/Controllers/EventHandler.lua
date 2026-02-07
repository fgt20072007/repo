local ReplicatedStorage = game:GetService('ReplicatedStorage')
local Players = game:GetService('Players')

local LuckyData = require(ReplicatedStorage.DataModules.LuckyData)

local Player = Players.LocalPlayer
local PlayerGui = Player.PlayerGui
local Main = PlayerGui:WaitForChild("MainGui")
local Container = Main.Events
local Template = Container.Template:Clone()

local Format = require(ReplicatedStorage.Utilities.Format)

local EventHandler = {}

function EventHandler.Initialize()
	for luckyName, v in pairs(LuckyData) do
		local NewTemplate = Template:Clone()
		NewTemplate.Name = luckyName
		NewTemplate.Image = v.Image
		NewTemplate.Visible = false
		NewTemplate.Parent = Container
		task.spawn(function()
			while true do
				local currentTime = os.time()
				local luckTime = workspace:GetAttribute(luckyName) or currentTime
				NewTemplate.Visible = luckTime - currentTime > 0
				NewTemplate.TextLabel.Text = Format.formatTime(luckTime - currentTime) .. "s"
				task.wait(1)
			end
		end)
	end
end

return EventHandler