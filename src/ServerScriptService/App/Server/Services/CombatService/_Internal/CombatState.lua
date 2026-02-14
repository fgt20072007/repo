local CombatState = {}
CombatState.__index = CombatState

function CombatState.new()
	local self = setmetatable({}, CombatState)
	self._sessions = {}
	return self
end

function CombatState:_getSession(player)
	local session = self._sessions[player]
	if session then
		return session
	end

	session = {
		ComboIndex = 1,
		LastAttackAt = 0,
		ParryEndsAt = 0,
		NextParryAt = 0,
	}

	self._sessions[player] = session
	return session
end

function CombatState:RemovePlayer(player)
	self._sessions[player] = nil
end

function CombatState:IsParrying(player, now)
	local session = self._sessions[player]
	if not session then
		return false
	end

	return now <= session.ParryEndsAt
end

function CombatState:CanParry(player, now)
	local session = self:_getSession(player)
	return now >= session.NextParryAt
end

function CombatState:BeginParry(player, now, duration, cooldown)
	local session = self:_getSession(player)
	session.ParryEndsAt = now + duration
	session.NextParryAt = now + cooldown
end

function CombatState:ConsumeComboIndex(player, now, comboLength, comboResetTime, requestedComboIndex)
	local session = self:_getSession(player)
	local count = math.max(1, comboLength)

	if now - session.LastAttackAt > comboResetTime then
		session.ComboIndex = 1
	end

	local expectedComboIndex = math.clamp(session.ComboIndex, 1, count)
	local comboIndex = expectedComboIndex

	if type(requestedComboIndex) == "number" then
		local requested = math.floor(requestedComboIndex)
		if requested >= 1 and requested <= count then
			if requested == expectedComboIndex or requested == 1 then
				comboIndex = requested
			end
		end
	end

	session.ComboIndex = (comboIndex % count) + 1
	session.LastAttackAt = now

	return comboIndex
end

return CombatState
