--[[
	SERVER PLUGINS' NAMES MUST START WITH "Server:" OR "Server-"
	CLIENT PLUGINS' NAMES MUST START WITH "Client:" OR "Client-"

	Plugins have full access to the server/client tables and most variables.

	You can use the MakePluginEvent to use the script instead of setting up an event.
	PlayerJoined will fire after the player finishes initial loading
	CharacterAdded will also fire after the player is loaded, it does not use the CharacterAdded event.

	service.Events.PlayerAdded:Connect(function(p)
		print(`{p.Name} Joined! Example Plugin`)
	end)

	service.Events.CharacterAdded:Connect(function(p)
		server.RunCommand('name', plr.Name, 'BobTest Example Plugin')
	end)

--]]

return function(Vargs)
	local server, service = Vargs.Server, Vargs.Service

	server.Commands = {
		Prefix = server.Settings.Prefix;	-- Prefix to use for command
		Commands = {"follow"};	-- Commands
		Args = {"UserID/Player"};	-- Command arguments
		Description = "Follows the user to their server";	-- Command Description
		Hidden = false; -- Is it hidden from the command list?
		Fun = false;	-- Is it fun?
		AdminLevel = "Moderators";	    -- Admin level; If using settings.CustomRanks set this to the custom rank name (eg. "Baristas")
		Function = function(plr,args)    -- Function to run for command
			if not args[1] then
				return "Please specify a player."
			end

			-- Get target player from name
			local target = service.Players:FindFirstChild(args[1])

			if not target then
				return "Player not found in this server."
			end

			local TeleportService = game:GetService("TeleportService")

			local success, placeId, jobId = pcall(function()
				return TeleportService:GetPlayerPlaceInstanceAsync(target.UserId)
			end)

			if success and placeId and jobId then
				TeleportService:TeleportToPlaceInstance(placeId, jobId, plr)
			else
				return "Could not follow player. They may be in a private server or offline."
			end
		end
	}
end
