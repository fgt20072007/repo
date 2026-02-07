local ReplicatedStorage = game:GetService("ReplicatedStorage")
local remote = ReplicatedStorage:WaitForChild("OpenDoorEvent")

local door = script.Parent
local opened = false

local OPEN_TIME = 5
local originalCFrame = door.CFrame
local openCFrame = originalCFrame * CFrame.new(0, 10, 0)

remote.OnServerEvent:Connect(function(player)
	if opened then return end
	opened = true

	door.Anchored = true
	door.CanCollide = false
	door.Transparency = 0.7
	door.CFrame = openCFrame

	task.delay(OPEN_TIME, function()
		door.CFrame = originalCFrame
		door.Transparency = 0
		door.CanCollide = true
		opened = false
	end)
end)
