--!strict

local CollectionService = game:GetService("CollectionService")
local Players = game:GetService("Players")
local PolicyService = game:GetService("PolicyService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")

local appServer = ServerScriptService:WaitForChild("App"):WaitForChild("Server")
local system = appServer:WaitForChild("System")

local appShared = ReplicatedStorage:WaitForChild("App"):WaitForChild("Shared")

local BaseService = require(system:WaitForChild("BaseService"))
local RateLimit = require(appShared:WaitForChild("Util"):WaitForChild("RateLimit"))
local Net = require(appShared:WaitForChild("Net")) :: any

local internal = script:WaitForChild("_Internal")
local HandlerResolver = require(internal:WaitForChild("HandlerResolver"))
local handlersFolder = internal:WaitForChild("Handlers")

local DESTROY_PROMPT_PREFIX = "DestroyPrompt_"
local SERVICE_NAME = "ProximityPromptService"
local RATE_PER_SECOND = 4

local Service = BaseService.New(SERVICE_NAME)

local standardFolder = handlersFolder:FindFirstChild("Standard")
local paidFolder = handlersFolder:FindFirstChild("PaidRandomItems")

local standardHandlers = if standardFolder then HandlerResolver.Build(standardFolder) else {}
local paidHandlers = if paidFolder then HandlerResolver.Build(paidFolder) else {}

local rateLimit = RateLimit.New(RATE_PER_SECOND)
local restrictedPlayers: { [Player]: boolean } = {}

local function queryPolicyRestriction(player: Player): boolean
	local ok, policyInfo = pcall(PolicyService.GetPolicyInfoForPlayerAsync, PolicyService, player)

	if ok ~= true then
		return true
	end

	return policyInfo.ArePaidRandomItemsRestricted == true
end

local function isPlayerRestricted(player: Player): boolean
	local cached = restrictedPlayers[player]
	if cached ~= nil then
		return cached
	end

	local restricted = queryPolicyRestriction(player)
	restrictedPlayers[player] = restricted
	return restricted
end

local function findTaggedPromptNear(player: Player, tag: string): ProximityPrompt?
	local character = player.Character
	if character == nil then
		return nil
	end

	local root = character:FindFirstChild("HumanoidRootPart") :: BasePart?
	if root == nil then
		return nil
	end

	local playerPosition = root.Position

	local tagged = CollectionService:GetTagged(tag)
	for _, instance in tagged do
		if instance:IsA("ProximityPrompt") ~= true then
			continue
		end

		local prompt = instance :: ProximityPrompt
		local adornee = prompt.Parent
		if adornee == nil or adornee:IsA("BasePart") ~= true then
			continue
		end

		local distance = (playerPosition - (adornee :: BasePart).Position).Magnitude
		if distance <= prompt.MaxActivationDistance then
			return prompt
		end
	end

	return nil
end

local function evaluatePaidAccess(player: Player)
	local restricted = isPlayerRestricted(player)
	if restricted ~= true then
		return
	end

	for tag in paidHandlers do
		player:SetAttribute(DESTROY_PROMPT_PREFIX .. tag, true)
	end
end

local function onClientTriggered(player: Player, tag: string)
	if type(tag) ~= "string" then
		return
	end

	if rateLimit:CheckRate(player) ~= true then
		return
	end

	local paidHandler = paidHandlers[tag]
	if paidHandler ~= nil then
		if isPlayerRestricted(player) then
			return
		end

		local prompt = findTaggedPromptNear(player, tag)
		if prompt == nil then
			return
		end

		paidHandler.OnTriggered(player, prompt)
		return
	end

	local standardHandler = standardHandlers[tag]
	if standardHandler == nil then
		return
	end

	local prompt = findTaggedPromptNear(player, tag)
	if prompt == nil then
		return
	end

	standardHandler.OnTriggered(player, prompt)
end

function Service:Init(_registry) end

function Service:Start(_registry)
	Net.ProximityPromptTriggered.On(onClientTriggered)

	self.Maid:Add(Players.PlayerAdded:Connect(function(player)
		task.spawn(evaluatePaidAccess, player)
	end))

	self.Maid:Add(Players.PlayerRemoving:Connect(function(player)
		restrictedPlayers[player] = nil
	end))

	for _, player in Players:GetPlayers() do
		task.spawn(evaluatePaidAccess, player)
	end

	self.Maid:Add(function()
		rateLimit:Destroy()
		table.clear(restrictedPlayers)
	end)
end

return Service