
-- Services
local ReplicatedStorage = game:GetService('ReplicatedStorage')
local ServerScriptService = game:GetService("ServerScriptService")
local ServerStorage = game:GetService('ServerStorage')
local Players = game:GetService('Players')

-- Variables
local Http = game:GetService('HttpService')

-- Dependencies
local DataService = require(ReplicatedStorage.Utilities.DataService)

local SignalBank = require(ServerStorage.SignalBank)
local SharedUtilities = require(ReplicatedStorage.Utilities.SharedUtilities)
local RemoteBank = require(ReplicatedStorage.RemoteBank)

local GamepassHandler = require(ServerScriptService.Components.GamepassHandler)

local GearsHandler = require("./GearsHandler")

export type Tag = "Entity" | "Luckybox" | "Luckyblock"

local InventoryHandler = {}
local ModulesRequired = {}

local OneSessionTools = {}

local function resolveTag(tag: any)
	if typeof(tag) ~= "string" then
		return nil
	end

	local lowerTag = string.lower(tag)
	if lowerTag == "luckyblock" or lowerTag == "luckybox" then
		return "Luckybox"
	end
	if lowerTag == "entity" then
		return "Entity"
	end

	return tag
end

local function getToolFactory(tag: string)
	local moduleFactory = ModulesRequired[tag]
	if moduleFactory then
		return moduleFactory
	end

	if tag == "Luckybox" then
		return ModulesRequired.Entity
	end

	return nil
end

-- Initialization function for the script
function InventoryHandler:Initialize()																																																																																																											
	for _, v in script:GetChildren() do
		if v:IsA('ModuleScript') then
			ModulesRequired[v.Name] = require(v)
		end
	end

	for _, v in Players:GetPlayers() do
		InventoryHandler.OnPlayerAdded(v)
	end

	Players.PlayerAdded:Connect(function(player)
		InventoryHandler.OnPlayerAdded(player)
	end)
end

function InventoryHandler.CacheIndexObject(player, informations)
	local indexInformations = DataService.server:get(player, "index")
	if not indexInformations[informations.mutation] then
		DataService.server:set(player, {"index", informations.mutation}, {})
	end

	if not table.find(indexInformations[informations.mutation], informations.name) then
		DataService.server:arrayInsert(player, {"index", informations.mutation}, informations.name)
	end
end

function InventoryHandler.CreateNewTool(Player: Player, Tag: string, guid, informations: {})
	Tag = resolveTag(Tag)
	if not Tag then
		return
	end

	local factory = getToolFactory(Tag)
	if not factory then
		warn("The tag provided could not be found in the module scripts | " .. tostring(Tag))
		return
	end

	local success, errormsg: Tool = pcall(function()
		return factory(informations, guid)
	end)

	if not success then
		warn("The tag provided could not be found in the module scripts | " .. errormsg)
	else
		if errormsg then
			errormsg:AddTag(Tag)
			errormsg.Parent = Player.Backpack
		end
	end
end

function InventoryHandler.CacheTool(player: Player, Tag: string, informations: {})
	Tag = resolveTag(Tag)
	if not Tag then
		return
	end
	local RandomizedId = Http:GenerateGUID()
	DataService.server:set(player, {"inventory", RandomizedId}, {tag = Tag, informations = informations})

	if Tag == "Entity" then
		InventoryHandler.CacheIndexObject(player, informations)
	end

	if player.Character then
		InventoryHandler.CreateNewTool(player, Tag, RandomizedId,  informations)
	end
end

function InventoryHandler.AddOneSessionTool(player: Player, tool: Tool)
	if not OneSessionTools[player] then
		OneSessionTools[player] = {}
	end

	table.insert(OneSessionTools[player], tool:Clone())
	RemoteBank.ToolsAdded:FireClient(player)
end

function InventoryHandler.AddToolsAndClear(player: Player, doNotDestroy: boolean)
	if not doNotDestroy then
		local tools = SharedUtilities.getToolsForBackpackAndEquipped(player)
		for _, v in tools do
			if v:IsA("Tool") then
				v:Destroy()
			end
		end
	end

	local ownedGears = DataService.server:get(player, "gears")
	for _, v in ownedGears do
		GearsHandler.CreateNewGear(player, v)
	end

	if OneSessionTools[player] then
		for _, v in OneSessionTools[player] do
			local newTool = v:Clone()
			newTool.Parent = player.Backpack
		end
	end

	for id, data in DataService.server:get(player, "inventory") do
		if typeof(data) == "table" then
			if data.tag then
				InventoryHandler.CreateNewTool(player, data.tag, id, data.informations)
			end
		end
	end

	GamepassHandler.AddVipTools(player)
end

function InventoryHandler.CharacterAdded(player: Player, char: Model)
	InventoryHandler.AddToolsAndClear(player, true)
end

function InventoryHandler.RemoveTool(player: Player, tool)
	if tool:IsA("Tool") then
		local id = tool:GetAttribute("Id")
		if id then
			local informations = DataService.server:get(player, {"inventory", id})
			DataService.server:set(player, {"inventory", id}, nil, true)
			tool:Destroy()
			return informations.informations
		end
	end
end

function InventoryHandler.OnPlayerAdded(player: Player)
	DataService.server:waitForData(player)
	if player.Character then
		InventoryHandler.CharacterAdded(player, player.Character)
	end

	player.CharacterAdded:Connect(function(char)
		InventoryHandler.CharacterAdded(player, char)
	end)
end

return InventoryHandler