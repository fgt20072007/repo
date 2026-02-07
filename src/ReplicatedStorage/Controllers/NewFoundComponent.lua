local Players = game:GetService('Players')
local ReplicatedStorage = game:GetService('ReplicatedStorage')
local TweenService = game:GetService('TweenService')

local Rarities = require(ReplicatedStorage.DataModules.Rarities)
local EntityData = require(ReplicatedStorage.DataModules.EntityData)

local NewFoundGui = Players.LocalPlayer.PlayerGui:WaitForChild("FoundScreen")
local Fireworks = require("./Fireworks")

local NewFoundComponent = {}

local timeAlive = 1.5
local tweenTime = 0.3

local animationInProgress = false
local FoundQueue = {}

function NewFoundComponent:CreateNewAnimaton(entityName)
	local informations = EntityData[entityName]
	if informations then
		local RarityGradient = Rarities[informations.Rarity].Gradient
		animationInProgress = true
		local NewGui = NewFoundGui:Clone()
		local Container = NewGui.Container
		
		NewGui.Parent = Players.LocalPlayer.PlayerGui
		
		local char = Players.LocalPlayer.Character
		if char then
			local head = char:FindFirstChild("Head")
			Fireworks.PlayFireworks(head, true)
		end
		
		Container.ItemImage.Image = informations.Image
		Container.ItemNameText.Text = entityName
		Container.RarityText.Text = informations.Rarity
		
		local newBackgroundGradient, newStrokeGradient = RarityGradient:Clone(), RarityGradient:Clone()
		newBackgroundGradient.Parent = Container.RarityText
		newStrokeGradient.Parent = Container.RarityText:FindFirstChildOfClass("UIStroke")
		
		local maxDelay = 0
		for _, v in pairs(NewGui:GetDescendants()) do
			if v:IsA("GuiObject") then
				local SavedSize = v.Size
				v.Size = UDim2.fromScale(0, 0)
				local DelayTime = v:GetAttribute("DelayTime") or 0
				if DelayTime > maxDelay then maxDelay = DelayTime end
				task.delay(DelayTime, function()
					TweenService:Create(v, TweenInfo.new(tweenTime, Enum.EasingStyle.Back), {Size = SavedSize}):Play()
					task.wait(timeAlive + DelayTime + tweenTime)
					TweenService:Create(v, TweenInfo.new(tweenTime, Enum.EasingStyle.Sine), {Size = UDim2.fromScale(0, 0)}):Play()
				end)
			end
		end
		
		NewGui.Enabled = true
		
		task.delay(timeAlive + tweenTime * 2 + maxDelay, function()
			NewGui:Destroy()
			if FoundQueue[1] then
				NewFoundComponent:CreateNewAnimaton(table.remove(FoundQueue, 1))
			end
			animationInProgress = false
		end)
	end
end

function NewFoundComponent.QueueAnimation(...)
	if animationInProgress then
		table.insert(FoundQueue, ...)
	else
		NewFoundComponent:CreateNewAnimaton(...)
	end
end

return NewFoundComponent