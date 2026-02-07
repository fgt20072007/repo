local ReplicatedStorage = game:GetService('ReplicatedStorage')
local Players = game:GetService('Players')

local ToolAdded = ReplicatedStorage.Communication.Remotes.ToolAdded
local ToolsData = require(ReplicatedStorage.DataModules.ToolsData)
local SharedUtilities = require(ReplicatedStorage.Utilities.SharedUtilities)

local ToolGiver = {}
local SessionTools = {}

function ToolGiver.GiveTool(player: Player, tool: Tool)
	if player.Backpack:FindFirstChild(tool.Name) or (player.Character and player.Character:FindFirstChild(tool.Name)) then return end
	local newTool = tool:Clone()
	newTool.Parent = player.Backpack
	ToolAdded:FireClient(player, tool)
end

function ToolGiver.ClearTools(player)
	local tools = SharedUtilities.getToolsForBackpackAndEquipped(player)
	for _, v in tools do
		if v:IsA("Tool") then
			v:Destroy()
		end
	end
	
	ToolAdded:FireClient(player)
	
	ToolGiver.CheckForPermanentTools(player)
end

function ToolGiver.CheckForPermanentTools(player: Player)
	for _, v in ToolsData do
		if v.GamepassId ~= 0 then
			if SharedUtilities.ownsGamepass(player, v.GamepassId) then
				ToolGiver.GiveTool(player, v.Tool)
			end
		end
	end
	if SessionTools[player] then
		for _, v in SessionTools[player] do
			ToolGiver.GiveTool(player, v)
		end
	end
end

function ToolGiver.GiveToolForSession(player: Player, tool: Tool)
	if not SessionTools[player] then
		SessionTools[player] = {}
	end
	
	table.insert(SessionTools[player], tool)
	ToolGiver.CheckForPermanentTools(player)
end

function ToolGiver.Initialize()
	Players.PlayerAdded:Connect(function(plr)
		task.wait(2)
		ToolGiver.CheckForPermanentTools(plr)
		plr.CharacterAdded:Connect(function()
			ToolGiver.CheckForPermanentTools(plr)
		end)
	end)
end

return ToolGiver