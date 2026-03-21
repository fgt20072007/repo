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

local destroyPromptAttributePrefix = "DestroyPrompt_"
local promptRatePerSecond = 4

local Service = BaseService.New("ProximityPromptService", { "GarageService", "CarSpawnerService" })

local standardFolder = handlersFolder:FindFirstChild("Standard")
local paidFolder = handlersFolder:FindFirstChild("PaidRandomItems")

local standardHandlers = if standardFolder then HandlerResolver.Build(standardFolder) else {}
local paidHandlers = if paidFolder then HandlerResolver.Build(paidFolder) else {}

local rateLimit = RateLimit.New(promptRatePerSecond)

local function isPaidRestricted(player: Player): boolean
	local ok, policyInfo = pcall(PolicyService.GetPolicyInfoForPlayerAsync, PolicyService, player)

	if ok ~= true then
		return true
	end

	return policyInfo.ArePaidRandomItemsRestricted == true
end

local function evaluatePaidAccess(player: Player)
	if isPaidRestricted(player) ~= true then
		return
	end

	for tag in paidHandlers do
		player:SetAttribute(destroyPromptAttributePrefix .. tag, true)
	end
end

local function loadTaggedPrompt(handler: HandlerResolver.Handler, instance: Instance, context: any)
	local onLoad = handler.OnLoad
	if type(onLoad) ~= "function" then
		return
	end

	if instance:IsA("ProximityPrompt") ~= true then
		return
	end

	onLoad(instance :: ProximityPrompt, context)
end

function Service:_BuildContext()
	return {
		GarageService = self._GarageService,
		CarSpawnerService = self._CarSpawnerService,
	}
end

function Service:_BindHandlerLoads(handlersByTag: { [string]: HandlerResolver.Handler })
	for tag, handler in handlersByTag do
		for _, instance in CollectionService:GetTagged(tag) do
			loadTaggedPrompt(handler, instance, self:_BuildContext())
		end

		self.Maid:Add(CollectionService:GetInstanceAddedSignal(tag):Connect(function(instance)
			loadTaggedPrompt(handler, instance, self:_BuildContext())
		end))
	end
end

function Service:_OnClientTriggered(player: Player, tag: string, prompt: ProximityPrompt?)
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

		if typeof(prompt) ~= "Instance" or prompt:IsA("ProximityPrompt") ~= true then
			return
		end

		local typedPrompt = prompt :: ProximityPrompt
		if CollectionService:HasTag(typedPrompt, tag) ~= true then
			return
		end

		paidHandler.OnTriggered(player, typedPrompt, self:_BuildContext())
		return
	end

	local standardHandler = standardHandlers[tag]
	if standardHandler == nil then
		return
	end

	if typeof(prompt) ~= "Instance" or prompt:IsA("ProximityPrompt") ~= true then
		return
	end

	local typedPrompt = prompt :: ProximityPrompt
	if CollectionService:HasTag(typedPrompt, tag) ~= true then
		return
	end

	standardHandler.OnTriggered(player, typedPrompt, self:_BuildContext())
end

function Service:Init(registry)
	self._GarageService = registry:Get("GarageService")
	self._CarSpawnerService = registry:Get("CarSpawnerService")
end

function Service:Start(_registry)
	self:_BindHandlerLoads(standardHandlers)
	self:_BindHandlerLoads(paidHandlers)

	Net.ProximityPromptTriggered.On(function(player, tag, prompt)
		self:_OnClientTriggered(player, tag, prompt)
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