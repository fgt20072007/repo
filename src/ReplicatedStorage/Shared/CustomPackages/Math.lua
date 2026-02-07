local Math = {}

function Math.CompareValues(value1: number, value2: number)
	if typeof(value1) ~= "number" or typeof(value2) ~= "number" then
		warn(`Value1 and Value2 must be of type number`)
		return
	end

	if value1 == value2 then
		return "EQUAL"
	end

	return value1 > value2
end

function Math.GetDifferenceOfNumbers(value1: number, value2: number, abs: boolean?)
	if typeof(value1) ~= "number" or typeof(value2) ~= "number" then
		warn(`Value1 and Value2 must be of type number`)
		return
	end

	if value1 == value2 then
		return 0, value1
	end

	local biggestNumber = value1 > value2 and value1 or value2

	if abs then
		return math.abs(value1 - value2), biggestNumber
	end

	local notBiggestNumber = biggestNumber == value1 and value2 or value1

	return biggestNumber - notBiggestNumber, biggestNumber
end

function Math.FormatCurrency(value: number)
	if typeof(value) ~= "number" then
		return "0"
	end

	local absValue = math.abs(value)
	local sign = value < 0 and "-" or ""

	local units = {
		{ 1e15, "q" },
		{ 1e12, "t" },
		{ 1e9, "b" },
		{ 1e6, "m" },
		{ 1e3, "k" },
	}

	for _, unit in units do
		if absValue >= unit[1] then
			local formatted = absValue / unit[1]
			formatted = formatted >= 100 and math.floor(formatted) or math.floor(formatted * 10) / 10

			return sign .. formatted .. unit[2]
		end
	end

	return sign .. tostring(math.floor(absValue))
end

return Math
