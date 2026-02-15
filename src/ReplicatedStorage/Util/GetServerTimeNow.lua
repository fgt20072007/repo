--!strict
local REQUEST_EVERY = 5

local LastRequest = 0
local LastResponse = 0

local function GetServerTimeNow(): number
	local now = os.clock()
	local diff = now - LastRequest 

	if diff >= REQUEST_EVERY then
		LastRequest = now
		LastResponse = workspace:GetServerTimeNow()
		return LastResponse
	end

	return LastResponse + diff
end

return GetServerTimeNow