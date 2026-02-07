local ReplicatedStorage = game:GetService('ReplicatedStorage')
local Players = game:GetService('Players')
local TweenService = game:GetService('TweenService')
local CollectionService = game:GetService('CollectionService')

local LuckyBlocksData = require(ReplicatedStorage.DataModules.LuckyBlocksData)

local EntityHandler = require("./EntityClientHandler")
local OpenFunction = ReplicatedStorage.Communication.Functions.OpenLuckyblock

local GlobalConfiguration = require(ReplicatedStorage.DataModules.GlobalConfiguration)

local EntityData = require(ReplicatedStorage.DataModules.EntityData)
local NotificationComponent = require("./NotificationComponent")

local ProductIds = require(ReplicatedStorage.DataModules.ProductIds)
local PromptPurchase = ReplicatedStorage.Communication.Functions.PromptPurchase

local Format = require(ReplicatedStorage.Utilities.Format)

local LuckyBlockHandler = {}
local Debounces = {}

function LuckyBlockHandler.HandleLuckyblock(Luckyblock: Folder & { GuiSpawn: BasePart, Luckyblock: Model })
	Debounces[Luckyblock] = false
	local NewBillboard =  script.BillboardGui:Clone()
	NewBillboard.ResetOnSpawn = false  -- 👈 AQUÍ VA
	NewBillboard.Parent = Players.LocalPlayer.PlayerGui
	NewBillboard.Adornee = Luckyblock:WaitForChild("GuiSpawn")
	
	local luckyblockInformations = LuckyBlocksData[Luckyblock.Name]
	NewBillboard.List.LuckyBlockName.Text = luckyblockInformations.DisplayName
	
	local Container = NewBillboard.List.RewardsContainer
	local Template = Container.Template
	
	for element, percentage in luckyblockInformations.Findables do
		local entityInformations = EntityData[element]
		if entityInformations then
			local NewTemplate = Template:Clone()
			NewTemplate.LayoutOrder = -percentage
			NewTemplate.NameLabel.Text = element
			NewTemplate.ImageLabel.Image = entityInformations.Image
			NewTemplate.PercentageLabel.Text = percentage.."%"
			NewTemplate.Visible = true
			NewTemplate.Parent = Container
		end
	end
	
	local ButtonsContainer = NewBillboard.ButtonsContainer
	local NormalLuck = ButtonsContainer.NormalLuck
	local SuperLuck = ButtonsContainer.SuperLuck
	local OpenButton = ButtonsContainer.OpenButton
	
	local player = Players.LocalPlayer
	task.spawn(function()
		while true do
			local currentTime = os.time()
			local Luck2xTime = player:GetAttribute(GlobalConfiguration.Luck2xAttribute) or currentTime
			local Luck10xTime = player:GetAttribute(GlobalConfiguration.Luck10xAttribute) or currentTime
			
			NormalLuck.Activated:Connect(function()
				PromptPurchase:InvokeServer(false, ProductIds.Luckyblock2x)
			end)
			
			SuperLuck.Activated:Connect(function()
				PromptPurchase:InvokeServer(false, ProductIds.Luckyblock10x)
			end)
			
			
			NormalLuck.TextLabel.Text = Format.formatTime(Luck2xTime - currentTime) .. "s"
			SuperLuck.TextLabel.Text = Format.formatTime(Luck10xTime - currentTime) .. "s"
			task.wait(1)
		end
	end)
	
	OpenButton.Activated:Connect(function()
		if Debounces[Luckyblock] then 
			NotificationComponent:Notify("Luckyblock is in cooldown!")
			return
		end
		Debounces[Luckyblock] = true
		local result = OpenFunction:InvokeServer(Luckyblock.Name)
		if result then
			local LuckyblockModel: Model = Luckyblock:FindFirstChild("Luckyblock")
			for i=1, 30 do
				LuckyblockModel:PivotTo(LuckyblockModel:GetPivot() * CFrame.Angles(0, math.rad(12), 0))
				task.wait()
			end
			
			local remove = EntityHandler.SpawnEntity(result, Luckyblock:FindFirstChild("EntitySpawn").CFrame)
			
			task.delay(GlobalConfiguration.DefaultDelayBetween, function()
				remove()
				Debounces[Luckyblock] = false
			end)
		else
			Debounces[Luckyblock] = false
		end
	end)
end

function LuckyBlockHandler.Initialize()
	task.wait(2)
	for _, v in CollectionService:GetTagged(GlobalConfiguration.LuckyBlockTag) do
		LuckyBlockHandler.HandleLuckyblock(v)
	end
end

return LuckyBlockHandler
