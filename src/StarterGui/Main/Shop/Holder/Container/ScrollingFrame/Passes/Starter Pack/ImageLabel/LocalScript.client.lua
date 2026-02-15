local TweenService = game:GetService("TweenService")

local ui = script.Parent

local tweenInfo = TweenInfo.new(
	0.6,
	Enum.EasingStyle.Sine,
	Enum.EasingDirection.InOut
)

ui.Rotation = -24

local function tweenTo(rot)
	local t = TweenService:Create(ui, tweenInfo, { Rotation = rot })
	t:Play()
	t.Completed:Wait()
end

while ui.Parent do
	tweenTo(0)
	tweenTo(-24)
end
