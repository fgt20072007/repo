local RunService = game:GetService("RunService")
if not RunService:IsStudio() then
	return
end

local SoundService = game:GetService("SoundService")
local BLOCKED_SOUND_ASSET_ID = "131766937611736"

local function sanitizeSound(instance)
	if not instance:IsA("Sound") then
		return
	end

	local soundId = tostring(instance.SoundId or "")
	if string.find(soundId, BLOCKED_SOUND_ASSET_ID, 1, true) then
		instance:Stop()
		instance.Playing = false
		instance.SoundId = ""
	end
end

for _, instance in SoundService:GetDescendants() do
	sanitizeSound(instance)
end

local connection = SoundService.DescendantAdded:Connect(sanitizeSound)
task.delay(10, function()
	if connection.Connected then
		connection:Disconnect()
	end
end)