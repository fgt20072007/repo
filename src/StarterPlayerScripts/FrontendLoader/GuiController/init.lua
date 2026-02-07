local players = game:GetService("Players")
local collectionService = game:GetService("CollectionService")
local replicatedStorage = game:GetService("ReplicatedStorage")

local DataService = require(replicatedStorage.Utilities.DataService).client

local lPlayer = players.LocalPlayer
local gui = lPlayer.PlayerGui:WaitForChild("MainGui")
local animationsHandler = require(script.Animations).new("MainGui")
local registry = require(script.Registry)

local RemoteBank = require(replicatedStorage.RemoteBank)
local Format = require(replicatedStorage.Utilities.Format)
local SharedFunctions = require(replicatedStorage.DataModules.SharedFunctions)

local ReplicatedStorage = game:GetService('ReplicatedStorage')
local Signal = require(ReplicatedStorage.Utilities.Signal)

local AcceptSignal = Signal.new()
local RejectSignal = Signal.new()

local guiHandler = {}
local framesContainer = gui.Frames
local xButtonName = "XButton"

local Zone = require(replicatedStorage.Utilities.Zone)

function guiHandler.AddButton(button)
	animationsHandler:HandleButton(button)
end

function guiHandler.handleFrame(frame: Frame)
	local closeButton = frame:FindFirstChild(xButtonName, true)
	local updateCallback = nil
	local referenceModule = script.Parent.Frames:FindFirstChild(frame.Name .. "Frame")
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

local Spring = require(ReplicatedStorage.Utilities.Spring)
function guiHandler.Initialize()
	
	for _, frame in framesContainer:GetChildren() do
		guiHandler.handleFrame(frame)
	end

	for _, v in pairs(script.Parent.Frames:GetChildren()) do
		if v:IsA("ModuleScript") then
			local r = require(v)
			if r["Initialize"] then
				task.spawn(function()
					r["Initialize"](framesContainer)
				end)
			end
		end
	end
	
	local cashSrping = Spring.new(0, 1, 20)
	game:GetService("RunService").RenderStepped:Connect(function()
		gui.Currencies.CashLabel.Text = "$" .. Format.formatWithCommas(math.floor(cashSrping.Position)) 
	end)
	
	cashSrping.Target = DataService:get("cash")
	DataService:getChangedSignal("cash"):Connect(function()
		cashSrping.Target = DataService:get("cash")
	end)
	
	local sellzoneobject = workspace:WaitForChild("SellZone")
	local sellzone = Zone.new(sellzoneobject)
	
	sellzone.localPlayerEntered:Connect(function()
		animationsHandler:OpenFrame(framesContainer.SellFrame)
	end)
	
	local gearzone = Zone.new(workspace:WaitForChild("GearShopZone"))

	gearzone.localPlayerEntered:Connect(function()
		animationsHandler:OpenFrame(framesContainer.GearsShop)
	end)
end

return guiHandler
