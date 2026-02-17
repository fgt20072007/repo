local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local CollectionService = game:GetService("CollectionService")
local Workspace = game:GetService("Workspace")
local ServerStorage = game:GetService 'ServerStorage'
local Debris = game:GetService("Debris")

local Packages = ReplicatedStorage:WaitForChild("Packages")
local Observers = require(Packages:WaitForChild("Observers"))


local Net = require(ReplicatedStorage.Packages.Net)
local Notification = Net:RemoteEvent("Notification")

local GeneralData = require(ReplicatedStorage.Data.General)
local RankingService = require(ServerStorage.Services.RankingService) 
local AntiTeleport = require(ServerStorage.Services.AntiCheatService.AntiTeleport)

local ArrestService = {}

type DetainState = {
	executor: Player,
	prompt: ProximityPrompt?,
	humanoid: Humanoid,
	targetTorso: BasePart,
	weld: WeldConstraint,
	originalMassless: {[BasePart]: boolean},
	originalAutoRotate: boolean,
	connections: {RBXScriptConnection},
}


local detainedPlayers: {[Player]: DetainState} = {}
local cantArrestParts: {[BasePart]: boolean} = {}

local function registerCantArrestPart(part: BasePart)
	part.Transparency = 1
	cantArrestParts[part] = true
end

local function initCantArrestFolder()
	local folder = Workspace:FindFirstChild("CantArrestHere")
	if not folder then return end

	for _, descendant in ipairs(folder:GetDescendants()) do
		if descendant:IsA("BasePart") then
			registerCantArrestPart(descendant)
		end
	end

	folder.DescendantAdded:Connect(function(descendant)
		if not descendant:IsA("BasePart") then return end
		registerCantArrestPart(descendant)
	end)

	folder.DescendantRemoving:Connect(function(descendant)
		if not descendant:IsA("BasePart") then return end
		cantArrestParts[descendant] = nil
	end)
end

local function getPlayerState(player: Player, attribute: string)
	if not player then
		return nil
	end

	return player:GetAttribute(attribute)
end

local function resolvePromptOwner(prompt: ProximityPrompt): (Player?, Model?)
	local current = prompt.Parent
	while current do
		if current:IsA("Model") then
			local owner = Players:GetPlayerFromCharacter(current)
			if owner then
				return owner, current
			end
		end
		current = current.Parent
	end

	return nil, nil
end

local function findTorso(character: Model): BasePart?
	if not character then
		return nil
	end

	local torso = character:FindFirstChild("UpperTorso") or character:FindFirstChild("Torso")
	return torso :: BasePart?
end

local function isPointInsidePart(part: BasePart, point: Vector3): boolean
	if not part or not part.Parent then return false end

	local localPoint = part.CFrame:PointToObjectSpace(point)
	local halfSize = part.Size * 0.5
	local epsilon = math.max(0.01, math.min(0.1, halfSize.Magnitude * 0.001))

	if math.abs(localPoint.X) > halfSize.X + epsilon then return false end
	if math.abs(localPoint.Y) > halfSize.Y + epsilon then return false end
	if math.abs(localPoint.Z) > halfSize.Z + epsilon then return false end
	return true
end

local function isInCantArrestZone(target: Player): boolean
	local character = target.Character
	if not character then return false end
	local root = character:FindFirstChild("HumanoidRootPart") or findTorso(character)
	if not root then return false end
	local position = root.Position

	for part in pairs(cantArrestParts) do
		if not part or not part.Parent then
			cantArrestParts[part] = nil
		else
			if isPointInsidePart(part, position) then return true end
		end
	end

	return false
end

local function playerHasCuffs(player: Player): boolean
	if not player then
		return false
	end

	local backpack = player:FindFirstChildOfClass("Backpack") or player:FindFirstChild("Backpack")
	if backpack and backpack:FindFirstChild("Cuffs") then
		return true
	end

	local character = player.Character
	if character and character:FindFirstChild("Cuffs") then
		return true
	end

	return false
end

local function playerIsFederal(player: Player): boolean
	local team = player and player.Team
	if not team then
		return false
	end

	return team:HasTag("Federal")
end

local function disconnectConnections(connections: {RBXScriptConnection})
	for _, connection in ipairs(connections) do
		connection:Disconnect()
	end
	table.clear(connections)
end

function ArrestService:IsPlayerDetained(player: Player): boolean
	return detainedPlayers[player] ~= nil
end

