return function(player:Player)
	local Username = string.upper(player.Name)
	local UserId = player.UserId
	local UserNameLength = string.len(Username)

	local hName = 0
	for i = 1, UserNameLength do
		hName = hName + string.byte(Username, i)
	end

	if hName == 0 then
		hName = 42
	end

	local function GetLetter(Base)
		if UserNameLength == 0 then
			return 'Z'
		end

		local indice = (Base % UserNameLength) + 1

		if indice >= 1 and indice <= UserNameLength then
			return string.sub(Username, indice, indice)
		else
			return 'Z'
		end
	end

	local baseL1 = hName
	local baseL2 = hName + UserId
	local baseL3 = UserNameLength * hName

	local L1 = GetLetter(baseL1)
	local L2 = GetLetter(baseL2)
	local L3 = GetLetter(baseL3)

	local Letters = L1 .. L2 .. L3
	local MixedValue = (UserId * hName) + UserId

	local ComponentNumber = string.format("%04d", MixedValue % 10000)

	local licensePlate = Letters .. ComponentNumber

	return licensePlate
end
