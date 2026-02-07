local part = script.Parent
local TweenService = game:GetService("TweenService")

local distance = 20      -- cuánto se mueve
local time = 2           -- segundos por lado

local startCFrame = part.CFrame
local endCFrame = startCFrame * CFrame.new(distance, 0, 0)

local tweenInfo = TweenInfo.new(
	time,
	Enum.EasingStyle.Sine,
	Enum.EasingDirection.InOut,
	-1,        -- infinito
	true       -- va y vuelve
)

local tween = TweenService:Create(part, tweenInfo, {
	CFrame = endCFrame
})

tween:Play()
