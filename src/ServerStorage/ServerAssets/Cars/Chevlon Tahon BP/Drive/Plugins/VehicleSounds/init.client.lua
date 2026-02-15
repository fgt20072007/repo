local car = script.Parent.Car.Value
local handler = car:WaitForChild("VehicleSoundsEvent")
local _Tune = require(car["Drive"])

while wait() do
	local _RPM = script.Parent.Values.RPM.Value
	local throt = 0
	local on = 0
	if script.Parent.Values.Throttle.Value <= _Tune.IdleThrottle/100 then
		throt = math.max(.3,throt-.2)	
	else
		throt = math.min(1,throt+.1)	
	end	

	if not script.Parent.IsOn.Value then on=math.max(on-.015,0) else on=1 end
	handler:FireServer(_RPM, _Tune.Redline, on)
end
