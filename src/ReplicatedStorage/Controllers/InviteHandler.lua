local SocialService = game:GetService("SocialService")
local Players = game:GetService("Players")

local InviteModule = {}

-- Checks whether the local player can send invites
function InviteModule.CanSendInvites()
	local player = Players.LocalPlayer

	local success, result = pcall(function()
		return SocialService:CanSendGameInviteAsync(player)
	end)

	if success then
		return result
	else
		warn("Failed to check invite permissions:", result)
		return false
	end
end

-- Prompts the invite UI
function InviteModule.PromptInvite()
	local player = Players.LocalPlayer

	local success, err = pcall(function()
		SocialService:PromptGameInvite(player)
	end)

	if not success then
		warn("Failed to prompt invite:", err)
	end
end

function InviteModule.Initialize()
	local PlayerCanSendInvites = InviteModule.CanSendInvites()
end

return InviteModule