local ReplicatedStorage = game:GetService('ReplicatedStorage')
local ServerStorage = game:GetService('ServerStorage')

local ToolsPath = ServerStorage.ServerAssets.Tools

local Assets = ReplicatedStorage.Assets.Tools
local PurchasePromptTemplate = Assets.General.BasePurchasePrompt

local Data = ReplicatedStorage.Data
local ToolsData = require(Data.Tools)

local Packages = ReplicatedStorage.Packages
local Observer = require(Packages.Observers)
local Net = require(Packages.Net)

local NotifEvent = Net:RemoteEvent('Notification')

local Manager = {}

function Manager.AttemptEquip(player: Player, itemId: string): (boolean, string?)
	local char = player.Character
	if not char then return false, nil end
	
	local team = player.Team
	if not (team and team:HasTag('Federal')) then return false, 'FedTools/CivilianBlocked' end
	
	local equippedTool = char:FindFirstChildOfClass('Tool')
	if equippedTool and equippedTool.Name == itemId then return false, 'FedTools/AlreadyEquipped' end
	
	local inInventory = player.Backpack and player.Backpack:FindFirstChild(itemId) or nil
	if inInventory then return false, 'FedTools/AlreadyEquipped' end
	
	local template = ToolsPath:FindFirstChild(itemId)
	if not template then return false, 'FedTools/Unexpected' end

	local new = template:Clone()
		new.Parent = player.Backpack
	return true, 'FedTools/Purchased'
end

function Manager._HandleTool(item: Instance)
	if not item:IsA('Model') then return end

	local id = item.Name
	local itemData = ToolsData[id]
	if not itemData then return end

	local main = item.PrimaryPart or item:FindFirstChild('Main')
		or item:FindFirstChildOfClass('BasePart')
	if not main then return end

	local att = main:FindFirstChild('PromptAtt')
	local prompt = PurchasePromptTemplate:Clone()
		prompt.ActionText = `Equip {id}`
		prompt.ObjectText = `FREE!`
		prompt.HoldDuration = 0.4
		prompt.UIOffset = att and Vector2.new(0, 5) or Vector2.zero
		prompt.Parent = (att or main) :: any

	prompt.Triggered:Connect(function(who: Player)
		local success, res = Manager.AttemptEquip(who, id)
		if res ~= nil then NotifEvent:FireClient(who, res) end
	end)
end

function Manager.Init()
	Observer.observeTag('FederalTool', Manager._HandleTool)
end

return Manager
