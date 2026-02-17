--!strict
local ServerStorage = game:GetService("ServerStorage")

local Services = ServerStorage:WaitForChild("Services")
local ToolPath = ServerStorage.ServerAssets.Tools

local MarketService = require(Services.MarketService)

local PASS_NAME = "El Patron"
local EXCLUSIVE_TOOL = "Golden Deagle"

local module = {}

local function PlayerHasTool(player: Player, toolName: string): boolean
	local backpack = player:FindFirstChildOfClass("Backpack")
	if backpack and backpack:FindFirstChild(toolName) then
		return true
	end

	local character = player.Character
	if character and character:FindFirstChild(toolName) then
		return true
	end

	return false
end

local function GiveTool(player: Player, toolName: string): Instance?
	local template = ToolPath:FindFirstChild(toolName)
	if not template then
		return nil
	end

	if PlayerHasTool(player, toolName) then
		return nil
	end

	local backpack = player:FindFirstChildOfClass("Backpack") or player:WaitForChild("Backpack", 5)
	if not backpack then
		return nil
	end

	local new = template:Clone()
	new.Parent = backpack
	return new
end

function module:ApplyEffect(player: Player)
	GiveTool(player, EXCLUSIVE_TOOL)
end

MarketService.PurchasedPass:Connect(function(player: Player, fixedId: string, source: string?)
	if fixedId ~= PASS_NAME then return end
	if source == "sync" then return end
	module:ApplyEffect(player)
end)

return module
