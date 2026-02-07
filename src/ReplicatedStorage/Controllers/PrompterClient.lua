local AvatarEditorService = game:GetService('AvatarEditorService')
local ReplicatedStorage = game:GetService('ReplicatedStorage')
local SocialService = game:GetService('SocialService')

local GlobalConfiguration = require(ReplicatedStorage.DataModules.GlobalConfiguration)

local PrompterClient = {}

function PrompterClient.Initialize()
	if GlobalConfiguration.PromptGameFavourite then
		task.delay(GlobalConfiguration.FavroutieTimeAfterJoin, function()
			AvatarEditorService:PromptSetFavorite(game.PlaceId, 1)
		end)
	end
	
	if GlobalConfiguration.PromptEvent then
		task.delay(GlobalConfiguration.EventTimeAfterPlayerJoin, function()
			local status = SocialService:GetEventRsvpStatusAsync(GlobalConfiguration.EventId)
			if status == Enum.RsvpStatus.None or status == Enum.RsvpStatus.NotGoing then
				SocialService:PromptRsvpToEventAsync(GlobalConfiguration.EventId)
			end
		end)
	end
end

return PrompterClient
