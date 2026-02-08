-- Services
local ReplicatedStorage = game:GetService('ReplicatedStorage')
local Players = game:GetService('Players')

-- Variables

-- Dependencies
local DataService = require(ReplicatedStorage.Utilities.DataService)
local Bases = require(ReplicatedStorage.DataModules.Bases)
local SharedFunctions = require(ReplicatedStorage.DataModules.SharedFunctions)
local LuckyBoxes = require(ReplicatedStorage.DataModules.LuckyBoxes)
local Format = require(ReplicatedStorage.Utilities.Format)

local GlobalConfiguration = require(ReplicatedStorage.DataModules.GlobalConfiguration)
local SharedUtilities = require(ReplicatedStorage.Utilities.SharedUtilities)

local DevProducts = require(ReplicatedStorage.DataModules.DevProducts)

local MarketplaceHandler = require("./MarketplaceHandler")
local EntityHandler = require("./EntityComponent")

local BaseTemplate = workspace.TemplateBase
BaseTemplate.Parent = ReplicatedStorage

type Base = typeof(workspace.TemplateBase) 

local RemoteBank = require(ReplicatedStorage.RemoteBank)

local BasesHandler = {}
local SpawnedBases = {}

function BasesHandler._getAvailableStandNumber(baseNumber, excludeStands)
	local baseInformations = SpawnedBases[baseNumber]
	if not baseInformations then return nil end

	local occupiedStands = {}

	for standNumber, _ in pairs(excludeStands) do
		occupiedStands[standNumber] = true
	end

	local availableStands = {}
	for i = 1, GlobalConfiguration.AmountOfStandsPerBase do
		if not occupiedStands[i] then
			table.insert(availableStands, i)
		end
	end

	if #availableStands == 0 then
		return nil
	end

	return availableStands[math.random(1, #availableStands)]
end

function BasesHandler.SpawnEntityOnStand(baseNumber, standNumber, forceRemove, entityName)
	local baseInformations = SpawnedBases[baseNumber]
	if baseInformations then
		if baseInformations.RobuxStands[standNumber] then
			return
		end

		local standInformations = baseInformations.Stands[standNumber] 
		if standInformations then
			if forceRemove then
				standInformations:Destroy(true)
			else
				return
			end
		end

		local BaseInformations = Bases[baseNumber]
		local NewEntityRandom = entityName
			or LuckyBoxes.GetRandomLuckyBoxForBase()
			or SharedFunctions.GetRandomEntity(BaseInformations.Percentages)
		local BaseModel: Base = baseInformations.BaseModel

		if NewEntityRandom then
			local StandInBase = BaseModel.Stands:FindFirstChild(standNumber)
			if StandInBase then
				local SpawnPoint = StandInBase:FindFirstChild("SpawnPoint")
				if not SpawnPoint then
					return
				end

				local NewEntity = EntityHandler.SpawnEntity(NewEntityRandom, SpawnPoint.CFrame, baseNumber)
				if not NewEntity then
					return
				end

				baseInformations.Stands[standNumber] = NewEntity
				NewEntity.destroyedSignal:Connect(function()
					baseInformations.Stands[standNumber] = nil

					BasesHandler.SpawnEntityOnStand(baseNumber, standNumber)
				end)
			end
		end
	end
end

function BasesHandler._spawnRobuxPurchasablesAsync(baseNumber)
	local baseInformations = SpawnedBases[baseNumber]
	if not baseInformations then return end

	local BaseSchema = Bases[baseNumber]
	if not BaseSchema or not BaseSchema.RobuxPurchasables then return end

	local BaseModel: Base = baseInformations.BaseModel

	for _, purchasableData in BaseSchema.RobuxPurchasables do
		local standNumber = BasesHandler._getAvailableStandNumber(baseNumber, baseInformations.RobuxStands)

		if standNumber then
			local StandInBase = BaseModel.Stands:FindFirstChild(standNumber)
			if StandInBase then
				local SpawnPoint = StandInBase:FindFirstChild("SpawnPoint")
				if not SpawnPoint then
					continue
				end

				local NewEntity = EntityHandler.SpawnEntity(
					purchasableData.EntityName, 
					SpawnPoint.CFrame, 
					baseNumber,
					true,
					purchasableData.PurchaseId
				)

				if NewEntity then
					baseInformations.RobuxStands[standNumber] = NewEntity
				end
			end
		end
	end
end

function BasesHandler.CreateNewBase(baseNumber: number, spawnCFrame: CFrame)
	local NewBaseTemplate = BaseTemplate:Clone()
	NewBaseTemplate.Parent = workspace.Map.Bases

	NewBaseTemplate:PivotTo(spawnCFrame)
	local BaseInformations = Bases[baseNumber]
	if BaseInformations then
		SpawnedBases[baseNumber] = {
			BaseModel = NewBaseTemplate,
			Stands = {},
			RobuxStands = {}
		}
		NewBaseTemplate.Name = baseNumber
		NewBaseTemplate.Sign.Main.SurfaceGui.TextLabel.Text = BaseInformations.LuckAmount .. "x Luck"
		NewBaseTemplate.Button.Main.Attachment.BillboardGui.PriceLabel.Text = "$" .. Format.abbreviateCash(BaseInformations.BasePrice)
		NewBaseTemplate.SignOnTop.SurfaceGui.TextLabel.Text = BaseInformations.BaseName

		for _, v in NewBaseTemplate.Buttons:GetChildren() do
			local TouchPart = v:FindFirstChild("TouchPart")

			task.delay(1, function()
				TouchPart.Attachment.BillboardGui.PriceLabel.Text = SharedUtilities.getProductPrice(v:GetAttribute("Id"), Enum.InfoType.Product) .. ""
			end)

			SharedUtilities.attachToTouchEvents(TouchPart, function(player, char)
				local Signal = MarketplaceHandler.Purchase(player, false, v:GetAttribute("Id"))
				Signal:Connect(function(purchased)
					if purchased then
						local newStandNumber = BasesHandler._getAvailableStandNumber(baseNumber, SpawnedBases[baseNumber].RobuxStands)
						if newStandNumber then
							local entity = SharedFunctions.GetRandomEntity({[v:GetAttribute("Rarity")] = 100})
							BasesHandler.SpawnEntityOnStand(baseNumber, newStandNumber, true, entity)
						end
					end
				end)
			end, 1)
		end

		BasesHandler._spawnRobuxPurchasablesAsync(baseNumber)

		for _, v in NewBaseTemplate.Stands:GetChildren() do
			local standNum = tonumber(v.Name)
			if not SpawnedBases[baseNumber].RobuxStands[standNum] then
				BasesHandler.SpawnEntityOnStand(baseNumber, standNum, false)
			end
		end
	end
end

function BasesHandler:Initialize()
	RemoteBank.TryPurchaseBase.OnServerInvoke = function(plr, baseNumber)
		local baseInformations = Bases[baseNumber]
		if baseInformations then
			local basesOwned = DataService.server:get(plr, "bases")
			if table.find(basesOwned, baseNumber) then
				RemoteBank.SendNotification:FireClient(plr, "Already purchased base ( how did you get here? )")
				return
			else 
				local purchased = false
				DataService.server:update(plr, "cash", function(old)
					if old >= baseInformations.BasePrice then
						RemoteBank.SendNotification:FireClient(plr, "Purchased base", Color3.new(0.45098, 1, 0))

						DataService.server:arrayInsert(plr, "bases", baseNumber)

						return old - baseInformations.BasePrice
					else
						RemoteBank.SendNotification:FireClient(plr, "You don't have enough to purchase.", Color3.new(1, 0.180392, 0.180392))
					end

					return old
				end)
			end
		end
	end

	task.spawn(function()
		while task.wait(1) do
			local currentTime = os.time()
			local timeSinceLastEvent = currentTime % GlobalConfiguration.MythicalSpawnAmount
			local timeRemaining = GlobalConfiguration.MythicalSpawnAmount - timeSinceLastEvent

			if timeRemaining <= 1 then
				local RandomBase = math.random(1, #Bases)
				local standNumber = BasesHandler._getAvailableStandNumber(RandomBase, SpawnedBases[RandomBase].RobuxStands)
				if standNumber then
					BasesHandler.SpawnEntityOnStand(RandomBase, standNumber, true, SharedFunctions.GetRandomEntity({["Mythical"] = 100}))
				end
			end
		end
	end)

	task.spawn(function()
		while task.wait(1) do
			local currentTime = os.time()
			local timeSinceLastEvent = currentTime % GlobalConfiguration.SecretSpawnAmount
			local timeRemaining = GlobalConfiguration.SecretSpawnAmount - timeSinceLastEvent

			if timeRemaining <= 1 then
				local RandomBase = math.random(1, #Bases)
				local standNumber = BasesHandler._getAvailableStandNumber(RandomBase, SpawnedBases[RandomBase].RobuxStands)
				if standNumber then
					BasesHandler.SpawnEntityOnStand(RandomBase, standNumber, true, SharedFunctions.GetRandomEntity({["Secret"] = 100}))
				end
			end
		end
	end)

	task.spawn(function()
		while task.wait(1) do
			local currentTime = os.time()
			local timeSinceLastEvent = currentTime % GlobalConfiguration.GodlySpawnAmount
			local timeRemaining = GlobalConfiguration.GodlySpawnAmount - timeSinceLastEvent

			if timeRemaining <= 1 then
				local RandomBase = math.random(1, #Bases)
				local standNumber = BasesHandler._getAvailableStandNumber(RandomBase, SpawnedBases[RandomBase].RobuxStands)
				if standNumber then
					BasesHandler.SpawnEntityOnStand(RandomBase, standNumber, true, SharedFunctions.GetRandomEntity({["Godly"] = 100}))
				end
			end
		end
	end)

	for baseNumber, _ in Bases do
		local spawnCFrameAttachment: Attachment = workspace.Map.BasesSpawn:FindFirstChild(baseNumber)
		if spawnCFrameAttachment then
			BasesHandler.CreateNewBase(baseNumber, spawnCFrameAttachment.WorldCFrame)
		end
	end
end

return BasesHandler