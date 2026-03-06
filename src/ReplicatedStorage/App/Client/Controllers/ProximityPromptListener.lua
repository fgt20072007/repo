--!strict

local CollectionService = game:GetService("CollectionService")
local ProximityPromptService = game:GetService("ProximityPromptService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local app = ReplicatedStorage:WaitForChild("App")
local shared = app:WaitForChild("Shared")

local Net = require(shared:WaitForChild("Net")) :: any

local ProximityPromptListener = {}

function ProximityPromptListener:Init()
	ProximityPromptService.PromptTriggered:Connect(function(prompt: ProximityPrompt, _player: Player)
		local tags = CollectionService:GetTags(prompt)
		for _, tag in tags do
			Net.ProximityPromptTriggered.Fire(tag)
		end
	end)
end

return ProximityPromptListener