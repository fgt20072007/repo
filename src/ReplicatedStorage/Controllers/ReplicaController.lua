local ReplicatedStorage = game:GetService('ReplicatedStorage')
local RunService = game:GetService('RunService')

local Packages = ReplicatedStorage:WaitForChild('Packages')
local ReplicaClient = require(Packages.ReplicaClient)
local Promise = require(Packages.Promise)
local Signal = require(Packages.Signal)

local TRACK_TOKENS = table.freeze { 'PlayerData' }

export type Replica = ReplicaClient.Replica

local ReplicaController = {
	OnReplicaLoaded = Signal.new() :: Signal.Signal<string, Replica>,
	Replicas = {} :: {[string]: Replica}
}

function ReplicaController.GetReplicaAsync(inputToken: string)
	return Promise.new(function(resolve, reject, onCancel)
		local exists = ReplicaController.Replicas[inputToken]
		if exists then return resolve(exists) end
		
		local connection: RBXScriptConnection
		connection = ReplicaController.OnReplicaLoaded:Connect(function(token, replica)
			if inputToken ~= token then return end
			connection:Disconnect()
			resolve(replica)
		end)
		
		onCancel(function()
			connection:Disconnect()
		end)
	end)
end

function ReplicaController.GetReplica(token: string)
	return ReplicaController.Replicas[token]
end

function ReplicaController.Init()
	ReplicaClient.RequestData()
	
	for _, token in TRACK_TOKENS do
		ReplicaClient.OnNew(token, function(replica)
			ReplicaController.Replicas[token] = replica
			ReplicaController.OnReplicaLoaded:Fire(token, replica)

			if RunService:IsStudio() then
				warn(replica.Token, replica.Data)
			end
		end)
	end
end

return ReplicaController
