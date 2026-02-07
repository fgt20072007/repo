local ReplicatedStorage = game:GetService('ReplicatedStorage')
local Players = game:GetService('Players')

local ToolsData = require(ReplicatedStorage.DataModules.ToolsData)
local SharedUtilities = require(ReplicatedStorage.Utilities.SharedUtilities)

local GlobalConfiguration = require(ReplicatedStorage.DataModules.GlobalConfiguration)

local ToolsUi = Players.LocalPlayer.PlayerGui:WaitForChild("MainGui").Right
local TemplateTool = ToolsUi.TemplateTool:Clone()

local purchaseFunction = ReplicatedStorage.Communication.Functions.PromptPurchase

local RightSideTools = {}

local function GetToolsFromVtoJ(v: number, j: number)
	local t = {}
	local i = 0
	for element, informations in ToolsData do
		i += 1
		if i > v and i <= j then
			t[element] = informations
		end
	end
	return t
end

function RightSideTools.Initialize()
	local NumberOfTools = SharedUtilities.getLenghtOfT(ToolsData)
	local FirstHalf = math.floor(NumberOfTools / 2)
	local CurrentRotation = 1
	task.spawn(function()
		while true do
			local Tools = GetToolsFromVtoJ(CurrentRotation == 1 and 0 or FirstHalf, CurrentRotation == 1 and FirstHalf or NumberOfTools)
			for _, v in ToolsUi:GetChildren() do
				if v:IsA("GuiObject") then v:Destroy() end
			end
			
			for entity, informations in Tools do
				local NewTemplate = TemplateTool:Clone()
				NewTemplate.Name = entity
				NewTemplate.TextLabel.Text = entity
				task.spawn(function()
					NewTemplate.PriceAmount.Text = SharedUtilities.getProductPrice(informations.GamepassId, Enum.InfoType.GamePass, Players.LocalPlayer) .. ""
				end)
				NewTemplate.ImageLabel.Image = informations.Image
				NewTemplate.Parent = ToolsUi
				NewTemplate.Visible = true
				NewTemplate.Activated:Connect(function()
					purchaseFunction:InvokeServer(true, informations.GamepassId)
				end)
			end
			
			CurrentRotation = CurrentRotation == 1 and 2 or 1
			task.wait(GlobalConfiguration.RightSideToolsRefreshCooldown)
		end
	end)
end

return RightSideTools