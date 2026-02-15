local ReplicatedStorage = game:GetService('ReplicatedStorage')
local Players = game:GetService('Players')

local Packages = ReplicatedStorage:WaitForChild('Packages')
local Cmdr = require(Packages.Cmdr)

local GROUP_ID = 517982158
local MIN_RANK = 253

local PROTECTED_LIST = table.freeze { 1679380824, 5728817299, -1, -2 }

local CmdrService = {}

function CmdrService.IsProtected(player: Player): boolean
	local cached = player:GetAttribute('IsProtected')
	if cached ~= nil then return cached end

	local protected = false
	
	local rank = player:GetRankInGroup(GROUP_ID)
	if rank and not protected then
		protected = rank >= MIN_RANK
	end
	
	if not protected then
		protected = table.find(PROTECTED_LIST, player.UserId) ~= nil
	end
	
	player:SetAttribute('IsProtected', protected)
	return protected
end

function CmdrService.Init()
	-- Cmdr
	Cmdr:RegisterTypesIn(script.Types)
	Cmdr:RegisterHooksIn(script.Hooks)

	Cmdr:RegisterDefaultCommands()

	for _, des in script.Commands:GetChildren() do
		local info = des:FindFirstChild('info')
		local run = des:FindFirstChild('run')
		if not info then continue end

		Cmdr:RegisterCommand(info, run)
	end
	
	-- Players
	for _, player in Players:GetPlayers() do
		task.spawn(CmdrService.IsProtected, player)
	end

	Players.PlayerAdded:Connect(CmdrService.IsProtected)
end

return CmdrService