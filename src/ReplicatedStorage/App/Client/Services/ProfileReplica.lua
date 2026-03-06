--!strict

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local app = ReplicatedStorage:WaitForChild("App")
local shared = app:WaitForChild("Shared")
local sharedData = shared:WaitForChild("Data")
local profilesData = sharedData:WaitForChild("Profiles")

local ReplicaClient = require(shared:WaitForChild("Libs"):WaitForChild("ReplicaClient"))
local PlayerProfileSchema = require(profilesData:WaitForChild("PlayerProfileSchema"))
local ProfileSchemaUtil = require(profilesData:WaitForChild("ProfileSchemaUtil"))

local ProfileReplicaService = {
	_isInitialized = false,
	_replica = nil,
}

function ProfileReplicaService:Init()
	if self._isInitialized == true then
		return
	end

	self._isInitialized = true

	ReplicaClient.OnNew(PlayerProfileSchema.ReplicaToken, function(replica)
		self._replica = replica
	end)
end

function ProfileReplicaService:GetSnapshot()
	local replica = self._replica
	if replica == nil then
		return nil
	end

	return ProfileSchemaUtil.BuildReplicatedData(PlayerProfileSchema.Fields, replica.Data)
end

return ProfileReplicaService