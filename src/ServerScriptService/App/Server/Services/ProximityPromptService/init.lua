--!strict

local CollectionService = game:GetService("CollectionService")
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

local SERVICE_NAME = "ProximityPromptService"
local RATE_PER_SECOND = 4

local Service = BaseService.New(SERVICE_NAME)

local handlersByTag = HandlerResolver.Build(handlersFolder)
local rateLimit = RateLimit.New(RATE_PER_SECOND)

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

local function onClientTriggered(player: Player, tag: string)
	if type(tag) ~= "string" then
		return
	end

	if rateLimit:CheckRate(player) ~= true then
		return
	end

	local handler = handlersByTag[tag]
	if handler == nil then
		return
	end

	local prompt = findTaggedPromptNear(player, tag)
	if prompt == nil then
		return
	end

	handler.OnTriggered(player, prompt)
end

function Service:Init(_registry) end

function Service:Start(_registry)
	Net.ProximityPromptTriggered.On(onClientTriggered)

	self.Maid:Add(function()
		rateLimit:Destroy()
	end)
end

return Service
