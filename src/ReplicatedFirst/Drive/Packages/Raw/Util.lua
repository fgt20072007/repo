--!strict
--!native
--!optimize 2

local math_pi = math.pi
local math_tau = 2*math_pi
local math_min = math.min
local math_lerp = math.lerp
local math_clamp = math.clamp

local string_find = string.find

local vector3_zero = Vector3.zero
local vector3_new = Vector3.new

local cframe_fromeuleranglesyxz = CFrame.fromEulerAnglesYXZ
local cframe_identity = CFrame.identity
local cframe_toobjectspace = cframe_identity.ToObjectSpace

local cframe_offset1 = CFrame.Angles(0, -math.pi, 0)

local lib = {}

function lib.clampV3(U: Vector3, M: number)
	local UM = U.Magnitude
	if UM == 0 then
		return vector3_zero, vector3_zero
	end

	local V = U/UM*math_min(UM, M)
	return V, U - V
end

function lib.computePower(m: number, n: number, p: number, q: number, M: number, b: number, x: number)
	return math_clamp(M - ((q - n)/(b^p - b^m)*(b^x - b^m) + n), 0, M)
end

function lib.wrapAngle(theta: number)
	return (theta + math_pi)%math_tau - math_pi
end

function lib.lerpAngle(theta0: number, theta1: number, t: number)
	local dtheta = lib.wrapAngle(theta1 - theta0)
	return theta0 + dtheta*t
end

function lib.updateHubMotor(HubMotor: any, HubCFrame: CFrame, Side: boolean, Rotation: number, Steer: number, Length: number)
	local Theta = cframe_fromeuleranglesyxz(Rotation, Steer, 0) do
		if Side then
			Theta *= cframe_offset1
		end
	end

	local Anchor = HubCFrame*Theta - vector3_new(0, Length, 0)
	HubMotor.C1 = Anchor
	HubMotor.C0 = cframe_toobjectspace(HubMotor.Part0.CFrame, HubMotor.Part1.CFrame)*Anchor
end

function lib.updateEngineSounds(Sounds: {Sound}, RPM: number, Throttle: number)
	for _, Sound in Sounds do
		if not Sound:IsA 'Sound' then continue end
		if not string_find(Sound.Name, 'ENG') then continue end
		
		local transitionStart = Sound:GetAttribute 'TransitionStart'
		local transitionEnd = Sound:GetAttribute 'TransitionEnd'
		
		local rangeStart = Sound:GetAttribute 'RangeStart'
		local rangeEnd = Sound:GetAttribute 'RangeEnd'
		local rangeAlpha = RPM/rangeEnd
		
		local baseVolume = Sound:GetAttribute 'BaseVolume'
		local basePlaybackSpeed = Sound:GetAttribute 'BasePlaybackSpeed'
		local redlinePlaybackSpeed = Sound:GetAttribute 'RedlinePlaybackSpeed'
		
		local throttleVolume = Throttle*Sound:GetAttribute 'ThrottleVolume'
		local redlineVolume = rangeAlpha*Sound:GetAttribute 'RedlineVolume'
		local inVolume = math_clamp((RPM - rangeStart)/transitionStart, 0, 1)
		local outVolume = math_clamp((rangeEnd - RPM)/transitionEnd, 0, 1)
		
		Sound.PlaybackSpeed = math_lerp(basePlaybackSpeed, redlinePlaybackSpeed, rangeAlpha)
		Sound.Volume = (baseVolume + throttleVolume + redlineVolume)*inVolume*outVolume
	end
end

return lib