function ArrestService:ReleasePlayer(target: Player, _reason: string?)
	local state = detainedPlayers[target]
	if not state then return false, "NotDetained" end

	if state.weld then state.weld:Destroy() end

	if state.targetTorso and state.targetTorso.Parent then
		state.targetTorso:SetNetworkOwner(target)
	end

	local humanoid = state.humanoid
	if humanoid and humanoid.Parent then
		humanoid.PlatformStand = false
		humanoid.AutoRotate = state.originalAutoRotate
	end

	for part, massless in pairs(state.originalMassless) do
		if part and part.Parent then
			part.Massless = massless
		end
	end

	if state.prompt and state.prompt.Parent then
		state.prompt.ActionText = "Detain"
	end

	disconnectConnections(state.connections)

	if target and target.Parent then
		target:SetAttribute("Detained", "Not Detained")
	end

	detainedPlayers[target] = nil

	target:SetAttribute("DetainedBy", nil)

	return true
end

function ArrestService:SetPlayerDetained(target: Player, executor: Player, prompt: ProximityPrompt?)
	if not (target and executor) then return false, "MissingPlayer" end
	if target == executor then return false, "SelfDetain" end
	if getPlayerState(target, "Detained") == "Arrested" then return false, "AlreadyArrested" end
	if detainedPlayers[target] and detainedPlayers[target].executor ~= executor then return false, "AlreadyDetainedByOther" end
	if isInCantArrestZone(target) then Notification:FireClient(executor, "Arrest/CantArrestHere"); return false, "CantArrestHere" end
	local revision = getPlayerState(target, "Revision")
	if not (revision == "Wanted" or revision == "Hostile") then Notification:FireClient(executor, "Arrest/Fail"); return false, "Not Wanted" end

	local targetCharacter = target.Character
	local targetHumanoid = targetCharacter and targetCharacter:FindFirstChildOfClass("Humanoid")
	if not targetHumanoid then return false, "TargetMissingHumanoid" end

	if targetHumanoid.Sit and targetHumanoid.SeatPart then
		local seatWeld = targetHumanoid.SeatPart:FindFirstChild("SeatWeld")
		if seatWeld then seatWeld:Destroy() end
		targetHumanoid.Sit = false
		task.wait(0.1)
	end

	local targetTorso = findTorso(targetCharacter)
	if not targetTorso then return false, "TargetMissingTorso" end

	local executorCharacter = executor.Character
	local executorTargetPart = executorCharacter and executorCharacter:FindFirstChild("HumanoidRootPart")
	if not executorTargetPart then return false, "ExecutorMissingTorso" end

	local executorHumanoid = executorCharacter:FindFirstChildOfClass("Humanoid")
	if detainedPlayers[target] then self:ReleasePlayer(target, "ReDetained") end

	targetHumanoid:UnequipTools()

	local state: DetainState = {
		executor = executor,
		prompt = prompt,
		humanoid = targetHumanoid,
		targetTorso = targetTorso,
		weld = nil :: any,
		originalMassless = {},
		originalAutoRotate = targetHumanoid.AutoRotate,
		connections = {},
	}

	for _, descendant in ipairs(targetCharacter:GetDescendants()) do
		if descendant:IsA("BasePart") then
			state.originalMassless[descendant] = descendant.Massless
			descendant.Massless = true
		end
	end

	targetHumanoid.PlatformStand = true
	targetHumanoid.AutoRotate = false

	targetTorso:SetNetworkOwner(executor)
	targetTorso.CFrame = executorTargetPart.CFrame * CFrame.new(0, 0, -5)

	local weld = Instance.new("WeldConstraint")
	weld.Name = "ArrestWeld"
	weld.Part0 = executorTargetPart
	weld.Part1 = targetTorso
	weld.Parent = targetTorso
	state.weld = weld

	local function track(connection: RBXScriptConnection?)
		if connection then
			table.insert(state.connections, connection)
		end
	end

	track(target.CharacterRemoving:Connect(function()
		ArrestService:ReleasePlayer(target, "TargetRespawn")
	end))

	track(targetHumanoid.Died:Connect(function()
		ArrestService:ReleasePlayer(target, "TargetDied")
	end))

	track(executor.CharacterRemoving:Connect(function()
		ArrestService:ReleasePlayer(target, "ExecutorRespawn")
	end))

	if executorHumanoid then
		track(executorHumanoid.Died:Connect(function()
			ArrestService:ReleasePlayer(target, "ExecutorDied")
		end))
	end

	if prompt then
		track(prompt.Destroying:Connect(function()
			ArrestService:ReleasePlayer(target, "PromptDestroyed")
		end))
		prompt.ActionText = "Release"
	end

	detainedPlayers[target] = state

	target:SetAttribute("Detained", "Detained")
	target:SetAttribute("DetainedBy", executor.Name)

	return true
end

local function unequipAndDestroyTools(player: Player)
	local character = player.Character
	if not character then return end

	local humanoid = character:FindFirstChildOfClass("Humanoid")
	if humanoid then humanoid:UnequipTools() end

	task.wait()

	for _, tool in character:GetChildren() do
		if tool:IsA("Tool") then tool:Destroy() end
	end

	local backpack = player:FindFirstChildOfClass("Backpack")
	if not backpack then return end

	for _, tool in backpack:GetChildren() do
		if tool:IsA("Tool") then tool:Destroy() end
	end
