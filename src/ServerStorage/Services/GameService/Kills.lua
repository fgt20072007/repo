--!strict
local Players = game:GetService 'Players'
local ReplicatedStorage = game:GetService 'ReplicatedStorage'
local ServerStorage = game:GetService 'ServerStorage'

local Trove = require(ReplicatedStorage.Packages.Trove)
local GeneralData = require(ReplicatedStorage.Data.General)
local RankingService = require(ServerStorage.Services.RankingService)

local ILLEGAL_REVISION = table.freeze { 'Wanted', 'Hostile' }

type PlayerConns = {
	DiedConn: RBXScriptConnection?,
	Trove: Trove.Trove,
}

local Manager = {
	Bound = {} :: {[Player]: PlayerConns},
}

function Manager.OnDeath(player: Player, hum: Humanoid)
	Manager._ClearDiedConn(player)

	if hum:GetAttribute('_CheckedOnDeath') then return end
	hum:SetAttribute('_CheckedOnDeath', true)

	if player:GetAttribute("Revision") ~= nil then
		player:SetAttribute("Revision", nil)
	end

	local enemyId = hum:GetAttribute('LastHit')
	if not enemyId then return end

	local enemy = Players:GetPlayerByUserId(enemyId)
	if not enemy then return end

	local revision = enemy:GetAttribute('Revision')

	if revision and table.find(ILLEGAL_REVISION, revision) then
		RankingService.AdjustXP(player, GeneralData.CriminalKillXP, 'Kill')
	elseif enemy.Team and enemy.Team:HasTag('Federal') then
		RankingService.AdjustXP(player, GeneralData.FedKillXP, 'Kill')
	end
end

function Manager._ClearDiedConn(player: Player)
	local conns = Manager.Bound[player]
	if not (conns and conns.DiedConn) then return end

	conns.Trove:Remove(conns.DiedConn)
	conns.DiedConn = conns.DiedConn:Disconnect()
end

function Manager._OnCharAdded(player: Player, char: Model)
	local conns = Manager.Bound[player]
	if not conns then return end

	local hum = char:FindFirstChildOfClass('Humanoid')
	if not hum then return end

	local conn = hum.Died:Connect(function()
		Manager.OnDeath(player, hum)
	end)

	conns.Trove:Add(conn)
	conns.DiedConn = conn
end

function Manager._Bind(player: Player): ()
	if Manager.Bound[player] then return end

	local trove = Trove.new()
	Manager.Bound[player] = { Trove = trove }

	local char = player.Character
	if char then
		task.spawn(Manager._OnCharAdded, player, char)
	end

	trove:Add(player.CharacterAdded:Connect(function(char: Model)
		Manager._OnCharAdded(player, char)
	end))

	trove:Add(player.CharacterRemoving:Connect(function()
		local char = player.Character
		if not char then return end

		local hum = char:FindFirstChildOfClass('Humanoid')
		if not hum then return end

		Manager.OnDeath(player, hum)
	end))
end

function Manager._UnBind(player: Player)
	local conns = Manager.Bound[player]
	if not conns then return end
	Manager.Bound[player] = nil

	conns.Trove:Destroy()
	table.clear(conns :: any)
end

function Manager.Init()
	task.spawn(function()
		for _, player in Players:GetPlayers() do
			Manager._Bind(player)
		end
	end)

	Players.PlayerAdded:Connect(Manager._Bind)
	Players.PlayerRemoving:Connect(Manager._UnBind)
end

return Manager
