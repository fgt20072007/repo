local SoundService = game:GetService("SoundService")

local SoundPlayer = {}


local function GetSound(folderName, soundName)
	local name = folderName
	local parent = SoundService
	if typeof(folderName) == "table" then
		for i = 1, #folderName do
			local index = folderName[i]
			parent = parent and parent:FindFirstChild(index) or SoundService:FindFirstChild(index)
		end
	else
		parent = SoundService:FindFirstChild(folderName)
	end

	local sound =  parent and parent:FindFirstChild(soundName)
	return sound
end

function SoundPlayer:GetSound(folderName, soundName)
	return GetSound(folderName, soundName)
end

function SoundPlayer:PlayGlobalSound(folderName, soundName, position, pitch, volume)
	local sound = GetSound(folderName, soundName)
	if not sound then return end

	local attachment = Instance.new("Attachment")
	attachment.WorldPosition = position
	attachment.Parent = workspace.Terrain

	local clone = sound:Clone()
	clone.PlayOnRemove = true
	clone.Pitch = pitch or 1
	clone.Volume =  volume or sound.Volume
	clone.Parent = attachment

	attachment:Destroy()
end

function SoundPlayer:PlaySoundOnce(folderName, soundName, pitch, Volume, deferTask )
	local sound = GetSound(folderName, soundName)
	if not sound then return end

	local clone:Sound = sound:Clone()

	if deferTask then
		deferTask(clone)
	end
	
	clone.Ended:Once(function()
		clone:Destroy()
	end)
	
	clone:Play()

	clone.Parent = SoundService
	clone.PlaybackSpeed = pitch or 1
	clone.Volume = Volume or clone.Volume
	--clone:Destroy()

	return clone
end


return SoundPlayer
