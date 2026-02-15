--!strict
local MIN_ABBREVIATE = 4
local NUM_SUFFIXES = table.freeze {
	'K', 'M', 'B', 't', 'q', 'Q', 's', 'S',
	'o', 'n', 'd', 'U', 'D', 'T', 'Qt', 'Qd',
	'Sd', 'St', 'O', 'N', 'v', 'c'
}

export type DisplayTimeOptions = {
	BaseTime: number?,
	WPM: number?, -- words per minute
	CharsPerSecond: number?
}

local Format = {
	RobuxUTF = utf8.char(0xE002)
}

function Format.WithSuffix(amount: number): string
	if amount < 1_000 then return tostring(amount) end
	
	local suffix = math.log10(amount) // 3
	local remainder = math.floor(amount * 10^(2 - 3 * suffix)) / 100
	
	local fixed = if suffix == -math.huge then 0 else string.format('%.2f', remainder):gsub('%.?0+$', '')
	return fixed .. (NUM_SUFFIXES[suffix] or '')
end

function Format.WithCommas(amount: number): string
	if amount < 1_000 then return tostring(amount) end
	
	local res, _ = string.reverse(tostring(amount)):gsub('(%d%d%d)', '%1,'):reverse():gsub('^,', '')
	return res
end

function Format.Dynamic(amount: number, abbreviateAfter: number?): string
	return if (#tostring(amount) > (abbreviateAfter or 4)) then Format.WithSuffix(amount) else Format.WithCommas(amount)
end

function Format.CalculateDisplayTime(text: string, options: DisplayTimeOptions?)
	local baseTime = options and options.BaseTime or 2
	local wordsPerMinute = options and options.WPM or 220
	local charsPerSecond = options and options.CharsPerSecond or 15

	local wordCount = select(2, string.gsub(text, "%S+", ""))
	local charCount = string.len(text)

	local timeBasedOnWords = (wordCount / wordsPerMinute) * 60
	local timeBasedOnCharacters = charCount / charsPerSecond

	return math.max(baseTime, timeBasedOnWords, timeBasedOnCharacters)
end

table.freeze(Format)
return Format