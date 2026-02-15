local CollectionService = game:GetService("CollectionService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Assets = ReplicatedStorage:WaitForChild("Assets")
local Beams = Assets:WaitForChild("Beams")
local TutorialBeam = Beams:WaitForChild("TutorialBeam") :: Beam

local ARROW_TAG = "TutorialBeam"

local TutorialController = {}

function TutorialController.Init()
	for _, module in script:GetChildren() do
		if not module:IsA("ModuleScript") then return end
		
		local success, result = pcall(require, module)
		
		if success then
			result.new(TutorialController)
		else
			warn("Failed to require module:", module.Name, result)
		end
	end
end

function TutorialController:IsFirstJoin(player: Player)
	if not player:IsA("Player") then return false end
	
	--
	return true
end

function TutorialController:applyBeam(source: Instance, target: Instance)
	if not source or not target then return false end
	
	local existingArrows = CollectionService:GetTagged(ARROW_TAG)
	
	for _, arrow in existingArrows do
		arrow:Destroy()
	end
	
	local beamClone = TutorialBeam:Clone() 
	beamClone:AddTag(ARROW_TAG)
	
	beamClone.Attachment0 = source
	beamClone.Attachment1 = target
	beamClone.Enabled = true
	beamClone.Parent = source
	return true
end

function TutorialController:displayMessage(message: string)
	if not message then return end
	
	warn(message)
end



return TutorialController