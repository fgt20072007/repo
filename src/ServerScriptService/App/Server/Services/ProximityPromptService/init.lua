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

local Service = BaseService.New(SERVICE_NAME, { "GarageService" })

local standardFolder = handlersFolder:FindFirstChild("Standard")
local paidFolder = handlersFolder:FindFirstChild("PaidRandomItems")

local standardHandlers = if standardFolder then HandlerResolver.Build(standardFolder) else {}
local paidHandlers = if paidFolder then HandlerResolver.Build(paidFolder) else {}

local rateLimit = RateLimit.New(RATE_PER_SECOND)

local function isPaidRestricted(player: Player): boolean
	local ok, policyInfo = pcall(PolicyService.GetPolicyInfoForPlayerAsync, PolicyService, player)

	if ok ~= true then
		return true
	end

	return policyInfo.ArePaidRandomItemsRestricted == true
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
	if isPaidRestricted(player) ~= true then
		return
	end

	for tag in paidHandlers do
		player:SetAttribute(DESTROY_PROMPT_PREFIX .. tag, true)
	end
end

function Service:_BuildContext()
	return {
		GarageService = self._garageService,
	}
end

function Service:_OnClientTriggered(player: Player, tag: string)
	if type(tag) ~= "string" then
		return
	end

	if rateLimit:CheckRate(player) ~= true then
		return
	end

	local paidHandler = paidHandlers[tag]
	if paidHandler ~= nil then
		if isPaidRestricted(player) then
			return
		end

		local prompt = findTaggedPromptNear(player, tag)
		if prompt == nil then
			return
		end

		paidHandler.OnTriggered(player, prompt, self:_BuildContext())
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

	standardHandler.OnTriggered(player, prompt, self:_BuildContext())
end

function Service:Init(registry)
	self._garageService = registry:Get("GarageService")
end

function Service:Start(_registry)
	Net.ProximityPromptTriggered.On(function(player, tag)
		self:_OnClientTriggered(player, tag)
	end)

	self.Maid:Add(Players.PlayerAdded:Connect(function(player)
		task.spawn(evaluatePaidAccess, player)
	end))

	for _, player in Players:GetPlayers() do
		task.spawn(evaluatePaidAccess, player)
	end

	self.Maid:Add(function()
		rateLimit:Destroy()
	end)
end

return Service