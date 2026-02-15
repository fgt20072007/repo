local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")

local Packages = ReplicatedStorage:WaitForChild("Packages")
local Observers = require(Packages:WaitForChild("Observers"))
 
local CollectionService = game:GetService("CollectionService")
 
local Player = Players.LocalPlayer

local Tool = script.Parent

local Net = require(ReplicatedStorage.Packages.Net)
local Notification = Net:RemoteEvent("Notification")

local Connections = {}

local function AddConnection(Connection)
	table.insert(Connections, Connection)
end

local function ClearConnections()
	for _, Connection in Connections do
		Connection:Disconnect()
	end
end

local function resolvePromptOwner(prompt: ProximityPrompt): (Player?, Model?)
	local current = prompt.Parent
	while current do
		if current:IsA("Model") then
			local owner = Players:GetPlayerFromCharacter(current)
			if owner then
				return owner, current
			end
		end
		current = current.Parent
	end

	return nil, nil
end


local AttributeListeners = {}




local function MakePromptsVisible(Tag:string, Enabled:boolean)
	for _, Prompt in CollectionService:GetTagged(Tag) do
		Prompt.Enabled = Enabled
	end
end

local function UpdatePromptsEquipped()
	MakePromptsVisible("DetainPrompt", true)
	
	for _, prompt:ProximityPrompt in CollectionService:GetTagged("ArrestPrompt") do
		local PromptOwner = resolvePromptOwner(prompt)
		if not PromptOwner then return end

		local function MakePromptVisible()
			prompt.Enabled = PromptOwner:GetAttribute("Detained") == "Detained" and true or false
		end

		AttributeListeners[PromptOwner] = PromptOwner:GetAttributeChangedSignal("Detained"):Connect(function()
			MakePromptVisible()
		end)
		MakePromptVisible()
	end
end


local IsEquipped = false
if Tool then
	Tool.Equipped:Connect(function()
		IsEquipped = true
		UpdatePromptsEquipped()	
		
		AddConnection(game.Players.PlayerAdded:Connect(function(Player:Player)
			AddConnection(Player.CharacterAdded:Connect(function(Character:Model)
				if not IsEquipped then return end
				UpdatePromptsEquipped()
			end))
		end))
		
	end)
	
	Tool.Unequipped:Connect(function()
		IsEquipped = false
		
		MakePromptsVisible("ArrestPrompt", false)
		MakePromptsVisible("DetainPrompt", false)
		
		for Player, Connection in AttributeListeners do
			Connection:Disconnect()
		end
		AttributeListeners = {}
	end)
end