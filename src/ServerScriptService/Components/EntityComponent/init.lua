-- Services
local ReplicatedStorage = game:GetService('ReplicatedStorage')
local Players = game:GetService('Players')
local ServerScriptService = game:GetService("ServerScriptService")

-- Variables

-- Dependencies
local GlobalConfiguration = require(ReplicatedStorage.DataModules.GlobalConfiguration)
local DataService = require(ReplicatedStorage.Utilities.DataService)
local StandHandler = require(ServerScriptService.Components.StandHandler)

local RaycastingParams = RaycastParams.new()
RaycastingParams.FilterType = Enum.RaycastFilterType.Include
RaycastingParams.FilterDescendantsInstances = {workspace.Map}

local Rarities = require(ReplicatedStorage.DataModules.Rarities)
local Format = require(ReplicatedStorage.Utilities.Format)
local Entities = require(ReplicatedStorage.DataModules.Entities)
local Signal = require(ReplicatedStorage.Utilities.Signal)

local EntityComponent = {}
EntityComponent.__index = EntityComponent

export type Entity = typeof(setmetatable({} :: {
	name: string,
	informations: {
		Model: Model,
		Rarity: string,
		DisplayName: string,
		MoneyPerSecond: number
	},
	model: Model,
	billboard: BillboardGui & {ClockTimer: Frame & {TextLabel: TextLabel, ImageLabel: ImageLabel}, NameLabel: TextLabel, RarityLabel: TextLabel, CashLabel: TextLabel},
	grabbed: Player,
	currentTime: number,
	timeConnection: RBXScriptConnection,
	claimed: boolean,
	proximity: ProximityPrompt,
	weld: {Instance},
	root: Part?,
	mutation: string,
	destroyedSignal: Signal.Signal,
	traits: {string},
	isPurchasable: boolean,
	robuxPrice: number?
}, {} :: typeof(EntityComponent)))

local Zone = require(ReplicatedStorage.Utilities.Zone)
local SharedUtilities = require(ReplicatedStorage.Utilities.SharedUtilities)
local RemoteBank = require(ReplicatedStorage.RemoteBank)
local SharedFunctions = require(ReplicatedStorage.DataModules.SharedFunctions)

local InventoryHandler = require("./InventoryHandler")
local MarketplaceHandler = require("./MarketplaceHandler")

local INFRONT_OFFSET = 2.3
local DISTANCE_BETWEEN = 5.5
local HEIGH_DISTANCE = 6

script.GrabAnimation.AnimationId = "rbxassetid://" .. GlobalConfiguration.GrabAnimationId

local Modifiers = {
	[1] = 0,
	[2] = 1,
	[3] = -1
}
local Lenght = #Modifiers

local GrabbedListPerPlayer = {}

function EntityComponent.IsCarrying(Player)
	local list = GrabbedListPerPlayer[Player]
	return list ~= nil and #list > 0
end

function EntityComponent.DropAll(Player, bool, HumanoidCFrame, force)
	if GrabbedListPerPlayer[Player] then
		print(Player, bool, HumanoidCFrame, force)
		
		RemoteBank.SendNotification:FireClient(Player, "You lost an entity 😡")

		GrabbedListPerPlayer[Player]:Drop(Player)
	end
	
	if bool then

		local char = Player.Character
		if not char then return end

		local Hrp: BasePart = char:FindFirstChild("HumanoidRootPart")
		if not Hrp then return end

		local ragdollFolder = char:FindFirstChild("ragdoll")
		if not ragdollFolder then return end

		local event: BindableFunction = ragdollFolder.functions.ragdoll
		event:Invoke(true, Vector3.new(0, 0, 0))

		local force = Instance.new("BodyVelocity")
		local direction = Vector3.new(0, 40, -70)
		force.Velocity = HumanoidCFrame:VectorToWorldSpace(direction)
		force.MaxForce = Vector3.new(math.huge, math.huge, math.huge)
		force.P = 10000
		force.Parent = Hrp

		task.delay(0.2, function()
			if force and force.Parent then
				force:Destroy()
			end
		end)

		task.delay(0.8, function()
			event:Invoke(false, Vector3.new(0, 0, 0))
		end)
	end
end

local function CreateWeldBetween(Part1, Part2, offset)
	return SharedUtilities.createWeld(Part1, Part2, offset)
end

function EntityComponent.ChangeAnchoredGroup(self: Entity, bool: boolean)
	for _, v in self.model:GetDescendants() do
		if v:IsA("BasePart") then
			v.Anchored = bool
			v.CanCollide = false
			v.Massless = true
		end
	end
end

