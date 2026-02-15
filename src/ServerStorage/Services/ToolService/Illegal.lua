--!strict
local ReplicatedStorage = game:GetService 'ReplicatedStorage'

local Observers = require(ReplicatedStorage.Packages.Observers)
local ToolData = require(ReplicatedStorage.Data.Tools)

local Manager = {}

function Manager.HandleTool(player: Player, tool: Instance)
	if not (tool and tool:IsA('Tool'))
		or (player.Team and player.Team:HasTag('Federal'))
	then return end

	local data = ToolData[tool.Name]
	if not data then return end

	local curr = player:GetAttribute('Revision')
	if curr == 'Hostile' then return end

	local att = (data.Weapon and 'Hostile')
		or (data.Illegal and 'Wanted')
		or nil

	if not att then return end
	player:SetAttribute('Revision', att)
end

function Manager.Init()
	Observers.observeCharacter(function(player: Player, char: Model)
		if player:GetAttribute('Revision') == 'Hostile' then
			player:SetAttribute('Revision', nil)
		end

		local has = char:FindFirstChildOfClass('Tool')
		if has then
			task.spawn(Manager.HandleTool, player, has)
		end

		local conn = char.ChildAdded:Connect(function(child: Instance)
			Manager.HandleTool(player, child)
		end)

		return function()
			if not conn then return end
			conn = conn:Disconnect() :: any
		end
	end)
end

return Manager