end

function ArrestService:ArrestPlayer(Target:Player, Executor:Player)
	local Character = Target.Character
	if not Character then return false, "NoCharacter" end
	if isInCantArrestZone(Target) then Notification:FireClient(Executor, "Arrest/CantArrestHere"); return false, "CantArrestHere" end

	local CurrentCellAttachment:Attachment = nil
	for _, PrisonCellTeleportAttachment:Attachment in CollectionService:GetTagged("PrisonCellTeleport") do
		if PrisonCellTeleportAttachment:GetAttribute("Occupied") then continue end

		CurrentCellAttachment = PrisonCellTeleportAttachment
		break
	end

	if not CurrentCellAttachment then return false, "Not available cell" end
	if not ArrestService:IsPlayerDetained(Target) then return false, "Not detained" end

	unequipAndDestroyTools(Target)

	local state = detainedPlayers[Target]
	if not state then return false, "StateNotFound" end

	if state.weld then state.weld:Destroy() end

	local humanoid = state.humanoid
	local targetTorso = state.targetTorso

	if targetTorso and targetTorso.Parent then
		targetTorso:SetNetworkOwner(Target)
	end

	if humanoid and humanoid.Parent then
		humanoid.PlatformStand = false
		humanoid.AutoRotate = state.originalAutoRotate
	end

	for part, massless in pairs(state.originalMassless) do
		if part and part.Parent then part.Massless = massless end
	end

	disconnectConnections(state.connections)
	detainedPlayers[Target] = nil

	Target:SetAttribute("Detained", "Arrested")
	Target:SetAttribute("DetainedBy", nil)

	task.spawn(function()
		task.wait(0.1)
		if Character and Character.Parent then
			AntiTeleport.WhitelistPlayer(Target, 4.5)
			Character:PivotTo(CurrentCellAttachment.WorldCFrame + Vector3.new(0, 3.5, 0))
		end
	end)

	CurrentCellAttachment:SetAttribute("Occupied")

	task.spawn(RankingService.AdjustXP, Executor, GeneralData.ArrestXP, "Arrest" :: RankingService.Transaction)
	return true
end


local function releaseForPlayer(player: Player)
	ArrestService:ReleasePlayer(player, "PlayerLeft")

	local impacted = {}
	for target, state in pairs(detainedPlayers) do
		if state.executor == player then
			table.insert(impacted, target)
		end
	end

	for _, target in ipairs(impacted) do
		ArrestService:ReleasePlayer(target, "ExecutorLeft")
	end
end

function ArrestService:SetupListeners()
	Observers.observeTag("DetainPrompt", function(prompt: ProximityPrompt)
		if not prompt then return end

		prompt.Triggered:Connect(function(executor: Player)
			if not executor then return end
			local victimPlayer = resolvePromptOwner(prompt)
			if not victimPlayer or victimPlayer == executor then return end
			if getPlayerState(victimPlayer, "Detained") == "Arrested" then return end
			if not (playerIsFederal(executor) and playerHasCuffs(executor))  then return end

			if ArrestService:IsPlayerDetained(victimPlayer) and victimPlayer:GetAttribute("DetainedBy") == executor.Name then
				ArrestService:ReleasePlayer(victimPlayer, "PromptRelease")
				return
			end

			local success, err = ArrestService:SetPlayerDetained(victimPlayer, executor, prompt)
			if not success then
				warn((" Failed to detain %s: %s"):format(victimPlayer.Name, err))
			end
		end)
	end)

	Observers.observeTag("ArrestPrompt", function(prompt: ProximityPrompt)
		if not prompt then return end

		prompt.Triggered:Connect(function(executor: Player)
			if not executor then return end
			local victimPlayer = resolvePromptOwner(prompt)
			if not victimPlayer or victimPlayer == executor then return end
			if getPlayerState(victimPlayer, "Detained") == "Arrested" then return end
			if not (playerIsFederal(executor) and playerHasCuffs(executor))  then return end
			if not ArrestService:IsPlayerDetained(victimPlayer) then return end

			local success, err = ArrestService:ArrestPlayer(victimPlayer, executor)
			if not success then
				warn((" Failed to arrest %s: %s"):format(victimPlayer.Name, err))
			end
		end)
	end)


	Observers.observeTag("JailDoor", function(prompt: ProximityPrompt)
		if not prompt then return end

		prompt.Triggered:Connect(function(executor: Player)
			executor:SetAttribute("Detained", "Not Detained")
			executor:LoadCharacterAsync()
		end)
	end)
end

function ArrestService.Init()
	initCantArrestFolder()
	ArrestService:SetupListeners()
	Players.PlayerRemoving:Connect(releaseForPlayer)
end

return ArrestService
