local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Charm = require(Shared.Packages.Charm)
local CharmSync = require(Shared.Packages.CharmSync)
local Atoms = require(Shared.Atoms)

local SyncAtoms = require(Shared.Remotes.SyncAtoms):Client()
local InitAtoms = require(Shared.Remotes.InitAtoms):Client()

local player = Players.LocalPlayer
local subscriptions = {}

local DataController = {}

function DataController._Init(self: DataController)
	local syncer = CharmSync.client({
		atoms = {
			DataStore = Atoms.DataStore,
		},
		ignoreUnhydrated = false,
	})

	SyncAtoms:On(function(profile)
		syncer:sync(profile)
	end)

	InitAtoms:Fire()
end

function DataController.OnChange(self: DataController, path: string, callback: (any) -> any)
	local userId = tostring(player.UserId)

	local pathAtom = Charm.computed(function()
		return Atoms.DataStore()[userId][path]
	end)

	local cleanup = Charm.subscribe(pathAtom, callback)

	if not subscriptions[player] then
		subscriptions[player] = {}
	end
	table.insert(subscriptions[player], cleanup)

	return cleanup
end

function DataController.GetProfile(self: DataController, Async: boolean)
	local userId = tostring(player.UserId)
	local profile = Atoms.DataStore()[userId]

	if not Async then
		return profile
	end

	while not profile do
		profile = Atoms.DataStore()[userId]
		task.wait(0.1)
	end

	return profile
end

function DataController.Get(self: DataController, Stat: string)
	local Profile = self:GetProfile(true)

	return Profile[Stat]
end

function DataController.Cleanup(self: DataController)
	if subscriptions[player] then
		for _, cleanup in subscriptions[player] do
			cleanup()
		end
		subscriptions[player] = nil
	end
end

type DataController = typeof(DataController)

return DataController
