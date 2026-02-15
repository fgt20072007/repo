local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local CollectionService = game:GetService("CollectionService")

local Packages = ReplicatedStorage:WaitForChild("Packages")
local Observers = require(Packages:WaitForChild("Observers"))

local Player = Players.LocalPlayer

local Tool = script.Parent


local Connections = {}

local function AddConnection(Connection)
	table.insert(Connections, Connection)
end

local function ClearConnections()
	for _, Connection in Connections do
		Connection:Disconnect()
	end
end


local function MakePromptsVisible(Tag:string, Enabled:boolean)
	for _, Prompt in CollectionService:GetTagged(Tag) do
		Prompt.Enabled = Enabled
	end
end


local IsEquipped = false
Tool.Equipped:Connect(function()
	IsEquipped = true
	MakePromptsVisible("StampPrompt", true)


	AddConnection(game.Players.PlayerAdded:Connect(function(Player:Player)
		AddConnection(Player.CharacterAdded:Connect(function(Character:Model)
			if not IsEquipped then return end
			MakePromptsVisible("StampPrompt", true)
		end))
	end))
end)

Tool.Unequipped:Connect(function()
	IsEquipped = false
	MakePromptsVisible("StampPrompt", false)
	ClearConnections()
end)