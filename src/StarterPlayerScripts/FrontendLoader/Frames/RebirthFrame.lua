-- Services
local ReplicatedStorage = game:GetService('ReplicatedStorage')
local Players = game:GetService('Players')

-- Variables
local Gui = Players.LocalPlayer.PlayerGui:WaitForChild("MainGui")
local Frames = Gui.Frames
local RebirthFrame = Frames.RebirthFrame

local Container = RebirthFrame.Container
local FirstFrame = Container.FirstFrame
local NextFrame = Container.NextFrame
local Bar = Container.Bar

-- Dependencies
local DataService = require(ReplicatedStorage.Utilities.DataService)
local GlobalConfiguration = require(ReplicatedStorage.DataModules.GlobalConfiguration)
local RemoteBank = require(ReplicatedStorage.RemoteBank)
local NotificationComponent = require(ReplicatedStorage.Utilities.NotificationComponent)

local Frame = {}

function Frame.UpdateBar()
	
end

-- Initialization function for the script
function Frame:Initialize()
	
end

return Frame
