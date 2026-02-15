local ReplicatedStorage = game:GetService('ReplicatedStorage')
local TextService = game:GetService('TextService')

local Packages = ReplicatedStorage:WaitForChild('Packages')
local Net = require(Packages.Net)

local SignRemote = Net:RemoteEvent('Sign_SetText')

local SignService = {}

local MAX_CHARACTERS = 50

local function FilterText(player, text)
	if not player then return end
	if typeof(text) ~= "string" then return end
	if text == "" then return "" end
	if #text > MAX_CHARACTERS then text = string.sub(text, 1, MAX_CHARACTERS) end

	local success, filteredResult = pcall(function()
		local filterObject = TextService:FilterStringAsync(text, player.UserId)
		return filterObject:GetNonChatStringForBroadcastAsync()
	end)

	if not success then return string.rep("#", #text) end
	if filteredResult == text then return text end

	local originalWords = string.split(text, " ")
	local filteredWords = string.split(filteredResult, " ")
	if #originalWords ~= #filteredWords then return filteredResult end

	for i = 1, #originalWords do
		if filteredWords[i] ~= originalWords[i] then
			originalWords[i] = string.rep("#", #originalWords[i])
		end
	end

	return table.concat(originalWords, " ")
end

local function IsPlayersTool(player, tool)
	if not player then return false end
	if not tool then return false end

	local character = player.Character
	if character and tool:IsDescendantOf(character) then return true end

	local backpack = player:FindFirstChild("Backpack")
	if backpack and tool:IsDescendantOf(backpack) then return true end

	return false
end

local function ApplyToTool(tool, filteredText)
	if not tool then return end

	local cardboard = tool:FindFirstChild("Cardboard")
	if not cardboard then return end

	local surfaceGui = cardboard:FindFirstChild("SurfaceGui")
	if not surfaceGui then return end

	local textLabel = surfaceGui:FindFirstChild("TextLabel")
	if not textLabel then return end

	textLabel.Text = filteredText
end

function SignService.Init()
	SignRemote.OnServerEvent:Connect(function(player, tool, text)
		if not player then return end
		if typeof(tool) ~= "Instance" then return end
		if not tool:IsA("Tool") then return end
		if tool.Name ~= "Sign" then return end
		if not IsPlayersTool(player, tool) then return end

		local filteredText = FilterText(player, text)
		if not filteredText then return end

		ApplyToTool(tool, filteredText)
	end)
end

return SignService