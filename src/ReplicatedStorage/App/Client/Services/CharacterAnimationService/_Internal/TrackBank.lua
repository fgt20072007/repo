local TrackBank = {}
TrackBank.__index = TrackBank

function TrackBank.new(animator, config)
	local self = setmetatable({}, TrackBank)
	self._animator = animator
	self._config = config

	self._trackDefinitions = config.TrackDefinitions or {}
	self._tracks = {}

	self._nonLoopedStates = config.NonLoopedTrackDefinitions or {}
	self._currentState = nil

	self._destroyed = false

	self:_loadTracks()
	return self
end

function TrackBank:_createTrack(assetId)
	if type(assetId) ~= "string" or assetId == "" then
		return nil
	end

	local animation = Instance.new("Animation")
	animation.AnimationId = assetId

	local track = self._animator:LoadAnimation(animation)
	track.Priority = self._config.BasePriority
	track.Looped = true

	animation:Destroy()
	return track
end

function TrackBank:_loadTracks()
	for stateName, assetId in pairs(self._trackDefinitions) do
		local track = self:_createTrack(assetId)
		if track then
			if self._nonLoopedStates[stateName] == true then
				track.Looped = false
			end
			self._tracks[stateName] = track
		end
	end
end

function TrackBank:GetCurrentState()
	return self._currentState
end

function TrackBank:HasState(stateName)
	return self._tracks[stateName] ~= nil
end

function TrackBank:IsStatePlaying(stateName)
	local track = self._tracks[stateName]
	if not track then
		return false
	end

	return track.IsPlaying
end

function TrackBank:SetPlaybackSpeed(stateName, speed)
	local track = self._tracks[stateName]
	if not track then
		return
	end

	track:AdjustSpeed(speed)
end

function TrackBank:PlayState(stateName)
	if self._destroyed then
		return
	end

	local targetTrack = self._tracks[stateName]
	if not targetTrack then
		return
	end

	if self._currentState == stateName and targetTrack.IsPlaying then
		return
	end

	for activeState, track in pairs(self._tracks) do
		if activeState == stateName then
			if not track.IsPlaying then
				track:Play(self._config.TransitionFadeTime)
			end
		else
			if track.IsPlaying then
				track:Stop(self._config.TransitionFadeTime)
			end
		end
	end

	self._currentState = stateName
end

function TrackBank:StopAll()
	for _, track in pairs(self._tracks) do
		if track.IsPlaying then
			track:Stop(self._config.ResetFadeTime)
		end
	end

	self._currentState = nil
end

function TrackBank:Destroy()
	if self._destroyed then
		return
	end
	self._destroyed = true

	for _, track in pairs(self._tracks) do
		track:Stop(0)
		track:Destroy()
	end

	table.clear(self._tracks)
	self._currentState = nil
end

return TrackBank
