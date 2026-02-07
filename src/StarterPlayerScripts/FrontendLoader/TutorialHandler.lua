-- Services
local ReplicatedStorage = game:GetService('ReplicatedStorage')
local Players = game:GetService('Players')
local SoundService = game:GetService('SoundService')

-- Variables
local TutorialFrame = Players.LocalPlayer.PlayerGui:WaitForChild("Extra").Top.TutorialText

-- Dependencies
local DataService = require(ReplicatedStorage.Utilities.DataService)
local RemoteBank = require(ReplicatedStorage.RemoteBank)

local NotificationComponent = require(ReplicatedStorage.Utilities.NotificationComponent)
local ConfettiHandler = require("./ConfettiHandler")

local TutorialHandler = {}
local currentTrail: Beam

local function createTrail(basepart: BasePart)
	if currentTrail then currentTrail:Destroy() end
	currentTrail = ReplicatedStorage.Assets.TutotorialBeam:Clone()
	currentTrail.Parent = workspace
	local char = Players.LocalPlayer.Character
	currentTrail.Attachment0 = char:WaitForChild("HumanoidRootPart"):WaitForChild("RootAttachment")
	local att1 = basepart:FindFirstChildOfClass("Attachment")
	if not att1 then
		att1 = Instance.new('Attachment', basepart)
	end
	currentTrail.Attachment1 = att1
end

-- Initialization function for the script
function TutorialHandler:Initialize()
	if not DataService.client:get("tutorial") then
		task.spawn(function()
			TutorialFrame.Visible = true
			local currentConnection
			Players.LocalPlayer.CharacterAdded:Connect(function(char)
				if currentTrail then
					currentTrail.Attachment0 = char:WaitForChild("HumanoidRootPart"):WaitForChild("RootAttachment")
				end
			end)
			
			TutorialFrame.Text = "1. Grab an entity!"
			
			local function GetClosestEntity()
				local char = Players.LocalPlayer.Character or Players.LocalPlayer.CharacterAdded:Wait()
				
				if not char then return end
				
				local bestdistance, entity
				for _, v in workspace.EntitiesFolder:GetChildren() do
					if v:GetAttribute("BaseNumber") == 1 then
						local distance = (char:GetPivot().Position - v:GetPivot().Position).Magnitude
						if not bestdistance or distance < bestdistance then
							bestdistance = distance
							entity = v
						end
					end
				end
				return entity and (entity.PrimaryPart or entity:FindFirstChild("HumanoidRootPart")) or nil
			end
			
			local grabbed = false
			task.spawn(function()
				while not grabbed do
					local closest = GetClosestEntity()
					if closest then
						createTrail(closest)
					end
					task.wait(0.5)
				end
			end)
			
			RemoteBank.GotEntity.OnClientEvent:Connect(function()
				grabbed = true
			end)
			
			repeat
				task.wait(0.1)
			until grabbed
			
			TutorialFrame.Text = "2. Run back and place the entity"
			
			local plot = RemoteBank.GetPlot:InvokeServer()
			if plot then
				local firstStand = plot.Floors.Floor0.Stands["1"]
				if firstStand then
					createTrail(firstStand:FindFirstChild("UpgradeButton"))
				end
			end
			
			RemoteBank.PlacedEntity.OnClientEvent:Wait()
			
			SoundService.Reward:Play()
			NotificationComponent.CreateNewNotification("Tutorial Completed!")
			ConfettiHandler.SpawnConfetti(50)
			
			TutorialFrame.Visible = false
			currentTrail:Destroy()

			RemoteBank.CompletedTutorial:InvokeServer()
		end)
	end
end

return TutorialHandler