function EntityComponent.InitializeProximityPrompt(self: Entity)
	local NewProximity = script.ProximityPrompt:Clone()

	if self.isPurchasable then
		NewProximity.ActionText = "Purchase"
		NewProximity.ObjectText = tostring(SharedUtilities.getProductPrice(self.productId, Enum.InfoType.Product))
	end

	NewProximity.Parent = self.root
	self.proximity = NewProximity
	return NewProximity.Triggered:Connect(function(player)
		if self.isPurchasable then
			self:_handlePurchaseAsync(player)
		else
			if not self.grabbed then
				self:Grab(player)
			end
		end
	end)
end

function EntityComponent._handlePurchaseAsync(self: Entity, player: Player)
	local signal = MarketplaceHandler.Purchase(player, false, self.productId)
	signal:Connect(function(purchased)
		if purchased then
			InventoryHandler.CacheTool(player, "Entity", {name = self.name, mutation = self.mutation, traits = self.traits}, true)
		end
	end)
end

function EntityComponent.RemoveFromPlayer(self: Entity, Player)
	GrabbedListPerPlayer[Player] = nil
end

function EntityComponent.InitializeBillboardSetup(self: Entity)
	self.billboard.Parent = self.root
	
	self.billboard.CashLabel.Visible = true
	self.billboard.CashLabel.Text = SharedFunctions.GetEarningsPerSecond(self.name, self.mutation) .. "$/s"

	if not self.isPurchasable then
		self.timeConnection = task.spawn(function()
			while task.wait(1) do
				if self.claimed then break end

				if not self.grabbed then
					self.currentTime -= 1
				end

				self.billboard.ClockTimer.Visible = if self.grabbed then false else true
				self.billboard.ClockTimer.TextLabel.Text = tostring(self.currentTime) .. "s"

				if self.currentTime == 0 then
					self:Destroy()
					break
				end
			end
		end)
	else
		self.billboard.ClockTimer.Visible = false
	end
end

function EntityComponent.Grab(self: Entity, Player: Player)
	if self.isPurchasable then return end

	local GrabInformations = GrabbedListPerPlayer[Player]
	if GrabInformations then return end

	if not Player.Character then return end
	if Player.Character:FindFirstChildOfClass("Humanoid").Health <= 0 then return end

	local OwnedBases = DataService.server:get(Player, "bases")
	local Owns = table.find(OwnedBases, self.BaseNumber)

	if not Owns then RemoteBank.SendNotification:FireClient(Player, "You don't own this base 😡!") return end

	RemoteBank.SendNotification:FireClient(Player, "You stealing a " .. self.name .. "! 🤫")

	Player:SetAttribute("Carrying", self.BaseNumber)
	self.proximity.Enabled = false
	self.grabbed = Player

	RemoteBank.GotEntity:FireClient(Player)

	local XOffset = INFRONT_OFFSET

	if Player.Character then
		local Animator: Animator = Player.Character:FindFirstChildOfClass("Humanoid"):FindFirstChildOfClass("Animator")
		local Loaded = Animator:LoadAnimation(script.GrabAnimation)
		Loaded:Play()
	end

	local PlayerChar = Player.Character
	if PlayerChar then
		local Humanoid = PlayerChar:FindFirstChildOfClass("Humanoid")
		if Humanoid and Humanoid.Health >= 0 then
			local HumanoidRootPart = PlayerChar:FindFirstChild("HumanoidRootPart")

			self:ChangeAnchoredGroup(false)

			local attachment0 = Instance.new("Attachment")
			attachment0.Parent = HumanoidRootPart
			attachment0.CFrame = CFrame.new(0, 0, -XOffset)

			local attachment1 = Instance.new("Attachment")
			attachment1.Parent = self.root

			self.root.CFrame = HumanoidRootPart.CFrame * attachment0.CFrame

			local rigidConstraint = Instance.new("RigidConstraint")
			rigidConstraint.Attachment0 = attachment0
			rigidConstraint.Attachment1 = attachment1
			rigidConstraint.Parent = self.root

			self.weld = {attachment0, attachment1, rigidConstraint}

			GrabbedListPerPlayer[Player] = self
		end
	end
end


function EntityComponent.StopAllAnimations(player: Player)
	local character = player.Character
	if not character then return end

	local humanoid = character:FindFirstChildOfClass("Humanoid")
	if not humanoid then return end

	local animator = humanoid:FindFirstChildOfClass("Animator")
	if not animator then return end

	for _, track in animator:GetPlayingAnimationTracks() do
		track:Stop()
	end
end

function EntityComponent.Claim(self: Entity, Player: Player)
	if self.isPurchasable then return end

	RemoteBank.SendNotification:FireClient(Player, "You stole " .. self.name .. "! 😈")
	Player:SetAttribute("Carrying", false)
	self:RemoveFromPlayer(Player)
	InventoryHandler.CacheTool(Player, "Entity", {name = self.name, mutation = self.mutation, traits = self.traits}, true)
	EntityComponent.StopAllAnimations(Player)
	self:Destroy()
