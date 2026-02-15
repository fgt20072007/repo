local tweenService = game:GetService("TweenService")

local Tween = {}

function Tween:Create(instance:Instance, info:{Time:number, EasingStyle:string, EasingDirection:string, RepeatCount:number, Reverses:boolean, Delay:number}, Properties:{any})
	local _time              = info[1] or 1
	local easingstyle        = info[2] or "Back"
	local easingDirection    = info[3] or "Out"
	local repeatCount        = info[4] or 0
	local reverses           = info[5] or false
	local _delay             = info[6] or 0

	local tweenInfo = TweenInfo.new(_time, Enum.EasingStyle[easingstyle], Enum.EasingDirection[easingDirection], repeatCount, reverses, _delay)
	local tween = tweenService:Create(instance, tweenInfo, Properties)

	return tween, tweenInfo
end

return Tween