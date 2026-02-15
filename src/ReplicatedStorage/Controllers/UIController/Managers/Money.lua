local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")

local Util = ReplicatedStorage:WaitForChild("Util")
local Format = require(Util.Format)
local Sounds = require(Util.Sounds)

local Controllers = ReplicatedStorage:WaitForChild("Controllers")
local ReplicaController = require(Controllers:WaitForChild('ReplicaController'))

local Assets = ReplicatedStorage:WaitForChild('Assets')
local TransactionAssets = Assets:WaitForChild('UI'):WaitForChild('Transaction')

local TransactionTemplate = TransactionAssets:WaitForChild('Item')
local PositiveGradient = TransactionAssets:WaitForChild('PositiveGradient')
local NegativeGradient = TransactionAssets:WaitForChild('NegativeGradient')

local Player = Players.LocalPlayer
local PlayerGui = Player:WaitForChild("PlayerGui")

local HUD = PlayerGui:WaitForChild("HUD") :: ScreenGui
local MoneyUI = HUD:WaitForChild("Money") :: Frame
local MoneyLabel = MoneyUI:WaitForChild("MoneyLabel") :: TextLabel
local MoneyButton = MoneyUI:WaitForChild("MoneyButton") :: GuiButton
local TransactionHolder = MoneyUI:WaitForChild('Transactions') :: Frame

local TRANSACTION_LIFETIME = 1.25
local IN_TWEEN_INFO = TweenInfo.new(.3, Enum.EasingStyle.Quad, Enum.EasingDirection.In)
local OUT_TWEEN_INFO = TweenInfo.new(.3, Enum.EasingStyle.Quad, Enum.EasingDirection.In)

local UIController
local TransactionCount = 0

local Money = {}

function Money._LogTransaction(amount: number)
	local increase = amount > 0
	local grad = (increase and PositiveGradient or NegativeGradient):Clone()
	
	local new = TransactionTemplate:Clone()
	local label = new:FindFirstChild('Label')
	
	TransactionCount += 1
	
	label.Text = `{increase and '+' or '-'}${Format.Dynamic(amount, 7)}`
	grad.Parent = label
	
	new.Size = UDim2.fromScale(1)
	new.LayoutOrder = TransactionCount
	new.Parent = TransactionHolder
	
	local inTween = TweenService:Create(new, IN_TWEEN_INFO, {Size = TransactionTemplate.Size})
	local outTween = TweenService:Create(new, OUT_TWEEN_INFO, {Size = UDim2.fromScale(1)})
	
	task.spawn(function()
		Sounds.Play('SFX/Notification/Transaction')
		
		inTween:Play()
		inTween.Completed:Wait()
		
		task.wait(TRANSACTION_LIFETIME)
		
		outTween:Play()
		outTween.Completed:Wait()
		
		inTween:Destroy()
		outTween:Destroy()
		new:Destroy()
	end)
end

function Money:_setupConnections()
	MoneyButton.MouseButton1Click:Connect(function()
		warn("opening toggle")
		UIController:Toggle("Shop")
		
		
		warn("opened shop")
	end)
end

function Money.Init(controller)
	UIController = controller
	
	task.spawn(function()
		local succ, res: ReplicaController.Replica = ReplicaController.GetReplicaAsync('PlayerData'):await()
		if not succ then return end

		local lastCount: number?
		local function onChange()
			local saved = lastCount
			local data = res.Data
			MoneyLabel.Text = "$"..Format.Dynamic(data and data.Cash or 0, 7)
			
			if not data.Cash or saved == data.Cash then return end
			lastCount = data.Cash
			
			if not saved then return end
			local diff = data.Cash - saved
			Money._LogTransaction(diff)
		end

		res:OnSet({'Cash'}, onChange)
		onChange()
		
		Money:_setupConnections()
	end)
end

return Money