end

function EntityComponent.Drop(self: Entity, Player)
	if self.isPurchasable then return end

	if self.weld then for _, v in self.weld do v:Destroy() end end 
	self.grabbed = false

	if Player then
		Player:SetAttribute("Carrying", false)
		self:RemoveFromPlayer(Player)
	end

	self:ChangeAnchoredGroup(true)

	if self.proximity then
		self.proximity.Enabled = true
	end

	self.grabbed = false
	self.model:PivotTo(self.SpawnCFrame * CFrame.new(0, self.model:GetExtentsSize().Y / 2, 0))
end

function EntityComponent.Destroy(self: Entity, dontsendSignal)
	if self.isPurchasable then return end

	self.claimed = true
	if not dontsendSignal then
		self.destroyedSignal:Fire()
	end
	self.destroyedSignal:Destroy()
	self.model:Destroy()
	self.proximityConnection:Disconnect()
	if self.billboard then
		self.billboard:Destroy()
	end
end

function EntityComponent.SpawnEntity(EntityName, SpawnCFrame: CFrame, BaseNumber, isPurchasable, productId): Entity
	if not EntityName then return end
	local randomMutation = SharedFunctions.GetRandomMutation()
	local RandomTraits = {}
	local EntityInformations = Entities[EntityName]

	if not isPurchasable then
		if EntityInformations.Rarity == "Mythical" then
			RemoteBank.SendNotification:FireAllClients("Mythical has spawned!", "Rainbow")
			RemoteBank.PlaySound:FireAllClients("Alert")
		elseif EntityInformations.Rarity == "Secret" then
			RemoteBank.SendNotification:FireAllClients("Secret has spawned!")
			RemoteBank.PlaySound:FireAllClients("Alert")
		elseif EntityInformations.Rarity == "Godly" then
			RemoteBank.SendNotification:FireAllClients("Godly has spawned!", "Godly")
			RemoteBank.PlaySound:FireAllClients("Alert")
		end
	end

	local self : Entity = setmetatable({
		BaseNumber = BaseNumber,
		name = EntityName,
		informations = EntityInformations,
		mutation = randomMutation,
		model = SharedFunctions.CreateEntity(EntityName, randomMutation, nil, false, nil, RandomTraits),
		billboard = SharedFunctions.CreateBillboard(EntityName, randomMutation, nil, nil, true, RandomTraits),
		currentTime = if isPurchasable then 0 else math.random(60, 150),
		traits = RandomTraits,
		destroyedSignal = Signal.new(),
		SpawnCFrame = SpawnCFrame,
		isPurchasable = isPurchasable or false,
		productId = productId
	}, EntityComponent)

	self.model:SetAttribute("BaseNumber", BaseNumber)
	self.model.Parent = workspace.EntitiesFolder

	self.root = self.model.PrimaryPart or self.model:FindFirstChild("HumanoidRootPart")
	if not self.root then self.model:Destroy() warn("No root has been found in the entity") return end

	self:InitializeBillboardSetup()
	local connection = self:InitializeProximityPrompt()
	self.proximityConnection = connection

	if not isPurchasable then
		self:Drop()
	else
		self:ChangeAnchoredGroup(true)
		self.model:PivotTo(SpawnCFrame * CFrame.new(0, self.model:GetExtentsSize().Y / 2, 0))
	end

	return self
end

function EntityComponent.OnCharAdded(player, char)
	local humanoid = char:WaitForChild("Humanoid")
	humanoid.Died:Connect(function()
		if GrabbedListPerPlayer[player] then
			GrabbedListPerPlayer:Drop()
		end
	end)
end

function EntityComponent.PlayerAdded(player: Player)
	if player.Character then
		EntityComponent.OnCharAdded(player, player.Character)
	end
	player.CharacterAdded:Connect(function(char)
		EntityComponent.OnCharAdded(player, char)
	end)
end

function EntityComponent.Initialize()
	for _, v in Players:GetPlayers() do
		EntityComponent.PlayerAdded(v)
	end
	Players.PlayerAdded:Connect(EntityComponent.PlayerAdded)

	RemoteBank.DropEntity.OnServerInvoke = function(...)
		EntityComponent.DropAll(...)
	end

	SharedUtilities.attachToTouchEvents(GlobalConfiguration.ClaimArea, function(player, char)
		if GrabbedListPerPlayer[player] then
			GrabbedListPerPlayer[player]:Claim(player)
		end
	end, 1)

end

return EntityComponent