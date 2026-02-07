local RunService = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage.Shared

local ClientRunContext = RunService:IsClient()

local NotificationManager = {}

function NotificationManager.Notify(NotificationManager, Message) end

return NotificationManager
