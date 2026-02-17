local ReplicatedStorage = game:GetService('ReplicatedStorage')
local TextService = game:GetService('TextService')
local TextChatService = game:GetService('TextChatService')

local Packages = ReplicatedStorage:WaitForChild('Packages')
local Net = require(Packages.Net)
local RateLimit = require(Packages:WaitForChild('ReplicaShared'):WaitForChild('RateLimit'))

local SignRemote = Net:RemoteEvent('Sign_SetText')

local SignService = {}

local MAX_CHARACTERS = 50
local UPDATE_COOLDOWN_SECONDS = 5

local UpdateRateLimit = RateLimit.New(1 / UPDATE_COOLDOWN_SECONDS, true)

local function TrimWhitespace(text: string): string
	return text:match('^%s*(.-)%s*$') or ''
end

local function TruncateUtf8(text: string, maxCharacters: number): string
	local length = utf8.len(text)
	if not length then
		return string.sub(text, 1, maxCharacters)
	end

	if length <= maxCharacters then
		return text
	end

	local byteIndex = utf8.offset(text, maxCharacters + 1)
	if not byteIndex then
		return text
	end

	return string.sub(text, 1, byteIndex - 1)
end

local function NormalizeInput(text): string?
	if typeof(text) ~= 'string' then return nil end
	text = text:gsub('[%c]', ' ')
	text = TrimWhitespace(text)

	if text == '' then
		return ''
	end

	return TruncateUtf8(text, MAX_CHARACTERS)
end

local function FilterText(player: Player, rawText): string?
	local text = NormalizeInput(rawText)
	if text == nil then return nil end
	if text == '' then return '' end

	local success, filteredResult = pcall(function()
		local filterObject = TextService:FilterStringAsync(text, player.UserId, Enum.TextFilterContext.PublicChat)
		return filterObject:GetNonChatStringForBroadcastAsync()
	end)

	if not success then
		return nil
	end

	return filteredResult
end

local function CanPlayerUsePublicText(player: Player): boolean
	local success, canChat = pcall(function()
		return TextChatService:CanUserChatAsync(player.UserId)
	end)

	if not success then
		return false
	end

	return canChat == true
end

local function IsPlayersTool(player: Player, tool: Tool): boolean
	if not player then return false end
	if not tool then return false end

	local character = player.Character
	if character and tool:IsDescendantOf(character) then return true end

	local backpack = player:FindFirstChild('Backpack')
	if backpack and tool:IsDescendantOf(backpack) then return true end

	return false
end

local function GetSignTextLabel(tool: Tool): TextLabel?
	local cardboard = tool:FindFirstChild('Cardboard')
	if not cardboard then return nil end

	local surfaceGui = cardboard:FindFirstChild('SurfaceGui') or cardboard:FindFirstChildWhichIsA('SurfaceGui', true)
	if not (surfaceGui and surfaceGui:IsA('SurfaceGui')) then return nil end

	local textLabel = surfaceGui:FindFirstChild('TextLabel') or surfaceGui:FindFirstChildWhichIsA('TextLabel', true)
	if not (textLabel and textLabel:IsA('TextLabel')) then return nil end

	return textLabel
end

local function ApplyToTool(tool: Tool, filteredText: string)
	local textLabel = GetSignTextLabel(tool)
	if not textLabel then return end

	textLabel.Text = filteredText
end

function SignService.Init()
	SignRemote.OnServerEvent:Connect(function(player, tool, text)
		if not player then return end
		if typeof(tool) ~= 'Instance' then return end
		if not tool:IsA("Tool") then return end
		if tool.Name ~= 'Sign' then return end
		if not IsPlayersTool(player, tool) then return end
		if not GetSignTextLabel(tool) then return end
		if not UpdateRateLimit:CheckRate(player) then return end
		if not CanPlayerUsePublicText(player) then return end

		local filteredText = FilterText(player, text)
		if not filteredText then return end

		ApplyToTool(tool, filteredText)
	end)
end

return SignService
