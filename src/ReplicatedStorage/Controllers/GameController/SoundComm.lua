--!strict
local ReplicatedStorage = game:GetService 'ReplicatedStorage'

local Net = require(ReplicatedStorage.Packages.Net)
local Sounds = require(ReplicatedStorage.Util.Sounds)

local Manager = {}

function Manager.Init()
	--Net:RemoteEvent('PlaySound').OnClientEvent:Connect(Sounds.Play :: any)
	Net:RemoteEvent('PlaySoundAt').OnClientEvent:Connect(Sounds.PlayAt :: any)
end

table.freeze(Manager)
return Manager
