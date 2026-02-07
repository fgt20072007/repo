local players = game:GetService("Players")
local collectionService = game:GetService("CollectionService")
local replicatedStorage = game:GetService("ReplicatedStorage")

local DataService = require(replicatedStorage.Utilities.DataService).client

local lPlayer = players.LocalPlayer
local gui = lPlayer.PlayerGui:WaitForChild("MainGui")
local animationsHandler = require(script.Animations).new("MainGui")
local registry = require(script.Registry)

local InviteModule = require("./InviteHandler")

local guiHandler = {}
local framesContainer = gui.Frames
local xButtonName = "XButton"

function guiHandler.handleFrame(frame: Frame)
	local closeButton = frame:FindFirstChild(xButtonName, true)
	local updateCallback = nil
	local referenceModule = replicatedStorage.Controllers.Frames:FindFirstChild(frame.Name .. "Frame")
	if registry[frame.Name] then
		animationsHandler:SetupFrameInSelf(frame, nil, registry[frame.Name])
	end
	if referenceModule then
		local success, returnfunction = pcall(function()
			local r = require(referenceModule)
			if typeof(r["Update"]) == "function" then
				updateCallback = r["Update"]
			end
		end)
		if not success then
			warn(returnfunction)
		end
	end

	for _, v in collectionService:GetTagged(frame.Name) do
		animationsHandler:BindButtonToFrame(v, frame)
	end

	animationsHandler:BindActionToFrameOpen(updateCallback, frame)

	if closeButton then
		animationsHandler:BindCloseButtonToFrame(closeButton, frame)
	end
end

function guiHandler.Initialize()
	
	for _, frame in framesContainer:GetChildren() do
		guiHandler.handleFrame(frame)
	end
	
	local SpawnButton = gui:FindFirstChild("SpawnButton", true)
	local InviteButton = gui:FindFirstChild("InviteButton", true)
	
	SpawnButton.Activated:Connect(function()
		local char = players.LocalPlayer.Character
		if char then
			char:PivotTo(workspace.ConveyorPoints.SpawnPart.CFrame)
		end
	end)
	
	workspace:WaitForChild('IndexOpen').ProximityPrompt.Triggered:Connect(function()
		animationsHandler:OpenFrame(framesContainer.Index)
	end)
	
	workspace:WaitForChild('ShopOpen').ProximityPrompt.Triggered:Connect(function()
		animationsHandler:OpenFrame(framesContainer.Shop)
	end)
	
	InviteButton.Activated:Connect(function()
		InviteModule.PromptInvite()
	end)

	for _, v in pairs(replicatedStorage.Controllers.Frames:GetChildren()) do
		if v:IsA("ModuleScript") then
			local r = require(v)
			if r["Initialize"] then
				r["Initialize"](framesContainer)
			end
		end
	end
end

return guiHandler
