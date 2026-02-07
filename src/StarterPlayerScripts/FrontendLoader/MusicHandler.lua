-- Services
local Players = game:GetService('Players')
local SoundService = game:GetService('SoundService')

-- Variables
local CARRYING_VOLUME = 0.12
local NOT_CARRYING_VOLUME = 0.3

-- Dependencies
local carryingMusic = SoundService:WaitForChild('DangerAreaSound')
local normalMusic = SoundService:WaitForChild('BackgroundMusic')

local MusicManager = {}

function MusicManager:Initialize()
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