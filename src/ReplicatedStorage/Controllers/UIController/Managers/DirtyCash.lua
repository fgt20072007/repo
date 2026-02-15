local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")

local Util = ReplicatedStorage:WaitForChild("Util")
local Format = require(Util.Format)

local Player = Players.LocalPlayer
local PlayerGui = Player:WaitForChild("PlayerGui")

local HUD = PlayerGui:WaitForChild("HUD") :: ScreenGui
local MainUI = HUD:WaitForChild("DirtyCash") :: Frame
local CountLabel = MainUI:WaitForChild("Count") :: TextLabel

local UIController
local Manager = {}

function Manager.UpdateCount(amount: number)
	CountLabel.Text = `${Format.WithCommas(amount)}`
end

function Manager.Display(amount: number)
	Manager.UpdateCount(amount)
	MainUI.Visible = true
end

function Manager.Hide()
	MainUI.Visible = false
end

function Manager.Init(controller)
	UIController = controller
	Manager.Hide()
end

return Manager