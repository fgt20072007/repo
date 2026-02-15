local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")

local Packages = ReplicatedStorage:WaitForChild('Packages')
local Net = require(Packages.Net)

local Util = ReplicatedStorage:WaitForChild("Util")
local Format = require(Util.Format)
local Sounds = require(Util.Sounds)

local Assets = ReplicatedStorage:WaitForChild('Assets')
local TransactionAssets = Assets:WaitForChild('UI'):WaitForChild('Transaction')
local TransactionTemplate = TransactionAssets:WaitForChild('XPItem')

-- UI
local Player = Players.LocalPlayer
local PlayerGui = Player:WaitForChild("PlayerGui")

local HUD = PlayerGui:WaitForChild("HUD") :: ScreenGui
local Holder = HUD:WaitForChild("XPTransactions") :: Frame

-- Config
local TRANSACTION_LIFETIME = 1.25
local IN_TWEEN_INFO = TweenInfo.new(.3, Enum.EasingStyle.Quad, Enum.EasingDirection.In)
local OUT_TWEEN_INFO = TweenInfo.new(.3, Enum.EasingStyle.Quad, Enum.EasingDirection.In)

local FIX_TYPE: {[string]: string} = table.freeze {}

-- Manager
local NotifEvent = Net:RemoteEvent('XPTransaction')

local UIController
local TransactionCount = 0
local XPTransactions = {}

function XPTransactions._LogTransaction(amount: number, transType: string?)
	if typeof(amount) ~= 'number' then return end
	
	local new = TransactionTemplate:Clone()
	local label = new:FindFirstChild('Label')

	TransactionCount += 1

	local base = `{amount > 0 and '+' or '-'}{Format.Dynamic(amount, 6)} XP`
	label.Text = "<"..transType and `{base} <font color="#ffffff" weight="SemiBold"><i>({FIX_TYPE[transType] or transType})</i></font>`
		or base
	
	new.LayoutOrder = TransactionCount
	new.Parent = Holder

	local inTween = TweenService:Create(new, IN_TWEEN_INFO, {Size = TransactionTemplate.Size})
	local outTween = TweenService:Create(new, OUT_TWEEN_INFO, {Size = UDim2.fromScale(1)})

	task.spawn(function()
		Sounds.Play('SFX/Notification/XP')

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

function XPTransactions.Init(controller)
	UIController = controller
	
	NotifEvent.OnClientEvent:Connect(XPTransactions._LogTransaction)
end

return XPTransactions