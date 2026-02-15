
local ServerStorage = game:GetService('ServerStorage')
local Services = ServerStorage:WaitForChild("Services")

local Path = ServerStorage.ServerAssets.Tools
local MarketService = require(Services.MarketService)
local DataService = require(Services.DataService)

local module = {}

local function GiveTool(Player:Player, ToolName:string)
	local found = Path:FindFirstChild(ToolName)
	if not found then return 'Failed to find asset' end

	local new = found:Clone()
	new.Parent = Player.Backpack
	
	return new
end

function module:ApplyEffect(player:Player)
	--> GiveClokc
	GiveTool(player, "Glock")
	GiveTool(player, "C4")
	DataService.AdjustBalance(player, 75000)
	
	
end

MarketService.PurchasedPass:Connect(function(player:Player, FixedId)
	if FixedId ~= "Starterpack" then return end
	module:ApplyEffect(player)
end)

return module
