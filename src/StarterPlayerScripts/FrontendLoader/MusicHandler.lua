-- Services
local Players = game:GetService('Players')
local SoundService = game:GetService('SoundService')
local RunService = game:GetService('RunService')

-- Variables
local CARRYING_VOLUME = 0.12
local NOT_CARRYING_VOLUME = 0.3
local BLOCKED_SOUND_ASSET_ID = "131766937611736"

-- Dependencies
local carryingMusic = SoundService:WaitForChild('DangerAreaSound')
local normalMusic = SoundService:WaitForChild('BackgroundMusic')

local MusicManager = {}

local function sanitizeBlockedStudioSound(sound)
	if not RunService:IsStudio() then
		return
	end

	local soundId = tostring(sound.SoundId or "")
	if string.find(soundId, BLOCKED_SOUND_ASSET_ID, 1, true) then
		sound:Stop()
		sound.Playing = false
		sound.SoundId = ""
	end
end

function MusicManager:Initialize()
	sanitizeBlockedStudioSound(carryingMusic)
	sanitizeBlockedStudioSound(normalMusic)

	local player = Players.LocalPlayer

	self:_updateMusic(player:GetAttribute('Carrying') or false)

	player:GetAttributeChangedSignal('Carrying'):Connect(function()
		self:_updateMusic(player:GetAttribute('Carrying'))
	end)
end

function MusicManager:_updateMusic(isCarrying)
	if isCarrying then
		carryingMusic.Volume = 0.4
		normalMusic.Volume = 0
	else
		carryingMusic.Volume = 0
		normalMusic.Volume = 0.1
	end
end

return MusicManager