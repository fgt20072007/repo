local TextChatService = game:GetService("TextChatService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local remote = ReplicatedStorage:WaitForChild("OpenDoorEvent")
local correctPhrase = "bombardino cocodrilo"

TextChatService.OnIncomingMessage = function(message)
	if not message.TextSource then return end

	-- Normalizar texto
	local text = string.lower(message.Text)
	text = text:gsub("%s+", " "):match("^%s*(.-)%s*$") -- limpia espacios

	if text == correctPhrase then
		remote:FireServer()
	end
end
