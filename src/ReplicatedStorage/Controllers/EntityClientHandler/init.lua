local ReplicatedStorage = game:GetService('ReplicatedStorage')
local Players = game:GetService('Players')
local TweenService = game:GetService('TweenService')

local EntityData = require(ReplicatedStorage.DataModules.EntityData)
local Rarities = require(ReplicatedStorage.DataModules.Rarities)

local BoundingBoxCache = game.Workspace:WaitForChild("BoundingBoxCache")
local EntitySpawnsFolder = game.Workspace.EntitySpawns

local CoreNotification = require("./CoreNotification")
local NewFoundScreen = require("./NewFoundComponent")
local Signal = require(ReplicatedStorage.Utilities.Signal)

local EntityCache = {}
local EntityClientHandler = {
	NewEntityGenerated = Signal.new()
}

local Debounces = {}

function EntityClientHandler.ShowEntityFoundScreen(EntityName: string)
	NewFoundScreen.QueueAnimation(EntityName)
end

function EntityClientHandler.GiveEntity(EntityName: string)
	local Success = ReplicatedStorage.Communication.Functions.GiveEntity:InvokeServer(EntityName)
	if Success then
		EntityClientHandler.ShowEntityFoundScreen(EntityName); CoreNotification.SendNotification(EntityName, true)
	else
		CoreNotification.SendNotification(EntityName, false)
	end
end

function EntityClientHandler.ChangeVisibility(EntityName: string, Boolean: boolean)
	for _, v: BillboardGui in pairs(EntityCache) do
		if v.Name == EntityName then
			v.Enabled = Boolean
		end
	end
end

function EntityClientHandler.SpawnEntity(EntityName: string, SpawnPosition: CFrame, ReachPosition: CFrame?, TweenTime: number?)
	local Informations = EntityData[EntityName]
	if Informations then
		local BillboardGui = script.EntityBillboard:Clone()
		local ImageString = Informations.Image
		local Size: Vector3 = Informations.Size or Vector3.new(5, 5, 5)

		local NewPart = Instance.new("Part")
		NewPart.CFrame = SpawnPosition
		NewPart.Size = Size
		NewPart.CanCollide = false
		NewPart.Anchored = true
		NewPart.Transparency = 1
		NewPart.Parent = BoundingBoxCache

		BillboardGui.ImageLabel.Image = ImageString

		local RarityName = Informations.Rarity or "Common"
		local RarityInfo = Rarities[RarityName]
		local RarityName = Informations.Rarity or "Common"
		local RarityInfo = Rarities[RarityName]

		local rarityAttachment = BillboardGui:WaitForChild("RarityAttachment")
		local rarityBillboard = rarityAttachment:WaitForChild("BillboardGui")
		local rarityTextLabel = rarityBillboard:WaitForChild("RarityText")

		rarityTextLabel.Text = RarityName

		if RarityInfo and RarityInfo.Gradient then
			RarityInfo.Gradient:Clone().Parent = rarityTextLabel
		end


		BillboardGui.Size = UDim2.new(Size.X, 0, Size.Y, 0)
		BillboardGui.Parent = NewPart
		BillboardGui.Name = EntityName
		NewPart.Touched:Connect(function(element)
			if element.Parent then
				local player = Players:GetPlayerFromCharacter(element.Parent)
				if not player or player ~= Players.LocalPlayer then return end
				if Debounces[player] then return end
				Debounces[player] = true
				EntityClientHandler.GiveEntity(EntityName)
				task.delay(0.4, function()
					Debounces[player] = false
				end)
			end
		end)

		table.insert(EntityCache, BillboardGui)
		EntityClientHandler.NewEntityGenerated:Fire(EntityName, function()
			BillboardGui.Enabled = false
		end)

		if ReachPosition then
			local tween = TweenService:Create(NewPart, TweenInfo.new(TweenTime or 1, Enum.EasingStyle.Linear), {CFrame = ReachPosition})
			tween:Play()
			tween.Completed:Connect(function()
				NewPart:Destroy()
				tween:Destroy()
			end)
		end

		return function()
			NewPart:Destroy()
		end
	end
end

function EntityClientHandler.Initialize()
	task.wait(2)
	for _, entitySpawn in EntitySpawnsFolder:GetChildren() do
		EntityClientHandler.SpawnEntity(entitySpawn.Name, entitySpawn.CFrame)
	end

	ReplicatedStorage.Communication.Functions.GiveEntity.OnClientInvoke = function(entityName)
		EntityClientHandler.ShowEntityFoundScreen(entityName)
	end
end

return EntityClientHandler